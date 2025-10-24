//
//  WelcomeView.swift
//  KaunWho
//
//  Created by Dilraj on 2025-10-23.
//

import SwiftUI
import MultipeerConnectivity

struct WelcomeView: View {
    @StateObject private var multipeerManager = MultipeerManager()
    @StateObject private var gameManager: GameManager
    @State private var playerName = ""
    @State private var showingJoinGame = false
    @State private var showingPhotoSelection = false
    
    init() {
        let multipeer = MultipeerManager()
        _multipeerManager = StateObject(wrappedValue: multipeer)
        _gameManager = StateObject(wrappedValue: GameManager(multipeerManager: multipeer))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fun gradient background
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3), Color.pink.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Title with fun styling
                    VStack(spacing: 10) {
                        Text("🎭")
                            .font(.system(size: 80))
                        
                        Text("Kaun Who?")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .shadow(color: .white, radius: 2)
                        
                        Text("Guess Who IRL")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Player name input
                    VStack(spacing: 20) {
                        Text("What's your name?")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        TextField("Enter your name", text: $playerName)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .font(.system(size: 18, design: .rounded))
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Start Game Button
                        Button(action: startGame) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Start a Game")
                            }
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(playerName.isEmpty)
                        
                        // Join Game Button
                        Button(action: { showingJoinGame = true }) {
                            HStack {
                                Image(systemName: "person.2.circle.fill")
                                Text("Join a Game")
                            }
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(playerName.isEmpty)
                    }
                    
                    Spacer()
                    
                    // Fun subtitle
                    Text("🎉 Party Game • 📱 Offline • 👥 2 Players")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
            }
        }
        .sheet(isPresented: $showingJoinGame) {
            JoinGameView(
                playerName: playerName,
                multipeerManager: multipeerManager,
                gameManager: gameManager,
                isPresented: $showingJoinGame
            )
        }
        .fullScreenCover(isPresented: $showingPhotoSelection) {
            PhotoSelectionView(
                gameManager: gameManager,
                isPresented: $showingPhotoSelection
            )
        }
    }
    
    private func startGame() {
        gameManager.createGame(playerName: playerName)
        showingPhotoSelection = true
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.9))
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct JoinGameView: View {
    let playerName: String
    @ObservedObject var multipeerManager: MultipeerManager
    @ObservedObject var gameManager: GameManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Text("🔍")
                            .font(.system(size: 60))
                        
                        Text("Looking for Games...")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Make sure both devices are nearby!")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Available games list
                    if multipeerManager.discoveredPeers.isEmpty {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("No games found yet")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Text("Available Games:")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            ForEach(multipeerManager.discoveredPeers, id: \.self) { peer in
                                Button(action: { joinGame(peer: peer) }) {
                                    HStack {
                                        Image(systemName: "gamecontroller.fill")
                                        Text(peer.displayName)
                                        Spacer()
                                        Image(systemName: "arrow.right.circle.fill")
                                    }
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 30)
            }
            .navigationTitle("Join Game")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            multipeerManager.startBrowsing()
        }
        .onDisappear {
            multipeerManager.stopBrowsing()
        }
    }
    
    private func joinGame(peer: MCPeerID) {
        gameManager.joinGame(playerName: playerName, hostPeer: peer)
        isPresented = false
    }
}

#Preview {
    WelcomeView()
}
