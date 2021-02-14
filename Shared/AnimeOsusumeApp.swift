//
//  AnimeOsusumeApp.swift
//  Shared
//
//  Created by Nico Prananta on 11.02.21.
//

import SwiftUI
import SQift

func checkAndCreateDirectory(at url: URL) {
    let fm = FileManager.default
    if !fm.fileExists(atPath: url.absoluteString) {
        do {
            try fm.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        } catch {
            print(error)
        }
    }
}

func pathForAppSupportDirectory() -> URL? {
    guard let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
        return nil
    }
    checkAndCreateDirectory(at: appSupportDirectory)
    return appSupportDirectory
}

func prepareDb() throws -> Connection {
    let dbPath = pathForAppSupportDirectory()?.appendingPathComponent("db.sqlite")
    let connection = try Connection(storageLocation: .onDisk(dbPath!.absoluteString))
    let sql = try String(contentsOfFile: Bundle.main.path(forResource: "list-anime", ofType: "sql")!)
    try connection.execute(sql)
    return connection
}

class AppState: ObservableObject {
    @Published var db: Connection?
    @Published var useSample: Bool = false
    
    convenience init(useSample: Bool) {
        self.init()
        self.useSample = useSample
    }
}

var appState: AppState = AppState()

@main
struct AnimeOsusumeApp: App {
    init() {
        do {
            let db = try prepareDb()
            appState.db = db
        } catch {
            print(error)
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
