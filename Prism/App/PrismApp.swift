//
//  PrismApp.swift
//  Prism
//
//  Created by okooo5km(十里) on 2025/9/30.
//

import SwiftUI
import AppKit
import Sparkle

@main
struct PrismApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        let updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                             updaterDelegate: self,
                                                             userDriverDelegate: nil)
        
        NSApplication.shared.setActivationPolicy(.accessory)
        StatusBarController.shared.setup()
        
        UpdaterViewModel.shared.updaterController = updaterController
        // 可选：启动一次后台检查
        UpdaterViewModel.shared.startAutomaticChecksIfNeeded()
        
        // Sync configuration on app startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ConfigImportService.shared.syncConfigurationOnStartup()
        }
    }

    // MARK: - SPUUpdaterDelegate（在 2.x 中仍支持这些回调）
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        DispatchQueue.main.async {
            UpdaterViewModel.shared.foundItem = item
            UpdaterViewModel.shared.updateAvailable = true
        }
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        DispatchQueue.main.async {
            UpdaterViewModel.shared.foundItem = nil
            UpdaterViewModel.shared.updateAvailable = false
        }
    }
}
