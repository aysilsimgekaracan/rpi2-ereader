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

/// Represents supported paint colors.
enum PaintColor: UInt8 {
    case black = 0x00
    case gray3 = 0x01
    case gray2 = 0x02
    case gray1 = 0x03
    case white = 0xFF

    /// Alias used by the original C API.
    static let red: PaintColor = .black

    /// Alias for the fourth gray level.
    static let gray4: PaintColor = .black
}

struct GUIPaint {
    private var paint = Paint(
        width: 0,
        height: 0,
        widthMemory: 0,
        heightMemory: 0,
        color: PaintColor,
        rotate: .degrees0,
        mirror: .none,
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
        paint.color = .white
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

    /// Draws a pixel at the specified coordinates.
    /// - Parameter xPoint: At point X, horizontal coordinate of the pixel.
    /// - Parameter yPoint: At point Y, vertical coordinate of the pixel.
    /// - Parameter color: Color to paint
    func paintSetPixel(xPoint: UInt16, yPoint: UInt16, color: PaintColor) {
        guard let image = paint.image else {
            dbg("Image buffer is nil")
            return
        }

        guard xPoint <= paint.width && yPoint <= paint.height else {
            dbg("Exceeding display boundaries")
            return
        }

        var x: UInt16
        var y: UInt16

        switch paint.rotate {
        case .degrees0:
            x = xPoint
            y = yPoint

        case .degrees90:
            x = paint.widthMemory - yPoint - 1
            y = xPoint

        case .degrees180:
            x = paint.widthMemory - xPoint - 1
            y = paint.heightMemory - yPoint - 1

        case .degrees270:
            x = yPoint
            y = paint.heightMemory - xPoint - 1
        }

        switch paint.mirror {
        case .none:
            break

        case .horizontal:
            x = paint.widthMemory - x - 1

        case .vertical:
            y = paint.heightMemory - y - 1
            
        case .origin:
            x = paint.widthMemory - x - 1
            y = paint.heightMemory - y - 1
        }

        guard x <= paint.widthMemory && y <= paint.heightMemory else {
            dbg("Exceeding display boundaries")
            return
        }

        switch paint.scale {
        case .two:
            let addr = Int(x / 8 + y * paint.widthByte)
            let rData = image[addr]
            let mask = UInt8(0x80) >> UInt8(x % 8)

            if color == .black {
                image[addr] = rData & ~mask
            } else {
                image[addr] = rData | mask
            }

        case .four:
            let addr = Int(x / 4 + y * paint.widthByte)
            let colorValue = color.rawValue % 4 // Guaranteed color scale is 4 --- 0~3
            var rData = image[addr]

            let shift = UInt8((x % 4) * 2)
            let mask = UInt8(0xC0) >> shift

            rData = rData & ~mask // Clear first, then set value
            image[addr] = rData | ((colorValue << 6) >> shift)

        case .seven:
            let addr = Int(x / 2 + y * paint.widthByte)
            let colorValue = color.rawValue
            var rData = image[addr]

            let shift = UInt8((x % 2) * 4)
            let mask = UInt8(0xF0) >> shift

            rData = rData & ~mask // Clear first, then set value
            image[addr] = rData | ((colorValue << 4) >> shift)
            dbg("Addr = \(addr), data = \(rData)")
        }
    }

    /// Clears the entire image buffer with the specified color.
    /// - Parameter color: Color used to fill the image buffer.
    func paintClear(color: PaintColor) {
        guard let image = paint.image else { return }

        switch paint.scale {
        case .two, .four:
            for y in 0..<paint.heightByte {
                for x in 0..<paint.widthByte {
                    let addr = Int(x + (y * paint.widthByte))
                    image[addr] = color.rawValue
                }
            }

        case .seven:
            for y in 0..<paint.heightByte {
                for x in 0..<paint.widthByte {
                    let addr = Int(x + (y * paint.widthByte))
                    image[addr] = (color.rawValue<<4) | color.rawValue
                }
            }
        }
    }
}
