//
//  NSImageExtension.swift
//  ScriptToolkit
//
//  Created by Dan Cech on 05.03.2019.
//

import AppKit
import Foundation

public extension NSImage {
    /// Returns the height of the current image.
    var height: CGFloat {
        size.height
    }

    /// Returns the width of the current image.
    var width: CGFloat {
        size.width
    }

    var CGImage: CGImage {
        let imageData = tiffRepresentation!
        let source = CGImageSourceCreateWithData(imageData as CFData, nil).unsafelyUnwrapped
        let maskRef = CGImageSourceCreateImageAtIndex(source, Int(0), nil)
        return maskRef.unsafelyUnwrapped
    }

    /// Returns a png representation of the current image.
    var pngRepresentation: Data? {
        if let tiff = tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
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
        let frame = NSRect(x: 0, y: 0, width: size.width, height: size.height)

        // Get the best representation for the given size.
        guard let rep = bestRepresentation(for: frame, context: nil, hints: nil) else {
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
        let leftTiff = leftImage.tiffRepresentation
        let rightTiff = rightImage.tiffRepresentation

        return leftTiff == rightTiff
    }

    ///  Saves the PNG representation of the current image to the HD.
    ///
    /// - parameter url: The location url to which to write the png file.
    func savePNGRepresentationToURL(url: URL, onlyChange: Bool = true) throws {
        if let pngData = pngRepresentation {
            if let originalImage = NSImage(contentsOf: url) {
                if onlyChange, areImagesSame(leftImage: self, rightImage: originalImage) {
                    logger.print("    Keeping original file - no change")
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
        verticalTitlePosition: CGFloat
    ) -> NSImage {
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

        let point = NSPoint(x: image.size.width * horizontalTitlePosition + offsetX, y: image.size.height * verticalTitlePosition - textSize.height/2)

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
            verticalTitlePosition: verticalTitlePosition
        )
    }
}
