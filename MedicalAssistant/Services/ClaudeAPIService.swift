//
//  ClaudeAPIService.swift
//  MedicalAssistant
//
//  Created by Claude
//

import Foundation

class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let systemPrompt = """
From now on, act as my expert assistant with access to all your reasoning and knowledge. Always provide:

⚠️ DISCLAIMER: I am an AI agent and not a medical professional. The information I provide should NOT be taken as medical advice. I am only providing information available on the public internet learned by an LLM. I am not responsible for any of the content provided. Always consult with qualified healthcare professionals for medical advice.

1. A clear, direct answer to your request.
2. A step-by-step explanation of how I got there.
3. Alternative perspectives or solutions you might not have thought of.
4. A practical summary or action plan you can apply immediately.
"""

    // LLM Tuning Parameters
    var temperature: Double = 0.7
    var maxTokens: Int = 2048
    var topP: Double = 1.0
    var customSystemPrompt: String = ""

    private init() {}

    private func callClaude(apiKey: String, prompt: String, context: String = "") async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        var systemMessage = context.isEmpty ? "You are a helpful medical AI assistant." : "You are a helpful medical AI assistant.\n\nContext:\n\(context)"
        if !customSystemPrompt.isEmpty {
            systemMessage = customSystemPrompt + "\n\n" + systemMessage
        }

        // Create request body without apiKey
        let requestBody = ClaudeAPIRequestBody(
            model: "claude-3-5-sonnet-20241022",
            maxTokens: maxTokens,
            temperature: temperature,
            system: systemMessage,
            messages: [ClaudeMessage(role: "user", content: prompt)]
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let bodyData = try encoder.encode(requestBody)

        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data)
            throw NSError(
                domain: "ClaudeAPI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorResponse?.error.message ?? "API request failed"]
            )
        }

        let decoder = JSONDecoder()
        let claudeResponse = try decoder.decode(ClaudeResponse.self, from: data)

        return claudeResponse.content.first?.text ?? ""
    }

    func extractTextFromPDF(apiKey: String, pdfData: Data) async throws -> String {
        let base64PDF = pdfData.base64EncodedString()
        let truncatedPDF = String(base64PDF.prefix(1000))

        return try await callClaude(
            apiKey: apiKey,
            prompt: "Extract all medical information, test results, diagnoses, and relevant data from this document. Present it in a clear, structured format.",
            context: "PDF Content (base64): \(truncatedPDF)..."
        )
    }

    func analyzeSymptoms(apiKey: String, medicalData: String) async throws -> [Symptom] {
        let response = try await callClaude(
            apiKey: apiKey,
            prompt: "Analyze this medical data and extract all symptoms, abnormal findings, and concerning indicators. Return ONLY a JSON array of symptoms with this exact format: [{\"symptom\": \"symptom name\", \"severity\": \"mild|moderate|severe\", \"source\": \"where it was found\"}]. No other text.",
            context: "Medical Data:\n\(medicalData)"
        )

        // Extract JSON from response
        guard let jsonRange = response.range(of: "\\[[\\s\\S]*\\]", options: .regularExpression),
              let jsonData = response[jsonRange].data(using: .utf8) else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse symptoms from response"])
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Symptom].self, from: jsonData)
    }

    func analyzeCauses(apiKey: String, symptoms: [String]) async throws -> CausesResponse {
        let symptomsText = symptoms.joined(separator: ", ")
        let response = try await callClaude(
            apiKey: apiKey,
            prompt: "Analyze these symptoms and provide potential medical causes/conditions. Format as JSON: {\"causes\": [{\"condition\": \"name\", \"probability\": \"high|medium|low\", \"explanation\": \"why\", \"urgency\": \"immediate|soon|routine\"}]}",
            context: "Symptoms: \(symptomsText)"
        )

        // Extract JSON from response
        guard let jsonRange = response.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression),
              let jsonData = response[jsonRange].data(using: .utf8) else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse causes from response"])
        }

        let decoder = JSONDecoder()
        return try decoder.decode(CausesResponse.self, from: jsonData)
    }

    func findSolutions(apiKey: String, conditions: [String]) async throws -> SolutionsResponse {
        let conditionsText = conditions.joined(separator: "\", \"")
        let response = try await callClaude(
            apiKey: apiKey,
            prompt: """
            For EACH of the following conditions, provide treatment approaches organized by medical system.
            
            Conditions: ["\(conditionsText)"]
            
            For EACH condition, provide treatments in these 6 medical systems:
            1. General (General advice, lifestyle changes, or treatments that don't fit other categories)
            2. Allopathic (Modern medicine)
            3. Ayurvedic
            4. Naturopathic
            5. Homeopathic
            6. Unani
            
            CRITICAL: Structure the response as an array where each element represents ONE condition with its treatments across all systems.
            
            Format strictly as JSON:
            {
              "solutions": [
                {
                  "causeName": "First Condition Name",
                  "systems": [
                    {
                      "category": "Allopathic",
                      "treatments": [
                        {
                          "name": "Treatment Name",
                          "description": "Detailed description",
                          "source": "Reputable Source Name",
                          "url": "https://source-url.com",
                          "recommendedQuestions": ["Question 1", "Question 2"]
                        }
                      ]
                    },
                    {
                      "category": "Ayurvedic",
                      "treatments": [...]
                    }
                  ]
                },
                {
                  "causeName": "Second Condition Name",
                  "systems": []
                }
              ]
            }
            
            Ensure EVERY condition has ALL 6 medical systems, even if some have fewer treatments.
            """,
            context: "Conditions: \(conditionsText)"
        )

        // Extract JSON from response
        guard let jsonRange = response.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression),
              let jsonData = response[jsonRange].data(using: .utf8) else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse solutions from response"])
        }

        let decoder = JSONDecoder()
        return try decoder.decode(SolutionsResponse.self, from: jsonData)
    }

    func chatWithSource(apiKey: String, message: String, treatment: Treatment, symptoms: [String] = [], causes: [String] = []) async throws -> String {
        var contextParts: [String] = []
        
        // Add symptoms context
        if !symptoms.isEmpty {
            contextParts.append("Patient Symptoms: \(symptoms.joined(separator: ", "))")
        }
        
        // Add causes context
        if !causes.isEmpty {
            contextParts.append("Potential Causes: \(causes.joined(separator: ", "))")
        }
        
        // Add treatment context
        contextParts.append("Treatment Being Discussed: \(treatment.name)")
        contextParts.append("Description: \(treatment.description)")
        contextParts.append("Source: \(treatment.source)")
        
        let fullContext = contextParts.joined(separator: "\n")
        
        return try await callClaude(
            apiKey: apiKey,
            prompt: message,
            context: fullContext
        )
    }
    
    func chatAboutSymptom(apiKey: String, message: String, symptom: Symptom) async throws -> String {
        return try await callClaude(
            apiKey: apiKey,
            prompt: message,
            context: "Symptom: \(symptom.symptom)\nSeverity: \(symptom.severity.rawValue)\nSource Context: \(symptom.source)"
        )
    }
    
    func chatAboutCause(apiKey: String, message: String, cause: MedicalCause) async throws -> String {
        return try await callClaude(
            apiKey: apiKey,
            prompt: message,
            context: "Condition: \(cause.condition)\nProbability: \(cause.probability.rawValue)\nExplanation: \(cause.explanation)\nUrgency: \(cause.urgency.rawValue)"
        )
    }
}

// MARK: - API Request Body
struct ClaudeAPIRequestBody: Codable {
    let model: String
    let maxTokens: Int
    let temperature: Double
    let system: String
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case temperature
        case system
        case messages
    }
}
