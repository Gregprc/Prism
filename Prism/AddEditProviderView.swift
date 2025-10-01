//
//  AddEditProviderView.swift
//  Prism
//
//  Created by okooo5km(十里) on 2025/9/30.
//

import SwiftUI

struct AddEditProviderView: View {
    let provider: Provider?
    let onSave: (Provider) -> Void
    let onCancel: () -> Void
    
    @State private var providerName: String
    @State private var selectedTemplate: ProviderTemplate? = .zhipuAI
    @State private var envVariables: [String: String]
    
    init(provider: Provider?, onSave: @escaping (Provider) -> Void, onCancel: @escaping () -> Void) {
        self.provider = provider
        self.onSave = onSave
        self.onCancel = onCancel
        
        print("🔧 AddEditProviderView init - provider: \(provider?.name ?? "nil")")
        _providerName = State(initialValue: provider?.name ?? "")
        _envVariables = State(initialValue: provider?.envVariables ?? [:])
        _selectedTemplate = State(initialValue: nil)
        
        print("🔧 Initial state - name: '\(providerName)', envVars: \(envVariables)")
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Button(action: {
                    onCancel()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Text(provider == nil ? "Add Provider" : "Edit Provider")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    let newProvider: Provider
                    if let existingProvider = provider {
                        // Editing: preserve id, isActive, and icon
                        newProvider = Provider(
                            id: existingProvider.id,
                            name: providerName.isEmpty ? "Untitled Provider" : providerName,
                            envVariables: envVariables,
                            icon: existingProvider.icon,
                            isActive: existingProvider.isActive
                        )
                    } else {
                        // Adding: infer icon from BASE_URL
                        let inferredIcon = ProviderStore.inferIcon(from: envVariables)
                        newProvider = Provider(
                            name: providerName.isEmpty ? "Untitled Provider" : providerName,
                            envVariables: envVariables,
                            icon: inferredIcon,
                            isActive: false
                        )
                    }
                    onSave(newProvider)
                }, label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                })
                .buttonStyle(.gradient(configuration: .primary))
                .disabled(providerName.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    
                    if provider == nil {
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.text.square.fill")
                                Text("Provider Template")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            
                            Spacer()
                            
                            Picker("", selection: $selectedTemplate) {
                                Label("Choose a template", systemImage: "checklist")
                                    .tag(nil as ProviderTemplate?)
                                ForEach(ProviderTemplate.allTemplates, id: \.name) { template in
                                    Text(template.name)
                                        .tag(template as ProviderTemplate?)
                                }
                            }
                            .pickerStyle(.menu)
                            .controlSize(.small)
                            .onChange(of: selectedTemplate) { _, template in
                                if let template = template {
                                    providerName = template.name
                                    envVariables = template.envVariables
                                }
                            }
                        }
                        .padding(8)
                        .background(cornerRadius: 12, strokeColor: .primary.opacity(0.08), fill: .background.opacity(0.6))
                    }
                    
                    // Provider Information
                    DetailTextFieldCardView(
                        title: "Provider Name",
                        systemImage: "person.text.rectangle",
                        placeholder: "Enter provider name",
                        value: $providerName
                    )
                    
                    // Environment Variables
                    ForEach(EnvKey.allCases) { envKey in
                        if envKey == .authToken {
                            DetailSecureFieldCardView(
                                title: envKey.displayName,
                                systemImage: envKey.systemImage,
                                placeholder: envKey.placeholder,
                                value: binding(for: envKey)
                            )
                        } else {
                            DetailTextFieldCardView(
                                title: envKey.displayName,
                                systemImage: envKey.systemImage,
                                placeholder: envKey.placeholder,
                                value: binding(for: envKey)
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }
    
    private func binding(for envKey: EnvKey) -> Binding<String> {
        Binding<String>(
            get: {
                envVariables[envKey.rawValue] ?? ""
            },
            set: { newValue in
                envVariables[envKey.rawValue] = newValue
            }
        )
    }
}

#Preview {
    AddEditProviderView(
        provider: nil,
        onSave: { provider in
            print("Saved provider: \(provider.name)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
