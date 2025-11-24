//
//  OllamaAPIService.swift
//  MedicalAssistant
//
//  Created by Claude
//

import Foundation
import PDFKit

class OllamaAPIService: @unchecked Sendable {
    static let shared = OllamaAPIService()
    // LLM Tuning Parameters
    var temperature: Double = 0.7
    var maxTokens: Int = 8192
    var topP: Double = 1.0
    var customSystemPrompt: String = ""
    
    private init() {}
    
    // MARK: - PDF Extraction (Local using PDFKit)
    func extractTextFromPDF(pdfData: Data) async throws -> String {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load PDF data"])
        }
        
        var fullText = ""
        let pageCount = pdfDocument.pageCount
        
        for i in 0..<pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No text could be extracted from the PDF. It might be an image-only PDF."])
        }
        
        return fullText
    }
    
    // MARK: - API Call
    private func callOllama(baseURL: String, model: String, messages: [[String: String]], systemPrompt: String? = nil) async throws -> String {
        print("Calling Ollama with maxTokens: \(maxTokens), temperature: \(temperature)")
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Base URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var apiMessages = messages
        
        // Handle System Prompt (Prepend custom if available)
        var effectiveSystemPrompt = systemPrompt
        if !customSystemPrompt.isEmpty {
            if let existing = effectiveSystemPrompt {
                effectiveSystemPrompt = customSystemPrompt + "\n\n" + existing
            } else {
                effectiveSystemPrompt = customSystemPrompt
            }
        }
        
        if let system = effectiveSystemPrompt {
            apiMessages.insert(["role": "system", "content": system], at: 0)
        }
        
        let body: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "stream": false,
            "options": [
                "temperature": temperature,
                "num_predict": maxTokens, // Ollama uses num_predict for max tokens
                "top_p": topP
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Debug Log Request
        if let requestBody = String(data: request.httpBody!, encoding: .utf8) {
            print("Ollama Request: \(requestBody)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Ollama Error Response: \(errorMsg)")
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorMsg)"])
        }
        
        // Debug Log Response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Ollama Raw Response: \(responseString)")
        }
        
        // Decode response
        struct OllamaResponse: Codable {
            let message: Message
            
            struct Message: Codable {
                let content: String
            }
        }
        
        let result = try JSONDecoder().decode(OllamaResponse.self, from: data)
        print("Ollama Content: \(result.message.content)")
        return result.message.content
    }
    
    // MARK: - Analysis Functions
    
    func analyzeSymptoms(baseURL: String, model: String, medicalData: String) async throws -> [Symptom] {
        let systemPrompt = """
        You are a medical AI assistant. Your task is to analyze the provided medical text and extract a list of distinct symptoms.
        Return ONLY a JSON array of strings, where each string is a specific symptom found in the text.
        Example format: ["Headache", "Nausea", "Fatigue"]
        Do not include any markdown formatting or explanation.
        """
        
        let userMessage = "Analyze the following medical data and list the symptoms:\n\n\(medicalData)"
        
        let response = try await callOllama(baseURL: baseURL, model: model, messages: [["role": "user", "content": userMessage]], systemPrompt: systemPrompt)
        
        // Clean up response to ensure it's valid JSON
        let cleanResponse = response.replacingOccurrences(of: "```json", with: "")
                                   .replacingOccurrences(of: "```", with: "")
                                   .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanResponse.data(using: .utf8) else {
             throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"])
        }
        
        do {
            let strings = try JSONDecoder().decode([String].self, from: data)
            return strings.map { Symptom(symptom: $0, severity: .moderate, source: "AI Analysis") }
        } catch {
            // Fallback: try to parse line by line if JSON fails
            let lines = cleanResponse.components(separatedBy: .newlines)
            let symptoms = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty && !$0.starts(with: "[") && !$0.starts(with: "]") }
                                .map { $0.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespaces) }
            
            if !symptoms.isEmpty {
                return symptoms.map { Symptom(symptom: $0, severity: .moderate, source: "AI Analysis") }
            }
            
            print("Failed to parse symptoms. Raw response: \(cleanResponse)")
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse symptoms. Raw output: \(cleanResponse)"])
        }
    }
    
    func analyzeCauses(baseURL: String, model: String, symptoms: [String], medicalHistory: String? = nil) async throws -> CausesResponse {
        let systemPrompt = """
        You are a medical diagnostic assistant. Analyze the provided symptoms and identify the top 3 potential causes.
        For each cause, include 5 specific questions the patient should ask their doctor.
        
        Return ONLY a JSON object with a "causes" key containing an array of objects. Each object should have:
        - "condition": Name of the condition
        - "probability": A string indicating likelihood (low, medium, high) - MUST be lowercase
        - "explanation": A brief explanation of why this condition is suspected
        - "urgency": A string indicating urgency (routine, soon, immediate) - MUST be lowercase
        - "recommendedQuestions": Array of 5 specific questions for the doctor
        
        Example format:
        {
          "causes": [
            {
              "condition": "Migraine",
              "probability": "high",
              "explanation": "Matches symptoms of headache and nausea.",
              "urgency": "soon",
              "recommendedQuestions": [
                "What tests can confirm this is a migraine?",
                "Are there preventive medications I should consider?",
                "What triggers should I avoid?",
                "When should I seek emergency care?",
                "Are there lifestyle changes that could help?"
              ]
            }
          ]
        }
        Do not include any markdown formatting.
        """
        
        var userMessage = "Symptoms: \(symptoms.joined(separator: ", "))"
        if let history = medicalHistory, !history.isEmpty {
            userMessage += "\n\nContext:\n\(history)"
        }
        
        let response = try await callOllama(baseURL: baseURL, model: model, messages: [["role": "user", "content": userMessage]], systemPrompt: systemPrompt)
        
        // Multi-strategy JSON extraction
        var jsonString = response
        
        // Strategy 1: Try regex extraction for JSON object
        if let jsonRange = response.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression) {
            jsonString = String(response[jsonRange])
        } 
        // Strategy 2: If no match, try removing markdown blocks (original method)
        else {
            jsonString = response
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Strategy 3: Check for array format and wrap it
        if jsonString.hasPrefix("[") {
            jsonString = "{ \"causes\": \(jsonString) }"
        }

        print("====== OLLAMA CAUSES ANALYSIS DEBUG ======")
        print("Extracted JSON: \(jsonString)")

        guard let data = jsonString.data(using: .utf8) else {
            let errorMsg = "Could not parse causes from response. Raw response: \(response)"
            print(errorMsg)
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        do {
            // Robust decoding: Use strings for enums to handle case/format variations
            struct RawCausesResponse: Codable {
                let causes: [RawCause]
            }
            
            struct RawCause: Codable {
                let condition: String
                let probability: String
                let explanation: String
                let urgency: String? // Optional in case model misses it
                let recommendedQuestions: [String]? // Optional in case model misses it
            }
            
            let rawResponse = try JSONDecoder().decode(RawCausesResponse.self, from: data)
            
            let validCauses = rawResponse.causes.map { raw -> MedicalCause in
                let probString = raw.probability.lowercased()
                let prob: MedicalCause.Probability
                if probString.contains("high") { prob = .high }
                else if probString.contains("medium") { prob = .medium }
                else { prob = .low }
                
                let urgString = (raw.urgency ?? "routine").lowercased()
                let urg: MedicalCause.Urgency
                if urgString.contains("immediate") { urg = .immediate }
                else if urgString.contains("soon") { urg = .soon }
                else { urg = .routine }
                
                return MedicalCause(
                    condition: raw.condition,
                    probability: prob,
                    explanation: raw.explanation,
                    urgency: urg,
                    recommendedQuestions: raw.recommendedQuestions ?? []
                )
            }
            
            return CausesResponse(causes: validCauses)
        } catch {
            print("=== OLLAMA PARSING ERROR ===")
            print("Full response length: \(response.count) characters")
            print("Full response: \(response)")
            print("Extracted JSON: \(jsonString)")
            print("Parse error: \(error)")
            print("=========================")
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse causes. The response may be truncated. Try increasing max tokens in settings. Error: \(error.localizedDescription)"])
        }
    }
    
    
    // MARK: - Chat Functions
    
    func chatWithSource(baseURL: String, model: String, message: String, treatment: Treatment, symptoms: [String] = [], causes: [String] = []) async throws -> String {
        var contextParts: [String] = []
        if !symptoms.isEmpty { contextParts.append("Patient Symptoms: \(symptoms.joined(separator: ", "))") }
        if !causes.isEmpty { contextParts.append("Potential Causes: \(causes.joined(separator: ", "))") }
        contextParts.append("Treatment: \(treatment.name)")
        contextParts.append("Description: \(treatment.description)")
        let systemPrompt = "You are a helpful medical assistant. Answer questions about this treatment.\n\n" + contextParts.joined(separator: "\n")
        return try await callOllama(baseURL: baseURL, model: model, messages: [["role": "user", "content": message]], systemPrompt: systemPrompt)
    }
    
    func chatAboutSymptom(baseURL: String, model: String, message: String, symptom: Symptom) async throws -> String {
        let systemPrompt = """
        You are a helpful medical assistant. You are discussing the symptom: \(symptom.symptom).
        Answer the user's questions about this symptom, what it might indicate, and how to manage it.
        Keep answers concise and informative.
        """
        
        return try await callOllama(baseURL: baseURL, model: model, messages: [["role": "user", "content": message]], systemPrompt: systemPrompt)
    }
    
    func chatAboutCause(baseURL: String, model: String, message: String, cause: MedicalCause) async throws -> String {
        let systemPrompt = """
        You are a helpful medical assistant. You are discussing the potential condition: \(cause.condition).
        Context: The user has symptoms that might indicate this condition. Reasoning: \(cause.explanation).
        Answer the user's questions about this condition, its diagnosis, and typical progression.
        Keep answers concise and informative.
        """
        
        return try await callOllama(baseURL: baseURL, model: model, messages: [["role": "user", "content": message]], systemPrompt: systemPrompt)
    }
}
