//
//  FullScreenMapView.swift
//  runshaw-buses
//
//  Created by Jacob on 03/05/2025.
//  Copyright © 2025 Konpeki. All rights reserved.
//

import SwiftUI

/// Full-screen interactive map view with zoom and pan functionality
struct FullScreenMapView: View {
    /// URL of the map image to display
    let mapUrl: URL
    
    /// Binding to control visibility of the full-screen view
    @Binding var isPresented: Bool
    
    // State variables for interactive gestures
    /// Current scale factor for zooming
    @State private var scale: CGFloat = 1.0
    
    /// Last scale factor for tracking gesture changes
    @State private var lastScale: CGFloat = 1.0
    
    /// Current offset for panning
    @State private var offset: CGSize = .zero
    
    /// Last offset for tracking gesture changes
    @State private var lastOffset: CGSize = .zero
    
    /// Resets zoom and position to default state
    private func resetView() {
        scale = 1.0
        lastScale = 1.0
        offset = .zero
        lastOffset = .zero
    }
    
    var body: some View {
        ZStack {
            // Black background for better visibility
            Color.black
                .ignoresSafeArea()
            
            // Map content with zoom and pan gestures
            AsyncImage(url: mapUrl) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            // Pinch gesture for zooming
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    
                                    // Limit zoom range between 0.5x and 5x
                                    let newScale = scale * delta
                                    scale = min(max(0.5, newScale), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .simultaneousGesture(
                            // Drag gesture for panning
                            DragGesture()
                                .onChanged { value in
                                    let newOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    
                                    // Only allow panning when zoomed in
                                    if scale > 1.0 {
                                        offset = newOffset
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            // Double-tap to reset view
                            withAnimation {
                                resetView()
                            }
                        }
                case .failure:
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("Failed to load map")
                            .foregroundColor(.white)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            
            // Custom header bar
            VStack {
                // Custom header with close and reset buttons
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Bus Lane Map")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            resetView()
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                
                Spacer()
                
                // Zoom instructions
                Text("Double tap to reset zoom")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom)
            }
        }
        .preferredColorScheme(.dark) // Force dark mode for better viewing
    }
}

/// Preview provider for FullScreenMapView
#Preview {
    // Sample URL for preview purposes
    let sampleUrl = URL(string: "https://picsum.photos/200/300")!
    
    return FullScreenMapView(mapUrl: sampleUrl, isPresented: .constant(true))
}
