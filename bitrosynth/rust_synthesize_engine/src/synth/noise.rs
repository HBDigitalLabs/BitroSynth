use std::sync::atomic::Ordering;

use rand::prelude::*;
use crate::global_state::SAMPLE_RATE;


pub fn generate_pink_noise(milliseconds: u32) -> Vec<f32> {
    let mut b0: f32 = 0.0;
    let mut b1: f32 = 0.0;
    let mut b2: f32 = 0.0;
    let mut b3: f32 = 0.0;
    let mut b4: f32 = 0.0;
    let mut b5: f32 = 0.0;
    let mut b6: f32 = 0.0;

    let input: Vec<f32> = generate_noise(milliseconds);

    let mut output_data: Vec<f32> = Vec::with_capacity(input.len());

    for x in input {
        b0 = 0.99886 * b0 + x * 0.0555179;
        b1 = 0.99332 * b1 + x * 0.0750759;
        b2 = 0.96900 * b2 + x * 0.1538520;
        b3 = 0.86650 * b3 + x * 0.3104856;
        b4 = 0.55000 * b4 + x * 0.5329522;
        b5 = -0.7616 * b5 - x * 0.0168980;
        let y: f32 = b0 + b1 + b2 + b3 + b4 + b5 + b6 + x * 0.5362;
        b6 = x * 0.115926;
        output_data.push(y);
    }

    let max_amp: f32 = output_data
        .iter()
        .cloned()
        .fold(0.0f32, |a, b| a.max(b.abs()));

    if max_amp > 1.0 {
        output_data.iter_mut().for_each(|s| *s /= max_amp);
    }

    return output_data;
}

pub fn generate_noise(milliseconds: u32) -> Vec<f32> {
    let mut rng: ThreadRng = rand::rng();
    let seconds: f32 = milliseconds as f32 / 1000.0;

    let sample_rate: f32 = SAMPLE_RATE.load(Ordering::SeqCst) as f32;
    let total_samples_length = (seconds * sample_rate) as usize;
    let mut output_data: Vec<f32> = Vec::new();
    for _ in 0..total_samples_length {
        output_data.push(rng.random_range(-1.0..=1.0));
    }
    return output_data;
}