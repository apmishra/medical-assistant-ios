//
//  OllamaAPIService.swift
//  MedicalAssistant
//
//  Created by Claude
//

import Foundation
import PDFKit

class OllamaAPIService {
    static let shared = OllamaAPIService()
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
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Base URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var apiMessages = messages
        if let system = systemPrompt {
            apiMessages.insert(["role": "system", "content": system], at: 0)
        }
        
        let body: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "stream": false
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
    
    func analyzeCauses(baseURL: String, model: String, symptoms: [String]) async throws -> CausesResponse {
        let systemPrompt = """
        You are a medical AI assistant. Based on the list of symptoms provided, identify potential medical causes or conditions.
        Return ONLY a JSON object with a "causes" key containing an array of objects. Each object should have:
        - "condition": Name of the condition
        - "probability": A string indicating likelihood (low, medium, high) - MUST be lowercase
        - "explanation": A brief explanation of why this condition is suspected
        - "urgency": A string indicating urgency (routine, soon, immediate) - MUST be lowercase
        
        Example format:
        {
          "causes": [
            {
              "condition": "Migraine",
              "probability": "high",
              "explanation": "Matches symptoms of headache and nausea.",
              "urgency": "soon"
            }
          ]
        }
        Do not include any markdown formatting.
        """
        
        let userMessage = "Symptoms: \(symptoms.joined(separator: ", "))"
        
        let response = try await callOllama(baseURL: baseURL, model: model, messages: [["role": "user", "content": userMessage]], systemPrompt: systemPrompt)
        
        let cleanResponse = response.replacingOccurrences(of: "```json", with: "")
                                   .replacingOccurrences(of: "```", with: "")
                                   .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanResponse.data(using: .utf8) else {
             throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"])
        }
        
        do {
            return try JSONDecoder().decode(CausesResponse.self, from: data)
        } catch {
            print("Failed to parse causes. Raw response: \(cleanResponse)")
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse causes. Raw output: \(cleanResponse)"])
        }
    }
    
    func findSolutions(baseURL: String, model: String, conditions: [String]) async throws -> SolutionsResponse {
        let systemPrompt = """
        You are a medical AI assistant. For the provided medical conditions, suggest treatments and management strategies.
        Return ONLY a JSON object with a "solutions" key containing an array of objects. Each object should have:
        - "category": Category name (e.g., Ayurvedic, Homeopathic, Allopathic, Naturopathic)
        - "treatments": Array of treatment objects, each containing:
            - "name": Name of the treatment
            - "description": How it works
            - "source": Source name
            - "url": URL to source
            - "recommendedQuestions": Array of questions to ask a doctor
        
        Example format:
        {
          "solutions": [
            {
              "category": "Allopathic",
              "treatments": [
                {
                  "name": "Ibuprofen",
                  "description": "Anti-inflammatory pain reliever",
                  "source": "Mayo Clinic",
                  "url": "https://www.mayoclinic.org",
                  "recommendedQuestions": ["Dosage?", "Side effects?"]
                }
              ]
            }
          ]
        }
        
        Do not include any markdown formatting.
        """
        
        let userMessage = "Provide solutions for these conditions: \(conditions.joined(separator: ", "))"
        
        let response = try await callOllama(baseURL: baseURL, model: model, messages: [["role": "user", "content": userMessage]], systemPrompt: systemPrompt)
        
        let cleanResponse = response.replacingOccurrences(of: "```json", with: "")
                                   .replacingOccurrences(of: "```", with: "")
                                   .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanResponse.data(using: .utf8) else {
             throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"])
        }
        
        do {
            return try JSONDecoder().decode(SolutionsResponse.self, from: data)
        } catch {
            print("Failed to parse solutions. Raw response: \(cleanResponse)")
            throw NSError(domain: "OllamaAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse solutions. Raw output: \(cleanResponse)"])
        }
    }
    
    // MARK: - Chat Functions
    
    func chatWithSource(baseURL: String, model: String, message: String, treatment: Treatment) async throws -> String {
        let systemPrompt = """
        You are a helpful medical assistant. You are discussing the treatment plan for \(treatment.name).
        Answer the user's questions specifically about this treatment, its side effects, usage, and effectiveness.
        Keep answers concise and informative.
        """
        
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
