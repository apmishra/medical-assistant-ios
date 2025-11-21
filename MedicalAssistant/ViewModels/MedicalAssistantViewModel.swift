//
//  MedicalAssistantViewModel.swift
//  MedicalAssistant
//
//  Created by Claude
//

import Foundation
import SwiftUI

enum LLMProvider: String, CaseIterable, Codable {
    case claude = "Claude"
    case gemini = "Gemini"
    case openai = "OpenAI"
    case ollama = "Ollama"
    case appleIntelligence = "Apple Intelligence"
}



@MainActor
class MedicalAssistantViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedProvider: LLMProvider = .claude
    @Published var apiKey: String = ""
    @Published var geminiApiKey: String = ""
    @Published var openaiApiKey: String = ""
    @Published var ollamaBaseURL: String = "http://localhost:11434"
    @Published var ollamaModel: String = "llama3"
    @Published var pdfText: String = "" { didSet { updateCurrentSession() } }
    @Published var manualText: String = "" { didSet { updateCurrentSession() } }
    @Published var extractedSymptoms: [Symptom] = [] { didSet { updateCurrentSession() } }
    @Published var confirmedSymptoms: Set<Symptom> = [] { didSet { updateCurrentSession() } }
    @Published var additionalSymptoms: String = "" { didSet { updateCurrentSession() } }
    @Published var potentialCauses: CausesResponse? { didSet { updateCurrentSession() } }
    @Published var solutions: SolutionsResponse? { didSet { updateCurrentSession() } }
    @Published var chatMessages: [String: [ChatMessage]] = [:] { didSet { updateCurrentSession() } }
    @Published var activeChatTreatment: Treatment?
    @Published var activeChatSymptom: Symptom?
    @Published var activeChatCause: MedicalCause?
    @Published var selectedCauses: Set<MedicalCause> = [] { didSet { updateCurrentSession() } }
    @Published var expandedSources: Set<String> = []
    @Published var selectedTab: Int = 0
    @Published var debugLogs: [DebugLog] = [] { didSet { updateCurrentSession() } }
    @Published var isLoading: Bool = false
    @Published var showApiKeyInput: Bool = false
    
    // Session Management
    @Published var sessions: [MedicalSession] = []
    @Published var currentSessionId: UUID?

    private let apiService = ClaudeAPIService.shared
    private let geminiService = GeminiAPIService.shared
    private let openaiService = OpenAIAPIService.shared
    private let ollamaService = OllamaAPIService.shared
    private let appleIntelligenceService = AppleIntelligenceService.shared
    
    private let providerStorageKey = "selected_provider"
    private let apiKeyStorageKey = "claude_api_key"
    private let geminiApiKeyStorageKey = "gemini_api_key"
    private let openaiApiKeyStorageKey = "openai_api_key"
    private let ollamaBaseURLStorageKey = "ollama_base_url"
    private let ollamaModelStorageKey = "ollama_model"

    init() {
        loadAPIKey()
        loadSessions()
    }

    // MARK: - API Key Management
    func loadAPIKey() {
        // Load selected provider
        if let savedProviderRaw = UserDefaults.standard.string(forKey: providerStorageKey),
           let provider = LLMProvider(rawValue: savedProviderRaw) {
            selectedProvider = provider
        }
        
        if let storedKey = UserDefaults.standard.string(forKey: apiKeyStorageKey) {
            apiKey = storedKey
        }
        
        if let storedGeminiKey = UserDefaults.standard.string(forKey: geminiApiKeyStorageKey) {
            geminiApiKey = storedGeminiKey
        }
        
        if let storedOpenAIKey = UserDefaults.standard.string(forKey: openaiApiKeyStorageKey) {
            openaiApiKey = storedOpenAIKey
        }
        
        if let storedOllamaURL = UserDefaults.standard.string(forKey: ollamaBaseURLStorageKey) {
            ollamaBaseURL = storedOllamaURL
        }
        
        if let storedOllamaModel = UserDefaults.standard.string(forKey: ollamaModelStorageKey) {
            ollamaModel = storedOllamaModel
        }
        
        checkAPIKeyStatus()
    }
    
    func checkAPIKeyStatus() {
        let hasKey: Bool
        switch selectedProvider {
        case .claude: hasKey = !apiKey.isEmpty
        case .gemini: hasKey = !geminiApiKey.isEmpty
        case .openai: hasKey = !openaiApiKey.isEmpty
        case .ollama: hasKey = !ollamaBaseURL.isEmpty && !ollamaModel.isEmpty
        case .appleIntelligence: hasKey = true
        }
        
        if !hasKey {
            showApiKeyInput = true
            addDebugLog("Please configure API key for \(selectedProvider.rawValue)", type: .warning)
        } else {
            addDebugLog("\(selectedProvider.rawValue) API Key loaded", type: .success)
        }
    }

    func saveProvider(_ provider: LLMProvider) {
        selectedProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: providerStorageKey)
        checkAPIKeyStatus()
    }

    func saveAPIKey(_ key: String) {
        guard !key.isEmpty else { return }
        UserDefaults.standard.set(key, forKey: apiKeyStorageKey)
        apiKey = key
        if selectedProvider == .claude { showApiKeyInput = false }
        addDebugLog("Claude API Key saved", type: .success)
    }
    
    func saveGeminiAPIKey(_ key: String) {
        guard !key.isEmpty else { return }
        UserDefaults.standard.set(key, forKey: geminiApiKeyStorageKey)
        geminiApiKey = key
        if selectedProvider == .gemini { showApiKeyInput = false }
        addDebugLog("Gemini API Key saved", type: .success)
    }
    
    func saveOpenAIAPIKey(_ key: String) {
        guard !key.isEmpty else { return }
        UserDefaults.standard.set(key, forKey: openaiApiKeyStorageKey)
        openaiApiKey = key
        if selectedProvider == .openai { showApiKeyInput = false }
        addDebugLog("OpenAI API Key saved", type: .success)
    }
    
    func saveOllamaConfig(url: String, model: String) {
        guard !url.isEmpty, !model.isEmpty else { return }
        UserDefaults.standard.set(url, forKey: ollamaBaseURLStorageKey)
        UserDefaults.standard.set(model, forKey: ollamaModelStorageKey)
        ollamaBaseURL = url
        ollamaModel = model
        if selectedProvider == .ollama { showApiKeyInput = false }
        addDebugLog("Ollama configuration saved", type: .success)
    }

    // MARK: - Debug Logging
    func addDebugLog(_ message: String, type: DebugLog.LogType = .info, inputTokens: Int? = nil, outputTokens: Int? = nil) {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let timestamp = formatter.string(from: Date())
        let log = DebugLog(timestamp: timestamp, message: message, type: type, inputTokens: inputTokens, outputTokens: outputTokens)
        debugLogs.append(log)
    }

    func clearDebugLogs() {
        debugLogs.removeAll()
    }

    // MARK: - PDF Processing
    func handlePDFUpload(data: Data) async -> Bool {
        isLoading = true
        addDebugLog("Extracting text from PDF...", type: .info)
        var success = false

        do {
            let text: String
            switch selectedProvider {
            case .claude:
                text = try await apiService.extractTextFromPDF(apiKey: apiKey, pdfData: data)
            case .gemini:
                text = try await geminiService.extractTextFromPDF(apiKey: geminiApiKey, pdfData: data)
            case .openai:
                text = try await openaiService.extractTextFromPDF(apiKey: openaiApiKey, pdfData: data)
            case .ollama:
                text = try await ollamaService.extractTextFromPDF(pdfData: data)
            case .appleIntelligence:
                text = try await appleIntelligenceService.extractTextFromPDF(pdfData: data)
            }
            pdfText = text
            addDebugLog("Text extracted from PDF using \(selectedProvider.rawValue)", type: .success)
            success = true
        } catch {
            addDebugLog("Failed to extract text: \(error.localizedDescription)", type: .error)
        }

        isLoading = false
        return success
    }

    // MARK: - Symptom Analysis
    func analyzeSymptoms() async -> Bool {
        let medicalData = !pdfText.isEmpty ? pdfText : manualText
        guard !medicalData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            addDebugLog("Please provide medical data first", type: .warning)
            return false
        }

        isLoading = true
        addDebugLog("Analyzing medical data for symptoms...", type: .info)
        var success = false

        do {
            let symptoms: [Symptom]
            switch selectedProvider {
            case .claude:
                symptoms = try await apiService.analyzeSymptoms(apiKey: apiKey, medicalData: medicalData)
            case .gemini:
                symptoms = try await geminiService.analyzeSymptoms(apiKey: geminiApiKey, medicalData: medicalData)
            case .openai:
                symptoms = try await openaiService.analyzeSymptoms(apiKey: openaiApiKey, medicalData: medicalData)
            case .ollama:
                symptoms = try await ollamaService.analyzeSymptoms(baseURL: ollamaBaseURL, model: ollamaModel, medicalData: medicalData)
            case .appleIntelligence:
                symptoms = try await appleIntelligenceService.analyzeSymptoms(medicalData: medicalData)
            }
            extractedSymptoms = symptoms
            addDebugLog("Extracted \(symptoms.count) symptoms using \(selectedProvider.rawValue)", type: .success)
            success = true
        } catch {
            addDebugLog("Failed to analyze symptoms: \(error.localizedDescription)", type: .error)
        }

        isLoading = false
        return success
    }

    func toggleSymptom(_ symptom: Symptom) {
        if confirmedSymptoms.contains(symptom) {
            confirmedSymptoms.remove(symptom)
        } else {
            confirmedSymptoms.insert(symptom)
        }
    }

    // MARK: - Cause Analysis
    func analyzeCauses() async -> Bool {
        guard !confirmedSymptoms.isEmpty || !additionalSymptoms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            addDebugLog("Please confirm at least one symptom or add additional symptoms", type: .warning)
            return false
        }

        isLoading = true
        addDebugLog("Analyzing potential causes...", type: .info)
        var success = false

        var allSymptoms = confirmedSymptoms.map { $0.symptom }
        let additional = additionalSymptoms
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        allSymptoms.append(contentsOf: additional)

        do {
            let causes: CausesResponse
            switch selectedProvider {
            case .claude:
                causes = try await apiService.analyzeCauses(apiKey: apiKey, symptoms: allSymptoms)
            case .gemini:
                causes = try await geminiService.analyzeCauses(apiKey: geminiApiKey, symptoms: allSymptoms)
            case .openai:
                causes = try await openaiService.analyzeCauses(apiKey: openaiApiKey, symptoms: allSymptoms)
            case .ollama:
                causes = try await ollamaService.analyzeCauses(baseURL: ollamaBaseURL, model: ollamaModel, symptoms: allSymptoms)
            case .appleIntelligence:
                causes = try await appleIntelligenceService.analyzeCauses(symptoms: allSymptoms)
            }
            potentialCauses = causes
            addDebugLog("Identified \(causes.causes.count) potential causes using \(selectedProvider.rawValue)", type: .success)
            success = true
        } catch {
            addDebugLog("Failed to analyze causes: \(error.localizedDescription)", type: .error)
        }

        isLoading = false
        return success
    }

    // MARK: - Solution Finding
    func findSolutions() async -> Bool {
        guard let causes = potentialCauses else {
            addDebugLog("Please analyze causes first", type: .warning)
            return false
        }

        isLoading = true
        addDebugLog("Searching for treatment solutions...", type: .info)
        var success = false

        // Use selected causes if any, otherwise use all potential causes
        let targetCauses = selectedCauses.isEmpty ? causes.causes : Array(selectedCauses)
        let conditions = targetCauses.map { $0.condition }

        do {
            let solutions: SolutionsResponse
            switch selectedProvider {
            case .claude:
                solutions = try await apiService.findSolutions(apiKey: apiKey, conditions: conditions)
            case .gemini:
                solutions = try await geminiService.findSolutions(apiKey: geminiApiKey, conditions: conditions)
            case .openai:
                solutions = try await openaiService.findSolutions(apiKey: openaiApiKey, conditions: conditions)
            case .ollama:
                solutions = try await ollamaService.findSolutions(baseURL: ollamaBaseURL, model: ollamaModel, conditions: conditions)
            case .appleIntelligence:
                solutions = try await appleIntelligenceService.findSolutions(conditions: conditions)
            }
            self.solutions = solutions
            addDebugLog("Found solutions using \(selectedProvider.rawValue)", type: .success)
            success = true
        } catch {
            addDebugLog("Failed to find solutions: \(error.localizedDescription)", type: .error)
        }

        isLoading = false
        return success
    }

    // MARK: - Chat
    func startChat(with treatment: Treatment) {
        activeChatTreatment = treatment
        if chatMessages[treatment.name] == nil {
            chatMessages[treatment.name] = []
        }
    }

    func sendChatMessage(_ message: String) async {
        guard let treatment = activeChatTreatment, !message.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: message, timestamp: Date())
        chatMessages[treatment.name, default: []].append(userMessage)

        addDebugLog("Chat query sent for \(treatment.name)", type: .info)

        do {
            let response: String
            switch selectedProvider {
            case .claude:
                response = try await apiService.chatWithSource(apiKey: apiKey, message: message, treatment: treatment)
            case .gemini:
                response = try await geminiService.chatWithSource(apiKey: geminiApiKey, message: message, treatment: treatment)
            case .openai:
                response = try await openaiService.chatWithSource(apiKey: openaiApiKey, message: message, treatment: treatment)
            case .ollama:
                response = try await ollamaService.chatWithSource(baseURL: ollamaBaseURL, model: ollamaModel, message: message, treatment: treatment)
            case .appleIntelligence:
                response = try await appleIntelligenceService.chatWithSource(message: message, treatment: treatment)
            }
            
            let assistantMessage = ChatMessage(role: .assistant, content: response, timestamp: Date())
            chatMessages[treatment.name, default: []].append(assistantMessage)
            addDebugLog("Chat response received from \(selectedProvider.rawValue)", type: .success)
        } catch {
            addDebugLog("Chat failed: \(error.localizedDescription)", type: .error)
        }
    }

    func closeChat() {
        activeChatTreatment = nil
        activeChatSymptom = nil
        activeChatCause = nil
    }

    // MARK: - Symptom Chat
    func startSymptomChat(with symptom: Symptom) {
        activeChatSymptom = symptom
        if chatMessages[symptom.symptom] == nil {
            chatMessages[symptom.symptom] = []
        }
    }

    func sendSymptomChatMessage(_ message: String) async {
        guard let symptom = activeChatSymptom, !message.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: message, timestamp: Date())
        chatMessages[symptom.symptom, default: []].append(userMessage)

        addDebugLog("Chat query sent for symptom: \(symptom.symptom)", type: .info)

        do {
            let response: String
            switch selectedProvider {
            case .claude:
                response = try await apiService.chatAboutSymptom(apiKey: apiKey, message: message, symptom: symptom)
            case .gemini:
                response = try await geminiService.chatAboutSymptom(apiKey: geminiApiKey, message: message, symptom: symptom)
            case .openai:
                response = try await openaiService.chatAboutSymptom(apiKey: openaiApiKey, message: message, symptom: symptom)
            case .ollama:
                response = try await ollamaService.chatAboutSymptom(baseURL: ollamaBaseURL, model: ollamaModel, message: message, symptom: symptom)
            case .appleIntelligence:
                response = try await appleIntelligenceService.chatAboutSymptom(message: message, symptom: symptom)
            }
            
            let assistantMessage = ChatMessage(role: .assistant, content: response, timestamp: Date())
            chatMessages[symptom.symptom, default: []].append(assistantMessage)
            addDebugLog("Chat response received from \(selectedProvider.rawValue)", type: .success)
        } catch {
            addDebugLog("Chat failed: \(error.localizedDescription)", type: .error)
        }
    }
    
    // MARK: - Cause Chat
    func startCauseChat(with cause: MedicalCause) {
        activeChatCause = cause
        if chatMessages[cause.condition] == nil {
            chatMessages[cause.condition] = []
            
            // Auto-prompt for description and top 5 reasons
            Task {
                await sendCauseChatMessage("Please provide a description for this condition and list the top 5 potential reasons for it. The reasons should be medically applicable and as specific as possible.")
            }
        }
    }

    func sendCauseChatMessage(_ message: String) async {
        guard let cause = activeChatCause, !message.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: message, timestamp: Date())
        chatMessages[cause.condition, default: []].append(userMessage)

        addDebugLog("Chat query sent for cause: \(cause.condition)", type: .info)

        do {
            let response: String
            switch selectedProvider {
            case .claude:
                response = try await apiService.chatAboutCause(apiKey: apiKey, message: message, cause: cause)
            case .gemini:
                response = try await geminiService.chatAboutCause(apiKey: geminiApiKey, message: message, cause: cause)
            case .openai:
                response = try await openaiService.chatAboutCause(apiKey: openaiApiKey, message: message, cause: cause)
            case .ollama:
                response = try await ollamaService.chatAboutCause(baseURL: ollamaBaseURL, model: ollamaModel, message: message, cause: cause)
            case .appleIntelligence:
                response = try await appleIntelligenceService.chatAboutCause(message: message, cause: cause)
            }
            
            let assistantMessage = ChatMessage(role: .assistant, content: response, timestamp: Date())
            chatMessages[cause.condition, default: []].append(assistantMessage)
            addDebugLog("Chat response received from \(selectedProvider.rawValue)", type: .success)
        } catch {
            addDebugLog("Chat failed: \(error.localizedDescription)", type: .error)
        }
    }

    // MARK: - Helper Methods
    func toggleSourceExpansion(_ key: String) {
        if expandedSources.contains(key) {
            expandedSources.remove(key)
        } else {
            expandedSources.insert(key)
        }
    }
    
    func toggleCause(_ cause: MedicalCause) {
        if selectedCauses.contains(cause) {
            selectedCauses.remove(cause)
        } else {
            selectedCauses.insert(cause)
        }
    }

    var medicalDataAvailable: Bool {
        !pdfText.isEmpty || !manualText.isEmpty
    }
    
    // MARK: - Session Management Logic
    private let sessionsStorageKey = "saved_sessions"
    
    func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsStorageKey) {
            if let decoded = try? JSONDecoder().decode([MedicalSession].self, from: data) {
                sessions = decoded.sorted(by: { $0.date > $1.date })
                addDebugLog("Loaded \(sessions.count) sessions", type: .success)
            }
        }
    }
    
    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsStorageKey)
        }
    }
    
    func createNewSession() {
        // Save current session if exists before creating new one
        if currentSessionId != nil {
            updateCurrentSession()
        }
        
        let newSession = MedicalSession(name: "Session \(Date().formatted(date: .abbreviated, time: .shortened))")
        sessions.insert(newSession, at: 0)
        saveSessions()
        loadSession(newSession)
    }
    
    func loadSession(_ session: MedicalSession) {
        // Save current session state before switching
        if currentSessionId != nil {
            updateCurrentSession()
        }
        
        currentSessionId = session.id
        
        // Restore state
        pdfText = session.pdfText
        manualText = session.manualText
        extractedSymptoms = session.extractedSymptoms
        confirmedSymptoms = session.confirmedSymptoms
        additionalSymptoms = session.additionalSymptoms
        potentialCauses = session.potentialCauses
        selectedCauses = session.selectedCauses
        solutions = session.solutions
        chatMessages = session.chatMessages
        debugLogs = session.debugLogs
        
        // Reset UI state
        selectedTab = 0
        activeChatTreatment = nil
        activeChatSymptom = nil
        activeChatCause = nil
        
        addDebugLog("Loaded session: \(session.name)", type: .info)
    }
    
    func updateCurrentSession() {
        guard let id = currentSessionId, let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        
        var session = sessions[index]
        session.pdfText = pdfText
        session.manualText = manualText
        session.extractedSymptoms = extractedSymptoms
        session.confirmedSymptoms = confirmedSymptoms
        session.additionalSymptoms = additionalSymptoms
        session.potentialCauses = potentialCauses
        session.selectedCauses = selectedCauses
        session.solutions = solutions
        session.chatMessages = chatMessages
        session.debugLogs = debugLogs
        
        sessions[index] = session
        saveSessions()
    }
    
    func deleteSession(_ session: MedicalSession) {
        if currentSessionId == session.id {
            currentSessionId = nil
            // Clear current state
            pdfText = ""
            manualText = ""
            extractedSymptoms = []
            confirmedSymptoms = []
            additionalSymptoms = ""
            potentialCauses = nil
            selectedCauses = []
            solutions = nil
            chatMessages = [:]
        }
        
        sessions.removeAll(where: { $0.id == session.id })
        saveSessions()
        addDebugLog("Deleted session: \(session.name)", type: .info)
    }
    
    func renameSession(_ session: MedicalSession, newName: String) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].name = newName
        saveSessions()
    }
}
