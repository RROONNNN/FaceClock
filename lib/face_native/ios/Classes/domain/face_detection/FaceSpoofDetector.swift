import Foundation
import UIKit
import TensorFlowLite
import CoreGraphics

@available(iOS 13.0.0, *)
class FaceSpoofDetector {
    // MARK: - Singleton
    static let shared: FaceSpoofDetector = {
        do {
            return try FaceSpoofDetector()
        } catch {
            fatalError("Failed to initialize FaceSpoofDetector: \(error.localizedDescription)")
        }
    }()
    
    struct FaceSpoofResult {
        let isSpoof: Bool
        let score: Float
        let timeMillis: Int64
    }
    
    private let scale1: Float = 2.7
    private let scale2: Float = 4.0
    private let inputImageDim: Int = 80
    private let outputDim: Int = 3
    
    private var firstModelInterpreter: Interpreter
    private var secondModelInterpreter: Interpreter
    
    private init(
        useGpu: Bool = false,
        useXNNPack: Bool = false
    ) throws {
        guard let bundlePath = Bundle(for: type(of: self)).path(forResource: "face_native", ofType: "bundle"),
      let bundle = Bundle(path: bundlePath),
           let firstModelPath = bundle.path(forResource: "spoof_model_scale_2_7", ofType: "tflite"),
        let secondModelPath = bundle.path(forResource: "spoof_model_scale_4_0", ofType: "tflite")
        else {
         throw FaceNetError.modelNotFound
     }
   
        var options = Interpreter.Options()
        options.threadCount = 4
        

        firstModelInterpreter = try Interpreter(
            modelPath: firstModelPath,
            options: options
        )
        secondModelInterpreter = try Interpreter(
            modelPath: secondModelPath,
            options: options
        )
        
        try firstModelInterpreter.allocateTensors()
        try secondModelInterpreter.allocateTensors()
    }
    
    func detectSpoof(
        frameImage: UIImage,
        faceRect: CGRect
    ) async throws -> FaceSpoofResult {
        let startTime = Date()
        

        guard var croppedImage1 = crop(
            origImage: frameImage,
            bbox: faceRect,
            bboxScale: scale1,
            targetWidth: inputImageDim,
            targetHeight: inputImageDim
        ) else {
            throw FaceSpoofError.imageProcessingFailed
        }
        
        croppedImage1 = rgbToBgr(croppedImage1)
        
        guard var croppedImage2 = crop(
            origImage: frameImage,
            bbox: faceRect,
            bboxScale: scale2,
            targetWidth: inputImageDim,
            targetHeight: inputImageDim
        ) else {
            throw FaceSpoofError.imageProcessingFailed
        }
        
        croppedImage2 = rgbToBgr(croppedImage2)
        
        guard let input1 = imageToFloatBuffer(croppedImage1) else {
            throw FaceSpoofError.imageProcessingFailed
        }
        guard let input2 = imageToFloatBuffer(croppedImage2) else {
            throw FaceSpoofError.imageProcessingFailed
        }
        
        let output1 = try runInference(
            interpreter: firstModelInterpreter,
            input: input1
        )
        let output2 = try runInference(
            interpreter: secondModelInterpreter,
            input: input2
        )
        
        let timeMillis = Int64(Date().timeIntervalSince(startTime) * 1000)
        
        let softMax1 = softMax(output1)
        let softMax2 = softMax(output2)
        
        var combined = [Float](repeating: 0, count: outputDim)
        for i in 0..<outputDim {
            combined[i] = softMax1[i] + softMax2[i]
        }
        
        let maxValue = combined.max() ?? 0
        let label = combined.firstIndex(of: maxValue) ?? 0
        let isSpoof = label != 1
        let score = combined[label] / 2.0
        
        return FaceSpoofResult(
            isSpoof: isSpoof,
            score: score,
            timeMillis: timeMillis
        )
    }
    
    private func runInference(
        interpreter: Interpreter,
        input: Data
    ) throws -> [Float] {
        try interpreter.copy(input, toInputAt: 0)
        
        try interpreter.invoke()
        
        let outputTensor = try interpreter.output(at: 0)
        let outputData = outputTensor.data
        
        let floatArray = outputData.withUnsafeBytes {
            Array(
                UnsafeBufferPointer<Float>(
                    start: $0.baseAddress?.assumingMemoryBound(to: Float.self),
                    count: outputDim
                )
            )
        }
        
        return floatArray
    }
    
    private func softMax(_ x: [Float]) -> [Float] {
        let expValues = x.map { exp($0) }
        let expSum = expValues.reduce(0, +)
        return expValues.map { $0 / expSum }
    }
    
    private func crop(
        origImage: UIImage,
        bbox: CGRect,
        bboxScale: Float,
        targetWidth: Int,
        targetHeight: Int
    ) -> UIImage? {
        guard let cgImage = origImage.cgImage else { return nil }
        
        let srcWidth = cgImage.width
        let srcHeight = cgImage.height
        
        let scaledBox = getScaledBox(
            srcWidth: srcWidth,
            srcHeight: srcHeight,
            box: bbox,
            bboxScale: bboxScale
        )
        
        guard let croppedCGImage = cgImage.cropping(to: scaledBox) else {
            return nil
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage)
        
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: targetWidth, height: targetHeight),
            false,
            1.0
        )
        croppedImage.draw(
            in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        )
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    private func getScaledBox(
        srcWidth: Int,
        srcHeight: Int,
        box: CGRect,
        bboxScale: Float
    ) -> CGRect {
        let x = box.origin.x
        let y = box.origin.y
        let w = box.width
        let h = box.height
        
        let scale = min(
            Float(srcHeight - 1) / Float(h),
            Float(srcWidth - 1) / Float(w),
            bboxScale
        )
        
        let newWidth = w * CGFloat(scale)
        let newHeight = h * CGFloat(scale)
        let centerX = w / 2 + x
        let centerY = h / 2 + y
        
        var topLeftX = centerX - newWidth / 2
        var topLeftY = centerY - newHeight / 2
        var bottomRightX = centerX + newWidth / 2
        var bottomRightY = centerY + newHeight / 2
        
        if topLeftX < 0 {
            bottomRightX -= topLeftX
            topLeftX = 0
        }
        if topLeftY < 0 {
            bottomRightY -= topLeftY
            topLeftY = 0
        }
        if bottomRightX > CGFloat(srcWidth - 1) {
            topLeftX -= (bottomRightX - CGFloat(srcWidth - 1))
            bottomRightX = CGFloat(srcWidth - 1)
        }
        if bottomRightY > CGFloat(srcHeight - 1) {
            topLeftY -= (bottomRightY - CGFloat(srcHeight - 1))
            bottomRightY = CGFloat(srcHeight - 1)
        }
        
        return CGRect(
            x: topLeftX,
            y: topLeftY,
            width: bottomRightX - topLeftX,
            height: bottomRightY - topLeftY
        )
    }
    
    private func rgbToBgr(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](
            repeating: 0,
            count: width * height * bytesPerPixel
        )
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return image
        }
        
        context.draw(
            cgImage,
            in: CGRect(x: 0, y: 0, width: width, height: height)
        )
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let temp = pixelData[i]
            pixelData[i] = pixelData[i + 2]
            pixelData[i + 2] = temp
        }
        
        guard let newContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ),
        let newCGImage = newContext.makeImage() else {
            return image
        }
        
        return UIImage(cgImage: newCGImage)
    }
    
    private func imageToFloatBuffer(_ image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](
            repeating: 0,
            count: width * height * bytesPerPixel
        )
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }
        
        context.draw(
            cgImage,
            in: CGRect(x: 0, y: 0, width: width, height: height)
        )
        
        var floatPixels = [Float]()
        floatPixels.reserveCapacity(width * height * 3)
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            floatPixels.append(Float(pixelData[i]))
            floatPixels.append(Float(pixelData[i + 1]))
            floatPixels.append(Float(pixelData[i + 2]))
        }
        
        let data = Data(
            bytes: &floatPixels,
            count: floatPixels.count * MemoryLayout<Float>.stride
        )
        
        return data
    }
}

enum FaceSpoofError: Error {
    case modelNotFound
    case imageProcessingFailed
    case inferenceError
    
    var localizedDescription: String {
        switch self {
        case .modelNotFound:
            return "Spoof detection model file not found"
        case .imageProcessingFailed:
            return "Failed to process image for spoof detection"
        case .inferenceError:
            return "Failed to run spoof detection inference"
        }
    }
}

