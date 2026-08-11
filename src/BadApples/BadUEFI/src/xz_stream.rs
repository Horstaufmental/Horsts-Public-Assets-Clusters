/*
* Copyright (c) 2026
* Horst's Public Assets Clusters (Horstaufmental)
* SPDX-License-Identifier: GPL-3.0-or-later
*/
use alloc::boxed::Box;
use alloc::vec;
use alloc::vec::Vec;
use uefi::proto::media::file::RegularFile;
use xz4rust::XzDecoder;

/// Streaming XZ decoder that pulls the compressed bytes out of a regular
/// file in chunks, so the whole tarball never has to live in RAM at once.
pub struct XzStream {
    file: RegularFile,
    xz: Box<XzDecoder<'static>>,
    in_buf: Vec<u8>,
    in_len: usize,
    in_pos: usize,
    out_buf: Vec<u8>,
    out_len: usize,
    out_pos: usize,
    eof: bool,
}

impl XzStream {
    const IN_SIZE: usize = 8192;
    const OUT_SIZE: usize = 65536;

    pub fn new(file: RegularFile) -> Self {
        Self {
            file,
            xz: XzDecoder::in_heap(),
            in_buf: vec![0; Self::IN_SIZE],
            in_len: 0,
            in_pos: 0,
            out_buf: vec![0; Self::OUT_SIZE],
            out_len: 0,
            out_pos: 0,
            eof: false,
        }
    }

    fn refill_input(&mut self) {
        let n = self
            .file
            .read(&mut self.in_buf)
            .expect("failed to read xz data");
        self.in_len = n;
        self.in_pos = 0;
    }

    /// Fill `self.out_buf` with the next chunk of
    /// decompressed data.
    fn pump(&mut self) {
        if self.eof {
            return;
        }
        if self.in_pos == self.in_len {
            self.refill_input();
            if self.in_len == 0 {
                self.eof = true;
                return;
            }
        }
        loop {
            let res = self
                .xz
                .decode(&self.in_buf[self.in_pos..self.in_len], &mut self.out_buf)
                .expect("xz decompression failed");
            let consumed = res.input_consumed();
            let produced = res.output_produced();
            self.in_pos += consumed;
            self.out_len = produced;
            self.out_pos = 0;
            if res.is_end_of_stream() {
                self.eof = true;
            }
            if produced > 0 {
                return;
            }
            if self.eof {
                return;
            }
            if self.in_pos == self.in_len {
                self.refill_input();
                if self.in_len == 0 {
                    self.eof = true;
                    return;
                }
            } else if consumed == 0 {
                // input available but no progress; cannot happen
                // with our buffer sizes, bail out
                // instead of spinning forever
                self.eof = true;
                return;
            }
        }
    }

    /// Copy up to `dst.len()` decompressed bytes into `dst`.
    pub fn read(&mut self, dst: &mut [u8]) -> usize {
        let mut n = 0;
        while n < dst.len() {
            if self.out_pos == self.out_len {
                self.pump();
                if self.out_pos == self.out_len {
                    break;
                }
            }
            let avail = self.out_len - self.out_pos;
            let take = avail.min(dst.len() - n);
            dst[n..n + take].copy_from_slice(&self.out_buf[self.out_pos..self.out_pos + take]);
            self.out_pos += take;
            n += take;
        }
        n
    }

    /// Read exactly `dst.len()` bytes, or return false on EOF.
    pub fn read_exact(&mut self, dst: &mut [u8]) -> bool {
        self.read(dst) == dst.len()
    }
}
