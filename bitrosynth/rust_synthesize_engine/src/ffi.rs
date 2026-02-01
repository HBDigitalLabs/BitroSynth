use std::ffi::{c_char, c_int, c_uchar, c_uint};
use std::thread;
use std::sync::atomic::Ordering;

use crate::audio::wav::write_wav;
use crate::common_types::{CommandType, ProcessStatus};
use crate::utils::{c_char_to_string, set_status};
use crate::synth::channel::generate_channel;
use crate::global_state::*;


// ------------------------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn get_process_status() -> c_int {
    return CURRENT_STATUS.load(std::sync::atomic::Ordering::SeqCst) as c_int;
}

#[unsafe(no_mangle)]
pub extern "C" fn get_current_command() -> c_int {
    return CURRENT_COMMAND.load(std::sync::atomic::Ordering::SeqCst) as c_int;
}


// ------------------------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn set_8_bit_status(new_status: c_uchar){
    set_status(ProcessStatus::InProgress,CommandType::Set8BitStatus);
    if new_status == 1{
        BIT_8_STATUS.store(true, Ordering::SeqCst);
    }
    else{

        BIT_8_STATUS.store(false, Ordering::SeqCst);
    }
    set_status(ProcessStatus::Success,CommandType::None);
}


#[unsafe(no_mangle)]
pub extern "C" fn set_sample_rate(new_sample_rate: c_uint) {
    set_status(ProcessStatus::InProgress,CommandType::SetSampleRate);
    SAMPLE_RATE.store(new_sample_rate, Ordering::SeqCst);
    set_status(ProcessStatus::Success,CommandType::None);   
}

#[unsafe(no_mangle)]
pub extern "C" fn get_sample_rate() -> c_uint{
    return SAMPLE_RATE.load(Ordering::SeqCst) as c_uint;
}


// ------------------------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn synthesize_audio(
    data: *const *const *const c_char,
    sizes_array: *const c_uint,
    outer_size: c_uint,
    c_str_output_path: *const c_char,
) {
    set_status(ProcessStatus::InProgress, CommandType::SynthesizeAudio);

    let output_path = match c_char_to_string(c_str_output_path) {
        Some(s) => s,
        None => {
            set_status(ProcessStatus::Error, CommandType::None);
            return;
        }
    };

    if data.is_null() || sizes_array.is_null() || outer_size == 0 {
        set_status(ProcessStatus::Error, CommandType::None);
        return;
    }

    let sizes: Vec<usize> = unsafe {
        std::slice::from_raw_parts(sizes_array, outer_size as usize)
            .iter()
            .map(|&x| x as usize)
            .collect()
    };


    let mut all_notes: Vec<Vec<String>> = Vec::with_capacity(outer_size as usize);

    unsafe {
        let data_slice = std::slice::from_raw_parts(data, outer_size as usize);

        for (i, &piano_ptr) in data_slice.iter().enumerate() {
            let inner_size = sizes[i];
            let notes_slice = std::slice::from_raw_parts(piano_ptr, inner_size);
            let notes_vec: Vec<String> = notes_slice
                .iter()
                .map(|&ptr| c_char_to_string(ptr).unwrap_or_default())
                .collect();
            all_notes.push(notes_vec);
        }
    }

    thread::spawn(move || {
        let mut audio_datas: Vec<Vec<f32>> = Vec::new();

        for notes in &all_notes {
            if notes.is_empty() {
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            }

            let audio = match generate_channel(notes.clone()) {
                Some(v) => v,
                None => {
                    set_status(ProcessStatus::Error, CommandType::None);
                    return;
                }
            };
            audio_datas.push(audio);
        }

        let max_length = audio_datas.iter().map(|c| c.len()).max().unwrap_or(0);
        let mut output_data = Vec::with_capacity(max_length);

        for i in 0..max_length {
            let mut sum = 0.0;
            let mut active_channels = 0;

            for channel in &audio_datas {
                if let Some(&sample) = channel.get(i) {
                    if sample != 0.0 {
                        sum += sample;
                        active_channels += 1;
                    }
                }
            }

            output_data.push(if active_channels > 0 {
                sum / active_channels as f32
            } else {
                0.0
            });
        }

        let status: bool = write_wav(output_path, output_data);

        set_status(
            if status { ProcessStatus::Success } else { ProcessStatus::Error },
            CommandType::None,
        );
    });
}