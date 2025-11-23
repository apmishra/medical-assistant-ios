//
//  ClaudeAPIService.swift
//  MedicalAssistant
//
//  Created by Claude
//

import Foundation

class ClaudeAPIService: @unchecked Sendable {
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
    var maxTokens: Int = 8192
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
        print("Calling Claude with maxTokens: \(maxTokens)")
        let requestBody = ClaudeAPIRequestBody(
            model: "claude-sonnet-4-5-20250929",
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
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error data"
            print("Claude API Error Raw Response: \(errorString)")
            
            let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data)
            let errorMessage = errorResponse?.error.message ?? "API request failed: \(errorString)"
            
            throw NSError(
                domain: "ClaudeAPI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
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
        let jsonString = extractJSONString(from: response)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse symptoms from response"])
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode([Symptom].self, from: jsonData)
        } catch {
            print("Failed to decode symptoms JSON: \(jsonString)")
            print("Error: \(error)")
            throw error
        }
    }

    func analyzeCauses(apiKey: String, symptoms: [String], medicalHistory: String? = nil) async throws -> CausesResponse {
        let symptomsText = symptoms.joined(separator: ", ")
        var contextText = "Symptoms: \(symptomsText)"
        if let history = medicalHistory, !history.isEmpty {
            contextText += "\n\nContext:\n\(history)"
        }
        
        let response = try await callClaude(
            apiKey: apiKey,
            prompt: "Analyze these symptoms and provide the top 3 potential medical causes/conditions. Format as JSON: {\"causes\": [{\"condition\": \"name\", \"probability\": \"high|medium|low\", \"explanation\": \"concise reason\", \"urgency\": \"immediate|soon|routine\"}]}. Return ONLY valid JSON. Keep explanations concise. Ensure all enum values (probability, urgency) are lowercase.",
            context: contextText
        )

        // Extract JSON from response
        var jsonString = extractJSONString(from: response)

        print("====== CAUSES ANALYSIS DEBUG ======")
        print("Raw Response: \(response)")
        print("Extracted JSON: \(jsonString)")

        // If the response is an array, wrap it in the expected object format
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("[") {
            jsonString = "{\"causes\": \(jsonString)}"
            print("Wrapped array in object format: \(jsonString)")
        }
        print("===================================")

        guard let jsonData = jsonString.data(using: .utf8) else {
            let errorMsg = "Could not parse causes from response. Raw response: \(response)"
            print(errorMsg)
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode(CausesResponse.self, from: jsonData)
            print("Successfully decoded \(result.causes.count) causes")
            return result
        } catch let DecodingError.keyNotFound(key, context) {
            let errorMsg = "Missing key '\(key.stringValue)' in JSON. Path: \(context.codingPath). JSON: \(jsonString)"
            print("Decoding Error: \(errorMsg)")
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required field: \(key.stringValue)"])
        } catch let DecodingError.typeMismatch(type, context) {
            let errorMsg = "Type mismatch for type '\(type)' at path: \(context.codingPath). JSON: \(jsonString)"
            print("Decoding Error: \(errorMsg)")
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid data format at \(context.codingPath)"])
        } catch let DecodingError.valueNotFound(type, context) {
            let errorMsg = "Missing value for type '\(type)' at path: \(context.codingPath). JSON: \(jsonString)"
            print("Decoding Error: \(errorMsg)")
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing value at \(context.codingPath)"])
        } catch let DecodingError.dataCorrupted(context) {
            let errorMsg = "Data corrupted at path: \(context.codingPath). JSON: \(jsonString). Debug: \(context.debugDescription)"
            print("Decoding Error: \(errorMsg)")
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format: \(context.debugDescription)"])
        } catch {
            print("Unknown decoding error: \(error)")
            print("Failed JSON: \(jsonString)")
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: \(error.localizedDescription)"])
        }
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


    private func extractJSONString(from text: String) -> String {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        } else if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the first '[' or '{' and the last ']' or '}'
        if let arrayStart = jsonString.firstIndex(of: "["),
           let arrayEnd = jsonString.lastIndex(of: "]"),
           arrayStart <= arrayEnd {
             return String(jsonString[arrayStart...arrayEnd])
        } else if let objectStart = jsonString.firstIndex(of: "{"),
                  let objectEnd = jsonString.lastIndex(of: "}"),
                  objectStart <= objectEnd {
            return String(jsonString[objectStart...objectEnd])
        }
        
        return jsonString
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
