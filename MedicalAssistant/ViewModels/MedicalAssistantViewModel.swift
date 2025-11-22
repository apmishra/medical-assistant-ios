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
    
    // LLM Tuning Parameters
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 2048
    @Published var topP: Double = 1.0
    @Published var customSystemPrompt: String = ""
    @Published var pdfText: String = "" { didSet { updateCurrentSession() } }
    @Published var manualText: String = "" { didSet { updateCurrentSession() } }
    @Published var extractedSymptoms: [Symptom] = [] { didSet { updateCurrentSession() } }
    @Published var confirmedSymptoms: Set<Symptom> = [] { didSet { updateCurrentSession() } }
    @Published var additionalSymptoms: String = "" { didSet { updateCurrentSession() } }
    @Published var potentialCauses: CausesResponse? { didSet { updateCurrentSession() } }
    @Published var selectedTreatments: [Treatment] = [] { didSet { updateCurrentSession() } }
    @Published var treatmentsByCause: [String: [Treatment]] = [:] { didSet { updateCurrentSession() } }
    @Published var selectedTreatmentsByCause: [String: Set<String>] = [:] { didSet { updateCurrentSession() } }
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
    @Published var categories: [String] = [] {
        didSet {
            saveCategories()
        }
    }

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
    private let temperatureStorageKey = "llm_temperature"
    private let maxTokensStorageKey = "llm_max_tokens"
    private let topPStorageKey = "llm_top_p"
    private let customSystemPromptStorageKey = "llm_custom_system_prompt"
    private let categoriesStorageKey = "medical_categories"

    init() {
        loadAPIKey()
        loadSessions()
        loadCategories()
    }

    // MARK: - API Key Management
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
        
        loadTuningParameters(for: selectedProvider)
        syncTuningParametersToServices()
        checkAPIKeyStatus()
    }
    
    private func getStorageKey(for provider: LLMProvider, key: String) -> String {
        return "\(provider.rawValue.lowercased())_\(key)"
    }
    
    private func loadTuningParameters(for provider: LLMProvider) {
        let tempKey = getStorageKey(for: provider, key: "temperature")
        let maxTokensKey = getStorageKey(for: provider, key: "max_tokens")
        let topPKey = getStorageKey(for: provider, key: "top_p")
        let systemPromptKey = getStorageKey(for: provider, key: "custom_system_prompt")
        
        temperature = UserDefaults.standard.object(forKey: tempKey) as? Double ?? 0.7
        maxTokens = UserDefaults.standard.object(forKey: maxTokensKey) as? Int ?? 2048
        topP = UserDefaults.standard.object(forKey: topPKey) as? Double ?? 1.0
        customSystemPrompt = UserDefaults.standard.string(forKey: systemPromptKey) ?? ""
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
        loadTuningParameters(for: provider)
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
    
    func saveLLMTuningParameters(temperature: Double, maxTokens: Int, topP: Double, customSystemPrompt: String) {
        let provider = selectedProvider
        let tempKey = getStorageKey(for: provider, key: "temperature")
        let maxTokensKey = getStorageKey(for: provider, key: "max_tokens")
        let topPKey = getStorageKey(for: provider, key: "top_p")
        let systemPromptKey = getStorageKey(for: provider, key: "custom_system_prompt")
        
        UserDefaults.standard.set(temperature, forKey: tempKey)
        UserDefaults.standard.set(maxTokens, forKey: maxTokensKey)
        UserDefaults.standard.set(topP, forKey: topPKey)
        UserDefaults.standard.set(customSystemPrompt, forKey: systemPromptKey)
        
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.customSystemPrompt = customSystemPrompt
        
        syncTuningParametersToServices()
        addDebugLog("\(provider.rawValue) tuning parameters saved", type: .success)
    }
    
    private func syncTuningParametersToServices() {
        // Helper to load params for a specific provider without affecting current UI state
        func getParams(for provider: LLMProvider) -> (Double, Int, Double, String) {
            let tempKey = getStorageKey(for: provider, key: "temperature")
            let maxTokensKey = getStorageKey(for: provider, key: "max_tokens")
            let topPKey = getStorageKey(for: provider, key: "top_p")
            let systemPromptKey = getStorageKey(for: provider, key: "custom_system_prompt")
            
            let t = UserDefaults.standard.object(forKey: tempKey) as? Double ?? 0.7
            let m = UserDefaults.standard.object(forKey: maxTokensKey) as? Int ?? 2048
            let p = UserDefaults.standard.object(forKey: topPKey) as? Double ?? 1.0
            let s = UserDefaults.standard.string(forKey: systemPromptKey) ?? ""
            return (t, m, p, s)
        }
        
        // Sync to Claude
        let claudeParams = getParams(for: .claude)
        apiService.temperature = claudeParams.0
        apiService.maxTokens = claudeParams.1
        apiService.topP = claudeParams.2
        apiService.customSystemPrompt = claudeParams.3
        
        // Sync to Gemini
        let geminiParams = getParams(for: .gemini)
        geminiService.temperature = geminiParams.0
        geminiService.maxTokens = geminiParams.1
        geminiService.topP = geminiParams.2
        geminiService.customSystemPrompt = geminiParams.3
        
        // Sync to OpenAI
        let openaiParams = getParams(for: .openai)
        openaiService.temperature = openaiParams.0
        openaiService.maxTokens = openaiParams.1
        openaiService.topP = openaiParams.2
        openaiService.customSystemPrompt = openaiParams.3
        
        // Sync to Ollama
        let ollamaParams = getParams(for: .ollama)
        ollamaService.temperature = ollamaParams.0
        ollamaService.maxTokens = ollamaParams.1
        ollamaService.topP = ollamaParams.2
        ollamaService.customSystemPrompt = ollamaParams.3
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


    // MARK: - Chat
    func startChat(with treatment: Treatment) {
        activeChatTreatment = treatment
        if chatMessages[treatment.name] == nil {
            chatMessages[treatment.name] = []
            
            // Add welcome message only
            let welcomeMessage = ChatMessage(
                role: .assistant,
                content: "I can help you learn more about \(treatment.name). I have context about your symptoms and potential causes. Feel free to ask any questions!",
                timestamp: Date()
            )
            chatMessages[treatment.name, default: []].append(welcomeMessage)
        }
    }

    func sendChatMessage(_ message: String) async {
        guard let treatment = activeChatTreatment, !message.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: message, timestamp: Date())
        chatMessages[treatment.name, default: []].append(userMessage)

        addDebugLog("Chat query sent for \(treatment.name)", type: .info)

        do {
            // Prepare context
            let symptoms = confirmedSymptoms.map { $0.symptom }
            let causes = Array(selectedCauses).map { $0.condition }
            
            let response: String
            switch selectedProvider {
            case .claude:
                response = try await apiService.chatWithSource(apiKey: apiKey, message: message, treatment: treatment, symptoms: symptoms, causes: causes)
            case .gemini:
                response = try await geminiService.chatWithSource(apiKey: geminiApiKey, message: message, treatment: treatment, symptoms: symptoms, causes: causes)
            case .openai:
                response = try await openaiService.chatWithSource(apiKey: openaiApiKey, message: message, treatment: treatment, symptoms: symptoms, causes: causes)
            case .ollama:
                response = try await ollamaService.chatWithSource(baseURL: ollamaBaseURL, model: ollamaModel, message: message, treatment: treatment, symptoms: symptoms, causes: causes)
            case .appleIntelligence:
                response = try await appleIntelligenceService.chatWithSource(message: message, treatment: treatment, symptoms: symptoms, causes: causes)
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

    // MARK: - Category Management

    func loadCategories() {
        if let savedCategories = UserDefaults.standard.array(forKey: categoriesStorageKey) as? [String] {
            categories = savedCategories
        } else {
            // Pre-populate with default categories
            categories = ["General", "Allopathic", "Ayurvedic", "Homeopathic", "Naturopathic", "Unani"]
        }
    }

    func saveCategories() {
        UserDefaults.standard.set(categories, forKey: categoriesStorageKey)
    }

    func addCategory(_ category: String) -> Bool {
        // Check if category already exists
        if categories.contains(category) {
            return false
        }

        // Check if we've reached the maximum of 7 categories
        if categories.count >= 7 {
            return false
        }

        categories.append(category)
        return true
    }

    func removeCategory(at index: Int) {
        guard index >= 0 && index < categories.count else { return }
        categories.remove(at: index)
    }

    func updateCategory(at index: Int, with newName: String) -> Bool {
        guard index >= 0 && index < categories.count else { return false }

        // Check if the new name already exists (excluding the current index)
        if categories.contains(newName) && categories[index] != newName {
            return false
        }

        categories[index] = newName
        return true
    }

    // MARK: - Treatment Management

    func toggleTreatmentSelection(for cause: String, treatment: Treatment) {
        let treatmentKey = treatment.name + treatment.description // Unique identifier for the treatment

        if selectedTreatmentsByCause[cause] == nil {
            selectedTreatmentsByCause[cause] = []
        }

        if selectedTreatmentsByCause[cause]?.contains(treatmentKey) == true {
            // Remove from selected
            selectedTreatmentsByCause[cause]?.remove(treatmentKey)

            // Remove from overall selected treatments if it exists there
            if let index = selectedTreatments.firstIndex(where: { $0.name == treatment.name && $0.description == treatment.description }) {
                selectedTreatments.remove(at: index)
            }
        } else {
            // Add to selected
            selectedTreatmentsByCause[cause]?.insert(treatmentKey)

            // Add to overall selected treatments if not already there
            if !selectedTreatments.contains(where: { $0.name == treatment.name && $0.description == treatment.description }) {
                selectedTreatments.append(treatment)
            }
        }
    }

    func isTreatmentSelected(for cause: String, treatment: Treatment) -> Bool {
        let treatmentKey = treatment.name + treatment.description
        return selectedTreatmentsByCause[cause]?.contains(treatmentKey) == true
    }

    func setSelectedTreatments(for cause: String, treatments: [Treatment]) {
        let treatmentKeys = Set(treatments.map { $0.name + $0.description })
        selectedTreatmentsByCause[cause] = treatmentKeys

        // Update overall selected treatments
        selectedTreatments = Array(Set(selectedTreatments + treatments))
    }

    func removeTreatment(_ treatment: Treatment) {
        // Remove from overall list
        if let index = selectedTreatments.firstIndex(where: { $0.name == treatment.name && $0.description == treatment.description }) {
            selectedTreatments.remove(at: index)
        }

        // Remove from cause-specific lists
        let treatmentKey = treatment.name + treatment.description
        for (cause, _) in selectedTreatmentsByCause {
            if selectedTreatmentsByCause[cause]?.contains(treatmentKey) == true {
                selectedTreatmentsByCause[cause]?.remove(treatmentKey)
            }
        }
    }

    // MARK: - Treatment Retrieval by Category
    func fetchTreatments(for cause: String, category: String) async -> [Treatment] {
        let symptoms = confirmedSymptoms.map { $0.symptom }

        // Prepare the query for the specific category
        let query = """
        PROVIDE ONLY A VALID JSON ARRAY with exactly 3-5 \(category)-specific treatment options for \(cause), with NO ADDITIONAL TEXT OR EXPLANATION BEFORE OR AFTER THE JSON.

        The JSON structure MUST be exactly:
        [
          {
            "name": "Specific treatment name for \(category) approach",
            "description": "Detailed explanation of how this \(category) treatment addresses \(cause) in the context of \(symptoms.joined(separator: ", "))",
            "source": "\(category)",
            "url": "https://example.com/\(category.lowercased())-treatment or specific \(category) resource",
            "recommendedQuestions": [
              "How effective is this \(category) treatment for \(cause) considering \(symptoms.joined(separator: ", "))?",
              "What are the potential side effects or considerations with this \(category) approach?",
              "How should I integrate this \(category) treatment with my current medications?"
            ]
          }
        ]

        CRITICAL: Return ONLY the JSON array, nothing else.
        """

        do {
            let response: String
            switch selectedProvider {
            case .claude:
                response = try await apiService.chatWithSource(
                    apiKey: apiKey,
                    message: query,
                    treatment: Treatment(
                        name: "Treatment",
                        description: "Placeholder",
                        source: category,
                        url: "",
                        recommendedQuestions: ["Question 1", "Question 2", "Question 3"]
                    ),
                    symptoms: symptoms,
                    causes: [cause]
                )
            case .gemini:
                response = try await geminiService.chatWithSource(
                    apiKey: geminiApiKey,
                    message: query,
                    treatment: Treatment(
                        name: "Treatment",
                        description: "Placeholder",
                        source: category,
                        url: "",
                        recommendedQuestions: ["Question 1", "Question 2", "Question 3"]
                    ),
                    symptoms: symptoms,
                    causes: [cause]
                )
            case .openai:
                response = try await openaiService.chatWithSource(
                    apiKey: openaiApiKey,
                    message: query,
                    treatment: Treatment(
                        name: "Treatment",
                        description: "Placeholder",
                        source: category,
                        url: "",
                        recommendedQuestions: ["Question 1", "Question 2", "Question 3"]
                    ),
                    symptoms: symptoms,
                    causes: [cause]
                )
            case .ollama:
                response = try await ollamaService.chatWithSource(
                    baseURL: ollamaBaseURL,
                    model: ollamaModel,
                    message: query,
                    treatment: Treatment(
                        name: "Treatment",
                        description: "Placeholder",
                        source: category,
                        url: "",
                        recommendedQuestions: ["Question 1", "Question 2", "Question 3"]
                    ),
                    symptoms: symptoms,
                    causes: [cause]
                )
            case .appleIntelligence:
                response = try await appleIntelligenceService.chatWithSource(
                    message: query,
                    treatment: Treatment(
                        name: "Treatment",
                        description: "Placeholder",
                        source: category,
                        url: "",
                        recommendedQuestions: ["Question 1", "Question 2", "Question 3"]
                    ),
                    symptoms: symptoms,
                    causes: [cause]
                )
            }

            // Extract JSON from response
            var jsonString = response
            
            // More robust JSON extraction: find the first [ and the last ]
            if let startIndex = response.firstIndex(of: "["),
               let endIndex = response.lastIndex(of: "]") {
                // Ensure start is before end
                if startIndex <= endIndex {
                    jsonString = String(response[startIndex...endIndex])
                }
            }

            // Clean up the JSON string to remove any trailing characters or markdown formatting
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            if jsonString.hasPrefix("```json") {
                jsonString = String(jsonString.dropFirst(7))
            } else if jsonString.hasPrefix("```") {
                jsonString = String(jsonString.dropFirst(3))
            }
            if jsonString.hasSuffix("```") {
                jsonString = String(jsonString.dropLast(3))
            } else if jsonString.hasSuffix("```json") {
                jsonString = String(jsonString.dropLast(7))
            }
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

            // Additional cleaning: Remove any remaining text that might be outside the JSON
            if let startIndex = jsonString.range(of: "[")?.lowerBound,
               let endIndex = jsonString.range(of: "]", options: .backwards)?.upperBound {
                jsonString = String(jsonString[startIndex..<endIndex])
            } else if let startIndex = jsonString.range(of: "{")?.lowerBound,
                      let endIndex = jsonString.range(of: "}", options: .backwards)?.upperBound {
                jsonString = String(jsonString[startIndex..<endIndex])
            }

            guard let jsonData = jsonString.data(using: .utf8) else {
                addDebugLog("Could not parse treatment response from \(selectedProvider.rawValue)", type: .error)
                print("Trouble parsing this response as JSON: \(response)")
                return []
            }

            let treatments: [Treatment]
            do {
                treatments = try JSONDecoder().decode([Treatment].self, from: jsonData)

                // Only return if we got actual treatments
                if !treatments.isEmpty {
                    return treatments
                }
            } catch {
                print("JSON parsing error: \(error)")
                print("Failed to parse this JSON: \(jsonString)")
            }

            // If JSON parsing failed or returned no results, try to create treatments from the text response
            return createTreatmentsFromTextResponse(response, category: category, cause: cause, symptoms: symptoms)
        } catch {
            addDebugLog("Failed to fetch \(category) treatments for \(cause): \(error.localizedDescription)", type: .error)
            return []
        }
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
    
    func createNewSession(provider: String = "Unknown") {
        // Save current session if exists before creating new one
        if currentSessionId != nil {
            updateCurrentSession()
        }
        
        let newSession = MedicalSession(
            name: "Session \(Date().formatted(date: .abbreviated, time: .shortened))",
            authProvider: provider
        )
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
        selectedTreatments = session.selectedTreatments
        treatmentsByCause = session.treatmentsByCause
        selectedTreatmentsByCause = session.selectedTreatmentsByCause
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
        session.selectedTreatments = selectedTreatments
        session.treatmentsByCause = treatmentsByCause
        session.selectedTreatmentsByCause = selectedTreatmentsByCause
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
            selectedTreatments = []
            treatmentsByCause = [:]
            selectedTreatmentsByCause = [:]
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
    
    func clearCurrentSession() {
        currentSessionId = nil
        pdfText = ""
        manualText = ""
        extractedSymptoms = []
        confirmedSymptoms = []
        additionalSymptoms = ""
        potentialCauses = nil
        selectedCauses = []
        chatMessages = [:]
        debugLogs = []
        selectedTab = 0
    }
    private func createTreatmentsFromTextResponse(_ response: String, category: String, cause: String, symptoms: [String]) -> [Treatment] {
        // Extract treatment-like entries from the text response using regex
        var treatments: [Treatment] = []
        
        // Simple regex to find treatment-style entries in the response
        let treatmentPattern = "(?i)(?:^|\\n)\\s*[-*•]\\s*(.+?)\\.\\s+(.+?)(?=\\n|$)"
        if let regex = try? NSRegularExpression(pattern: treatmentPattern, options: [.anchorsMatchLines]) {
            let range = NSRange(location: 0, length: response.utf16.count)
            let matches = regex.matches(in: response, options: [], range: range)
            
            for match in matches.prefix(5) { // Limit to 5 treatments
                if let nameRange = Range(match.range(at: 1), in: response),
                   let descRange = Range(match.range(at: 2), in: response) {
                    let name = String(response[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let description = String(response[descRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !name.isEmpty {
                        let treatment = Treatment(
                            name: name,
                            description: description,
                            source: category,
                            url: "https://example.com/\(category.lowercased())-treatment",
                            recommendedQuestions: [
                                "How effective is this \(category) treatment for \(cause) considering \(symptoms.joined(separator: ", "))?",
                                "What are the potential side effects or considerations with this \(category) approach?",
                                "How should I integrate this with my current medications?"
                            ]
                        )
                        treatments.append(treatment)
                    }
                }
            }
        }
        
        // If we still have no treatments, return a basic one extracted from the text
        if treatments.isEmpty {
            return [
                Treatment(
                    name: "Treatment for \(cause) (\(category))",
                    description: response.prefix(300) + (response.count > 300 ? "..." : ""),
                    source: category,
                    url: "https://example.com/\(category.lowercased())-treatment",
                    recommendedQuestions: [
                        "How effective is this \(category) treatment for \(cause)?",
                        "What are the potential side effects or contraindications?",
                        "How should I integrate this with my current medications?"
                    ]
                )
            ]
        }
        
        return treatments
    }
}

