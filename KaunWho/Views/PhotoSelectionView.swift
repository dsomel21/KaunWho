//
//  PhotoSelectionView.swift
//  KaunWho
//
//  Created by Dilraj on 2025-10-23.
//

import SwiftUI
import PhotosUI
import AVFoundation
import Photos

struct PhotoSelectionView: View {
    @ObservedObject var gameManager: GameManager
    @Binding var isPresented: Bool
    @StateObject private var photoTimer = PhotoSelectionTimer()
    @State private var selectedPhotos: [GamePhoto] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with subtle photo animation
                BackgroundPhotoAnimation()
                
                VStack(spacing: 20) {
                    // Header with timer
                    VStack(spacing: 15) {
                        Text("📸")
                            .font(.system(size: 50))
                        
                        Text("Choose Your Photos!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Timer display
                        HStack {
                            Image(systemName: "timer")
                            Text(photoTimer.timeString)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(photoTimer.timeRemaining <= 10 ? .red : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // Instructions
                    VStack(spacing: 8) {
                        Text("Select 8-15 photos of faces")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Tap photos to remove them")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    // Photo selection area
                    PhotoSelectionGrid(
                        selectedPhotos: $selectedPhotos,
                        onAddPhoto: addPhotoButtonTapped,
                        onRemovePhoto: removePhoto
                    )
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if selectedPhotos.count >= 8 {
                            Button(action: finishPhotoSelection) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Ready to Play!")
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
                        } else {
                            Text("Need \(8 - selectedPhotos.count) more photos")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                        
                        Button("Cancel") {
                            isPresented = false
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Photo Selection")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .onAppear {
            photoTimer.start()
            loadExistingPhotos()
            checkPhotoLibraryPermission()
        }
        .onChange(of: photoTimer.timeRemaining) { _, timeRemaining in
            if timeRemaining == 0 {
                finishPhotoSelection()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                addPhoto(image)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                addPhoto(image)
            }
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(permissionAlertMessage)
        }
    }
    
    private func addPhotoButtonTapped() {
        let alert = UIAlertController(title: "Add Photo", message: "Choose how to add a photo", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            checkCameraPermission()
        })
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            checkPhotoLibraryPermissionAndShow()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func checkPhotoLibraryPermission() {
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus()
    }
    
    private func checkPhotoLibraryPermissionAndShow() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            showingImagePicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        showingImagePicker = true
                    } else {
                        showPermissionAlert(for: .photoLibrary)
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert(for: .photoLibrary)
        @unknown default:
            showPermissionAlert(for: .photoLibrary)
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    } else {
                        showPermissionAlert(for: .camera)
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert(for: .camera)
        @unknown default:
            showPermissionAlert(for: .camera)
        }
    }
    
    private func showPermissionAlert(for type: PermissionType) {
        switch type {
        case .camera:
            permissionAlertMessage = "Camera access is required to take photos. Please enable camera access in Settings to continue."
        case .photoLibrary:
            permissionAlertMessage = "Photo library access is required to select photos. Please enable photo library access in Settings to continue."
        }
        showingPermissionAlert = true
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func addPhoto(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let photo = GamePhoto(imageData: imageData)
        selectedPhotos.append(photo)
        gameManager.addPhoto(imageData)
        
        // Add haptic feedback
        HapticManager.shared.playSuccess()
    }
    
    private func removePhoto(_ photo: GamePhoto) {
        selectedPhotos.removeAll { $0.id == photo.id }
        gameManager.removePhoto(photo)
        
        // Add haptic feedback
        HapticManager.shared.playImpact()
    }
    
    private func loadExistingPhotos() {
        selectedPhotos = gameManager.myPlayer?.photos ?? []
    }
    
    private func finishPhotoSelection() {
        photoTimer.stop()
        isPresented = false
    }
}

enum PermissionType {
    case camera
    case photoLibrary
}

struct PhotoSelectionGrid: View {
    @Binding var selectedPhotos: [GamePhoto]
    let onAddPhoto: () -> Void
    let onRemovePhoto: (GamePhoto) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                // Single Add Photo Button
                Button(action: onAddPhoto) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        Text("Add Photo")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 100)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // Selected photos with beautiful UI
                ForEach(selectedPhotos) { photo in
                    SelectedPhotoView(photo: photo) {
                        onRemovePhoto(photo)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct SelectedPhotoView: View {
    let photo: GamePhoto
    let onRemove: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main photo
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
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .offset(x: 8, y: -8)
        }
        .onTapGesture {
            // Add tap animation
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

struct BackgroundPhotoAnimation: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [Color.orange.opacity(0.2), Color.yellow.opacity(0.2), Color.red.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle photo outlines
            VStack(spacing: 20) {
                HStack(spacing: 30) {
                    PhotoOutline()
                    PhotoOutline()
                    PhotoOutline()
                }
                HStack(spacing: 30) {
                    PhotoOutline()
                    PhotoOutline()
                    PhotoOutline()
                }
                HStack(spacing: 30) {
                    PhotoOutline()
                    PhotoOutline()
                    PhotoOutline()
                }
            }
            .offset(x: offset)
            .opacity(0.1)
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                offset = 50
            }
        }
    }
}

struct PhotoOutline: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            .frame(width: 40, height: 50)
            .rotationEffect(.degrees(Double.random(in: -15...15)))
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.onImagePicked(image)
                        }
                    }
                }
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    let multipeer = MultipeerManager()
    let gameManager = GameManager(multipeerManager: multipeer)
    return PhotoSelectionView(
        gameManager: gameManager,
        isPresented: .constant(true)
    )
}
