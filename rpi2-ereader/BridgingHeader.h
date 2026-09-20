#pragma once

#include "pico/stdlib.h"
#include "hardware/spi.h"
#include "hardware/gpio.h"
#include <stdio.h>

static inline void dbg(const char *s) { printf("%s", s); }

static inline void epd_spi_init(void) {
    spi_init(spi1, 4 * 1000 * 1000);            // 4 MHz
    spi_set_format(spi1, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST); // mode 0
    gpio_set_function(10, GPIO_FUNC_SPI);       // CLK
    gpio_set_function(11, GPIO_FUNC_SPI);       // DIN (MOSI)
}

static inline void epd_spi_write(uint8_t b) {
    spi_write_blocking(spi1, &b, 1);
}

static inline void epd_spi_write_buf(const uint8_t *buf, size_t len) {
    spi_write_blocking(spi1, buf, len);   // tamponu tek işlemde gönder
}