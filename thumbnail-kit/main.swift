#!/usr/bin/swift

import Foundation
import CoreGraphics
import Cocoa

class Storage {
    private let thumbnailsDirName = "thumbnails"
    func writeToFile(data: NSData, filePath: String) {
        let localFileURL : NSURL = NSURL(string: filePath)!
        let localFilePathString: NSString = localFileURL.absoluteString as NSString
        let localFilePath: String = localFilePathString.stringByDeletingLastPathComponent
        let fileName: String = localFilePathString.lastPathComponent
        
        let fileURL: NSURL = NSURL(fileURLWithPath: localFilePath + "/" + thumbnailsDirName + "/")
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(fileURL.path!) {
            do {
                try fileManager.createDirectoryAtPath(fileURL.path!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                exit(EXIT_FAILURE)
            }
        }
        let destinationFileURL: NSURL = NSURL(string: fileName, relativeToURL: fileURL)!
        if !data.writeToFile(destinationFileURL.path!, atomically: false) {
            print("Write to file failed")
            exit(EXIT_FAILURE)
        }
        print("Wrote to \(destinationFileURL.path!)")
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
    func createThumbnails(fileName: String, image: NSImage) {
        for size in Size.all {
            let destinationFileName = fileName.fileNameWithoutExtension + size.appendFileName + "." + fileName.fileExtension
            self.resize(with: image, resizeRate: size.scale, fileName: destinationFileName)
        }
    }
    private func resize(with sourceImage: NSImage, resizeRate: Double, fileName: String) {
        let originalSize: NSSize = sourceImage.size
        let thumbnailImageSize: NSSize = NSSize(width: CGFloat(Double(originalSize.width) * resizeRate), height: CGFloat(Double(originalSize.height) * resizeRate))
        let thumbnailImage: NSImage = NSImage(size: thumbnailImageSize)
        thumbnailImage.lockFocus()
        sourceImage.drawInRect(NSMakeRect(0, 0, thumbnailImageSize.width, thumbnailImageSize.height), fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height), operation: NSCompositingOperation.CompositeSourceOver, fraction: 1.0)
        thumbnailImage.unlockFocus()
        thumbnailImage.size = thumbnailImageSize
        let data: NSData = thumbnailImage.TIFFRepresentation!
        self.storage.writeToFile(data, filePath: fileName)
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
        converter.createThumbnails(filename, image: imageData)
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
    print("filepath is incomplete.")
    exit(EXIT_FAILURE)
} else {
    let filename: String = Process.arguments[1]
    Command.execute(filename)
    exit(EXIT_SUCCESS)
}

