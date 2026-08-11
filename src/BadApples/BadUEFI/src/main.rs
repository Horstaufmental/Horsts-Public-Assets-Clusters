/*
* Copyright (c) 2026
* Horst's Public Assets Clusters (Horstaufmental)
* SPDX-License-Identifier: GPL-3.0-or-later
*/
#![no_main]
#![no_std]

extern crate alloc;

mod fb;
mod xz_stream;

use alloc::vec::Vec;

use uefi::boot;
use uefi::proto::media::file::{File, FileAttribute, FileMode};
use uefi::{Status, cstr16, entry, println};

use fb::Framebuffer;
use xz_stream::XzStream;
use zune_png::PngDecoder;
use zune_png::zune_core::colorspace::ColorSpace;

macro_rules! bgra {
    ($b:expr, $g:expr, $r:expr, $a:expr) => {
        (($a as u32) << 24 as u8) | (($r as u32) << 16 as u8) | (($g as u32) << 8 as u8) | $b as u32
    };
}

fn show_image(fb: &mut Framebuffer, image_raw: &[u8]) {
    let mut decoder = PngDecoder::new(zune_png::zune_core::bytestream::ZCursor::new(image_raw));
    let pixels = match decoder.decode() {
        Ok(res) => res
            .u8()
            .unwrap_or_else(|| panic!("only 8-bit PNGs are supported")),
        Err(e) => panic!("Failed to decode PNG: {:?}", e),
    };
    let (img_w, img_h) = decoder.dimensions().expect("missing PNG dimensions");
    let channels = if decoder.colorspace() == Some(ColorSpace::RGBA) {
        4
    } else {
        3
    };

    // convert the raw RGBA/RGB bytes to a BGRA `u32` buffer once,
    // so that the actual drawing below is a plain memcpy
    // instead of per-pixel work
    let mut bgra_pixels: Vec<u32> = Vec::with_capacity(img_w * img_h);
    if channels == 4 {
        for px in pixels.chunks_exact(4) {
            bgra_pixels.push(bgra!(px[2], px[1], px[0], px[3]));
        }
    } else {
        for px in pixels.chunks_exact(3) {
            bgra_pixels.push(bgra!(px[2], px[1], px[0], 255));
        }
    }

    // solid black bg, memcpy the image on top (clipped to the
    // framebuffer, centered where possible)
    fb.fill(bgra!(0, 0, 0, 255));
    let ox = fb.width.saturating_sub(img_w) / 2;
    let oy = fb.height.saturating_sub(img_h) / 2;
    fb.blit(ox, oy, img_w, img_h, &bgra_pixels);
}

/// Parse an octal tar header field (NUL or space terminated).
fn parse_octal(bytes: &[u8]) -> Option<u64> {
    let s = core::str::from_utf8(bytes).ok()?;
    let s = s.trim_end_matches('\0').trim_end_matches(' ').trim_start();
    u64::from_str_radix(s, 8).ok()
}

#[entry]
fn main() -> Status {
    uefi::helpers::init().unwrap();

    // disable watchdog timer
    if let Err(e) = boot::set_watchdog_timer(0, 0, None) {
        println!("Failed to disable watchdog timer: {}", e);
    }

    let mut fs_proto = boot::get_image_file_system(boot::image_handle())
        .expect("failed to open the boot file system");
    let mut root = fs_proto
        .open_volume()
        .expect("failed to open the volume root");
    let handle = root
        .open(
            cstr16!("frames.tar.xz"),
            FileMode::Read,
            FileAttribute::empty(),
        )
        .expect("failed to open frames.tar.xz");
    let file = handle
        .into_regular_file()
        .expect("frames.tar.xz is not a regular file");

    let mut stream = XzStream::new(file);

    println!("Locating Graphics Output Protocol...");
    let mut fb = match Framebuffer::new() {
        Some(v) => {
            println!(
                "Found GOP, Width: {} | Height: {} | Stride: {}",
                v.width, v.height, v.stride
            );
            v
        }
        None => panic!("GOP unable to be located."),
    };

    println!("Playing frames from frames.tar.xz...");

    let mut frames = 0;
    let mut header = [0u8; 512];
    while stream.read_exact(&mut header) {
        // two consecutive zero blocks mark the end of a tar archive
        if header.iter().all(|&b| b == 0) {
            break;
        }
        let name_end = header[..100].iter().position(|&b| b == 0).unwrap_or(100);
        let name = core::str::from_utf8(&header[..name_end]).unwrap_or("");
        let size = parse_octal(&header[124..136]).expect("invalid tar size field") as usize;

        if name.ends_with(".png") {
            let mut png = Vec::with_capacity(size);
            png.resize(size, 0);
            if !stream.read_exact(&mut png) {
                break;
            }
            show_image(&mut fb, &png);
            frames += 1;
            // 20 miliseconds is chosen here as it is the (visually) closest
            // to the original 30 FPS, this is simply my best guess
            // and may not be completely accurate.
            //
            // This is the case for QEMU/KVM on Ryzen 5 5600,
            // with the same command as in the Makefile.
            boot::stall(core::time::Duration::from_millis(20));
        } else {
            let mut skip = [0u8; 512];
            let mut left = size;
            while left > 0 {
                let take = left.min(skip.len());
                if !stream.read_exact(&mut skip[..take]) {
                    break;
                }
                left -= take;
            }
        }

        // tar pads every entry's data out to a 512-byte boundary
        let pad = (512 - (size % 512)) % 512;
        if pad > 0 {
            let mut skip = [0u8; 512];
            if !stream.read_exact(&mut skip[..pad]) {
                break;
            }
        }
    }

    println!("Played {} frames", frames);

    Status::SUCCESS
    // unsafe { asm!("cli; hlt") }
    // unreachable!();
}
