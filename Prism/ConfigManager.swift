//
//  ConfigManager.swift
//  Prism
//
//  Created by okooo5km(十里) on 2025/9/30.
//

import Foundation

@Observable
class ConfigManager {
    private let claudeConfigPath: String
    private let backupPath: String

    init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        claudeConfigPath = homeDirectory.appendingPathComponent(".claude/settings.json").path
        backupPath = homeDirectory.appendingPathComponent(".claude/settings.json.backup").path
    }

    struct ClaudeConfig: Codable {
        var env: [String: String]?

        init() {
            self.env = nil
        }

        init(env: [String: String]? = nil) {
            self.env = env
        }
    }

    func readConfig() -> ClaudeConfig? {
        guard FileManager.default.fileExists(atPath: claudeConfigPath) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: claudeConfigPath))
            let config = try JSONDecoder().decode(ClaudeConfig.self, from: data)
            return config
        } catch {
            print("Failed to read Claude config: \(error)")
            return nil
        }
    }

    func writeConfig(_ config: ClaudeConfig) -> Bool {
        // Create backup before writing
        createBackup()

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let data = try encoder.encode(config)

            // Ensure directory exists
            let directory = (claudeConfigPath as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

            try data.write(to: URL(fileURLWithPath: claudeConfigPath))
            return true
        } catch {
            print("Failed to write Claude config: \(error)")
            // Restore backup if write failed
            restoreBackup()
            return false
        }
    }

    func updateEnvVariables(_ envVars: [String: String]) -> Bool {
        // Debug: Print what we're about to write
        print("🔧 Writing env variables to Claude config:")
        for (key, value) in envVars {
            let displayValue = key == "ANTHROPIC_AUTH_TOKEN" ?
                "\(String(value.prefix(10)))..." : value
            print("  \(key): \(displayValue)")
        }

        var config = readConfig() ?? ClaudeConfig()
        config.env = envVars
        return writeConfig(config)
    }

    func getCurrentEnvVariables() -> [String: String] {
        return readConfig()?.env ?? [:]
    }

    private func createBackup() {
        if FileManager.default.fileExists(atPath: claudeConfigPath) {
            do {
                // Remove existing backup if it exists
                if FileManager.default.fileExists(atPath: backupPath) {
                    try FileManager.default.removeItem(atPath: backupPath)
                }
                // Create new backup
                try FileManager.default.copyItem(atPath: claudeConfigPath, toPath: backupPath)
            } catch {
                print("Failed to create backup: \(error)")
            }
        }
    }

    private func restoreBackup() {
        if FileManager.default.fileExists(atPath: backupPath) {
            do {
                try FileManager.default.removeItem(atPath: claudeConfigPath)
                try FileManager.default.copyItem(atPath: backupPath, toPath: claudeConfigPath)
                try FileManager.default.removeItem(atPath: backupPath)
            } catch {
                print("Failed to restore backup: \(error)")
            }
        }
    }
}