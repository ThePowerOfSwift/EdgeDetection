//
//  EdgeDetectionController.swift
//  App
//
//  Created by Animesh Sen on 4/17/18.
//

import Cocoa

class EdgeDetectionController: NSObject {
    
    func detectEdge(imageStr: String) -> String {
        let url = URL(string: "data:image/png;base64," + imageStr)
        guard let data = try? Data(contentsOf: url!) else {
            return "Error: Unable to convert to data"
        }
        guard let image = NSImage(data: data) else {
            return "Error: Unable to extract NSImage from Data"
        }
        
        let ciImageData = image.tiffRepresentation!
        let ciImage = CIImage(data: ciImageData)
        
        let detectedImage = self.performRectangleDetection(image: ciImage!)
        
        let rep: NSCIImageRep = NSCIImageRep(ciImage: detectedImage!)
        let nsImage: NSImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        var tiffData: NSData = nsImage.tiffRepresentation! as NSData
        let bitmap: NSBitmapImageRep = NSBitmapImageRep(data: tiffData as Data)!
        tiffData = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:])! as NSData
        let base64 = tiffData.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithCarriageReturn)
        
        return base64
    }
    
    func performRectangleDetection(image: CIImage) -> CIImage? {
        var resultImage: CIImage?
        resultImage = image
        let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.6])
        
        // Get the detections
        var halfPerimiterValue = 0.0 as Float;
        let features = detector?.features(in: image)
        print("feature \(String(describing: features?.count))")
        for feature in features as! [CIRectangleFeature] {
            
            let p1 = feature.topLeft
            let p2 = feature.topRight
            let width = hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y));
            //NSLog(@"xaxis    %@", @(p1.x));
            //NSLog(@"yaxis    %@", @(p1.y));
            let p3 = feature.topLeft
            let p4 = feature.bottomLeft
            let height = hypotf(Float(p3.x - p4.x), Float(p3.y - p4.y));
            let currentHalfPerimiterValue = height+width;
            if (halfPerimiterValue < currentHalfPerimiterValue)
            {
                halfPerimiterValue = currentHalfPerimiterValue
                resultImage = cropBusinessCardForPoints(image: image, topLeft: feature.topLeft, topRight: feature.topRight,
                                                        bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
                print("perimmeter   \(halfPerimiterValue)")
            }
            
        }
        
        return resultImage
    }
    
    func cropBusinessCardForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        
        var businessCard: CIImage
        businessCard = image.applyingFilter(
            "CIPerspectiveTransformWithExtent",
            parameters: [
                "inputExtent": CIVector(cgRect: image.extent),
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight)])
        businessCard = image.cropped(to: businessCard.extent)
        
        return businessCard
    }
}
