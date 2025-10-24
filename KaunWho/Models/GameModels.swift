//
//  GameModels.swift
//  KaunWho
//
//  Created by Dilraj on 2025-10-23.
//

import Foundation
import UIKit
import Combine

// MARK: - Game Models

struct Player: Codable, Identifiable {
    let id: UUID
    let name: String
    var photos: [GamePhoto]
    var mysteryFace: GamePhoto?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.photos = []
        self.mysteryFace = nil
    }
}

struct GamePhoto: Codable, Identifiable {
    let id: UUID
    let imageData: Data
    var isEliminated: Bool
    
    init(imageData: Data) {
        self.id = UUID()
        self.imageData = imageData
        self.isEliminated = false
    }
}

enum GameState: String, Codable, CaseIterable {
    case waitingForPlayers = "waiting"
    case photoSelection = "photos"
    case gameSetup = "setup"
    case playing = "playing"
    case gameOver = "over"
}

enum PlayerRole: String, Codable {
    case host = "host"
    case guest = "guest"
}

struct GameSession: Codable {
    let id: UUID
    var hostPlayer: Player
    var guestPlayer: Player?
    var gameState: GameState
    var sharedBoard: [GamePhoto]
    var currentTurn: PlayerRole?
    var winner: PlayerRole?
    let createdAt: Date
    
    init(hostPlayer: Player) {
        self.id = UUID()
        self.hostPlayer = hostPlayer
        self.guestPlayer = nil
        self.gameState = .waitingForPlayers
        self.sharedBoard = []
        self.currentTurn = nil
        self.winner = nil
        self.createdAt = Date()
    }
    
    var allPlayers: [Player] {
        var players = [hostPlayer]
        if let guest = guestPlayer {
            players.append(guest)
        }
        return players
    }
    
    var isReadyToStart: Bool {
        return guestPlayer != nil && 
               hostPlayer.photos.count >= 8 && 
               guestPlayer?.photos.count ?? 0 >= 8
    }
}

// MARK: - Game Messages for MultipeerConnectivity

struct GameMessage: Codable {
    let type: MessageType
    let data: Data?
    let timestamp: Date
    
    enum MessageType: String, Codable {
        case joinRequest = "join_request"
        case joinAccepted = "join_accepted"
        case joinRejected = "join_rejected"
        case gameStateUpdate = "game_state"
        case photoUpdate = "photo_update"
        case eliminationUpdate = "elimination"
        case guessAttempt = "guess"
        case gameOver = "game_over"
    }
}

// MARK: - Photo Selection Timer

class PhotoSelectionTimer: ObservableObject {
    @Published var timeRemaining: Int = 60
    @Published var isActive: Bool = false
    
    private var timer: Timer?
    
    init() {
        // Initialize with default values
    }
    
    func start() {
        timeRemaining = 60
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isActive = false
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
