//
//  FablerImage.swift
//  Fabler
//
//  Created by Christopher Day on 12/13/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import CoreGraphics
import Foundation
import UIKit
import CoreImage

extension UIImage {
    //
    // Original source from AlamofireImage, Release 2.1.1
    //
    //    Copyright (c) 2015 Alamofire Software Foundation (http://alamofire.org/)
    //
    //    Permission is hereby granted, free of charge, to any person obtaining a copy
    //    of this software and associated documentation files (the "Software"), to deal
    //    in the Software without restriction, including without limitation the rights
    //    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    //    copies of the Software, and to permit persons to whom the Software is
    //    furnished to do so, subject to the following conditions:
    //
    //    The above copyright notice and this permission notice shall be included in
    //    all copies or substantial portions of the Software.
    //
    //    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    //    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    //    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    //    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    //    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    //    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    //    THE SOFTWARE.
    //
    public func imageWithAppliedCoreImageFilter(filterName: String, filterParameters: [String: AnyObject]? = nil) -> UIImage? {
        var image: CoreImage.CIImage? = CIImage

        if image == nil, let CGImage = self.CGImage {
            image = CoreImage.CIImage(CGImage: CGImage)
        }

        guard let coreImage = image else { return nil }

        let context = CIContext(options: [kCIContextPriorityRequestLow: true])

        var parameters: [String: AnyObject] = filterParameters ?? [:]
        parameters[kCIInputImageKey] = coreImage

        guard let filter = CIFilter(name: filterName, withInputParameters: parameters) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        let cgImageRef = context.createCGImage(outputImage, fromRect: coreImage.extent)

        return UIImage(CGImage: cgImageRef, scale: scale, orientation: imageOrientation)
    }
}
