//
//  NSImageExtension.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 05.03.2019.
//

import Foundation
import AppKit

public extension NSImage {
    
    /// Returns the height of the current image.
    var height: CGFloat {
        return self.size.height
    }
    
    /// Returns the width of the current image.
    var width: CGFloat {
        return self.size.width
    }
    
    var CGImage: CGImage {
        get {
            let imageData = self.tiffRepresentation!
            let source = CGImageSourceCreateWithData(imageData as CFData, nil).unsafelyUnwrapped
            let maskRef = CGImageSourceCreateImageAtIndex(source, Int(0), nil)
            return maskRef.unsafelyUnwrapped
        }
    }
    
    /// Returns a png representation of the current image.
    var pngRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }
        
        return nil
    }
    
    ///  Copies the current image and resizes it to the given size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func copy(size: NSSize) throws -> NSImage {
        // Create a new rect with given width and height
        let frame = NSMakeRect(0, 0, size.width, size.height)
        
        // Get the best representation for the given size.
        guard let rep = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            throw ScriptError.generalError(message: "Unable to resize image")
        }
        
        // Create an empty image with the given size.
        let img = NSImage(size: size)
        
        // Set the drawing context and make sure to remove the focus before returning.
        img.lockFocus()
        defer { img.unlockFocus() }
        
        // Draw the new image
        if rep.draw(in: frame) {
            return img
        }
        
        // Return nil in case something went wrong.
        throw ScriptError.generalError(message: "Unable to resize image")
    }
    
        func areImagesSame(leftImage: NSImage, rightImage: NSImage) -> Bool {
            guard let leftPNGData = leftImage.pngRepresentation, let rightPNGData = rightImage.pngRepresentation else { return false }
            
            let sequence = Data([0x6C, 0x65, 0x58, 0x49, 0x66])
    
            guard let leftOffset = leftPNGData.indexOf(data: sequence) else { return false }
            let leftSubdata = leftPNGData.subdata(in: leftOffset ..< leftPNGData.endIndex)
    
            guard let rightOffset = rightPNGData.indexOf(data: sequence) else { return false }
            let rightSubdata = rightPNGData.subdata(in: rightOffset ..< rightPNGData.endIndex)
    
            return leftSubdata == rightSubdata
        }
    
//    func areImagesSame(leftImage: NSImage, rightImage: NSImage) -> Bool {
//        let width = Int(leftImage.size.width)
//        let height = Int(leftImage.size.height)
//
//        guard leftImage.size == rightImage.size else {
//            return false
//        }
//        var changes = 0
//
//        if let cfData1:CFData = leftImage.CGImage.dataProvider?.data,
//            let l = CFDataGetBytePtr(cfData1),
//            let cfData2:CFData = rightImage.CGImage.dataProvider?.data,
//            let r = CFDataGetBytePtr(cfData2) {
//            let bytesPerpixel = 4
//            let firstPixel = 0
//            let lastPixel = (width * height - 1) * bytesPerpixel
//            let range = stride(from: firstPixel, through: lastPixel, by: bytesPerpixel)
//            for pixelAddress in range {
//                if l.advanced(by: pixelAddress).pointee != r.advanced(by: pixelAddress).pointee ||     //Red
//                    l.advanced(by: pixelAddress + 1).pointee != r.advanced(by: pixelAddress + 1).pointee || //Green
//                    l.advanced(by: pixelAddress + 2).pointee != r.advanced(by: pixelAddress + 2).pointee || //Blue
//                    l.advanced(by: pixelAddress + 3).pointee != r.advanced(by: pixelAddress + 3).pointee  {  //Alpha
//                    changes += 1
//                }
//            }
//        }
//
//        return changes < 100
//    }
    
    ///  Saves the PNG representation of the current image to the HD.
    ///
    /// - parameter url: The location url to which to write the png file.
    func savePNGRepresentationToURL(url: URL, onlyChange: Bool = true) throws {
        if let pngData = self.pngRepresentation {
            if let originalImage = NSImage(contentsOf: url) {
                if onlyChange && areImagesSame(leftImage: self, rightImage: originalImage) {
                    print("    Keeping original file - no change")
                    return
                }
            }
            
            try pngData.write(to: url, options: .atomicWrite)
        }
    }
    
    
    /// Combine two images together
    func combine(withImage image: NSImage) throws -> NSImage {
        guard
            let firstImageData = image.tiffRepresentation,
            let firstImage = CIImage(data: firstImageData),
            let secondImageData = tiffRepresentation,
            let secondImage = CIImage(data: secondImageData)
            else {
                throw ScriptError.generalError(message: "Image processing error")
        }
        
        let filter = CIFilter(name: "CISourceOverCompositing")!
        filter.setDefaults()
        
        filter.setValue(firstImage, forKey: "inputImage")
        filter.setValue(secondImage, forKey: "inputBackgroundImage")
        
        let resultImage = filter.outputImage
        
        let rep = NSCIImageRep(ciImage: resultImage!)
        let finalResult = NSImage(size: rep.size)
        finalResult.addRepresentation(rep)
        
        return finalResult
    }
    
    /// Image annotation
    func image(
        withText text: String,
        alignmentMode: NSTextAlignment,
        attributes: [NSAttributedString.Key: Any],
        horizontalTitlePosition: CGFloat,
        verticalTitlePosition: CGFloat) -> NSImage {
        
        let image = self
        let text = text as NSString
        let options: NSString.DrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        
        let textSize = text.boundingRect(with: image.size, options: options, attributes: attributes).size
        var offsetX: CGFloat
        
        switch alignmentMode {
        case .left:
            offsetX = 0
        case .center:
            offsetX = -textSize.width/2
        case .right:
            offsetX = -textSize.width
        default:
            offsetX = 0
        }
        
        let point = NSMakePoint(image.size.width * horizontalTitlePosition + offsetX, image.size.height * verticalTitlePosition - textSize.height/2)
        
        image.lockFocus()
        text.draw(at: point, withAttributes: attributes)
        image.unlockFocus()
        
        return image
    }
    
    /// Image annotation
    func annotate(
        text: String,
        font: String,
        size: CGFloat,
        horizontalTitlePosition: CGFloat,
        verticalTitlePosition: CGFloat,
        titleAlignment: String,
        fill: NSColor,
        stroke: NSColor,
        strokeWidth: CGFloat
    ) throws -> NSImage {
        
        guard let titleFont = NSFont(name: font, size: size) else { throw ScriptError.argumentError(message: "Unable to find font \(font)") }
        
        var alignmentMode: NSTextAlignment
        
        switch titleAlignment {
        case "left":
            alignmentMode = .left
            
        case "right":
            alignmentMode = .right
            
        default:
            alignmentMode = .center
        }
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignmentMode
        
        // Solid color text
        let fillText = image(
            withText: text,
            alignmentMode: alignmentMode,
            attributes: [
                .foregroundColor: fill,
                .font: titleFont,
                .paragraphStyle: paragraph
            ],
            horizontalTitlePosition: horizontalTitlePosition,
            verticalTitlePosition: verticalTitlePosition
        )
        
        // Add strokes
        return fillText.image(
            withText: text,
            alignmentMode: alignmentMode,
            attributes: [
                .foregroundColor: NSColor.clear,
                .strokeColor: stroke,
                .strokeWidth: strokeWidth * size,
                .font: titleFont,
                .paragraphStyle: paragraph
            ],
            horizontalTitlePosition: horizontalTitlePosition,
            verticalTitlePosition: verticalTitlePosition)
    }
}

