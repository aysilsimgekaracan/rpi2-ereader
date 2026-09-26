//
//  GUIPaint.swift
//  rpi2-ereader
//
//  Created by Ayşıl Simge Karacan on 26.09.2026.
//

struct Paint {
    var image: UnsafeMutablePointer<UInt8>?
    var width: UInt16
    var height: UInt16
    var widthMemory: UInt16
    var heightMemory: UInt16
    var color: UInt16
    var rotate: RotateImage
    var mirror: MirrorImage
    var widthByte: UInt16
    var heightByte: UInt16
    var scale: PaintScale?
}

/// Defines the image rotation angle.
enum RotateImage: UInt16 {
    case degrees0 = 0
    case degrees90 = 90
    case degrees180 = 180
    case degrees270 = 270
}

/// Defines how the image is mirrored.
enum MirrorImage: UInt8 {
    case none = 0x00
    case horizontal = 0x01
    case vertical = 0x02
    case origin = 0x03
}

/// Defines the supported pixel scales.
enum PaintScale: UInt8 {
  case two = 2
  case four = 4
  case seven = 7
}

struct GUIPaint {
    private var paint = Paint(
        width: 0,
        height: 0,
        widthMemory: 0,
        heightMemory: 0,
        color: 0,
        rotate: .degrees0,
        mirror: 0,
        widthByte: 0,
        heightByte: 0
    )

    /// Create Image
    /// - Parameter image: Pointer to the image cache
    /// - Parameter width: The width of the picture
    /// - Parameter height: The height of the picture
    /// - Parameter color: Whether the picture is inverted
    func paintNewImage(image: UnsafeMutablePointer<UInt8>?, width: UInt16, height: UInt16, rotate: RotateImage, color: UInt16) {
        paint.image = nil
        paint.image = image

        paint.widthMemory = width
        paint.heightMemory = height
        paint.color = color
        paint.scale = 2

        paint.widthByte = (width % 8 == 0) ? (width / 8 ) : (width / 8 + 1)
        paint.heightByte = height
        dgb("widthByte: \(paint.widthByte), heightByte: \(paint.heightByte)")

        paint.rotate = rotate
        paint.mirror = MirrorImage.none

        if (rotate == .degrees0 || rotate == .degrees180) {
            paint.width = width
            paint.height = height
        } else {
            paint.width = height
            paint.height = width
        }
    }

    /// Select Image
    /// - Parameter image: Pointer to the image cache
    func paintSelectImage(image: UnsafeMutablePointer<UInt8>?) {
        paint.image = image
    }

    /// Select Image Rotate
    /// - Parameter rotate: 0, 90, 180, 270
    func paintSetRotate(rotate: RotateImage) {
        paint.rotate = rotate
    }

    /// Select Imgage Mirror
    ///  - Parameter mirror: none, horizontal, origin, vertical
    func paintSetMirroring(mirror: MirrorImage) {
        paint.mirror = mirror
    }

    /// Sets the paint scale and recalculates the row width.
    ///
    /// - Parameter scale: A supported paint scale.
    func setScale(_ scale: PaintScale) {
      paint.scale = scale

      switch scale {
      case .two:
        paint.widthByte = paint.widthMemory % 8 == 0
          ? paint.widthMemory / 8
          : paint.widthMemory / 8 + 1

      case .four:
        paint.widthByte = paint.widthMemory % 4 == 0
          ? paint.widthMemory / 4
          : paint.widthMemory / 4 + 1

      case .seven:
        paint.widthByte = paint.widthMemory % 2 == 0
          ? paint.widthMemory / 2
          : paint.widthMemory / 2 + 1
      }
    }

}
