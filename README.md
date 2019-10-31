# BarcodeTools
An iOS framework of useful barcode tools.

## BarcodeGenerator

Generate a barcode image from a String.

```swift
public class BarcodeGenerator {

    public enum Descriptor : String {
        case code128
        case pdf417
        case aztec
        case qr
    }

    public class func generate(from string: String, descriptor: Descriptor, size: CGSize) -> CIImage?
}

```

Example use:

```swift
if let ciImage = BarcodeGenerator.generate(from: "\(item_id)", descriptor: .qr, size: cardView.imageView.frame.size) {
			
	let qrImage = UIImage(ciImage: ciImage)
			
	cardView.qrBarcodeImageView.image = qrImage
}
```

## BarcodeScannerViewController

Scan a barcode and deliver a String to the delegate. This view controller is intended to be embedded in a container view.

```swift
public protocol BarcodeScannerDelegate {

    func didFindBarcode(_: String)

    func didFail(title: String, message: String?)
}

public class BarcodeScannerViewController : UIViewController {

    public var delegate: BarcodeScannerDelegate?

    public var frame: CGRect?

    public var barcodeType: AVMetadataObject.ObjectType?

    public var startImmediately: Bool

    public var useBackCamera: Bool { get set }

    public var orientation: UIInterfaceOrientation? { get set }

    public func startScanning()

    public func stopScanning()
}
```

Example use:

```swift
// MARK: - Navigation
	
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
    let destination = segue.destination
		
    if let scannerVC = destination as? BarcodeScannerViewController {
			
      // set up the BarcodeScannerViewController
			
      scannerVC.frame = self.barcodeScanView.bounds
			
      scannerVC.barcodeType = .qr
            
      scannerVC.useBackCamera = UserDefaults.standard.useBackCamera
			
      self.barcodeScannerVC = scannerVC
			
      self.barcodeScannerVC?.delegate = self
			
      self.barcodeScannerVC?.startImmediately = false
    }
}

override func viewDidLayoutSubviews() {
		
      super.viewDidLayoutSubviews()
		
      self.barcodeScannerVC?.orientation = UIApplication.shared.statusBarOrientation
}

// MARK: - BarcodeScannerDelegate

extension ContainerViewController: BarcodeScannerDelegate {
	
    func didFindBarcode(_ code: String) {
    
      // The barcode string is delivered here
    }
	
    func didFail(title: String, message: String?) {
    
      // Handle the error
		
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		
      self.present(alert, animated: true, completion: nil)
    }
}
```
