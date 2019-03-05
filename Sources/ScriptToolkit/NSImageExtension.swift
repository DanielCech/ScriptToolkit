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

    /// Returns a png representation of the current image.
    var PNGRepresentation: Data? {
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

    ///  Saves the PNG representation of the current image to the HD.
    ///
    /// - parameter url: The location url to which to write the png file.
    func savePNGRepresentationToURL(url: URL) throws {
        if let png = self.PNGRepresentation {
            try png.write(to: url, options: .atomicWrite)
        }
    }

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

    func image(withText text: String, attributes: [NSAttributedString.Key: Any]) -> NSImage {
        let image = self
        let text = text as NSString
        let options: NSString.DrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]

        let textSize = text.boundingRect(with: image.size, options: options, attributes: attributes).size

        let x = (image.size.width - textSize.width) / 2
        let y = (image.size.height - textSize.height) / 2
        let point = NSMakePoint(x, y * 0.2)

        image.lockFocus()
        text.draw(at: point, withAttributes: attributes)
        image.unlockFocus()

        return image
    }

    func annotate(text: String, size: CGFloat, fill: NSColor, stroke: NSColor) -> NSImage {

        // Solid color text
        let fillText = image(
            withText: text,
            attributes: [
                .foregroundColor: fill,
                .font: NSFont(name: "Impact", size: size)!
            ])

        // Add strokes
        return fillText.image(
            withText: text,
            attributes: [
                .foregroundColor: fill,
                .strokeColor: stroke,
                .strokeWidth: 1,
                .font: NSFont(name: "Impact", size: size)!
            ])
    }
}

