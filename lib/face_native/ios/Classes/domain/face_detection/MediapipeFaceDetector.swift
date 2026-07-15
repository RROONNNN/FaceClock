import Foundation
import UIKit
import MLKitFaceDetection
import MLKitVision
import AVFoundation

private let maxDimension: CGFloat = 1024

@available(iOS 13.0.0, *)
class MediapipeFaceDetector {
    // MARK: - Singleton
    static let shared = MediapipeFaceDetector()
    
    private let faceDetector: FaceDetector
    
    
    private init() {
        // Configure face detector options
        let options = FaceDetectorOptions()
        options.landmarkMode = .none
        options.classificationMode = .none
        options.performanceMode = .fast
        
        faceDetector = FaceDetector.faceDetector(options: options)
    }
    
    private func createPixelBuffer(from data: Data, width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)
        memcpy(baseAddress, (data as NSData).bytes, data.count)
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
    
private func getBiggestFace(faces: [Face]) -> Face? {
    guard !faces.isEmpty else { return nil }
    if faces.count == 1 { return faces[0] }
    return faces.max {
        $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height
    }
}
    func getCroppedFace(imageUrl: URL) async -> Result<UIImage, AppException> {
        do {
            print("🔍 Starting getCroppedFace with URL: \(imageUrl)")
            // Load image from URL
            if !FileManager.default.fileExists(atPath: imageUrl.path) {
                print("❌ File does not exist at path: \(imageUrl.path)")
                return .failure(AppException(code: .faceDetectorFailure))
            }
            
            guard let image = UIImage.init(contentsOfFile: imageUrl.path) else {
                print("❌ Failed to create UIImage from data")
                return .failure(AppException(code: .faceDetectorFailure))
            }
            print("✅ UIImage created successfully, size: \(image.size) orientation: \(image.imageOrientation.rawValue)")
            // Normalize image orientation
            let normalizedImage = UIUtilities.normalizedImage(image)
            UIUtilities.saveBitmap(normalizedImage, name:"fixedOrientation" )
            print("🔄 Normalized image size: \(normalizedImage.size), orientation: \(normalizedImage.imageOrientation.rawValue)")
            
            let resizedImage = UIUtilities.resizeImage(normalizedImage, maxDimension: maxDimension)
            UIUtilities.saveBitmap(resizedImage, name:"resized_for_detection" )
            
            // Calculate scale factor for bounding box
            let scaleX = normalizedImage.size.width / resizedImage.size.width
            let scaleY = normalizedImage.size.height / resizedImage.size.height
            print("📊 Scale factors - X: \(scaleX), Y: \(scaleY)")
            
            // Detect faces on resized image
            let visionImage = VisionImage(image: resizedImage)
            visionImage.orientation = .up
            print("👁️ Starting face detection on resized image...")
            
            let faces = try faceDetector.results(in: visionImage)
            print("🎯 Face detection completed, found \(faces.count) faces")
            
            guard !faces.isEmpty else {
                print("❌ No faces detected")
                return .failure(AppException(code: .faceDetectorFailure))
            }
            
            guard let face = getBiggestFace(faces: faces) else {
                print("❌ No faces detected")
                return .failure(AppException(code: .faceDetectorFailure))
            }
           
            let detectedRect = face.frame
            print("📐 Detected face bounding box (on resized image): x=\(detectedRect.origin.x), y=\(detectedRect.origin.y), width=\(detectedRect.width), height=\(detectedRect.height)")
            
            // Scale bounding box back to original image size
            let scaledRect = CGRect(
                x: detectedRect.origin.x * scaleX,
                y: detectedRect.origin.y * scaleY,
                width: detectedRect.width * scaleX,
                height: detectedRect.height * scaleY
            )
            print("📐 Scaled face bounding box (on original image): x=\(scaledRect.origin.x), y=\(scaledRect.origin.y), width=\(scaledRect.width), height=\(scaledRect.height)")
            
            guard validateRect(
                image: normalizedImage,
                boundingBox: scaledRect
            ),
                  let croppedImage = cropImage(
                    normalizedImage,
                    toRect: scaledRect
                  ) else {
                print("❌ Failed to validate rect or crop image")
                return .failure(AppException(code: .faceDetectorFailure))
            }
            UIUtilities.saveBitmap(croppedImage, name: "croppedImage")
            print("✂️ Face cropped successfully, cropped image size: \(croppedImage.size)")
            print("🎉 getCroppedFace completed successfully")
            return .success(croppedImage)
        } catch {
            print("💥 Error in getCroppedFace: \(error)")
            return .failure(AppException(code: .faceDetectorFailure))
        }
    }

//    func getAllCroppedFaces(imageUrl: URL ) async -> Result<[(UIImage, CGRect)],AppException> {
//        do {
//             if !FileManager.default.fileExists(atPath: imageUrl.path) {
//            print("❌ File does not exist at path: \(imageUrl.path)")
//            return .failure(AppException(code: .faceDetectorFailure))
//        }
//          guard let image = UIImage.init(contentsOfFile: imageUrl.path) else {
//                 print("❌ Failed to create UIImage from data")
//                 return .failure(AppException(code: .faceDetectorFailure))
//             }
//               print("✅ UIImage created successfully, size: \(image.size) orientation: \(image.imageOrientation.rawValue)")
//            // Normalize image orientation
//            let normalizedImage = normalizedImage(image)
//            saveBitmap(normalizedImage, name:"fixedOrientation" )
//            print("🔄 Normalized image size: \(normalizedImage.size), orientation: \(normalizedImage.imageOrientation.rawValue)")
//            let resizedImage = UIUtilities.resizeImage(normalizedImage, maxDimension: maxDimension)
//            saveBitmap(resizedImage, name:"resized_for_detection" )
//let visionImage = VisionImage(image: resizedImage)
//            visionImage.orientation = .up
//            print("👁️ Starting face detection on resized image...")
//            
//            let faces = try faceDetector.results(in: visionImage)
//            print("🎯 Face detection completed, found \(faces.count) faces")
//     guard !faces.isEmpty else {
//                print("❌ No faces detected")
//                return .failure(AppException(code: .faceDetectorFailure))
//            }
//            
//        } catch {
//            return .failure(AppException(code: .faceDetectorFailure))
//        }
//    }


    
 
    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Scale rect if needed
        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        
        // Crop the image
        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else {
            return nil
        }
        
        return UIImage(
            cgImage: croppedCGImage,
            scale: scale,
            orientation: image.imageOrientation
        )
    }
    
    private func validateRect(
        image: UIImage,
        boundingBox: CGRect
    ) -> Bool {
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        return boundingBox.origin.x >= 0 &&
            boundingBox.origin.y >= 0 &&
            (boundingBox.origin.x + boundingBox.width) <= imageWidth &&
            (boundingBox.origin.y + boundingBox.height) <= imageHeight
    }
    


// test detect Face
  private func detectFacesOnDevice(in image: VisionImage, width: CGFloat, height: CGFloat) {
    // When performing latency tests to determine ideal detection settings, run the app in 'release'
    // mode to get accurate performance metrics.
    let options = FaceDetectorOptions()
    options.landmarkMode = .none
    options.classificationMode = .none
    options.performanceMode = .fast
    let faceDetector = FaceDetector.faceDetector(options: options)
    var faces: [Face] = []
    var detectionError: Error?
    do {
      faces = try faceDetector.results(in: image)
    } catch let error {
      detectionError = error
    }
    weak var weakSelf = self
    DispatchQueue.main.sync {
      guard let strongSelf = weakSelf else {
        print("Self is nil!")
        return
      }
      if let detectionError = detectionError {
        print("Failed to detect faces with error: \(detectionError.localizedDescription).")
        return
      }
      guard !faces.isEmpty else {
        print("On-Device face detector returned no results.")
        return
      }

    }
  }
}





class AppException: Error {
    let code: ErrorCode
    
    init(code: ErrorCode) {
        self.code = code
    }
    
    var localizedDescription: String {
        return code.rawValue
    }
}

enum ErrorCode: String {
    case faceDetectorFailure = "FACE_DETECTOR_FAILURE"
    case multipleFaces = "MULTIPLE_FACES"
    case noFace = "NO_FACE"
}

