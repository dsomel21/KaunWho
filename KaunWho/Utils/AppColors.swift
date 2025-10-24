//
//  AppColors.swift
//  KaunWho
//
//  Created by Dilraj on 2025-10-23.
//

import SwiftUI

extension Color {
    // Party game color palette
    static let partyPurple = Color(red: 0.6, green: 0.3, blue: 0.8)
    static let partyBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let partyGreen = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let partyOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let partyPink = Color(red: 1.0, green: 0.4, blue: 0.7)
    static let partyYellow = Color(red: 1.0, green: 0.9, blue: 0.2)
    static let partyRed = Color(red: 1.0, green: 0.3, blue: 0.3)
    
    // Game-specific colors
    static let gameBackground = Color(red: 0.95, green: 0.95, blue: 0.98)
    static let cardBackground = Color.white
    static let eliminatedOverlay = Color.black.opacity(0.7)
    static let selectionBorder = Color.partyGreen
    static let turnIndicator = Color.partyBlue
}

// MARK: - Animation Extensions

extension View {
    func partyBounce() -> some View {
        self.scaleEffect(1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: UUID())
    }
    
    func partyPulse() -> some View {
        self.scaleEffect(1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
    }
    
    func celebrationEffect() -> some View {
        self.scaleEffect(1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: UUID())
    }
}

// MARK: - Haptic Feedback

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func playSuccess() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func playError() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func playSelection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}
