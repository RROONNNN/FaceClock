import Foundation
import UIKit
import TensorFlowLite
import Accelerate


class FaceNet {
    // MARK: - Singleton
    static let shared: FaceNet = {
        do {
            return try FaceNet()
        } catch {
            fatalError("Failed to initialize FaceNet: \(error.localizedDescription)")
        }
    }()
    
    var batchSize = 1
     var inputChannels = 3
     var inputWidth = 160 //160
     var inputHeight = 160 //160
    
    private let imgSize: Int = 160
    
    // Output embedding size
    private let embeddingDim: Int = 128
    
    private var interpreter: Interpreter
    
    private init(useGpu: Bool = true, useXNNPack: Bool = true) throws {
        // Load the TFLite model
     guard let bundlePath = Bundle(for: type(of: self)).path(forResource: "face_native", ofType: "bundle"),
      let bundle = Bundle(path: bundlePath),
           let modelPath = bundle.path(forResource: "facenet_128", ofType: "tflite") else {
         throw FaceNetError.modelNotFound
     }
        
        // Configure interpreter options
        var options = Interpreter.Options()
        options.threadCount = 4
        

        interpreter = try Interpreter(
            modelPath: modelPath,
            options: options
        )
        try interpreter.allocateTensors()
        let input = try interpreter.input(at: 0)
        batchSize = input.shape.dimensions[0]
        inputWidth = input.shape.dimensions[1]
        inputHeight = input.shape.dimensions[2]
        inputChannels = input.shape.dimensions[3]
        
        // Allocate tensors
       
    }
    
    func getFaceEmbedding(image: UIImage) async throws -> [Float] {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                UIUtilities.saveBitmap(image, name: "image_before_process")
                let embedding = try self.processImage(image)
                continuation.resume(returning: embedding)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func processImage(_ image: UIImage) throws -> [Float] {
        // Resize image to required size
        guard let resizedImage = UIUtilities.resizeImageToTargetSize(
            image,
            targetSize: CGSize(width: imgSize, height: imgSize) //160
        ) else {
            throw FaceNetError.imageProcessingFailed
        }
        UIUtilities.saveBitmap(image, name: "image_resized_processImage")
        
        // Convert to RGB pixel buffer
        guard let pixelBuffer = CVPixelBuffer.buffer(from: resizedImage) else {
            throw FaceNetError.imageProcessingFailed
        }
        UIUtilities.saveImage(from:pixelBuffer,name:"after covert to Buffer")
        // Normalize the pixel buffer
//        let normalizedBuffer = normalizeBuffer(pixelBuffer)
        
        // Run inference
        let embedding = try runFaceNet(input: pixelBuffer)
        
        return embedding
    }

    private func runFaceNet(input: CVPixelBuffer) throws -> [Float] {
        
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(input)
        assert(sourcePixelFormat == kCVPixelFormatType_32ARGB ||
                 sourcePixelFormat == kCVPixelFormatType_32BGRA ||
                   sourcePixelFormat == kCVPixelFormatType_32RGBA)
        let imageChannels = 4
            assert(imageChannels >= inputChannels)
        guard let thumbnailPixelBuffer = input.convertToSquarePixelBuffer(outputSize: imgSize) else { return [] }
    let embeddingOutputTensor: Tensor

        do {
            let inputTensor = try interpreter.input(at: 0)
            // Remove the alpha component from the image buffer to get the RGB data.
      guard let rgbData = rgbDataFromBuffer(
        thumbnailPixelBuffer,
        byteCount: batchSize * inputWidth * inputHeight * inputChannels,
        isModelQuantized: inputTensor.dataType == .uInt8
      ) else {
        print("Failed to convert the image buffer to RGB data.")
        return []
      }
       // Copy the RGB data to the input `Tensor`.
      try interpreter.copy(rgbData, toInputAt: 0)
      try interpreter.invoke()
  // Get the output `Tensor` to process the inference results.
      embeddingOutputTensor = try interpreter.output(at: 0)
         guard let embedding = getFloatsData(tensor: embeddingOutputTensor) else { return [] }
         return embedding
        }
        catch let error {
            print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
                  throw error
        }

    }
    

  /// Returns the float datas from output tensor
  private func getFloatsData(tensor: Tensor) -> [Float]? {
    let results: [Float]
    switch tensor.dataType {
    case .uInt8:
      guard let quantization = tensor.quantizationParameters else {
        print("No results returned because the quantization values for the output tensor are nil.")
        return nil
      }
      let quantizedResults = [UInt8](tensor.data)
      results = quantizedResults.map {
        quantization.scale * Float(Int($0) - quantization.zeroPoint)
      }
    case .float32:
        results = [Float32](unsafeData: tensor.data) ?? []
    default:
      print("Output tensor data type \(tensor.dataType) is unsupported for this example app.")
      return nil
    }
    return results
  }



  /// Returns the RGB data representation of the given image buffer with the specified `byteCount`.
  ///
  /// - Parameters
  ///   - buffer: The pixel buffer to convert to RGB data.
  ///   - byteCount: The expected byte count for the RGB data calculated using the values that the
  ///       model was trained on: `batchSize * imageWidth * imageHeight * componentsCount`.
  ///   - isModelQuantized: Whether the model is quantized (i.e. fixed point values rather than
  ///       floating point values).
  /// - Returns: The RGB data representation of the image buffer or `nil` if the buffer could not be
  ///     converted.
  private func rgbDataFromBuffer(
    _ buffer: CVPixelBuffer,
    byteCount: Int,
    isModelQuantized: Bool
  ) -> Data? {
    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    defer {
      CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
    }
    guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else {
      return nil
    }

    let width = CVPixelBufferGetWidth(buffer)
    let height = CVPixelBufferGetHeight(buffer)
    let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    let destinationChannelCount = 3
    let destinationBytesPerRow = destinationChannelCount * width

    var sourceBuffer = vImage_Buffer(data: sourceData,
                                     height: vImagePixelCount(height),
                                     width: vImagePixelCount(width),
                                     rowBytes: sourceBytesPerRow)

    guard let destinationData = malloc(height * destinationBytesPerRow) else {
      print("Error: out of memory")
      return nil
    }

    defer {
        free(destinationData)
    }

    var destinationBuffer = vImage_Buffer(data: destinationData,
                                          height: vImagePixelCount(height),
                                          width: vImagePixelCount(width),
                                          rowBytes: destinationBytesPerRow)

    let pixelBufferFormat = CVPixelBufferGetPixelFormatType(buffer)

    switch (pixelBufferFormat) {
    case kCVPixelFormatType_32BGRA:
        vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
    case kCVPixelFormatType_32ARGB:
        vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
    case kCVPixelFormatType_32RGBA:
        vImageConvert_RGBA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
    default:
        // Unknown pixel format.
        return nil
    }

    let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
    if isModelQuantized {
        return byteData
    }

    // Not quantized, convert to floats
    let bytes = Array<UInt8>(unsafeData: byteData)!
    var floats = [Float]()
    for i in 0..<bytes.count {
        floats.append(Float(bytes[i]) / 255.0)
    }
    return Data(copyingBufferOf: floats)
  }



    // private func convertImageToBuffer(_ image: UIImage) -> [Float]? {
    //     guard let cgImage = image.cgImage else { return nil }
        
    //     let width = cgImage.width
    //     let height = cgImage.height
    //     let bytesPerPixel = 4
    //     let bytesPerRow = bytesPerPixel * width
    //     let bitsPerComponent = 8
        
    //     var pixelData = [UInt8](
    //         repeating: 0,
    //         count: width * height * bytesPerPixel
    //     )
        
    //     let colorSpace = CGColorSpaceCreateDeviceRGB()
    //     let context = CGContext(
    //         data: &pixelData,
    //         width: width,
    //         height: height,
    //         bitsPerComponent: bitsPerComponent,
    //         bytesPerRow: bytesPerRow,
    //         space: colorSpace,
    //         bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    //     )
        
    //     context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
    //     // Convert UInt8 RGB to Float RGB (0-255 -> 0.0-255.0)
    //     var floatPixels = [Float]()
    //     floatPixels.reserveCapacity(width * height * 3)
        
    //     for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
    //         let r = Float(pixelData[i])
    //         let g = Float(pixelData[i + 1])
    //         let b = Float(pixelData[i + 2])
            
    //         floatPixels.append(r)
    //         floatPixels.append(g)
    //         floatPixels.append(b)
    //     }
        
    //     return floatPixels
    // }
    
    private func normalizeBuffer(_ pixels: [Float]) -> Data {
        var normalizedPixels = pixels
        
        // Calculate mean
        let sum = normalizedPixels.reduce(0, +)
        let mean = sum / Float(normalizedPixels.count)
        
        // Calculate standard deviation
        let squaredDiffs = normalizedPixels.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Float(normalizedPixels.count)
        var std = sqrt(variance)
        
        // Prevent division by zero
        let minStd = 1.0 / sqrt(Float(normalizedPixels.count))
        std = max(std, minStd)
        
        // Normalize: (pixel - mean) / std
        for i in 0..<normalizedPixels.count {
            normalizedPixels[i] = (normalizedPixels[i] - mean) / std
        }
        
        // Convert to Data
        let data = Data(
            bytes: &normalizedPixels,
            count: normalizedPixels.count * MemoryLayout<Float>.stride
        )
        
        return data
    }
}
// MARK: - Extensions
extension Data {
  /// Creates a new buffer by copying the buffer pointer of the given array.
  ///
  /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
  ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
  ///     data from the resulting buffer has undefined behavior.
  /// - Parameter array: An array with elements of type `T`.
  init<T>(copyingBufferOf array: [T]) {
    self = array.withUnsafeBufferPointer(Data.init)
  }
}
extension Array {
  /// Creates a new array from the bytes of the given unsafe data.
  ///
  /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
  ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
  ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
  /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
  ///     `MemoryLayout<Element>.stride`.
  /// - Parameter unsafeData: The data containing the bytes to turn into an array.
  init?(unsafeData: Data) {
    guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
    self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
  }
}

// MARK: - Error Types
enum FaceNetError: Error {
    case modelNotFound
    case imageProcessingFailed
    case inferenceError
    case invalidImageUrl
    
    var localizedDescription: String {
        switch self {
        case .modelNotFound:
            return "FaceNet model file not found"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .inferenceError:
            return "Failed to run inference"
        case .invalidImageUrl:
            return "Invalid Image Url"
        }
    }
}
