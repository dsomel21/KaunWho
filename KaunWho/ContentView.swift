//
//  ContentView.swift
//  KaunWho
//
//  Created by Dilraj on 2025-10-23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var multipeerManager = MultipeerManager()
    @StateObject private var gameManager: GameManager
    @State private var currentView: AppView = .welcome
    
    enum AppView {
        case welcome
        case photoSelection
        case gameBoard
        case winner
    }
    
    init() {
        let multipeer = MultipeerManager()
        _multipeerManager = StateObject(wrappedValue: multipeer)
        _gameManager = StateObject(wrappedValue: GameManager(multipeerManager: multipeer))
    }
    
    var body: some View {
        ZStack {
            switch currentView {
            case .welcome:
                WelcomeView()
                    .onReceive(gameManager.$gameState) { gameState in
                        if gameState == .photoSelection {
                            currentView = .photoSelection
                        }
                    }
                
            case .photoSelection:
                PhotoSelectionView(
                    gameManager: gameManager,
                    isPresented: .constant(true)
                )
                .onReceive(gameManager.$gameState) { gameState in
                    if gameState == .playing {
                        currentView = .gameBoard
                    }
                }
                
            case .gameBoard:
                GameBoardView(gameManager: gameManager)
                    .onReceive(gameManager.$gameState) { gameState in
                        if gameState == .gameOver {
                            currentView = .winner
                        }
                    }
                
            case .winner:
                WinnerView(
                    gameManager: gameManager,
                    isPresented: .constant(true)
                )
                .onReceive(gameManager.$gameState) { gameState in
                    if gameState == .waitingForPlayers {
                        currentView = .welcome
                    }
                }
            }
        }
        .onAppear {
            // Reset to welcome screen when app launches
            currentView = .welcome
        }
    }
}

#Preview {
    ContentView()
}
