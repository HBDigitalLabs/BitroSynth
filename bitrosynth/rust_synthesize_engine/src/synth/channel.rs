use std::sync::atomic::Ordering;

use crate::{global_state::SAMPLE_RATE,utils::note_to_frequency};

use super::{oscillators::*, noise::*};


fn generate_silence(milliseconds: u32) -> Vec<f32> {
    let sample_rate: f32 = SAMPLE_RATE.load(Ordering::SeqCst) as f32;

    return vec![0.0; (milliseconds as f32 / 1000.0 * sample_rate) as usize];
}

pub fn generate_channel(inputs: Vec<String>) -> Option<Vec<f32>> {

    let mut row_audios: Vec<Vec<f32>> = Vec::with_capacity(inputs.len());

    for (_row_index, input) in inputs.into_iter().enumerate() {
        let notes: Vec<&str> = input.split('>').collect();

        let mut row_wave: Vec<f32> = Vec::new();

        for note_str in notes.iter() {
            if note_str.trim().is_empty() { continue; }

            let note_parts: Vec<&str> = note_str.split('_').map(|s| s.trim()).collect();
            if note_parts.len() < 4 {
                return None;
            }

            // NOTE name -> frequency
            let note_name = note_parts[0].to_ascii_uppercase();
            let frequency: f32 = match note_to_frequency(&note_name) {
                Some(f) => f,
                None => return None
            };

            // milliseconds (u32)
            let milliseconds: u32 = match note_parts[1].parse::<u32>() {
                Ok(v) => v,
                Err(_) => return None,
            };

            let gain: f32 = match note_parts[2].replace(',', ".").parse::<f32>() {
                Ok(v) => v,
                Err(_) => return None,
            };

            let wave_form_type = note_parts[3].replace(' ', "");

            let mut wave: Vec<f32> = match wave_form_type.as_str() {
                "Triangle" => generate_triangle(milliseconds, frequency),
                "Sine" => generate_sine(milliseconds, frequency),
                "Square" => generate_square(milliseconds, frequency),
                "Sawtooth" => generate_sawtooth(milliseconds, frequency),
                "WhiteNoise" => generate_noise(milliseconds),
                "PinkNoise" => generate_pink_noise(milliseconds),
                "Silence" => generate_silence(milliseconds),
                _ => return None,
            };


            // apply gain & clamp
            for sample in wave.iter_mut() {
                *sample = (*sample * gain).clamp(-1.0, 1.0);
            }

            row_wave.extend(wave);
        } // for notes

        row_audios.push(row_wave);
    } // for rows

    if row_audios.is_empty() {
        return Some(Vec::new());
    }

    let max_length = row_audios.iter().map(|r| r.len()).max().unwrap_or(0);

    let mut output_data: Vec<f32> = vec![0.0; max_length];

    for row in &row_audios {
        for (i, &sample) in row.iter().enumerate() {
            output_data[i] += sample;
        }
    }

    let max_amp = output_data.iter().cloned().fold(0.0f32, |a, b| a.max(b.abs()));
    
    if max_amp > 1.0 {
        for s in output_data.iter_mut() {
            *s /= max_amp;
        }
    }

    Some(output_data)
}