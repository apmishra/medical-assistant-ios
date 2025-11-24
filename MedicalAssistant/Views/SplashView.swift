//
//  SplashView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var sessionToRename: MedicalSession?
    @State private var newName = ""
    @State private var searchText = ""
    @State private var showMedicalHistory = false
    
    // Filter sessions based on search text
    var filteredSessions: [MedicalSession] {
        if searchText.isEmpty {
            return viewModel.sessions
        } else {
            return viewModel.sessions.filter { session in
                // Search in session name
                if session.name.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // Search in symptoms
                if session.confirmedSymptoms.contains(where: { $0.symptom.localizedCaseInsensitiveContains(searchText) }) {
                    return true
                }
                
                // Search in causes
                if session.selectedCauses.contains(where: { $0.condition.localizedCaseInsensitiveContains(searchText) }) {
                    return true
                }
                
                // Search in treatments
                if session.selectedTreatments.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText) }) {
                    return true
                }
                
                // Also search in treatments by cause
                for treatments in session.treatmentsByCause.values {
                    if treatments.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText) }) {
                        return true
                    }
                }
                
                // Search in questions
                if session.selectedQuestions.contains(where: { $0.question.localizedCaseInsensitiveContains(searchText) }) {
                    return true
                }
                
                return false
            }
        }
    }

    // Group sessions by date (ignoring time)
    var groupedSessions: [(String, [MedicalSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session -> Date in
            calendar.startOfDay(for: session.date)
        }

        return grouped
            .sorted { $0.key > $1.key } // Most recent dates first
            .map { (key, value) in
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .full
                dateFormatter.timeStyle = .none

                // Check if date is today, yesterday, or other
                let dateString: String
                if calendar.isDateInToday(key) {
                    dateString = "Today"
                } else if calendar.isDateInYesterday(key) {
                    dateString = "Yesterday"
                } else {
                    dateString = dateFormatter.string(from: key)
                }

                return (dateString, value.sorted { $0.date > $1.date })
            }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header with title and + button
                HStack {
                    Text("Assistant")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        showMedicalHistory = true
                    }) {
                        Image(systemName: "heart.text.square")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    Button(action: {
                        viewModel.createNewSession(provider: "User")
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))

                Divider()

                // Sessions view - Always show List to keep search bar accessible
                List {
                    if groupedSessions.isEmpty {
                        // Empty state
                        Section {
                            VStack(spacing: 20) {
                                Image(systemName: searchText.isEmpty ? "calendar.badge.plus" : "magnifyingglass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)

                                Text(searchText.isEmpty ? "No Sessions Yet" : "No Results")
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                Text(searchText.isEmpty ? "Tap the + button to create your first session" : "No sessions match '\(searchText)'")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .padding(.bottom, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } else {
                        // Sessions list
                        ForEach(groupedSessions, id: \.0) { dateString, sessions in
                            Section {
                                ForEach(sessions) { session in
                                    SessionRowView(
                                        session: session,
                                        isActive: viewModel.currentSessionId == session.id,
                                        onTap: {
                                            viewModel.loadSession(session)
                                        },
                                        onRename: {
                                            sessionToRename = session
                                            newName = session.name
                                        },
                                        onDelete: {
                                            viewModel.deleteSession(session)
                                        }
                                    )
                                }
                            } header: {
                                DateSectionHeader(dateString: dateString, count: sessions.count)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search sessions")
            }
            .navigationBarHidden(true)
            .alert("Rename Session", isPresented: Binding(
                get: { sessionToRename != nil },
                set: { if !$0 { sessionToRename = nil } }
            )) {
                TextField("New Name", text: $newName)
                Button("Cancel", role: .cancel) { sessionToRename = nil }
                Button("Save") {
                    if let session = sessionToRename {
                        viewModel.renameSession(session, newName: newName)
                    }
                    sessionToRename = nil
                }
            }
            .sheet(isPresented: $showMedicalHistory) {
                MedicalHistoryView()
                    .environmentObject(viewModel)
            }
        }
    }
}

// MARK: - Date Section Header
struct DateSectionHeader: View {
    let dateString: String
    let count: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("\(count) session\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: MedicalSession
    let isActive: Bool
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time indicator
                VStack(spacing: 2) {
                    Text(session.date, style: .time)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    if isActive {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(width: 60)

                // Vertical line
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 2)

                // Session info
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if !session.confirmedSymptoms.isEmpty {
                            Label("\(session.confirmedSymptoms.count)", systemImage: "stethoscope")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if !session.selectedCauses.isEmpty {
                            Label("\(session.selectedCauses.count)", systemImage: "cross.case")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if !session.selectedTreatments.isEmpty {
                            Label("\(session.selectedTreatments.count)", systemImage: "pills")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onRename) {
                Label("Rename", systemImage: "pencil")
            }

            ShareLink(item: session.toCSV(), preview: SharePreview(session.name + ".csv")) {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }

            Button(action: onRename) {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.orange)

            ShareLink(item: session.toCSV(), preview: SharePreview(session.name + ".csv")) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }
}
