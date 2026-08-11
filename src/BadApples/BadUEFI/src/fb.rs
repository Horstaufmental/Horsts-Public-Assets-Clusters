/*
* Copyright (c) 2026
* Horst's Public Assets Clusters (Horstaufmental)
* SPDX-License-Identifier: GPL-3.0-or-later
*/
use uefi::{boot, proto::console::gop::GraphicsOutput};

pub struct Framebuffer {
    fb: &'static mut [u32],
    pub width: usize,
    pub height: usize,
    pub stride: usize,
}

impl Framebuffer {
    pub fn new() -> Option<Self> {
        let mut gop_proto = boot::open_protocol_exclusive::<GraphicsOutput>(
            boot::get_handle_for_protocol::<GraphicsOutput>().ok()?,
        )
        .ok()?;

        let (w, h) = gop_proto.current_mode_info().resolution();
        let px_scln = gop_proto.current_mode_info().stride();
        let mut fb = gop_proto.frame_buffer();

        Some(Framebuffer {
            fb: unsafe {
                core::slice::from_raw_parts_mut(fb.as_mut_ptr() as *mut u32, fb.size() / 4)
            },
            width: w,
            height: h,
            stride: px_scln,
        })
    }

    /// Fill the entire framebuffer with a BGRA color.
    pub fn fill(&mut self, color: u32) {
        self.fb.fill(color);
    }

    /// Blit a single row of BGRA pixels starting at `(x, y)`, clipped to the
    /// framebuffer. No-op if the row are entirely off the framebuffer.
    pub fn blit_row(&mut self, x: usize, y: usize, pixels: &[u32]) {
        if y >= self.height || x >= self.width {
            return;
        }
        let n = pixels.len().min(self.width - x);
        let start = y * self.stride + x;
        self.fb[start..start + n].copy_from_slice(&pixels[..n]);
    }

    /// Blit a `w x h` image buffer of BGRA pixels with its top left corner at
    /// `(x, y)`, clipped to the framebuffer bounds. `pixels` must contain at
    /// least `w * h` entries.
    pub fn blit(&mut self, x: usize, y: usize, w: usize, h: usize, pixels: &[u32]) {
        let rows = h.min(self.height.saturating_sub(y));
        for row in 0..rows {
            let start = row * w;
            self.blit_row(x, y + row, &pixels[start..start + w]);
        }
    }
}
