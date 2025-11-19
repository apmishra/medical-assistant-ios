//
//  MedicalModels.swift
//  MedicalAssistant
//
//  Created by Claude
//

import Foundation

// MARK: - Symptom
struct Symptom: Identifiable, Codable, Hashable {
    let id = UUID()
    let symptom: String
    let severity: Severity
    let source: String

    enum Severity: String, Codable {
        case mild
        case moderate
        case severe
    }

    enum CodingKeys: String, CodingKey {
        case symptom, severity, source
    }
}

// MARK: - Cause
struct MedicalCause: Identifiable, Codable {
    let id = UUID()
    let condition: String
    let probability: Probability
    let explanation: String
    let urgency: Urgency

    enum Probability: String, Codable {
        case low
        case medium
        case high
    }

    enum Urgency: String, Codable {
        case routine
        case soon
        case immediate
    }

    enum CodingKeys: String, CodingKey {
        case condition, probability, explanation, urgency
    }
}

struct CausesResponse: Codable {
    let causes: [MedicalCause]
}

// MARK: - Solution
struct Treatment: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let source: String
    let url: String
    let recommendedQuestions: [String]

    enum CodingKeys: String, CodingKey {
        case name, description, source, url, recommendedQuestions
    }
}

struct SolutionCategory: Identifiable, Codable {
    let id = UUID()
    let category: String
    let treatments: [Treatment]

    enum CodingKeys: String, CodingKey {
        case category, treatments
    }
}

struct SolutionsResponse: Codable {
    let solutions: [SolutionCategory]
}

// MARK: - Chat
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date

    enum Role {
        case user
        case assistant
    }
}

// MARK: - Debug Log
struct DebugLog: Identifiable {
    let id = UUID()
    let timestamp: String
    let message: String
    let type: LogType

    enum LogType {
        case info
        case success
        case warning
        case error
    }
}

// MARK: - Claude API Models
struct ClaudeRequest: Codable {
    let apiKey: String
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case apiKey, model
        case maxTokens = "max_tokens"
        case system, messages
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let content: [ContentBlock]
    let usage: Usage?

    struct ContentBlock: Codable {
        let text: String
    }

    struct Usage: Codable {
        let inputTokens: Int
        let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }
}

struct ClaudeErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
        let type: String
    }
}
