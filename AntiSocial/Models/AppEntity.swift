//
//  AppEntity.swift
//  AntiSocial
//
//  Created by D C on 03.07.2025.
//


import Foundation
import FamilyControls
import ManagedSettings

struct AppEntity: Codable, Identifiable {
    var id = UUID()
    var name: String
}

class MyModel: ObservableObject {
    let store = ManagedSettingsStore()
    @Published var selectionToDiscourage: FamilyActivitySelection
    @Published var selectionToEncourage: FamilyActivitySelection
    @Published var savedSelection: [AppEntity] = [] {
        didSet {
            saveApps()
        }
    }

    private let userDefaultsKey = "savedSelection"

    init() {
        selectionToDiscourage = FamilyActivitySelection()
        selectionToEncourage = FamilyActivitySelection()
        loadApps()
    }

    func loadApps() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                let decoded = try JSONDecoder().decode([AppEntity].self, from: data)
                self.savedSelection = decoded
            } catch {
                print("Failed to decode apps: \(error)")
                self.savedSelection = []
            }
        }
    }

    func saveApps() {
        do {
            let data = try JSONEncoder().encode(savedSelection)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to encode apps: \(error)")
        }
    }

    func addApp(name: String) {
        let newApp = AppEntity(name: name)
        savedSelection.append(newApp)
    }

    func deleteAllApps() {
        savedSelection.removeAll()
    }

    class var shared: MyModel {
        _MyModel
    }

    func setShieldRestrictions() {
        let applications = MyModel.shared.selectionToDiscourage
        store.shield.applications = applications.applicationTokens.isEmpty ? nil : applications.applicationTokens
        store.shield.applicationCategories = applications.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(applications.categoryTokens)
    }
}

private let _MyModel = MyModel()
