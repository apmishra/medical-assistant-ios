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

    var filteredSessions: [MedicalSession] {
        guard let currentUserId = authService.userId else { return [] }
        
        let sessions = viewModel.sessions.filter { $0.authProvider == currentUserId }
        
        if searchText.isEmpty {
            return sessions
        } else {
            return sessions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        List {
            ForEach(filteredSessions) { session in
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
