use hound;
use crate::global_state::{BIT_8_STATUS, SAMPLE_RATE};
use std::sync::atomic::Ordering;


pub fn write_wav(
    path: String,
    samples: Vec<f32>
) -> bool {


    if BIT_8_STATUS.load(Ordering::SeqCst) == true {
        // 8 Bit
        let spec: hound::WavSpec = hound::WavSpec {
            channels: 1,
            sample_rate: SAMPLE_RATE.load(Ordering::SeqCst),
            bits_per_sample: 8,
            sample_format: hound::SampleFormat::Int,
        };

        let mut writer = match hound::WavWriter::create(path, spec) {
            Ok(o) => o,
            Err(_) => return false,
        };
        for s in samples {
            let val: i8 = (s * i8::MAX as f32) as i8;
            match writer.write_sample(val) {
                Ok(_o) => {}
                Err(_) => return false,
            };
        }
        match writer.finalize() {
            Ok(_) => return true,
            Err(_) => return false,
        };
    } else {
        // 16 Bit
        let spec: hound::WavSpec = hound::WavSpec {
            channels: 1,
            sample_rate: SAMPLE_RATE.load(Ordering::SeqCst),
            bits_per_sample: 16,
            sample_format: hound::SampleFormat::Int,
        };

        let mut writer = match hound::WavWriter::create(path, spec) {
            Ok(o) => o,
            Err(_) => return false,
        };

        for s in samples {
            let val = (s * i16::MAX as f32) as i16;
            match writer.write_sample(val) {
                Ok(_o) => {}
                Err(_) => return false,
            };
        }

        match writer.finalize() {
            Ok(_) => return true,
            Err(_) => return false,
        };
    }
}