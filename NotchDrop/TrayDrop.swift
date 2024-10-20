//
//  TrayDrop.swift
//  NotchDrop
//
//  Edited by Lane Shukhov on 2024/10/21.
//

import Cocoa
import Combine
import Foundation
import OrderedCollections
import Yaml

class TrayDrop: ObservableObject {
    static let shared = TrayDrop()

    @Published var currentEntry: TimeEntry?
    @Published var entries: [TimeEntry] = []

    @Persist(key: "logDirectoryBookmark", defaultValue: Data())
    private var logDirectoryBookmark: Data

    @Published var logDirectory: String = ""

    private var logDirectoryURL: URL? {
        didSet {
            logDirectory = logDirectoryURL?.path ?? ""
        }
    }

    private init() {
        restoreLogDirectoryAccess()
    }

    func startNewEntry() -> TimeEntry {
        let newEntry = TimeEntry()
        currentEntry = newEntry
        return newEntry
    }

    func saveCurrentEntry() {
        guard let entry = currentEntry else { return }
        entries.append(entry)
        saveEntriesToFile()
        currentEntry = nil
    }

    func saveEntriesToFile() {
        guard let fileURL = getFileURL() else { return }
        let yamlString = entriesToYamlString(entries)
        do {
            try yamlString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving entries: \(error)")
        }
    }
    
    private func entriesToYamlString(_ entries: [TimeEntry]) -> String {
        var yamlString = ""
        for entry in entries {
            yamlString += "- id: \(entry.id.uuidString)\n"
            yamlString += "  startTime: \(ISO8601DateFormatter().string(from: entry.startTime))\n"
            yamlString += "  description: \(entry.description)\n"
        }
        return yamlString
    }
    
    func loadEntriesFromFile() {
        guard let fileURL = getFileURL() else { return }
        
        do {
            let yamlString = try String(contentsOf: fileURL, encoding: .utf8)
            let yaml = try Yaml.load(yamlString)
            entries = try yamlToEntries(yaml)
        } catch {
            print("Error loading entries: \(error)")
        }
    }
    
    private func yamlToEntries(_ yaml: Yaml) throws -> [TimeEntry] {
        guard case .array(let arrayYaml) = yaml else {
            throw NSError(domain: "YamlParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Expected array at root"])
        }
        
        return try arrayYaml.compactMap { entryYaml in
            guard case .dictionary(let dict) = entryYaml,
                  case .string(let idString)? = dict[.string("id")],
                  case .string(let startTimeString)? = dict[.string("startTime")],
                  case .string(let description)? = dict[.string("description")],
                  let id = UUID(uuidString: idString),
                  let startTime = ISO8601DateFormatter().date(from: startTimeString)
            else {
                print("Failed to parse entry: \(entryYaml)")
                return nil
            }
            
            return TimeEntry(id: id, startTime: startTime, description: description)
        }
    }

    private func getFileURL() -> URL? {
        guard let logDirectoryURL = logDirectoryURL else {
            print("Log directory not set")
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = dateFormatter.string(from: Date()) + ".yaml"
        return logDirectoryURL.appendingPathComponent(fileName)
    }

    func setLogDirectory(_ url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            logDirectoryBookmark = bookmarkData
            logDirectoryURL = url
            print("Log directory set to: \(url.path)")
        } catch {
            print("Failed to create bookmark for log directory: \(error)")
        }
    }

    private func restoreLogDirectoryAccess() {
        guard !logDirectoryBookmark.isEmpty else { return }

        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: logDirectoryBookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                // Обновляем закладку, если она устарела
                let newBookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                logDirectoryBookmark = newBookmarkData
            }

            if url.startAccessingSecurityScopedResource() {
                logDirectoryURL = url
                print("Restored access to log directory: \(url.path)")
            } else {
                print("Failed to access the bookmarked log directory")
            }
        } catch {
            print("Failed to resolve bookmark for log directory: \(error)")
        }
    }
}
