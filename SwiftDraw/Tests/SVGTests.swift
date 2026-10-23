//
//  SVGTests.swift
//  SwiftDraw
//
//  Created by Simon Whitty on 19/11/18.
//  Copyright 2020 Simon Whitty
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/swhitty/SwiftDraw
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import SwiftDrawDOM
@testable import SwiftDraw
import Testing

#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit) || canImport(UIKit)
struct SVGTests {

    @Test
    func validSVGLoads() {
        #expect(SVG(named: "lines.svg", in: .test) != nil)
    }

    @Test
    func invalidSVGReturnsNil() {
        #expect(SVG(named: "invalids.svg", in: .test) == nil)
    }

    @Test
    func missingSVGReturnsNil() {
        #expect(SVG(named: "missing.svg", in: .test) == nil)
    }

    @Test
    func root_em_ex_dimensions_parse_as_raw_values() {
        let ex = #"<svg xmlns="http://www.w3.org/2000/svg" width="2ex" height="1ex"><rect width="5" height="5"/></svg>"#
        let em = #"<svg xmlns="http://www.w3.org/2000/svg" width="2em" height="1em"><rect width="5" height="5"/></svg>"#
        let px = #"<svg xmlns="http://www.w3.org/2000/svg" width="2px" height="1px"><rect width="5" height="5"/></svg>"#

        let exSVG = SVG(data: Data(ex.utf8))
        let emSVG = SVG(data: Data(em.utf8))
        let pxSVG = SVG(data: Data(px.utf8))

        #expect(exSVG?.size == CGSize(width: 2, height: 1))
        #expect(emSVG?.size == CGSize(width: 2, height: 1))
        #expect(pxSVG?.size == CGSize(width: 2, height: 1))
    }

    @Test(arguments: ["objectBoundingBox", "userSpaceOnUse"], ["objectBoundingBox", "userSpaceOnUse"])
    func patternUnitsAndContentUnitsAreIndependent(patternUnits: String, contentUnits: String) throws {
        let tileWidth = patternUnits == "objectBoundingBox" ? "0.5" : "20"
        let tileHeight = patternUnits == "objectBoundingBox" ? "1" : "20"
        let contentWidth = contentUnits == "objectBoundingBox" ? "0.25" : "10"
        let contentHeight = contentUnits == "objectBoundingBox" ? "1" : "20"
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="20">
            <defs>
                <pattern id="p" width="\(tileWidth)" height="\(tileHeight)"
                         patternUnits="\(patternUnits)" patternContentUnits="\(contentUnits)">
                    <rect width="\(contentWidth)" height="\(contentHeight)" fill="red"/>
                </pattern>
            </defs>
            <rect width="40" height="20" fill="url(#p)"/>
        </svg>
        """)

        #expect(pixels.pixel(x: 5, y: 10) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 15, y: 10) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 25, y: 10) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 35, y: 10) == [0, 0, 0, 0])
    }

    @Test
    func patternDefaultsUseBoundingBoxTilesAndUserSpaceContents() throws {
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="20">
            <defs>
                <pattern id="p" width="0.5" height="1">
                    <rect width="10" height="20" fill="red"/>
                </pattern>
            </defs>
            <rect width="40" height="20" fill="url(#p)"/>
        </svg>
        """)

        #expect(pixels.pixel(x: 5, y: 10) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 15, y: 10) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 25, y: 10) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 35, y: 10) == [0, 0, 0, 0])
    }

    @Test(arguments: [1, 2, 3])
    func patternBoundingBoxContentsUseShapeOriginAndDimensions(scale: Int) throws {
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="60" height="40">
            <defs>
                <pattern id="p" width="1" height="1" patternContentUnits="objectBoundingBox">
                    <rect width="0.5" height="0.5" fill="red"/>
                </pattern>
            </defs>
            <rect x="10" y="10" width="40" height="20" fill="url(#p)"/>
        </svg>
        """, scale: scale)

        #expect(pixels.pixel(x: 25, y: 15) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 40, y: 15) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 25, y: 25) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 5, y: 15) == [0, 0, 0, 0])
    }

    @Test(arguments: ["objectBoundingBox", "userSpaceOnUse"])
    func patternTileOriginOffsetsUserSpaceContents(patternUnits: String) throws {
        let usesBoundingBox = patternUnits == "objectBoundingBox"
        let tileX = usesBoundingBox ? "0.125" : "5"
        let tileY = usesBoundingBox ? "0.15" : "3"
        let tileWidth = usesBoundingBox ? "0.5" : "20"
        let tileHeight = usesBoundingBox ? "1" : "20"
        let shapeWidth = usesBoundingBox ? "40" : "60"
        let shapeHeight = usesBoundingBox ? "20" : "40"
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="80" height="60">
            <defs>
                <pattern id="p" x="\(tileX)" y="\(tileY)" width="\(tileWidth)" height="\(tileHeight)"
                         patternUnits="\(patternUnits)">
                    <rect width="10" height="10" fill="red"/>
                </pattern>
            </defs>
            <rect width="\(shapeWidth)" height="\(shapeHeight)" fill="url(#p)"/>
        </svg>
        """)

        #expect(pixels.pixel(x: 7, y: 5) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 12, y: 5) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 27, y: 5) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 2, y: 5) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 17, y: 5) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 22, y: 5) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 7, y: 1) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 7, y: 15) == [0, 0, 0, 0])
    }

    @Test(arguments: [false, true])
    func patternUserSpaceTilesKeepBoundingBoxContentOrigin(hasTileOffset: Bool) throws {
        let tileX = hasTileOffset ? "5" : "0"
        let tileY = hasTileOffset ? "3" : "0"
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="60" height="40">
            <defs>
                <pattern id="p" x="\(tileX)" y="\(tileY)" width="20" height="20"
                         patternUnits="userSpaceOnUse" patternContentUnits="objectBoundingBox">
                    <rect width="0.25" height="0.5" fill="red"/>
                </pattern>
            </defs>
            <rect x="10" y="10" width="40" height="20" fill="url(#p)"/>
        </svg>
        """)
        let redPixels = hasTileOffset ? [(12, 11), (27, 11), (12, 25), (27, 25)] : [(25, 25), (45, 25)]
        let clearPixels = hasTileOffset ? [(17, 11), (27, 15), (27, 21)] : [(15, 15), (25, 15), (15, 25)]

        for (x, y) in redPixels {
            #expect(pixels.pixel(x: x, y: y) == [255, 0, 0, 255])
        }
        for (x, y) in clearPixels {
            #expect(pixels.pixel(x: x, y: y) == [0, 0, 0, 0])
        }
    }

    @Test
    func patternCanBeReusedForShapesWithDifferentBounds() throws {
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="60">
            <defs>
                <pattern id="p" width="1" height="1" patternContentUnits="objectBoundingBox">
                    <rect width="0.5" height="0.5" fill="red"/>
                </pattern>
            </defs>
            <rect x="10" y="10" width="20" height="20" fill="url(#p)"/>
            <rect x="50" y="10" width="40" height="40" fill="url(#p)"/>
        </svg>
        """)

        #expect(pixels.pixel(x: 15, y: 15) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 25, y: 15) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 15, y: 25) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 65, y: 25) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 75, y: 25) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 65, y: 45) == [0, 0, 0, 0])
    }

    @Test(arguments: [
        ("", false),
        (#"mask-type="luminance""#, false),
        (#"mask-type="alpha""#, true),
        (#"style="mask-type:alpha""#, true),
        (#"mask-type="luminance" style="mask-type:alpha""#, true)
    ])
    func maskTypeControlsOpacity(attributes: String, isAlpha: Bool) throws {
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20">
            <mask id="m" \(attributes)>
                <rect width="20" height="20" fill="black"/>
            </mask>
            <rect width="20" height="20" fill="#24344B" mask="url(#m)"/>
        </svg>
        """)
        #expect(pixels.pixel(x: 10, y: 10) == (isAlpha ? [36, 52, 75, 255] : [0, 0, 0, 0]))
    }

    @Test
    func maskTypeUsesStylesheet() throws {
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20">
            <style>mask { mask-type: alpha; }</style>
            <mask id="m" mask-type="luminance">
                <rect width="20" height="20" fill="black"/>
            </mask>
            <rect width="20" height="20" fill="#24344B" mask="url(#m)"/>
        </svg>
        """)
        #expect(pixels.pixel(x: 10, y: 10) == [36, 52, 75, 255])
    }

    @Test(arguments: ["", "none", "xMaxYMin meet"])
    func viewBoxPreservesAspectRatioAndAlignment(mode: String) throws {
        let attribute = mode.isEmpty ? "" : "preserveAspectRatio=\"\(mode)\""
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="20"
             viewBox="10 20 20 20" \(attribute)>
            <rect x="10" y="20" width="20" height="20" fill="red"/>
        </svg>
        """)
        #expect(pixels.pixel(x: 5, y: 10) == (mode == "none" ? [255, 0, 0, 255] : [0, 0, 0, 0]))
        #expect(pixels.pixel(x: 15, y: 10) == (mode == "xMaxYMin meet" ? [0, 0, 0, 0] : [255, 0, 0, 255]))
        #expect(pixels.pixel(x: 25, y: 10) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 35, y: 10) == (mode.isEmpty ? [0, 0, 0, 0] : [255, 0, 0, 255]))
    }

    @Test
    func viewBoxAlignsVertically() throws {
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="40"
             viewBox="0 0 20 20" preserveAspectRatio="xMinYMax meet">
            <rect width="20" height="20" fill="red"/>
        </svg>
        """)
        #expect(pixels.pixel(x: 10, y: 5) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 10, y: 25) == [255, 0, 0, 255])
    }

    @Test(arguments: ["xMidYMid meet", "xMidYMid slice"])
    func nestedViewBoxClipsToViewport(mode: String) throws {
        let pixels = try RasterizedSVG(xml: """
        <svg xmlns="http://www.w3.org/2000/svg" width="60" height="40">
            <svg x="10" y="10" width="40" height="20" viewBox="0 0 20 20"
                 preserveAspectRatio="\(mode)">
                <rect x="-10" width="40" height="20" fill="red"/>
            </svg>
        </svg>
        """)
        #expect(pixels.pixel(x: 30, y: 5) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 30, y: 35) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 5, y: 15) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 55, y: 15) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 15, y: 15) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 45, y: 15) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 30, y: 25) == [255, 0, 0, 255])
    }

    @Test
    func imageRasterizes() {
        let image = SVG.makeLines()
        let rendered = image.rasterize(scale: 1)
        #expect(rendered.size == image.size)
        #expect(throws: Never.self) {
            try image.pngData()
        }
        #expect(throws: Never.self) {
            try image.jpegData()
        }
        #expect(throws: Never.self) {
            try image.pdfData()
        }
    }

    @Test
    func shapesImageRasterizes() throws {
        let image = try #require(SVG(named: "shapes.svg", in: .test))
        #expect(throws: Never.self) {
            try image.pngData()
        }
        #expect(throws: Never.self) {
            try image.jpegData()
        }
        #expect(throws: Never.self) {
            try image.pdfData()
        }
    }

#if canImport(UIKit)
    @Test(arguments: [1, 2, 3])
    func patternRasterizesWithUIKitAtImageScale(scale: Int) throws {
        let reference = try #require(SVG(data: Data("""
        <svg xmlns="http://www.w3.org/2000/svg" width="60" height="40">
            <rect x="10" y="10" width="20" height="10" fill="red"/>
        </svg>
        """.utf8)))
        let referenceImage = reference.rasterize(size: reference.size, scale: CGFloat(scale))
        let referencePixels = try RasterizedSVG(cgImage: #require(referenceImage.cgImage), scale: scale)
        #expect(referencePixels.pixel(x: 25, y: 15) == [255, 0, 0, 255])
        #expect(referencePixels.pixel(x: 40, y: 15) == [0, 0, 0, 0])
        #expect(referencePixels.pixel(x: 25, y: 25) == [0, 0, 0, 0])

        let svg = try #require(SVG(data: Data("""
        <svg xmlns="http://www.w3.org/2000/svg" width="60" height="40">
            <defs>
                <pattern id="p" width="1" height="1" patternContentUnits="objectBoundingBox">
                    <rect width="0.5" height="0.5" fill="red"/>
                </pattern>
            </defs>
            <rect x="10" y="10" width="40" height="20" fill="url(#p)"/>
        </svg>
        """.utf8)))
        let image = svg.rasterize(size: svg.size, scale: CGFloat(scale))
        let pixels = try RasterizedSVG(cgImage: #require(image.cgImage), scale: scale)
        #expect(image.scale == CGFloat(scale))
        #expect(pixels.pixel(x: 25, y: 15) == [255, 0, 0, 255])
        #expect(pixels.pixel(x: 40, y: 15) == [0, 0, 0, 0])
        #expect(pixels.pixel(x: 25, y: 25) == [0, 0, 0, 0])
    }

    @Test
    func rasterize() {
        let svg = SVG(named: "gradient-apple.svg", in: .test)!
            .sized(CGSize(width: 100, height: 100))
        let image = svg.rasterize(scale: 3)
        #expect(image.size == CGSize(width: 100, height: 100))
        #expect(image.scale == 3)

        let data = image.pngData()!
        let reloaded = UIImage(data: data)!
        #expect(reloaded.size == CGSize(width: 300, height: 300))
        #expect(reloaded.scale == 1)
    }
#endif

    @Test
    func size() {
        let image = SVG.makeLines()

        #expect(
            image.size == CGSize(width: 100, height: 100)
        )
        #expect(
            image.sized(CGSize(width: 200, height: 200)).size == CGSize(width: 200, height: 200)
        )

        var copy = image
        copy.size(CGSize(width: 20, height: 20))
        #expect(
            copy.size == CGSize(width: 20, height: 20)
        )
    }

    @Test
    func scale() {
        let image = SVG.makeLines()

        #expect(
            image.size == CGSize(width: 100, height: 100)
        )
        #expect(
            image.scaled(2).size == CGSize(width: 200, height: 200)
        )
        #expect(
            image.scaled(0.5).size == CGSize(width: 50, height: 50)
        )
        #expect(
            image.scaled(x: 2, y: 3).size == CGSize(width: 200, height: 300)
        )

        var copy = image
        copy.scale(5)
        #expect(
            copy.size == CGSize(width: 500, height: 500)
        )
    }

    @Test
    func translate() {
        let image = SVG.makeLines()

        #expect(
            image.size == CGSize(width: 100, height: 100)
        )
        #expect(
            image.translated(tx: 10, ty: 10).size == CGSize(width: 100, height: 100)
        )

        var copy = image
        copy.translate(tx: 50, ty: 50)
        #expect(
            copy.size == CGSize(width: 100, height: 100)
        )
    }

    @Test
    func expand() {
        let image = SVG.makeLines()

        #expect(
            image.size == CGSize(width: 100, height: 100)
        )
        #expect(
            image.expanded(top: 50, right: 30).size == CGSize(width: 130, height: 150)
        )

        var copy = image
        copy.expand(-10)
        #expect(
            copy.size == CGSize(width: 80, height: 80)
        )
    }

    @Test
    func hashable() {
        var images = Set<SVG>()
        let lines = SVG.makeLines()

        #expect(!images.contains(lines))

        images.insert(SVG.makeLines())
        #expect(images.contains(lines))

        let linesResized = lines.sized(CGSize(width: 10, height: 10))
        #expect(!images.contains(linesResized))

        images.remove(lines)
        #expect(!images.contains(SVG.makeLines()))
    }

    @Test
    func deepNestedSVG() async {
        let circle = DOM.Circle(cx: 50, cy: 50, r: 10)
        let dom = DOM.SVG(width: 50, height: 50)
        dom.childElements.append(DOM.Group.make(child: circle, nestedLevels: 500))

        _ = SVG(dom: dom, options: .default)
    }

    @Test
    func cache() {
        let cache = SVGGCache(totalCostLimit: 10 * 1024 * 1024)
        let svg = SVG.makeLines()
        let url = URL(fileURLWithPath: "/test/cached.svg")

        // Initially empty
        #expect(cache.svg(fileURL: url) == nil)

        // Store and retrieve
        cache.setSVG(svg, for: url)
        #expect(cache.svg(fileURL: url) != nil)

        // Different URL returns nil
        let otherURL = URL(fileURLWithPath: "/test/other.svg")
        #expect(cache.svg(fileURL: otherURL) == nil)
    }

    @Test
    func cacheSharedInstance() {
        let shared = SVGGCache.shared
        #expect(shared === SVGGCache.shared)
    }

    @Test
    func insets() {
        let zero = SVG.Insets.zero
        #expect(zero.top == 0)
        #expect(zero.left == 0)
        #expect(zero.bottom == 0)
        #expect(zero.right == 0)

        let custom = SVG.Insets(top: 10, left: 20, bottom: 30, right: 40)
        #expect(custom.top == 10)
        #expect(custom.left == 20)
        #expect(custom.bottom == 30)
        #expect(custom.right == 40)

        #expect(SVG.Insets.zero == SVG.Insets(top: 0, left: 0, bottom: 0, right: 0))
        #expect(SVG.Insets.zero != custom)
    }

    @Test
    func defaultCostLimit() {
        let limit = SVGGCache.defaultTotalCostLimit
        #expect(limit > 0)
    }
}

private struct RasterizedSVG {
    private let data: Data
    private let bytesPerRow: Int
    private let scale: Int

    init(xml: String, scale: Int = 1) throws {
        let svg = try #require(SVG(data: Data(xml.utf8)))
        let width = Int(svg.size.width) * scale
        let height = Int(svg.size.height) * scale
        let context = try Self.makeContext(width: width, height: height)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
        context.draw(svg)

        let bytes = try #require(context.data)
        self.bytesPerRow = context.bytesPerRow
        self.data = Data(bytes: bytes, count: context.bytesPerRow * height)
        self.scale = scale
    }

    init(cgImage: CGImage, scale: Int) throws {
        let context = try Self.makeContext(width: cgImage.width, height: cgImage.height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))

        let bytes = try #require(context.data)
        self.bytesPerRow = context.bytesPerRow
        self.data = Data(bytes: bytes, count: context.bytesPerRow * cgImage.height)
        self.scale = scale
    }

    func pixel(x: Int, y: Int) -> [UInt8] {
        let offset = y * scale * bytesPerRow + x * scale * 4
        return Array(data[offset..<(offset + 4)])
    }

    private static func makeContext(width: Int, height: Int) throws -> CGContext {
        let context = try #require(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ))
        context.clear(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        return context
    }
}

private extension SVG {

    static func makeLines() -> SVG {
        let svg = DOM.SVG(width: 100, height: 100)
        svg.childElements.append(DOM.Line(x1: 0, y1: 0, x2: 100, y2: 100))
        svg.childElements.append(DOM.Line(x1: 100, y1: 0, x2: 0, y2: 100))
        return SVG(dom: svg, options: .default)
    }
}
#endif
