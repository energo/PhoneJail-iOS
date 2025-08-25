//
//  ExtensionDebugReader.swift
//  AntiSocial
//
//  Created by Assistant on 25.01.2025.
//

import Foundation

class ExtensionDebugReader {
    static let shared = ExtensionDebugReader()
    
    private init() {}
    
    /// Read debug log from extension
    func readExtensionDebugLog() -> String? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.app.antisocial.sharedData"
        ) else {
            return nil
        }
        
        let fileURL = containerURL.appendingPathComponent("extension_debug.txt")
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return content
        } catch {
            return "No debug log found or error reading: \(error.localizedDescription)"
        }
    }
    
    /// Clear debug log
    func clearExtensionDebugLog() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.app.antisocial.sharedData"
        ) else {
            return
        }
        
        let fileURL = containerURL.appendingPathComponent("extension_debug.txt")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    /// Print last N lines of debug log
    func printLastDebugLines(count: Int = 50) {
        guard let content = readExtensionDebugLog() else {
            print("No debug log available")
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        let lastLines = lines
        
        print("=== EXTENSION DEBUG LOG (Last \(count) lines) ===")
        for line in lastLines {
            print(line)
        }
        print("=== END DEBUG LOG ===")
    }
}
