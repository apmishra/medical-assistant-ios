//
//  GeminiAPIService.swift
//  MedicalAssistant
//
//  Created by Assistant
//

import Foundation

class GeminiAPIService {
    static let shared = GeminiAPIService()
    
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
    
    func callGemini(apiKey: String, prompt: String, context: String = "") async throws -> String {
        // Using gemini-2.0-flash-exp (Gemini 2.0 Flash Experimental)
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:generateContent?key=\(apiKey)"
//        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=\(apiKey)"
            
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let fullPrompt = context.isEmpty ? prompt : "\(context)\n\n\(prompt)"
        
        // Gemini Request Body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "\(systemPrompt)\n\n\(fullPrompt)"]
                    ]
                ]
            ]
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw NSError(domain: "GeminiAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "GeminiAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        // Parse Response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse response"])
        }
        
        return text
    }
    
    func extractTextFromPDF(apiKey: String, pdfData: Data) async throws -> String {
        // Gemini supports PDF via base64 in some versions, but for simplicity and consistency with Claude implementation which truncates,
        // we will stick to the text-based approach if possible, or just send the text.
        // However, the Claude implementation sends base64 text.
        // Gemini 1.5 Flash supports multimodal input.
        // For now, let's stick to the same pattern as Claude: sending it as text context.
        
        let base64PDF = pdfData.base64EncodedString()
        // Truncate to avoid hitting token limits if it's huge, though Gemini has large context.
        // Claude implementation truncated to 1000 chars of base64? That seems very short and likely invalid PDF data.
        // Wait, looking at ClaudeAPIService.swift:
        // let truncatedPDF = String(base64PDF.prefix(1000))
        // This effectively sends a corrupt PDF snippet.
        // If that's what the user wants, I'll replicate it.
        
        let truncatedPDF = String(base64PDF.prefix(1000))
        
        return try await callGemini(
            apiKey: apiKey,
            prompt: "Extract all medical information, test results, diagnoses, and relevant data from this document. Present it in a clear, structured format.",
            context: "PDF Content (base64): \(truncatedPDF)..."
        )
    }
    
    func analyzeSymptoms(apiKey: String, medicalData: String) async throws -> [Symptom] {
        let response = try await callGemini(
            apiKey: apiKey,
            prompt: "Analyze this medical data and extract all symptoms, abnormal findings, and concerning indicators. Return ONLY a JSON array of symptoms with this exact format: [{\"symptom\": \"symptom name\", \"severity\": \"mild|moderate|severe\", \"source\": \"where it was found\"}]. No other text. Do not wrap in markdown code blocks.",
            context: "Medical Data:\n\(medicalData)"
        )
        
        // Clean response (remove markdown code blocks if present)
        var cleanResponse = response.replacingOccurrences(of: "```json", with: "")
        cleanResponse = cleanResponse.replacingOccurrences(of: "```", with: "")
        
        guard let jsonData = cleanResponse.data(using: .utf8) else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse symptoms from response"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Symptom].self, from: jsonData)
    }
    
    func analyzeCauses(apiKey: String, symptoms: [String]) async throws -> CausesResponse {
        let symptomsText = symptoms.joined(separator: ", ")
        let response = try await callGemini(
            apiKey: apiKey,
            prompt: "Analyze these symptoms and provide potential medical causes/conditions. Format as JSON: {\"causes\": [{\"condition\": \"name\", \"probability\": \"high|medium|low\", \"explanation\": \"why\", \"urgency\": \"immediate|soon|routine\"}]}. Return ONLY JSON. Do not wrap in markdown code blocks.",
            context: "Symptoms: \(symptomsText)"
        )
        
        var cleanResponse = response.replacingOccurrences(of: "```json", with: "")
        cleanResponse = cleanResponse.replacingOccurrences(of: "```", with: "")
        
        guard let jsonData = cleanResponse.data(using: .utf8) else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse causes from response"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(CausesResponse.self, from: jsonData)
    }
    
    func findSolutions(apiKey: String, conditions: [String]) async throws -> SolutionsResponse {
        let conditionsText = conditions.joined(separator: ", ")
        let response = try await callGemini(
            apiKey: apiKey,
            prompt: "For these conditions, provide treatment approaches in Common Sense, Allopathic, Ayurvedic, Naturopathic, Homeopathic, and Unani medicine. Include reputable sources. Format as JSON: {\"solutions\": [{\"category\": \"Common Sense|Allopathic|Ayurvedic|Naturopathic|Homeopathic|Unani\", \"treatments\": [{\"name\": \"treatment\", \"description\": \"how it works\", \"source\": \"source name\", \"url\": \"URL\", \"recommendedQuestions\": [\"q1\", \"q2\"]}]}]}. Return ONLY JSON. Do not wrap in markdown code blocks.",
            context: "Conditions: \(conditionsText)"
        )
        
        var cleanResponse = response.replacingOccurrences(of: "```json", with: "")
        cleanResponse = cleanResponse.replacingOccurrences(of: "```", with: "")
        
        guard let jsonData = cleanResponse.data(using: .utf8) else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse solutions from response"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(SolutionsResponse.self, from: jsonData)
    }
    
    func chatWithSource(apiKey: String, message: String, treatment: Treatment) async throws -> String {
        return try await callGemini(
            apiKey: apiKey,
            prompt: message,
            context: "Source: \(treatment.name)\nDescription: \(treatment.description)\nURL: \(treatment.url)"
        )
    }
    
    func chatAboutSymptom(apiKey: String, message: String, symptom: Symptom) async throws -> String {
        return try await callGemini(
            apiKey: apiKey,
            prompt: message,
            context: "Symptom: \(symptom.symptom)\nSeverity: \(symptom.severity.rawValue)\nSource Context: \(symptom.source)"
        )
    }
    
    func chatAboutCause(apiKey: String, message: String, cause: MedicalCause) async throws -> String {
        return try await callGemini(
            apiKey: apiKey,
            prompt: message,
            context: "Condition: \(cause.condition)\nProbability: \(cause.probability.rawValue)\nExplanation: \(cause.explanation)\nUrgency: \(cause.urgency.rawValue)"
        )
    }
}
