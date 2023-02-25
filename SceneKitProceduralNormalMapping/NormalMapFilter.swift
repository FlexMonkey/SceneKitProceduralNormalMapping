//
//  NormalMapFilter.swift
//  SceneKitProceduralNormalMapping
//
//  Created by Simon Gladman on 11/04/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import CoreImage


class NormalMapFilter: CIFilter
{
    @objc dynamic var inputImage: CIImage?

    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "Normap Map",

            "inputImage": [kCIAttributeIdentity: 0,
                              kCIAttributeClass: "CIImage",
                        kCIAttributeDisplayName: "Image",
                               kCIAttributeType: kCIAttributeTypeImage]
        ]
    }

    // @FIXME: Rewrite with Metal Shading Language
    let normalMapKernel = CIKernel(source:
                                    "float lumaAtOffset(sampler source, vec2 origin, vec2 offset)" +
                                   "{" +
                                   " vec3 pixel = sample(source, samplerTransform(source, origin + offset)).rgb;" +
                                   " float luma = dot(pixel, vec3(0.2126, 0.7152, 0.0722));" +
                                   " return luma;" +
                                   "}" +


                                   "kernel vec4 normalMap(sampler image) \n" +
                                   "{ " +
                                   " vec2 d = destCoord();" +

                                   " float northLuma = lumaAtOffset(image, d, vec2(0.0, -1.0));" +
                                   " float southLuma = lumaAtOffset(image, d, vec2(0.0, 1.0));" +
                                   " float westLuma = lumaAtOffset(image, d, vec2(-1.0, 0.0));" +
                                   " float eastLuma = lumaAtOffset(image, d, vec2(1.0, 0.0));" +

                                   " float horizontalSlope = ((westLuma - eastLuma) + 1.0) * 0.5;" +
                                   " float verticalSlope = ((northLuma - southLuma) + 1.0) * 0.5;" +


                                   " return vec4(horizontalSlope, verticalSlope, 1.0, 1.0);" +
                                   "}"
    )

    override var outputImage: CIImage?
    {
        guard let inputImage = inputImage,
              let normalMapKernel = normalMapKernel else
        {
            return nil
        }

        return normalMapKernel.apply(extent: inputImage.extent,
                                     roiCallback:
                                        {
            (index, rect) in
            return rect
        },
                                     arguments: [inputImage])
    }
}

class CustomFiltersVendor: NSObject, CIFilterConstructor
{
    static func registerFilters()
    {
        CIFilter.registerName("NormalMap",
                              constructor: CustomFiltersVendor(),
                              classAttributes: [
                                kCIAttributeFilterCategories: ["CustomFilters"]
                              ])
    }

    func filter(withName name: String) -> CIFilter?
    {
        switch name
        {
        case "NormalMap":
            return NormalMapFilter()

        default:
            return nil
        }
    }
}

