//
//  GameManager.swift
//  KaunWho
//
//  Created by Dilraj on 2025-10-23.
//

import Foundation
import SwiftUI
import Combine
import MultipeerConnectivity

class GameManager: ObservableObject {
    @Published var currentGame: GameSession?
    @Published var myRole: PlayerRole = .host
    @Published var myPlayer: Player?
    @Published var opponentPlayer: Player?
    @Published var gameState: GameState = .waitingForPlayers
    @Published var currentTurn: PlayerRole?
    @Published var winner: PlayerRole?
    
    private let multipeerManager: MultipeerManager
    
    init(multipeerManager: MultipeerManager) {
        self.multipeerManager = multipeerManager
        setupMessageHandling()
    }
    
    private func setupMessageHandling() {
        // Listen for incoming messages
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let message = self.multipeerManager.receivedMessage {
                self.handleReceivedMessage(message)
                self.multipeerManager.receivedMessage = nil
            }
        }
    }
    
    // MARK: - Game Creation
    
    func createGame(playerName: String) {
        let player = Player(name: playerName)
        myPlayer = player
        myRole = .host
        
        let game = GameSession(hostPlayer: player)
        currentGame = game
        gameState = .waitingForPlayers
        
        multipeerManager.startHosting()
    }
    
    func joinGame(playerName: String, hostPeer: MCPeerID) {
        let player = Player(name: playerName)
        myPlayer = player
        myRole = .guest
        
        multipeerManager.invitePeer(hostPeer)
    }
    
    // MARK: - Photo Management
    
    func addPhoto(_ imageData: Data) {
        guard var player = myPlayer else { return }
        
        let photo = GamePhoto(imageData: imageData)
        player.photos.append(photo)
        myPlayer = player
        
        updateGameState()
    }
    
    func removePhoto(_ photo: GamePhoto) {
        guard var player = myPlayer else { return }
        
        player.photos.removeAll { $0.id == photo.id }
        myPlayer = player
        
        updateGameState()
    }
    
    // MARK: - Game Logic
    
    func startGame() {
        guard let game = currentGame, game.isReadyToStart else { return }
        
        // Merge all photos and select 15 randomly
        let allPhotos = game.allPlayers.flatMap { $0.photos }
        let shuffledPhotos = allPhotos.shuffled()
        let selectedPhotos = Array(shuffledPhotos.prefix(15))
        
        // Assign mystery faces
        var updatedGame = game
        updatedGame.sharedBoard = selectedPhotos
        updatedGame.gameState = .gameSetup
        
        // Randomly assign mystery faces
        let hostMystery = selectedPhotos.randomElement()
        let guestMystery = selectedPhotos.filter { $0.id != hostMystery?.id }.randomElement()
        
        updatedGame.hostPlayer.mysteryFace = hostMystery
        updatedGame.guestPlayer?.mysteryFace = guestMystery
        
        // Randomly choose who goes first
        updatedGame.currentTurn = Bool.random() ? .host : .guest
        
        currentGame = updatedGame
        gameState = .playing
        
        // Update local player references
        if myRole == .host {
            myPlayer?.mysteryFace = hostMystery
            opponentPlayer = updatedGame.guestPlayer
        } else {
            myPlayer?.mysteryFace = guestMystery
            opponentPlayer = updatedGame.hostPlayer
        }
        
        currentTurn = updatedGame.currentTurn
        
        // Send updated game state to opponent
        multipeerManager.sendGameState(updatedGame)
    }
    
    func eliminatePhoto(_ photo: GamePhoto) {
        guard let game = currentGame, game.gameState == .playing else { return }
        
        var updatedGame = game
        if let index = updatedGame.sharedBoard.firstIndex(where: { $0.id == photo.id }) {
            updatedGame.sharedBoard[index].isEliminated = true
        }
        
        currentGame = updatedGame
        
        // Send elimination update
        let message = GameMessage(type: .eliminationUpdate, data: nil, timestamp: Date())
        multipeerManager.sendMessage(message)
    }
    
    func makeGuess(_ photo: GamePhoto) -> Bool {
        guard let game = currentGame, let myPlayer = myPlayer else { return false }
        
        let isCorrect = myPlayer.mysteryFace?.id == photo.id
        
        var updatedGame = game
        if isCorrect {
            updatedGame.winner = myRole
            updatedGame.gameState = .gameOver
            winner = myRole
            gameState = .gameOver
        } else {
            // Wrong guess - opponent wins
            updatedGame.winner = myRole == .host ? .guest : .host
            updatedGame.gameState = .gameOver
            winner = updatedGame.winner
            gameState = .gameOver
        }
        
        currentGame = updatedGame
        
        // Send game over message
        let message = GameMessage(type: .gameOver, data: nil, timestamp: Date())
        multipeerManager.sendMessage(message)
        
        return isCorrect
    }
    
    func endTurn() {
        guard let game = currentGame else { return }
        
        var updatedGame = game
        updatedGame.currentTurn = game.currentTurn == .host ? .guest : .host
        currentTurn = updatedGame.currentTurn
        
        currentGame = updatedGame
        
        // Send turn update
        multipeerManager.sendGameState(updatedGame)
    }
    
    func resetGame() {
        currentGame = nil
        myPlayer = nil
        opponentPlayer = nil
        gameState = .waitingForPlayers
        currentTurn = nil
        winner = nil
        myRole = .host
        
        multipeerManager.disconnect()
    }
    
    // MARK: - Message Handling
    
    private func handleReceivedMessage(_ message: GameMessage) {
        switch message.type {
        case .gameStateUpdate:
            if let data = message.data {
                do {
                    let game = try JSONDecoder().decode(GameSession.self, from: data)
                    currentGame = game
                    gameState = game.gameState
                    currentTurn = game.currentTurn
                    winner = game.winner
                    
                    // Update opponent reference
                    if myRole == .host {
                        opponentPlayer = game.guestPlayer
                    } else {
                        opponentPlayer = game.hostPlayer
                    }
                } catch {
                    print("Failed to decode game state: \(error)")
                }
            }
            
        case .eliminationUpdate:
            // Handle elimination update if needed
            break
            
        case .gameOver:
            gameState = .gameOver
            break
            
        default:
            break
        }
    }
    
    private func updateGameState() {
        guard let game = currentGame else { return }
        
        var updatedGame = game
        if myRole == .host {
            updatedGame.hostPlayer = myPlayer ?? game.hostPlayer
        } else {
            updatedGame.guestPlayer = myPlayer
        }
        
        currentGame = updatedGame
        multipeerManager.sendGameState(updatedGame)
    }
}
