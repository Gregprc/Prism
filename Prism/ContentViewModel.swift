//
//  ContentViewModel.swift
//  Prism
//
//  Created by okooo5km(十里) on 2025/9/30.
//

import SwiftUI

@Observable
class ContentViewModel {
    // App Navigation State
    var currentView: AppView = .main

    enum AppView {
        case main
        case add
        case edit(Provider)
    }

    // Dependencies
    private let configManager = ConfigManager()
    private let providerStore = ProviderStore.shared

    init() {}

    // Computed Properties
    var isDefaultActive: Bool {
        let currentEnv = configManager.getCurrentEnvVariables()
        let hasBaseURL = !(currentEnv["ANTHROPIC_BASE_URL"] ?? "").isEmpty
        let hasAuthToken = !(currentEnv["ANTHROPIC_AUTH_TOKEN"] ?? "").isEmpty
        return !hasBaseURL && !hasAuthToken
    }

    var activeProvider: Provider? {
        providerStore.activeProvider
    }

    var providers: [Provider] {
        providerStore.providers
    }

    // MARK: - Navigation Actions
    func showAddProvider() {
        currentView = .add
    }

    func showEditProvider(_ provider: Provider) {
        currentView = .edit(provider)
    }

    func backToMain() {
        currentView = .main
    }

    // MARK: - Provider Actions
    func activateProvider(_ provider: Provider) {
        providerStore.activateProvider(provider)
        applyProviderToConfig(provider)
    }

    func activateDefault() {
        providerStore.deactivateAllProviders()
        clearConfigEnv()
    }

    func addProvider(_ provider: Provider) {
        providerStore.addProvider(provider)
        applyProviderToConfig(provider)
    }

    func updateProvider(_ provider: Provider) {
        providerStore.updateProvider(provider)
    }

    func deleteProvider(_ provider: Provider) {
        providerStore.deleteProvider(provider)
    }

    // MARK: - Private Helper Methods
    private func applyProviderToConfig(_ provider: Provider) {
        let success = configManager.updateEnvVariables(provider.envVariables)
        if !success {
            print("Failed to apply provider configuration")
        }
    }

    private func clearConfigEnv() {
        let success = configManager.updateEnvVariables([:])
        if !success {
            print("Failed to clear configuration")
        }
    }
}