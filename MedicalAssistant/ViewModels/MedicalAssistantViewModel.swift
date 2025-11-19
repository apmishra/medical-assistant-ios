//
//  MedicalAssistantViewModel.swift
//  MedicalAssistant
//
//  Created by Claude
//

import Foundation
import SwiftUI

@MainActor
class MedicalAssistantViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var apiKey: String = ""
    @Published var pdfText: String = ""
    @Published var manualText: String = ""
    @Published var extractedSymptoms: [Symptom] = []
    @Published var confirmedSymptoms: Set<Symptom> = []
    @Published var additionalSymptoms: String = ""
    @Published var potentialCauses: CausesResponse?
    @Published var solutions: SolutionsResponse?
    @Published var debugLogs: [DebugLog] = []
    @Published var isLoading: Bool = false
    @Published var showApiKeyInput: Bool = false
    @Published var chatMessages: [String: [ChatMessage]] = [:]
    @Published var activeChatTreatment: Treatment?
    @Published var expandedSources: Set<String> = []

    private let apiService = ClaudeAPIService.shared
    private let apiKeyStorageKey = "claude_api_key"

    init() {
        loadAPIKey()
    }

    // MARK: - API Key Management
    func loadAPIKey() {
        if let storedKey = UserDefaults.standard.string(forKey: apiKeyStorageKey) {
            apiKey = storedKey
            addDebugLog("API Key loaded from storage", type: .success)
        } else {
            showApiKeyInput = true
            addDebugLog("No API Key found - please enter one", type: .warning)
        }
    }

    func saveAPIKey(_ key: String) {
        guard !key.isEmpty else { return }
        UserDefaults.standard.set(key, forKey: apiKeyStorageKey)
        apiKey = key
        showApiKeyInput = false
        addDebugLog("API Key saved successfully", type: .success)
    }

    // MARK: - Debug Logging
    func addDebugLog(_ message: String, type: DebugLog.LogType = .info) {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let timestamp = formatter.string(from: Date())
        let log = DebugLog(timestamp: timestamp, message: message, type: type)
        debugLogs.append(log)
    }

    func clearDebugLogs() {
        debugLogs.removeAll()
    }

    // MARK: - PDF Processing
    func handlePDFUpload(data: Data) async {
        isLoading = true
        addDebugLog("Extracting text from PDF...", type: .info)

        do {
            let text = try await apiService.extractTextFromPDF(apiKey: apiKey, pdfData: data)
            pdfText = text
            addDebugLog("Text extracted from PDF", type: .success)
        } catch {
            addDebugLog("Failed to extract text from PDF: \(error.localizedDescription)", type: .error)
        }

        isLoading = false
    }

    // MARK: - Symptom Analysis
    func analyzeSymptoms() async {
        let medicalData = !pdfText.isEmpty ? pdfText : manualText
        guard !medicalData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            addDebugLog("Please provide medical data first", type: .warning)
            return
        }

        isLoading = true
        addDebugLog("Analyzing medical data for symptoms...", type: .info)

        do {
            let symptoms = try await apiService.analyzeSymptoms(apiKey: apiKey, medicalData: medicalData)
            extractedSymptoms = symptoms
            addDebugLog("Extracted \(symptoms.count) symptoms", type: .success)
        } catch {
            addDebugLog("Failed to analyze symptoms: \(error.localizedDescription)", type: .error)
        }

        isLoading = false
    }

    func toggleSymptom(_ symptom: Symptom) {
        if confirmedSymptoms.contains(symptom) {
            confirmedSymptoms.remove(symptom)
        } else {
            confirmedSymptoms.insert(symptom)
        }
    }

    // MARK: - Cause Analysis
    func analyzeCauses() async {
        guard !confirmedSymptoms.isEmpty || !additionalSymptoms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            addDebugLog("Please confirm at least one symptom or add additional symptoms", type: .warning)
            return
        }

        isLoading = true
        addDebugLog("Analyzing potential causes...", type: .info)

        var allSymptoms = confirmedSymptoms.map { $0.symptom }
        let additional = additionalSymptoms
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        allSymptoms.append(contentsOf: additional)

        do {
            let causes = try await apiService.analyzeCauses(apiKey: apiKey, symptoms: allSymptoms)
            potentialCauses = causes
            addDebugLog("Identified \(causes.causes.count) potential causes", type: .success)
        } catch {
            addDebugLog("Failed to analyze causes: \(error.localizedDescription)", type: .error)
        }

        isLoading = false
    }

    // MARK: - Solution Finding
    func findSolutions() async {
        guard let causes = potentialCauses else {
            addDebugLog("Please analyze causes first", type: .warning)
            return
        }

        isLoading = true
        addDebugLog("Searching for treatment solutions...", type: .info)

        let conditions = causes.causes.map { $0.condition }

        do {
            let solutions = try await apiService.findSolutions(apiKey: apiKey, conditions: conditions)
            self.solutions = solutions
            addDebugLog("Found solutions across \(solutions.solutions.count) categories", type: .success)
        } catch {
            addDebugLog("Failed to find solutions: \(error.localizedDescription)", type: .error)
        }

        isLoading = false
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
            let response = try await apiService.chatWithSource(apiKey: apiKey, message: message, treatment: treatment)
            let assistantMessage = ChatMessage(role: .assistant, content: response, timestamp: Date())
            chatMessages[treatment.name, default: []].append(assistantMessage)
            addDebugLog("Chat response received", type: .success)
        } catch {
            addDebugLog("Chat failed: \(error.localizedDescription)", type: .error)
        }
    }

    func closeChat() {
        activeChatTreatment = nil
    }

    // MARK: - Helper Methods
    func toggleSourceExpansion(_ key: String) {
        if expandedSources.contains(key) {
            expandedSources.remove(key)
        } else {
            expandedSources.insert(key)
        }
    }

    var medicalDataAvailable: Bool {
        !pdfText.isEmpty || !manualText.isEmpty
    }
}
