//
//  Main.swift
//  rpi2-ereader
//
//  Created by Ayşıl Simge Karacan on 19.09.2026.
//

@main
struct Main {
  // Pins
    static let RST:  UInt32 = 12
    static let DC:   UInt32 = 8
    static let CS:   UInt32 = 9
    static let BUSY: UInt32 = 13
    static let LED:  UInt32 = 25
    static let PWR: UInt32 = 18

    static let EPD_HEIGHT = 480
    static let EPD_WIDTH = 800
    static let bytesPerRow = (EPD_WIDTH + 7) / 8

    static func gpioOut(_ p: UInt32) { gpio_init(p); gpio_set_dir(p, true) }
    static func gpioIn(_ p: UInt32)  { gpio_init(p); gpio_set_dir(p, false) }

    /// Send Command
    /// - Parameter c: Command Register
    static func sendCommand(_ c: UInt8) {
        gpio_put(DC, false)
        gpio_put(CS, false)
        epd_spi_write(c)
        gpio_put(CS, true)
    }

    /// Send Data
    /// - Parameter d: Write data
    static func sendData(_ d: UInt8) {
        gpio_put(DC, true)
        gpio_put(CS, false)
        epd_spi_write(d)
        gpio_put(CS, true)
    }

    static func sendData(_ buf: [UInt8]) {
        gpio_put(DC, true)
        gpio_put(CS, false)
        buf.withUnsafeBufferPointer { p in
            epd_spi_write_buf(p.baseAddress, p.count)
        }
        gpio_put(CS, true)
    }

    /// Software Reset
    static func reset() {
        gpio_put(RST, true)
        sleep_ms(20)
        gpio_put(RST, false)
        sleep_ms(2)
        gpio_put(RST, true)
        sleep_ms(20)
    }

    /// Wait until the busy_pin goes LOW
    static func waitUntilIdle() {
        dbg("busy\r\n")

        repeat {
        sleep_ms(5)
        } while gpio_get(BUSY) == false

        sleep_ms(5)
        dbg("busy release\r\n")
    }

    /// Initialize the e-Paper register
    static func epdInit() {
        reset()
        sendCommand(0x01) // POWER SETTING
        sendData(0x07)
        sendData(0x07)  // VGH=20V,VGL=-20V
        sendData(0x3f) // VDH=15V
        sendData(0x3f) // VDL=-15V

        //Enhanced display drive(Add 0x06 command)
        sendCommand(0x06) //Booster Soft Start
        sendData(0x17)
        sendData(0x17)
        sendData(0x28)
        sendData(0x17)

        sendCommand(0x04) // POWER ON
        sleep_ms(100)
        waitUntilIdle() // waiting for the electronic paper IC to release the idle signal
        //sleep_ms(2000)

        sendCommand(0x00) // PANNEL SETTING
        sendData(0x1F) //KW-3f   KWR-2F	BWROTP 0f	BWOTP 1f

        sendCommand(0x61) // tres
        sendData(0x03) // source 800
        sendData(0x20)
        sendData(0x01) // gate 480
        sendData(0xE0)

        sendCommand(0x15)
        sendData(0x00)

        // If the screen appears gray, use the annotated initialization command
        sendCommand(0x50)
        sendData(0x10)
        sendData(0x07)
        sendCommand(0x60) // TCON SETTING
        sendData(0x22)
    }

    static func sendBlock(_ p: UnsafeMutableBufferPointer<UInt8>) {
        gpio_put(DC, true)
        gpio_put(CS, false)
        epd_spi_write_buf(p.baseAddress, p.count)
        gpio_put(CS, true)
    }

    /// Clear/Fill screen
    /// 0x00 = white, 0xFF = black
    static func epdFill(_ v: UInt8) {
    let n = bytesPerRow
    withUnsafeTemporaryAllocation(of: UInt8.self, capacity: n) { row in
        for i in 0..<n { row[i] = 0xFF }
        sendCommand(0x10)
        for _ in 0..<EPD_HEIGHT { sendBlock(row) }

        for i in 0..<n { row[i] = v }
        sendCommand(0x13)
        for _ in 0..<EPD_HEIGHT { sendBlock(row) }
    }
    sendCommand(0x12)
    sleep_ms(100)
    waitUntilIdle()
    //sleep_ms(2000)
}

    static func main() {
        stdio_init_all()
        
        gpioOut(LED)
        gpioOut(PWR)
        gpio_put(PWR, true)
        sleep_ms(10)
        
        gpioOut(RST)
        gpioOut(DC)
        gpioOut(CS)
        gpioIn(BUSY)
        
        gpio_put(CS, true)
        
        epd_spi_init()
        dbg("start\r\n")
        
        gpio_put(LED, true)
        epdInit()
        dbg("init done\r\n")

        epdFill(0xFF)
        dbg("fill done\r\n")

        gpio_put(LED, false)

        while true {
            gpio_put(LED, true);  sleep_ms(500)
            gpio_put(LED, false); sleep_ms(500)
        }
    }
}
