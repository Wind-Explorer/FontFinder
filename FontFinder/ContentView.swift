//
//  ContentView.swift
//  FontFinder
//
//  Created by Adam C, Yining Z, Prudence N, Joshua L on 09/12/2025.
//  Explore Machine Learning with Swift
//  November 8 - 9, 2025
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var classifier = FontClassifier()
    @State private var isPaused: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Rainbow glow border
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        .red, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple, .pink, .red
                                    ]),
                                    center: .center
                                ),
                                lineWidth: 3
                            )
                            .blur(radius: 4)
                            .opacity(0.9)
                    )
                    .shadow(color: .red.opacity(0.25), radius: 8, x: 0, y: 0)
                    .shadow(color: .blue.opacity(0.25), radius: 8, x: 0, y: 0)

                // Camera content clipped to rectangle
                RoundedRectangle(cornerRadius: 24)
                    .fill(.clear)
                    .overlay(
                        ZStack(alignment: .topLeading) {
                            CameraView(sampleBufferHandler: { sampleBuffer in
                                if !isPaused {
                                    classifier.handleSampleBuffer(sampleBuffer)
                                }
                            })
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .contentShape(RoundedRectangle(cornerRadius: 24))
                            // Visual pause effect: blur and dim the live feed when paused
                            .overlay(
                                Group {
                                    if isPaused {
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(.black.opacity(0.25))
                                            .blur(radius: 0)
                                    }
                                }
                            )
                            .blur(radius: isPaused ? 8 : 0)
                            .overlay(
                                // Centered paused badge
                                Group {
                                    if isPaused {
                                        VStack(spacing: 8) {
                                            Image(systemName: "pause.fill")
                                                .font(.system(size: 28, weight: .bold))
                                            Text("Paused")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .foregroundStyle(.white)
                                        .background(.black.opacity(0.45), in: .rect(cornerRadius: 12))
                                    }
                                }
                            )
                        }
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 360)
            .padding(.horizontal)

            // Pause/Resume button
            Button(action: { isPaused.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    Text(isPaused ? "Resume Scanning" : "Pause Scanning")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(isPaused ? Color.green.gradient : Color.orange.gradient)
                )
                .foregroundStyle(.white)
            }
            .padding(.horizontal)

            // Prominent detected font name below controls
            Group {
                if let result = classifier.currentResult {
                    Text(result.label)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if let error = classifier.lastErrorMessage {
                    Text(error)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("Point the camera at text to detect the font…")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            Spacer(minLength: 0)
        }
        .background(
            ZStack {
                Color(.systemBackground)
                LinearGradient(colors: [
                    Color.primary.opacity(0.03),
                    Color.clear
                ], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
        )
        .task {
            await classifier.requestCameraAccessIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}
