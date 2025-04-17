//
//  mailmeilApp.swift
//  mailmeil
//
//  Created by 고재현 on 4/11/25.
//

import SwiftUI

@main
struct mailmeilApp: App {
    var body: some Scene {
        WindowGroup {
            GoalsHomeView()
                .environmentObject(GoalsViewModel())
        }
    }
}
