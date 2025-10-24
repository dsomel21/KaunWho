//
//  GameBoardView.swift
//  KaunWho
//
//  Created by Dilraj on 2025-10-23.
//

import SwiftUI

struct GameBoardView: View {
    @ObservedObject var gameManager: GameManager
    @State private var showingGuessAlert = false
    @State private var selectedPhotoForGuess: GamePhoto?
    @State private var showingWinnerScreen = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Game board background
                LinearGradient(
                    colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Game header
                    VStack(spacing: 15) {
                        Text("🎯")
                            .font(.system(size: 40))
                        
                        Text("Guess Who!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Turn indicator
                        HStack {
                            Image(systemName: gameManager.currentTurn == gameManager.myRole ? "person.fill" : "person")
                            Text(gameManager.currentTurn == gameManager.myRole ? "Your Turn!" : "Opponent's Turn")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(gameManager.currentTurn == gameManager.myRole ? .green : .orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // Instructions
                    Text("Tap faces to eliminate them")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Game board grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(gameManager.currentGame?.sharedBoard ?? []) { photo in
                                GamePhotoView(
                                    photo: photo,
                                    isMyTurn: gameManager.currentTurn == gameManager.myRole,
                                    onTap: { tapPhoto(photo) },
                                    onLongPress: { longPressPhoto(photo) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if gameManager.currentTurn == gameManager.myRole {
                            Button(action: endTurn) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("End Turn")
                                }
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(20)
                            }
                        }
                        
                        Button("Make a Guess") {
                            showingGuessAlert = true
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Game Board")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .onChange(of: gameManager.gameState) { _, gameState in
            if gameState == .gameOver {
                showingWinnerScreen = true
            }
        }
        .alert("Make Your Guess", isPresented: $showingGuessAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Select Face") {
                // This will be handled by the photo selection
            }
        } message: {
            Text("Choose which face you think is your opponent's mystery person.")
        }
        .fullScreenCover(isPresented: $showingWinnerScreen) {
            WinnerView(
                gameManager: gameManager,
                isPresented: $showingWinnerScreen
            )
        }
    }
    
    private func tapPhoto(_ photo: GamePhoto) {
        guard gameManager.currentTurn == gameManager.myRole,
              !photo.isEliminated else { return }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        gameManager.eliminatePhoto(photo)
    }
    
    private func longPressPhoto(_ photo: GamePhoto) {
        guard gameManager.currentTurn == gameManager.myRole else { return }
        
        selectedPhotoForGuess = photo
        showingGuessAlert = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    private func endTurn() {
        gameManager.endTurn()
    }
}

struct GamePhotoView: View {
    let photo: GamePhoto
    let isMyTurn: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            // Photo
            Image(uiImage: UIImage(data: photo.imageData) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // Elimination overlay
            if photo.isEliminated {
                ZStack {
                    Color.black.opacity(0.7)
                        .cornerRadius(15)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            
            // Tap indicator for my turn
            if isMyTurn && !photo.isEliminated {
                Circle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 110, height: 110)
                    .opacity(0.8)
            }
        }
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress()
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

struct WinnerView: View {
    @ObservedObject var gameManager: GameManager
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Celebration background
            LinearGradient(
                colors: [Color.yellow.opacity(0.4), Color.orange.opacity(0.4), Color.red.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Winner celebration
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 80))
                    
                    if gameManager.winner == gameManager.myRole {
                        Text("You Win!")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    } else {
                        Text("You Lost!")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                    
                    Text("🎊 Congratulations! 🎊")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Mystery face reveal
                if let mysteryFace = gameManager.myPlayer?.mysteryFace {
                    VStack(spacing: 15) {
                        Text("Your mystery person was:")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Image(uiImage: UIImage(data: mysteryFace.imageData) ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: playAgain) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("Play Again")
                        }
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(25)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: goHome) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Back to Home")
                        }
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
    }
    
    private func playAgain() {
        // Reset game state and go back to photo selection
        gameManager.resetGame()
        isPresented = false
    }
    
    private func goHome() {
        gameManager.resetGame()
        isPresented = false
    }
}

#Preview {
    let multipeer = MultipeerManager()
    let gameManager = GameManager(multipeerManager: multipeer)
    return GameBoardView(gameManager: gameManager)
}
