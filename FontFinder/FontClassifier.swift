//
//  FontClassifier.swift
//  FontFinder
//
//  Created by Adam C, Yining Z, Prudence N, Joshua L on 09/12/2025.
//  Explore Machine Learning with Swift
//  November 8 - 9, 2025
//

import Foundation
import AVFoundation
import Vision
import CoreML
import SwiftUI

@MainActor
final class FontClassifier: ObservableObject {
    struct Result {
        let label: String
        let confidence: Float
    }

    @Published var currentResult: Result?
    @Published var lastErrorMessage: String?

    private var request: VNCoreMLRequest?
    private var lastPredictionTime: CFAbsoluteTime = 0
    private let predictionInterval: CFTimeInterval = 0.2 // throttle to ~5 fps

    init() {
        do {
            self.request = try Self.makeRequest()
            // Link the request's completion handler to self
            if let box = Self.requestBox {
                box.value = self
            }
        } catch {
            self.lastErrorMessage = "Failed to load model: \(error.localizedDescription)"
        }
    }

    func requestCameraAccessIfNeeded() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                self.lastErrorMessage = "Camera access denied."
            }
        case .denied, .restricted:
            self.lastErrorMessage = "Camera access denied. Enable it in Settings."
        @unknown default:
            break
        }
    }

    func handleSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        // Throttle
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastPredictionTime < predictionInterval { return }
        lastPredictionTime = now

        guard let request = self.request,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        var requestOptions: [VNImageOption: Any] = [:]
        if let attachments = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) as? [CFString: Any] {
            for (cfKey, value) in attachments {
                let keyString = cfKey as String
                let vnKey = VNImageOption(rawValue: keyString)
                requestOptions[vnKey] = value
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: requestOptions)
        do {
            try handler.perform([request])
        } catch {
            Task { @MainActor in
                self.lastErrorMessage = "Vision error: \(error.localizedDescription)"
            }
        }
    }

    // Static box to hold weak reference to instance for callback
    private static var requestBox: Box?

    private static func makeRequest() throws -> VNCoreMLRequest {
        // Replace "FontDetector" with the actual auto-generated model class name if different
        let config = MLModelConfiguration()
        let model = try FontDetector(configuration: config).model
        let vnModel = try VNCoreMLModel(for: model)
        let request = VNCoreMLRequest(model: vnModel) { request, _ in
            guard let results = request.results as? [VNClassificationObservation],
                  let best = results.first,
                  let owner = requestBox?.value else {
                return
            }
            Task { @MainActor in
                owner.currentResult = Result(label: best.identifier, confidence: best.confidence)
            }
        }
        request.imageCropAndScaleOption = .centerCrop

        // Setup static box for linking instance later
        let box = Box()
        requestBox = box

        return request
    }

    private class Box {
        weak var value: FontClassifier?
    }
}
