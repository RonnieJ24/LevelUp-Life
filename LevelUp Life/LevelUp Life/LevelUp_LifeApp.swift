//
//  LevelUp_LifeApp.swift
//  LevelUp Life
//
//  Created by Rani Yaqoob on 2025-10-15.
//

import SwiftUI

@main
struct LevelUp_LifeApp: App {
    @StateObject private var appViewModel = AppViewModel.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}
