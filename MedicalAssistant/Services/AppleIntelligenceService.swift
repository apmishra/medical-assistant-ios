//
//  AppleIntelligenceService.swift
//  MedicalAssistant
//
//  Created by Assistant
//

import Foundation
import NaturalLanguage
import PDFKit

class AppleIntelligenceService: @unchecked Sendable {
    static let shared = AppleIntelligenceService()
    
    private init() {}
    
    // MARK: - PDF Extraction
    func extractTextFromPDF(pdfData: Data) async throws -> String {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw NSError(domain: "AppleIntelligenceService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load PDF"])
        }
        
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Analysis
    func analyzeSymptoms(medicalData: String) async throws -> [Symptom] {
        // Basic on-device analysis using NaturalLanguage
        // We will split the text into sentences and look for symptom-related keywords.
        
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = medicalData
        
        var symptoms: [Symptom] = []
        let keywords = ["pain", "ache", "fever", "cough", "swelling", "fatigue", "nausea", "dizziness", "bleeding", "rash", "injury", "discomfort", "shortness of breath", "vomiting", "headache", "sore", "hurt", "burn", "itch"]
        
        tokenizer.enumerateTokens(in: medicalData.startIndex..<medicalData.endIndex) { tokenRange, _ in
            let sentence = String(medicalData[tokenRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercasedSentence = sentence.lowercased()
            
            // Check if sentence contains any keyword
            for keyword in keywords {
                if lowercasedSentence.contains(keyword) {
                    // Found a potential symptom sentence
                    // Clean it up a bit - truncate if too long
                    let displaySymptom = sentence.count > 100 ? String(sentence.prefix(97)) + "..." : sentence
                    
                    // Avoid duplicates
                    if !symptoms.contains(where: { $0.symptom == displaySymptom }) {
                        symptoms.append(Symptom(
                            symptom: displaySymptom,
                            severity: .moderate, // Default to moderate for detected items
                            source: "Extracted from text"
                        ))
                    }
                    break // Move to next sentence after finding one keyword
                }
            }
            return true
        }
        
        if symptoms.isEmpty {
            return [Symptom(symptom: "No specific symptoms detected in text.", severity: .mild, source: "Analysis")]
        }
        
        return symptoms
    }
    
    func analyzeCauses(symptoms: [String]) async throws -> CausesResponse {
        // Generic response since we can't run a full medical LLM on-device easily yet
        return CausesResponse(causes: [
            MedicalCause(
                condition: "Medical Observation",
                probability: .high,
                explanation: "Based on the extracted text, the patient is experiencing symptoms that require professional evaluation. This on-device analysis has highlighted key areas of concern from the document.",
                urgency: .routine
            ),
            MedicalCause(
                condition: "Consultation Recommended",
                probability: .medium,
                explanation: "The symptoms described (e.g., \(symptoms.prefix(2).joined(separator: ", "))) suggest a need for a physical examination to rule out underlying causes.",
                urgency: .routine
            )
        ])
    }
    
    
    // MARK: - Chat
    func chatWithSource(message: String, treatment: Treatment, symptoms: [String] = [], causes: [String] = []) async throws -> String {
        var response = "Regarding \(treatment.name):\n\n"
        if !symptoms.isEmpty { response += "Based on your symptoms (\(symptoms.joined(separator: ", "))), " }
        if !causes.isEmpty { response += "and potential causes (\(causes.joined(separator: ", "))), " }
        response += "here's information about this treatment:\n\n"
        response += "\(treatment.description)\n\n"
        response += "This is a general response. For specific medical advice, please consult a healthcare professional."
        return response
    }
    
    func chatAboutSymptom(message: String, symptom: Symptom) async throws -> String {
        return "I detected the symptom: '\(symptom.symptom)'. Please provide more details to your healthcare provider."
    }
    
    func chatAboutCause(message: String, cause: MedicalCause) async throws -> String {
        return "Regarding '\(cause.condition)': \(cause.explanation). This is a preliminary analysis based on text extraction."
    }
}
