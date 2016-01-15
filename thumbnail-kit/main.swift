#!/usr/bin/swift

import Foundation
import CoreGraphics
import Cocoa
import ImageIO

class Storage {
    private let DefaultTempDirName = "thumbnail-kit"
    var url: NSURL?
    init() {
        self.url = createTemporaryDirectory()
    }
    
    func createTemporaryDirectory() -> NSURL? {
        let url: NSURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
        let pathURL : NSURL = url.URLByAppendingPathComponent(DefaultTempDirName)
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.createDirectoryAtURL(pathURL, withIntermediateDirectories: true, attributes: nil)
            return pathURL
        } catch {
            return nil
        }
    }
    
    func writeToFile(image : CGImageRef, filename : String) -> NSData {
        let bitmapRep : NSBitmapImageRep = NSBitmapImageRep(CGImage: image)
        let fileURL : NSURL = NSURL(string: filename, relativeToURL: self.url)!
        let properties = Dictionary<String, AnyObject>()
        let data : NSData = bitmapRep.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: properties)!
        print("write to \(fileURL.absoluteString)")
        if !data.writeToFile(fileURL.path!, atomically: false) {
            print("Write to file failed")
        }
        return data
    }
}

enum Size {
    case Large
    case Middle
    case Small
    var scale: Double {
        switch self {
        case .Large:
            return 1
        case .Middle:
            return 0.66
        case .Small:
            return 0.33
        }
    }
    var appendFileName: String {
        switch self {
        case .Large:
            return "@3x"
        case .Middle:
            return "@2x"
        case .Small:
            return ""
        }
    }
    static let all: [Size] = [.Large, .Middle, .Small]
}

class Converter {
    let storage: Storage = Storage()
    func createThumbnails(fileName: String, image: NSImage, url: NSURL) {
        for size in Size.all {
            let destinationFileName = fileName.fileNameWithoutExtension + size.appendFileName + "." + fileName.fileExtension
            self.createThumbnail(with: image, destinationURL: url, resizeRate: size.scale, fileName: destinationFileName)
        }
    }
    private func createThumbnail(with sourceImage: NSImage, destinationURL: NSURL, resizeRate: Double, fileName: String) {
        guard let image = NSBitmapImageRep(data: sourceImage.TIFFRepresentation!)?.CGImage else {
            print("Can't read bitmap from image.")
            exit(EXIT_FAILURE)
        }
        if resizeRate == 1.0 {
            self.storage.writeToFile(image, filename: fileName)
        } else {
            let width = Double(CGImageGetWidth(image)) * resizeRate
            let height = Double(CGImageGetHeight(image)) * resizeRate
            let bitsPerComponent = CGImageGetBitsPerComponent(image)
            let bytesPerRow = CGImageGetBytesPerRow(image)
            let colorSpace = CGImageGetColorSpace(image)
            let bitmapInfo = CGImageAlphaInfo.PremultipliedLast
            guard let context: CGContextRef = CGBitmapContextCreate(nil, Int(width), Int(height), bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue) else {
                print("Can't create bitmap context.")
                exit(EXIT_FAILURE)
            }
            CGContextSetAllowsAntialiasing(context, true)
            CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
            CGContextDrawImage(context, CGRect(origin: CGPointZero, size: CGSize(width: CGFloat(width), height: CGFloat(height))), image)
            let newImageRef: CGImage? = CGBitmapContextCreateImage(context)
            self.storage.writeToFile(newImageRef!, filename: fileName)
        }
    }
}

class Command {
    static func execute(filename: String) {
        let path: NSString =  NSString(string: filename)
        let expandedPath = path.stringByExpandingTildeInPath
        let data: NSData? = NSData(contentsOfFile: expandedPath)
        guard let fileData = data else {
            print("Can't read local file.")
            exit(EXIT_FAILURE)
        }
        let image: NSImage? = NSImage(data: fileData)
        guard let imageData = image else {
            print("Can't convert to NSImage")
            exit(EXIT_FAILURE)
        }
        let converter: Converter = Converter()
        converter.createThumbnails(filename, image: imageData, url: converter.storage.url!)
    }
}

extension String {
    var fileExtension: String {
        return self.componentsSeparatedByString(".").last!
    }
    var fileNameWithoutExtension: String {
        return self.componentsSeparatedByString(".").first!
    }
}

if Process.arguments.count < 2 {
    print("filename is incomplete.")
    exit(EXIT_FAILURE)
} else {
    let filename: String = Process.arguments[1]
    Command.execute(filename)
    print("wrote to \(filename)")
    exit(EXIT_SUCCESS)
}

