//
//  OpenAIAPIService.swift
//  MedicalAssistant
//
//  Created by Assistant
//

import Foundation
import PDFKit

class OpenAIAPIService {
    static let shared = OpenAIAPIService()
    
    private let systemPrompt = """
    You are a helpful medical assistant. Always provide:
    1. A clear, direct answer.
    2. A step-by-step explanation.
    3. Alternative perspectives.
    4. A practical summary.
    
    ⚠️ DISCLAIMER: You are an AI, not a doctor. Do not provide medical advice.
    """
    
    private init() {}
    
    // MARK: - PDF Extraction (Local using PDFKit)
    func extractTextFromPDF(apiKey: String, pdfData: Data) async throws -> String {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw NSError(domain: "OpenAIAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load PDF data"])
        }
        
        var fullText = ""
        let pageCount = pdfDocument.pageCount
        
        for i in 0..<pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw NSError(domain: "OpenAIAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No text could be extracted from the PDF."])
        }
        
        return fullText
    }
    
    // MARK: - API Call
    private func callOpenAI(apiKey: String, messages: [[String: String]], temperature: Double = 0.7, jsonMode: Bool = false) async throws -> (content: String, inputTokens: Int, outputTokens: Int) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "OpenAIAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": temperature
        ]
        
        if jsonMode {
            body["response_format"] = ["type": "json_object"]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Debug Log Request
        if let requestBody = String(data: request.httpBody!, encoding: .utf8) {
            print("OpenAI Request: \(requestBody)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("OpenAI Error Response: \(errorMsg)")
            throw NSError(domain: "OpenAIAPIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorMsg)"])
        }
        
        // Debug Log Response
        if let responseString = String(data: data, encoding: .utf8) {
            print("OpenAI Raw Response: \(responseString)")
        }
        
        struct OpenAIResponse: Codable {
            let choices: [Choice]
            let usage: Usage?
            
            struct Choice: Codable {
                let message: Message
            }
            
            struct Message: Codable {
                let content: String
            }
            
            struct Usage: Codable {
                let prompt_tokens: Int
                let completion_tokens: Int
                let total_tokens: Int
            }
        }
        
        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let content = result.choices.first?.message.content ?? ""
        let inputTokens = result.usage?.prompt_tokens ?? 0
        let outputTokens = result.usage?.completion_tokens ?? 0
        
        return (content, inputTokens, outputTokens)
    }
    
    // MARK: - Analysis Functions
    
    func analyzeSymptoms(apiKey: String, medicalData: String) async throws -> [Symptom] {
        let system = """
        Analyze the medical data and extract symptoms.
        Return a JSON object with a key "symptoms" containing an array of objects.
        Each object must have:
        - "symptom": Name of the symptom
        - "severity": "mild", "moderate", or "severe"
        - "source": Where it was found
        """
        
        let userMessage = "Medical Data:\n\(medicalData)"
        
        let (response, _, _) = try await callOpenAI(
            apiKey: apiKey,
            messages: [
                ["role": "system", "content": system],
                ["role": "user", "content": userMessage]
            ],
            jsonMode: true
        )
        
        struct SymptomWrapper: Codable {
            let symptoms: [Symptom]
        }
        
        guard let data = response.data(using: .utf8) else {
             throw NSError(domain: "OpenAIAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"])
        }
        
        return try JSONDecoder().decode(SymptomWrapper.self, from: data).symptoms
    }
    
    func analyzeCauses(apiKey: String, symptoms: [String]) async throws -> CausesResponse {
        let system = """
        Identify potential medical causes based on symptoms.
        Return a JSON object with a key "causes" containing an array of objects.
        Each object must have:
        - "condition": Name
        - "probability": "high", "medium", or "low" (lowercase)
        - "explanation": Brief reasoning
        - "urgency": "immediate", "soon", or "routine" (lowercase)
        """
        
        let userMessage = "Symptoms: \(symptoms.joined(separator: ", "))"
        
        let (response, _, _) = try await callOpenAI(
            apiKey: apiKey,
            messages: [
                ["role": "system", "content": system],
                ["role": "user", "content": userMessage]
            ],
            jsonMode: true
        )
        
        guard let data = response.data(using: .utf8) else {
             throw NSError(domain: "OpenAIAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"])
        }
        
        // Robust decoding
        struct RawCausesResponse: Codable {
            let causes: [RawCause]
        }
        
        struct RawCause: Codable {
            let condition: String
            let probability: String
            let explanation: String
            let urgency: String?
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
            
            return MedicalCause(condition: raw.condition, probability: prob, explanation: raw.explanation, urgency: urg)
        }
        
        return CausesResponse(causes: validCauses)
    }
    
    func findSolutions(apiKey: String, conditions: [String]) async throws -> SolutionsResponse {
        let system = """
        Suggest treatments for the conditions.
        Return a JSON object with a key "solutions" containing an array of objects.
        Each object must have:
        - "category": "Common Sense", "Allopathic", "Ayurvedic", "Naturopathic", "Homeopathic", or "Unani"
        - "treatments": Array of objects with "name", "description", "source", "url", "recommendedQuestions"
        """
        
        let userMessage = "Conditions: \(conditions.joined(separator: ", "))"
        
        let (response, _, _) = try await callOpenAI(
            apiKey: apiKey,
            messages: [
                ["role": "system", "content": system],
                ["role": "user", "content": userMessage]
            ],
            jsonMode: true
        )
        
        guard let data = response.data(using: .utf8) else {
             throw NSError(domain: "OpenAIAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"])
        }
        
        return try JSONDecoder().decode(SolutionsResponse.self, from: data)
    }
    
    // MARK: - Chat Functions
    
    func chatWithSource(apiKey: String, message: String, treatment: Treatment) async throws -> String {
        let system = "You are a helpful medical assistant discussing the treatment: \(treatment.name). Context: \(treatment.description)"
        let (response, _, _) = try await callOpenAI(apiKey: apiKey, messages: [
            ["role": "system", "content": system],
            ["role": "user", "content": message]
        ])
        return response
    }
    
    func chatAboutSymptom(apiKey: String, message: String, symptom: Symptom) async throws -> String {
        let system = "You are a helpful medical assistant discussing the symptom: \(symptom.symptom). Severity: \(symptom.severity.rawValue)"
        let (response, _, _) = try await callOpenAI(apiKey: apiKey, messages: [
            ["role": "system", "content": system],
            ["role": "user", "content": message]
        ])
        return response
    }
    
    func chatAboutCause(apiKey: String, message: String, cause: MedicalCause) async throws -> String {
        let system = "You are a helpful medical assistant discussing the condition: \(cause.condition). Probability: \(cause.probability.rawValue). Explanation: \(cause.explanation)"
        let (response, _, _) = try await callOpenAI(apiKey: apiKey, messages: [
            ["role": "system", "content": system],
            ["role": "user", "content": message]
        ])
        return response
    }
}
