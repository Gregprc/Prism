//
//  ConfigManager.swift
//  Prism
//
//  Created by okooo5km(十里) on 2025/9/30.
//

import Foundation

@Observable
class ConfigManager {
    private let sandboxManager = SandboxAccessManager.shared

    // Use raw JSON dictionary to preserve all config keys
    typealias ClaudeConfig = [String: Any]

    func readConfig() -> ClaudeConfig? {
        do {
            return try sandboxManager.withSecureAccess { directoryURL in
                let configURL = directoryURL.appendingPathComponent("settings.json")
                guard FileManager.default.fileExists(atPath: configURL.path) else {
                    return nil
                }

                let data = try Data(contentsOf: configURL)
                let config = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                return config
            }
        } catch {
            print("Failed to read Claude config: \(error)")
            return nil
        }
    }

    func writeConfig(_ config: ClaudeConfig) -> Bool {
        // Create backup before writing
        createBackup()

        do {
            return try sandboxManager.withSecureAccess { directoryURL in
                let configURL = directoryURL.appendingPathComponent("settings.json")

                let data = try JSONSerialization.data(
                    withJSONObject: config,
                    options: [.prettyPrinted, .withoutEscapingSlashes]
                )

                // Ensure directory exists
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

                try data.write(to: configURL)
                return true
            }
        } catch {
            print("Failed to write Claude config: \(error)")
            // Restore backup if write failed
            restoreBackup()
            return false
        }
    }

    func updateEnvVariables(_ envVars: [String: EnvValue], previousKeys: [String]) -> Bool {
        // Debug: Print what we're about to write
        print("🔧 Writing env variables to Claude config:")
        for (key, envValue) in envVars {
            let displayValue = key == "ANTHROPIC_AUTH_TOKEN" ?
                String(repeating: "*", count: min(envValue.value.count, 20)) : envValue.value
            print("  \(key): \(displayValue) (type: \(envValue.type))")
        }

        // Read existing config to preserve all fields
        var config = readConfig() ?? [:]

        // Get existing env or create new one
        var existingEnv = (config["env"] as? [String: Any]) ?? [:]

        print("🧹 Clearing previous Prism-managed keys: \(previousKeys)")

        // Remove all previously managed keys (includes base + custom vars from previous provider)
        for key in previousKeys {
            existingEnv.removeValue(forKey: key)
        }

        // Add new environment variables with proper type conversion
        for (key, envValue) in envVars {
            switch envValue.type {
            case .string:
                existingEnv[key] = envValue.value
            case .integer:
                if let intValue = Int(envValue.value) {
                    existingEnv[key] = intValue
                } else {
                    print("⚠️ Warning: Failed to convert '\(envValue.value)' to integer for key '\(key)', storing as string")
                    existingEnv[key] = envValue.value
                }
            case .boolean:
                // Convert to 0/1 integer format for Claude Code compatibility
                if envValue.value == "1" || envValue.value.lowercased() == "true" {
                    existingEnv[key] = 1
                } else {
                    existingEnv[key] = 0
                }
            }
        }

        // Update config with merged env
        config["env"] = existingEnv

        return writeConfig(config)
    }

    func getCurrentEnvVariables() -> [String: EnvValue] {
        guard let config = readConfig() else { return [:] }
        guard let env = config["env"] as? [String: Any] else { return [:] }

        // Convert [String: Any] to [String: EnvValue]
        var result: [String: EnvValue] = [:]
        for (key, value) in env {
            // Determine type based on EnvKey enum, default to string
            let valueType: EnvValueType
            if let envKey = EnvKey(rawValue: key) {
                valueType = envKey.valueType
            } else {
                // Custom variable: infer type from value
                if value is Int {
                    valueType = .integer
                } else if value is Bool {
                    valueType = .boolean
                } else {
                    valueType = .string
                }
            }

            // Convert value to string
            let stringValue: String
            if let intValue = value as? Int {
                stringValue = String(intValue)
            } else if let boolValue = value as? Bool {
                stringValue = boolValue ? "1" : "0"
            } else if let strValue = value as? String {
                stringValue = strValue
            } else {
                stringValue = "\(value)"
            }

            result[key] = EnvValue(value: stringValue, type: valueType)
        }

        return result
    }

    func debugPrintCurrentEnvVariables() {
        let envVars = getCurrentEnvVariables()
        if envVars.isEmpty {
            print("🔍 No environment variables found")
            return
        }

        print("🔍 Current Claude Code env variables:")
        for (key, envValue) in envVars {
            let displayValue = key == "ANTHROPIC_AUTH_TOKEN" ?
                String(repeating: "*", count: min(envValue.value.count, 20)) : envValue.value
            print("  \(key): \(displayValue) (type: \(envValue.type))")
        }
    }

    func removeManagedEnvVariables(previousKeys: [String]) -> Bool {
        // Read existing config to preserve all fields
        var config = readConfig() ?? [:]

        // Get existing env or create new one
        var existingEnv = (config["env"] as? [String: Any]) ?? [:]

        print("🧹 Removing Prism-managed env variables: \(previousKeys)")

        // Remove all previously managed keys (includes base + custom vars from previous provider)
        for key in previousKeys {
            existingEnv.removeValue(forKey: key)
        }

        // Update config with cleaned env
        config["env"] = existingEnv

        return writeConfig(config)
    }

    private func createBackup() {
        do {
            try sandboxManager.withSecureAccess { directoryURL in
                let configURL = directoryURL.appendingPathComponent("settings.json")
                let backupURL = directoryURL.appendingPathComponent("settings.json.backup")

                guard FileManager.default.fileExists(atPath: configURL.path) else { return }

                // Remove existing backup if it exists
                if FileManager.default.fileExists(atPath: backupURL.path) {
                    try FileManager.default.removeItem(at: backupURL)
                }
                // Create new backup
                try FileManager.default.copyItem(at: configURL, to: backupURL)
            }
        } catch {
            print("Failed to create backup: \(error)")
        }
    }

    private func restoreBackup() {
        do {
            try sandboxManager.withSecureAccess { directoryURL in
                let configURL = directoryURL.appendingPathComponent("settings.json")
                let backupURL = directoryURL.appendingPathComponent("settings.json.backup")

                guard FileManager.default.fileExists(atPath: backupURL.path) else { return }

                try FileManager.default.removeItem(at: configURL)
                try FileManager.default.copyItem(at: backupURL, to: configURL)
                try FileManager.default.removeItem(at: backupURL)
            }
        } catch {
            print("Failed to restore backup: \(error)")
        }
    }
}