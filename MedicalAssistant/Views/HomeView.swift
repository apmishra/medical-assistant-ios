//
//  HomeView.swift
//  MedicalAssistant
//
//  Created by Barbarik
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var sessionToRename: MedicalSession?
    @State private var newName = ""
    @State private var searchText = ""

    var providerSessions: [MedicalSession] {
        let sessions = viewModel.sessions

        if searchText.isEmpty {
            return sessions
        } else {
            return sessions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // Group sessions by date (ignoring time)
    var groupedSessions: [(String, [MedicalSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: providerSessions) { session -> Date in
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
                // Welcome header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Manage your sessions")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .background(Color(.systemBackground))

                Divider()

                // Sessions calendar view
                if groupedSessions.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()

                        Image(systemName: "calendar.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)

                        Text("No Sessions Yet")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Tap the + button to create your first session")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Spacer()
                    }
                } else {
                    // Sessions list
                    List {
                        ForEach(groupedSessions, id: \.0) { dateString, sessions in
                            Section {
                                ForEach(sessions) { session in
                                    HomeSessionRowView(
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
                                HomeDateHeader(dateString: dateString, count: sessions.count)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search sessions")
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.createNewSession(provider: "User")
                    }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
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
}

// MARK: - Home Date Header
struct HomeDateHeader: View {
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

// MARK: - Home Session Row View
struct HomeSessionRowView: View {
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
