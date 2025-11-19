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

I never give vague answers. If the question is broad, I break it into parts. I act like a professional in the relevant domain and push my reasoning to 100% of my capacity.
"""

    private init() {}

    func callClaude(apiKey: String, prompt: String, context: String = "") async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let fullPrompt = context.isEmpty ? prompt : "\(context)\n\n\(prompt)"
        let claudeRequest = ClaudeRequest(
            apiKey: apiKey,
            model: "claude-sonnet-4-20250514",
            maxTokens: 4096,
            system: systemPrompt,
            messages: [ClaudeMessage(role: "user", content: fullPrompt)]
        )

        // Create encoder without apiKey in body
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode([
            "model": claudeRequest.model,
            "max_tokens": claudeRequest.maxTokens,
            "system": claudeRequest.system,
            "messages": claudeRequest.messages
        ] as [String: Any])

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
        guard let jsonRange = response.range(of: #"\[[\s\S]*\]"#, options: .regularExpression),
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
        guard let jsonRange = response.range(of: #"\{[\s\S]*\}"#, options: .regularExpression),
              let jsonData = response[jsonRange].data(using: .utf8) else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse causes from response"])
        }

        let decoder = JSONDecoder()
        return try decoder.decode(CausesResponse.self, from: jsonData)
    }

    func findSolutions(apiKey: String, conditions: [String]) async throws -> SolutionsResponse {
        let conditionsText = conditions.joined(separator: ", ")
        let response = try await callClaude(
            apiKey: apiKey,
            prompt: "For these conditions, provide treatment approaches in Ayurvedic, Homeopathic, Allopathic, and Naturopathic medicine. Include reputable sources. Format as JSON: {\"solutions\": [{\"category\": \"Ayurvedic|Homeopathic|Allopathic|Naturopathic\", \"treatments\": [{\"name\": \"treatment\", \"description\": \"how it works\", \"source\": \"source name\", \"url\": \"URL\", \"recommendedQuestions\": [\"q1\", \"q2\"]}]}]}",
            context: "Conditions: \(conditionsText)"
        )

        // Extract JSON from response
        guard let jsonRange = response.range(of: #"\{[\s\S]*\}"#, options: .regularExpression),
              let jsonData = response[jsonRange].data(using: .utf8) else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse solutions from response"])
        }

        let decoder = JSONDecoder()
        return try decoder.decode(SolutionsResponse.self, from: jsonData)
    }

    func chatWithSource(apiKey: String, message: String, treatment: Treatment) async throws -> String {
        return try await callClaude(
            apiKey: apiKey,
            prompt: message,
            context: "Source: \(treatment.name)\nDescription: \(treatment.description)\nURL: \(treatment.url)"
        )
    }
}

// Helper to encode mixed types
extension JSONEncoder {
    func encode<T: Encodable>(_ value: [String: Any]) throws -> Data {
        let wrappedDict = value.mapValues { AnyEncodable($0) }
        return try encode(wrappedDict)
    }
}

struct AnyEncodable: Encodable {
    private let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
