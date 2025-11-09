//
//  CameraView.swift
//  FontFinder
//
//  Created by Adam C, Yining Z, Prudence N, Joshua L on 09/12/2025.
//  Explore Machine Learning with Swift
//  November 8 - 9, 2025
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraViewController

    var sampleBufferHandler: (CMSampleBuffer) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.sampleBufferHandler = sampleBufferHandler
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

final class CameraViewController: UIViewController {
    var sampleBufferHandler: ((CMSampleBuffer) -> Void)?

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSession()
        configurePreview()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("CameraView: Failed to create camera input")
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            let queue = DispatchQueue(label: "CameraView.videoQueue")
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        }

        session.commitConfiguration()
    }

    private func configurePreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.bounds
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        sampleBufferHandler?(sampleBuffer)
    }
}
