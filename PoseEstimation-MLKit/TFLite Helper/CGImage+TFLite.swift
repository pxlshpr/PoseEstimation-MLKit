//
//  CGImage+TFLite.swift
//  MobileNetApp-MLKit
//
//  Created by GwakDoyoung on 13/06/2018.
//  Copyright © 2018 GwakDoyoung. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGImage {
    
    /// Returns a scaled image data array from the given values.
    ///
    /// - Parameters
    ///   - size: Size to scale the image to (i.e. expected size of the image in the trained model).
    ///   - componentsCount: Number of color components for the image.
    ///   - batchSize: Batch size for the image.
    ///   - isQuantized: Indicates whether the model uses quantization. If `true`, apply
    ///     `(value - mean) / std` to each pixel to convert the data from Int(0, 255) scale to
    ///     Float(-1, 1).
    /// - Returns: The scaled image data array or `nil` if the image could not be scaled.
    func scaledImageData(with size: CGSize,
                         componentsCount newComponentsCount: Int,
                         batchSize: Int,
                         isQuantized: Bool) -> [Any]? {
        
        guard self.width > 0 else { return nil }
        let oldComponentsCount = self.bytesPerRow / self.width
        guard newComponentsCount <= oldComponentsCount else { return nil }
        
        let newWidth = Int(size.width)
        let newHeight = Int(size.height)
        let dataSize = newWidth * newHeight * oldComponentsCount * batchSize
        var imageData = [UInt8](repeating: 0, count: dataSize)
        guard let context = CGContext(
            data: &imageData,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: self.bitsPerComponent,
            bytesPerRow: oldComponentsCount * newWidth,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return nil
        }
        context.draw(self, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        var scaledImageData = [Any]()
        
        for yCoordinate in 0..<newHeight {
            var rowArray = [Any]()
                
            for xCoordinate in 0..<newWidth {
                var pixelArray = [Any]()
                    
                for component in 0..<newComponentsCount {
                    let inputIndex =
                          (yCoordinate * newWidth * oldComponentsCount)
                        + (xCoordinate * oldComponentsCount + component)
                    let pixel = imageData[inputIndex]
                    if isQuantized {
                        pixelArray.append(pixel)
                    } else {
                        // Convert pixel values from [0, 255] to [-1, 1].
                        let pixel = (Float32(pixel) - Constants.meanRGBValue) / Constants.stdRGBValue
                        pixelArray.append(pixel)
                    }
                }
                
                rowArray.append(pixelArray)
                
            }
            
            scaledImageData.append(rowArray)
            
        }
        return [scaledImageData]
    }
}


// MARK: - Fileprivate

fileprivate enum Constants {
    static let maxRGBValue: Float32 = 255.0
    static let meanRGBValue: Float32 = maxRGBValue / 2.0
    static let stdRGBValue: Float32 = maxRGBValue / 2.0
    static let jpegCompressionQuality: CGFloat = 0.8
}
