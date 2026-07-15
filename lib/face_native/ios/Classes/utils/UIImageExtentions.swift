//
//  UIImageExtentions.swift
//  face_native
//
//  Created by Apple on 03/11/2025.
//

import Foundation
extension UIImage {
    
    func rotate(radians: Double) -> UIImage? {
            var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
            // Trim off the extremely small float value to prevent core graphics from rounding it up
            newSize.width = floor(newSize.width)
            newSize.height = floor(newSize.height)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            
            // Move origin to middle
            context.translateBy(x: newSize.width/2, y: newSize.height/2)
            // Rotate around middle
            context.rotate(by: CGFloat(radians))
            // Draw the image at its center
            self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
        }
    
//    func toCVPixelBuffer() -> CVPixelBuffer? {
//            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
//            var pixelBuffer : CVPixelBuffer?
//            let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
//            guard status == kCVReturnSuccess else {
//                return nil
//            }
//
//            if let pixelBuffer = pixelBuffer {
//                CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//                let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
//
//                let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//                let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
//
//                context?.translateBy(x: 0, y: self.size.height)
//                context?.scaleBy(x: 1.0, y: -1.0)
//
//                UIGraphicsPushContext(context!)
//                self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
//                UIGraphicsPopContext()
//                CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//
//                return pixelBuffer
//            }
//            return nil
//        }
}
