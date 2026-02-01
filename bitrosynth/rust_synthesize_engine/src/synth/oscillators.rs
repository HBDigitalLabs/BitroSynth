use crate::global_state::SAMPLE_RATE;
use std::{f32::consts, sync::atomic::Ordering};


pub fn generate_triangle(milliseconds: u32, frequency: f32) -> Vec<f32> {
    let sample_rate: f32 = SAMPLE_RATE.load(Ordering::SeqCst) as f32;
    let seconds: f32 = milliseconds as f32 / 1000.0;
    let total_samples: usize = (seconds * sample_rate) as usize;
    let mut output: Vec<f32> = Vec::with_capacity(total_samples);

    for n in 0..total_samples {
        let t: f32 = n as f32 / sample_rate;
        let value: f32 = 4.0 * ((frequency * t - 0.25).fract() - 0.5).abs() - 1.0;
        output.push(value);
    }

    return output;
}

pub fn generate_square(milliseconds: u32, frequency: f32) -> Vec<f32> {
    let sample_rate: f32 = SAMPLE_RATE.load(Ordering::SeqCst) as f32;
    let seconds: f32 = milliseconds as f32 / 1000.0;
    let total_samples: usize = (seconds * sample_rate) as usize;
    let mut output: Vec<f32> = Vec::with_capacity(total_samples);

    for n in 0..total_samples {
        let t: f32 = n as f32 / sample_rate;
        let value: f32 = if (2.0 * std::f32::consts::PI * frequency * t).sin() >= 0.0 {
            1.0
        } else {
            -1.0
        };
        output.push(value);
    }

    return output;
}

pub fn generate_sine(milliseconds: u32, frequency: f32) -> Vec<f32> {
    let sample_rate: f32 = SAMPLE_RATE.load(Ordering::SeqCst) as f32;
    let seconds: f32 = milliseconds as f32 / 1000.0;
    let total_samples: usize = (seconds * sample_rate) as usize;
    let mut output: Vec<f32> = Vec::with_capacity(total_samples);

    for n in 0..total_samples {
        let t = n as f32 / sample_rate;
        let value = (2.0 * consts::PI * frequency * t).sin();
        output.push(value);
    }

    return output;
}

pub fn generate_sawtooth(milliseconds: u32, frequency: f32) -> Vec<f32> {
    let sample_rate: f32 = SAMPLE_RATE.load(Ordering::SeqCst) as f32;
    let seconds: f32 = milliseconds as f32 / 1000.0;
    let total_samples: usize = (seconds * sample_rate) as usize;
    let mut output: Vec<f32> = Vec::with_capacity(total_samples);

    for n in 0..total_samples {
        let t: f32 = n as f32 / sample_rate;
        let value: f32 = 2.0 * (frequency * t - (frequency * t).floor()) - 1.0;
        output.push(value);
    }

    return output;
}