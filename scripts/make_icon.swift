#!/usr/bin/env swift
// Generates app icon and launch screen W images.
// Run from repo root:  swift scripts/make_icon.swift

import AppKit
import CoreGraphics

// MARK: - Helper

func renderW(canvasSize: Int, fontSize: CGFloat, outputPath: String) {
    let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: canvasSize,
        pixelsHigh: canvasSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)!

    NSColor.black.setFill()
    NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize).fill()

    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let letter = "W" as NSString
    let letterSize = letter.size(withAttributes: attrs)
    let x = (CGFloat(canvasSize) - letterSize.width)  / 2
    let y = (CGFloat(canvasSize) - letterSize.height) / 2 - letterSize.height * 0.04
    letter.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG for \(outputPath)"); exit(1)
    }
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Wrote \(outputPath) (\(canvasSize)×\(canvasSize))")
    } catch {
        print("Write failed: \(error)"); exit(1)
    }
}

// MARK: - App Icon (1024×1024)

renderW(
    canvasSize: 1024,
    fontSize: 640,
    outputPath: "Wanderlore/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
)

// MARK: - Launch Screen W (200 pt logical size → 1×/2×/3× PNGs)
// UILaunchScreen centers the image at its natural point size.
// At 200 pt the W is visually large on every device without overflowing.

let launchBase = "Wanderlore/Resources/Assets.xcassets/LaunchW.imageset/LaunchW"
renderW(canvasSize: 200, fontSize: 130, outputPath: "\(launchBase)@1x.png")
renderW(canvasSize: 400, fontSize: 260, outputPath: "\(launchBase)@2x.png")
renderW(canvasSize: 600, fontSize: 390, outputPath: "\(launchBase)@3x.png")
