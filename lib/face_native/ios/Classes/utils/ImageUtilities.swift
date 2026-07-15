import AVFoundation
import UIKit
public class UIUtilities {
      public static func normalizedImage(_ image: UIImage) -> UIImage {
    // If already up, return
    if image.imageOrientation == .up { return image }
    // Draw the image into a new context which applies orientation automatically
    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
    image.draw(in: CGRect(origin: .zero, size: image.size))
    let normalized = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return normalized
}

public static func saveImage(from pixelBuffer: CVPixelBuffer, name: String = "captured_image") -> URL? {
    // Chuyển PixelBuffer thành UIImage
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext()
    
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        print("❌ Failed to convert pixelBuffer to CGImage")
        return nil
    }
    
    let uiImage = UIImage(cgImage: cgImage)
    
    // Convert UIImage -> Data (JPEG hoặc PNG)
    guard let imageData = uiImage.jpegData(compressionQuality: 0.9) else {
        print("❌ Failed to convert UIImage to Data")
        return nil
    }
    // Lưu file ra thư mục Documents
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentsURL.appendingPathComponent("\(name).jpg")
    
    do {
        try imageData.write(to: fileURL)
        print("✅ Saved image to: \(fileURL.path)")
        return fileURL
    } catch {
        print("❌ Failed to save image: \(error.localizedDescription)")
        return nil
    }
}
    @discardableResult
    public static func saveBitmap(_ image: UIImage, name: String) -> String {
        guard let cgImage = image.cgImage else {
            return ""
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("\(name).png")
        
        let width = cgImage.width
        let height = cgImage.height
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return ""
        }

        // Flip context (UIKit <-> Core Graphics coordinate fix)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Draw image pixels correctly
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let renderedImage = UIGraphicsGetImageFromCurrentImageContext(),
              let data = renderedImage.pngData() else {
            UIGraphicsEndImageContext()
            return ""
        }
        UIGraphicsEndImageContext()
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return ""
        }
    }
    
        public static func resizeImageToTargetSize(
            _ image: UIImage,
            targetSize: CGSize
        ) -> UIImage? {
            let size = image.size
    
            let widthRatio = targetSize.width / size.width
            let heightRatio = targetSize.height / size.height
    
            let newSize = CGSize(
                width: size.width * widthRatio,
                height: size.height * heightRatio
            )
            let rect = CGRect(origin: .zero, size: newSize)
    
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
    
            return newImage
        }
//      public static func imageOrientation(
//    fromDevicePosition devicePosition: AVCaptureDevice.Position = .back
//  ) -> UIImage.Orientation {
//    var deviceOrientation = UIDevice.current.orientation
//    if deviceOrientation == .faceDown || deviceOrientation == .faceUp
//      || deviceOrientation
//        == .unknown
//    {
//      deviceOrientation = currentUIOrientation()
//    }
//    switch deviceOrientation {
//    case .portrait:
//      return devicePosition == .front ? .leftMirrored : .right
//    case .landscapeLeft:
//      return devicePosition == .front ? .downMirrored : .up
//    case .portraitUpsideDown:
//      return devicePosition == .front ? .rightMirrored : .left
//    case .landscapeRight:
//      return devicePosition == .front ? .upMirrored : .down
//    case .faceDown, .faceUp, .unknown:
//      return .up
//    @unknown default:
//      fatalError()
//    }
//  }
    // Resize image to a maximum dimension while maintaining aspect ratio
   public static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        print("📏 Resizing image from \(size) to \(newSize)")
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    private static func currentUIOrientation() -> UIDeviceOrientation {
      let deviceOrientation = { () -> UIDeviceOrientation in
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
          return .landscapeRight
        case .landscapeRight:
          return .landscapeLeft
        case .portraitUpsideDown:
          return .portraitUpsideDown
        case .portrait, .unknown:
          return .portrait
        @unknown default:
          fatalError()
        }
      }
      guard Thread.isMainThread else {
        var currentOrientation: UIDeviceOrientation = .portrait
        DispatchQueue.main.sync {
          currentOrientation = deviceOrientation()
        }
        return currentOrientation
      }
      return deviceOrientation()
    }
    /// Converts an image buffer to a `UIImage`.
    ///
    /// @param imageBuffer The image buffer which should be converted.
    /// @param orientation The orientation already applied to the image.
    /// @return A new `UIImage` instance.
    public static func createUIImage(
      from imageBuffer: CVImageBuffer,
      orientation: UIImage.Orientation
    ) -> UIImage? {
      let ciImage = CIImage(cvPixelBuffer: imageBuffer)
      let context = CIContext(options: nil)
      guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
      return UIImage(cgImage: cgImage, scale: UIIMageConstants.originalScale, orientation: orientation)
    }
}

enum UIIMageConstants {
  static let circleViewAlpha: CGFloat = 0.7
  static let rectangleViewAlpha: CGFloat = 0.3
  static let shapeViewAlpha: CGFloat = 0.3
  static let rectangleViewCornerRadius: CGFloat = 10.0
  static let maxColorComponentValue: CGFloat = 255.0
  static let originalScale: CGFloat = 1.0
  static let bgraBytesPerPixel = 4
  static let circleViewIdentifier = "MLKit Circle View"
  static let lineViewIdentifier = "MLKit Line View"
  static let rectangleViewIdentifier = "MLKit Rectangle View"
}

// MARK: - Extension

extension CGRect {
  /// Returns a `Bool` indicating whether the rectangle's values are valid`.
  func isValid() -> Bool {
    return
      !(origin.x.isNaN || origin.y.isNaN || width.isNaN || height.isNaN || width < 0 || height < 0)
  }
}
