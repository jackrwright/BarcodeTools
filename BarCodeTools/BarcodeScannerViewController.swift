//
//  BarcodeScannerViewController.swift
//  FurniturePricer
//
//  Created by Jack Wright on 5/19/19.
//  Copyright © 2019 Jack Wright. All rights reserved.
//

import UIKit
import AVFoundation

public protocol BarcodeScannerDelegate {
	
	func didFindBarcode(_: String)
	func didFail(title: String, message: String?)
}

public class BarcodeScannerViewController: UIViewController {
	
	// MARK: - Public (properties)
	
	public var delegate: BarcodeScannerDelegate?
	public var frame: CGRect?
	public var barcodeType: AVMetadataObject.ObjectType?
	public var startImmediately: Bool = true
    public var useBackCamera: Bool = false {
        didSet {
            self.cameraPosition = useBackCamera ? .back : .front
        }
    }
    public var orientation: UIInterfaceOrientation? {
		didSet {
			if let orientation = orientation {
				self.setOrientation(orientation)
			}
		}
	}

	// MARK: - Public (methods)
	
	public func startScanning() {
		
		if (captureSession?.isRunning == false) {
			captureSession.startRunning()
		}
	}
	
	public func stopScanning() {
		
		if (captureSession?.isRunning == true) {
			captureSession.stopRunning()
		}
	}
	
	// MARK: - View controller life-cycle
	
	private func setupVideoCapture(for position: AVCaptureDevice.Position) {
	
		captureSession = AVCaptureSession()
		
		var videoCapDevice: AVCaptureDevice?
		
		// Use the front-facing camera, if available
		if #available(iOS 10.0, *) {
			if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
				videoCapDevice = device
			}
		} else {
			// Fallback on earlier versions
			if let device = AVCaptureDevice.devices().filter({ $0.position == position }).first {
				videoCapDevice = device
			}
		}
		
		if videoCapDevice == nil {
			
			// No front facing camera, get any camera available
			
			videoCapDevice = AVCaptureDevice.default(for: .video)
		}
		
		guard let videoCaptureDevice = videoCapDevice else { return }
		
		let videoInput: AVCaptureDeviceInput
		
		do {
			videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
		} catch {
			return
		}
		
		if (captureSession.canAddInput(videoInput)) {
			
			captureSession.addInput(videoInput)
			
		} else {
			
			failed()
			return
		}
		
		let metadataOutput = AVCaptureMetadataOutput()
		
		if (captureSession.canAddOutput(metadataOutput)) {
			
			captureSession.addOutput(metadataOutput)
			
			metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
			metadataOutput.metadataObjectTypes = [self.barcodeType ?? .code128]
			
		} else {
			
			failed()
			return
		}
		
		previewLayer?.removeFromSuperlayer()
		
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		if let frame = self.frame {
			previewLayer?.frame = frame
		} else {
			previewLayer?.frame = view.layer.bounds
		}
		previewLayer?.videoGravity = .resizeAspectFill
		if let previewLayer = self.previewLayer {
			view.layer.addSublayer(previewLayer)
		}
	}
	
	override public func viewDidLoad() {
		
		super.viewDidLoad()
		
		view.backgroundColor = UIColor.black
        
        self.cameraPosition = useBackCamera ? .back : .front
		
		setupVideoCapture(for: self.cameraPosition)		
	}
	
	override public func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if (captureSession?.isRunning == true) {
			captureSession.stopRunning()
		}
	}
	
	override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}
	
	// set the initial orientation
	override public func viewDidLayoutSubviews() {
		
		super.viewDidLayoutSubviews()

		let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
		
		self.setOrientation(orientation)
	}


	// MARK: - Private (properties)
	
	private var captureSession: AVCaptureSession!
	
	private var previewLayer: AVCaptureVideoPreviewLayer?
	
	private var cameraPosition: AVCaptureDevice.Position {
		get {
			return self.useBackCamera ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front
		}
		set {
			stopScanning()
			setupVideoCapture(for: newValue)
			self.setOrientation(UIApplication.shared.statusBarOrientation)
			startScanning()
			
//			self.useBackCamera = newValue == .back ? true : false
		}
	}


	// MARK: - Private (methods)
	
	private func setOrientation(_ orientation: UIInterfaceOrientation) {
	
		switch orientation {
		case .portrait:
			previewLayer?.connection?.videoOrientation = .portrait
		case .portraitUpsideDown:
			previewLayer?.connection?.videoOrientation = .portraitUpsideDown
		case .landscapeLeft:
			previewLayer?.connection?.videoOrientation = .landscapeLeft
		case .landscapeRight:
			previewLayer?.connection?.videoOrientation = .landscapeRight
		default:
			break
		}
	}

	private func found(code: String) {
		
		print(code)
		
		self.delegate?.didFindBarcode(code)
	}

	private func failed() {
		
		self.delegate?.didFail(title: "Scanning not supported", message: "Your device does not support scanning a code. Please use a device with a camera.")
		
		captureSession = nil
	}
}


// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
	
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		captureSession.stopRunning()
		
		if let metadataObject = metadataObjects.first {
			
			guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
			guard let stringValue = readableObject.stringValue else { return }
			
			AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
			
			self.found(code: stringValue)
		}
	}
}
