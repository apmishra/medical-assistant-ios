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

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            switch rawValue.lowercased() {
            case "mild", "low", "minor":
                self = .mild
            case "moderate", "medium", "med":
                self = .moderate
            case "severe", "high", "major", "critical":
                self = .severe
            default:
                // Default to moderate if unknown
                self = .moderate
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case symptom, severity, source
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(symptom)
        hasher.combine(severity)
        hasher.combine(source)
    }

    static func == (lhs: Symptom, rhs: Symptom) -> Bool {
        return lhs.symptom == rhs.symptom &&
               lhs.severity == rhs.severity &&
               lhs.source == rhs.source
    }
}

// MARK: - Cause
struct MedicalCause: Identifiable, Codable, Hashable {
    let id = UUID()
    let condition: String
    let probability: Probability
    let explanation: String
    let urgency: Urgency

    enum Probability: String, Codable {
        case low
        case medium
        case high

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            switch rawValue.lowercased() {
            case "low":
                self = .low
            case "medium", "med":
                self = .medium
            case "high":
                self = .high
            default:
                // Default to medium if unknown
                self = .medium
            }
        }
    }

    enum Urgency: String, Codable {
        case routine
        case soon
        case immediate

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            switch rawValue.lowercased() {
            case "routine", "normal", "low":
                self = .routine
            case "soon", "moderate", "medium":
                self = .soon
            case "immediate", "urgent", "high", "emergency":
                self = .immediate
            default:
                // Default to routine if unknown
                self = .routine
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case condition, probability, explanation, urgency
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(condition)
        hasher.combine(probability)
        hasher.combine(explanation)
        hasher.combine(urgency)
    }

    static func == (lhs: MedicalCause, rhs: MedicalCause) -> Bool {
        return lhs.condition == rhs.condition &&
               lhs.probability == rhs.probability &&
               lhs.explanation == rhs.explanation &&
               lhs.urgency == rhs.urgency
    }
}

struct CausesResponse: Codable {
    let causes: [MedicalCause]
}

// MARK: - Solution
struct Treatment: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let source: String
    let url: String
    let recommendedQuestions: [String]

    enum CodingKeys: String, CodingKey {
        case name, description, source, url, recommendedQuestions
    }

    init(name: String, description: String, source: String, url: String, recommendedQuestions: [String]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.source = source
        self.url = url
        self.recommendedQuestions = recommendedQuestions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()  // Generate new ID for each instance
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.source = try container.decode(String.self, forKey: .source)
        self.url = try container.decode(String.self, forKey: .url)
        self.recommendedQuestions = try container.decode([String].self, forKey: .recommendedQuestions)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(source)
        hasher.combine(url)
    }

    static func == (lhs: Treatment, rhs: Treatment) -> Bool {
        return lhs.name == rhs.name &&
               lhs.description == rhs.description &&
               lhs.source == rhs.source &&
               lhs.url == rhs.url
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

struct CauseSolution: Identifiable, Codable {
    let id = UUID()
    let causeName: String
    let systems: [SolutionCategory]

    enum CodingKeys: String, CodingKey {
        case causeName, systems
    }
}

struct SolutionsResponse: Codable {
    let solutions: [CauseSolution]
}

// MARK: - Chat
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    enum Role: String, Codable {
        case user
        case assistant
    }
}

// MARK: - Debug Log
struct DebugLog: Identifiable, Codable {
    let id: UUID
    let timestamp: String
    let message: String
    let type: LogType
    let inputTokens: Int?
    let outputTokens: Int?
    
    init(id: UUID = UUID(), timestamp: String, message: String, type: LogType, inputTokens: Int? = nil, outputTokens: Int? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
        self.type = type
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
    }

    enum LogType: String, Codable {
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

// MARK: - Session Management
struct MedicalSession: Identifiable, Codable {
    let id: UUID
    var name: String
    let date: Date
    
    // Data
    var pdfText: String
    var manualText: String
    var extractedSymptoms: [Symptom]
    var confirmedSymptoms: Set<Symptom>
    var additionalSymptoms: String
    var potentialCauses: CausesResponse?
    var selectedCauses: Set<MedicalCause>
    var selectedTreatments: [Treatment]
    var treatmentsByCause: [String: [Treatment]]
    var selectedTreatmentsByCause: [String: Set<String>]
    var chatMessages: [String: [ChatMessage]]
    var debugLogs: [DebugLog]
    var authProvider: String
    
    init(id: UUID = UUID(), name: String = "New Session", date: Date = Date(), authProvider: String = "Unknown") {
        self.id = id
        self.name = name
        self.date = date
        self.authProvider = authProvider
        self.pdfText = ""
        self.manualText = ""
        self.extractedSymptoms = []
        self.confirmedSymptoms = []
        self.additionalSymptoms = ""
        self.potentialCauses = nil
        self.selectedCauses = []
        self.selectedTreatments = []
        self.treatmentsByCause = [:]
        self.selectedTreatmentsByCause = [:]
        self.chatMessages = [:]
        self.debugLogs = []
    }
    func toCSV() -> String {
        var csv = "Type,Item,Details,Selected\n"
        
        // Session Info
        csv += "Session Info,\"\(name)\",\(date.formatted()),-\n"
        
        // Symptoms
        for symptom in extractedSymptoms {
            let status = confirmedSymptoms.contains(symptom) ? "Confirmed" : "Unconfirmed"
            csv += "Symptom,\"\(symptom.symptom)\",\(status) - \(symptom.severity.rawValue),-\n"
        }
        
        // Additional Symptoms
        if !additionalSymptoms.isEmpty {
             csv += "Additional Symptom,\"\(additionalSymptoms)\",Manual Entry,-\n"
        }
        
        // Selected Causes
        for cause in selectedCauses {
            csv += "Selected Cause,\"\(cause.condition)\",\(cause.probability.rawValue) probability,-\n"
        }
        
        // Treatments (All retrieved)
        for (cause, treatments) in treatmentsByCause {
            for treatment in treatments {
                let treatmentKey = treatment.name + treatment.description
                let isSelected = selectedTreatmentsByCause[cause]?.contains(treatmentKey) == true ||
                               selectedTreatments.contains(where: { $0.name == treatment.name && $0.description == treatment.description })
                
                let selectedStr = isSelected ? "Yes" : "No"
                // Escape quotes in description
                let description = treatment.description.replacingOccurrences(of: "\"", with: "\"\"")
                csv += "Treatment,\"\(treatment.name) (\(treatment.source))\",\"\(description)\",\(selectedStr)\n"
            }
        }
        
        return csv
    }
}
