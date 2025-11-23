//
//  SessionsView.swift
//  MedicalAssistant
//
//  Created by Claude
//

import SwiftUI

struct SessionsView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @EnvironmentObject var authService: AuthenticationService
    @State private var searchText = ""
    @State private var sessionToRename: MedicalSession?
    @State private var newName = ""
    @State private var showingNewSessionSheet = false

    var filteredSessions: [MedicalSession] {
        guard let currentUserId = authService.userId else { return [] }

        let sessions = viewModel.sessions.filter { $0.authProvider == currentUserId }

        if searchText.isEmpty {
            return sessions
        } else {
            return sessions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
        List {
            ForEach(groupedSessions, id: \.0) { dateString, sessions in
                Section(header: DateHeaderView(dateString: dateString, count: sessions.count)) {
                    ForEach(sessions) { session in
                Button(action: {
                    viewModel.loadSession(session)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(session.authProvider)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        if viewModel.currentSessionId == session.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .contextMenu {
                    Button(action: {
                        sessionToRename = session
                        newName = session.name
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    ShareLink(item: session.toCSV(), preview: SharePreview(session.name + ".csv")) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: {
                        viewModel.deleteSession(session)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteSession(session)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        sessionToRename = session
                        newName = session.name
                    } label: {
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
            }
        }
        .navigationTitle("Sessions")
        .searchable(text: $searchText, prompt: "Search sessions")
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
    }
}

// MARK: - Date Header View
struct DateHeaderView: View {
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
