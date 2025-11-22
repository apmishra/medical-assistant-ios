//
//  CategoryManagementView.swift
//  MedicalAssistant
//
//  Created by OpenCode Assistant
//

import SwiftUI

struct CategoryManagementView: View {
    @EnvironmentObject var viewModel: MedicalAssistantViewModel
    @State private var newCategoryName: String = ""
    @State private var showingAddAlert = false
    @State private var showingLimitAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Medical Treatment Categories")
                .font(.headline)
            
            Text("Manage categories for treatment solutions (Maximum 7 categories)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Current Categories List
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Categories (\(viewModel.categories.count)/7)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if viewModel.categories.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tag")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("No categories added yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                } else {
                    ForEach(Array(viewModel.categories.enumerated()), id: \.element) { index, category in
                        HStack {
                            Text(category)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.removeCategory(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Add Category Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Add New Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Enter category name", text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addCategory) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            Spacer()
        }
        .padding()
        .alert("Category Limit Reached", isPresented: $showingLimitAlert) {
            Button("OK") { }
        } message: {
            Text("You can only have up to 7 categories. Please remove some before adding more.")
        }
        .onChange(of: viewModel.categories) { newValue in
            // Ensure we don't exceed the limit
            if newValue.count > 7 {
                // This shouldn't happen with proper validation, but just in case
                let truncatedCategories = Array(newValue.prefix(7))
                viewModel.categories = truncatedCategories
            }
        }
    }
    
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return
        }
        
        if viewModel.categories.count >= 7 {
            showingLimitAlert = true
            return
        }
        
        if viewModel.addCategory(trimmedName) {
            newCategoryName = ""
        } else {
            // Category already exists
            showingAddAlert = true
        }
    }
}

struct CategoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryManagementView()
            .environmentObject(MedicalAssistantViewModel())
    }
}