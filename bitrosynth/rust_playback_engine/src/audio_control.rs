use std::sync::Arc;
use std::sync::Mutex;
use std::sync::atomic::Ordering;
use std::thread;
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};

use crate::audio_stream::*;
use crate::common_types::CommandType;
use crate::common_types::ProcessStatus;
use crate::wav_reader::*;
use crate::utils::set_status;
use crate::global_state::*;


pub fn de_init() {
    thread::spawn(move || {
        set_status(ProcessStatus::InProgress, CommandType::DeInit);

        PLAYBACK_STATUS.store(false, Ordering::SeqCst);

        if let Some(stream_arc) = STREAM.get() {
            let mut stream_lock = match stream_arc.lock() {
                Ok(o) => o,
                Err(_) => {
                    set_status(ProcessStatus::Error, CommandType::None);
                    return;
                },
            };
            *stream_lock = None;
        }

        if let Some(buffer_arc) = AUDIO_BUFFER.get() {
            let mut buf = match buffer_arc.lock() {
                Ok(o) => o,
                Err(_) => {
                    
                    set_status(ProcessStatus::Error, CommandType::None);
                    return;
                },
            };
            buf.clear();
        }

        if let Some(pos_arc) = AUDIO_POSITION.get() {
            let mut pos = match pos_arc.lock() {
                Ok(o) => o,
                Err(_) => {
                    
                    set_status(ProcessStatus::Error, CommandType::None);
                    return;
                },
            };
            *pos = 0;
        }

        
        set_status(ProcessStatus::Success, CommandType::None);
    });
    
}


pub fn init() {

    thread::spawn(move || {
                    
        set_status(ProcessStatus::InProgress, CommandType::Init);
        

        AUDIO_BUFFER.get_or_init(|| Arc::new(Mutex::new(Vec::new())));
        AUDIO_POSITION.get_or_init(|| Arc::new(Mutex::new(0)));


        let host = cpal::default_host();

        let device = match host.default_output_device() {
            Some(d) => d,
            None => {
                    
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };


        let supported_config = match device.default_output_config() {
            Ok(cfg) => cfg.config(),
            Err(_) => {
                    
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };


        let buffer = match AUDIO_BUFFER.get() {
            Some(b) => Arc::clone(b),
            None => {
                    
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };


        let pos = match AUDIO_POSITION.get() {
            Some(p) => Arc::clone(p),
            None => {
                    
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };


        let stream = match build_output_stream(
            &device,
            &supported_config,
            Arc::clone(&buffer),
            Arc::clone(&pos)
        ) {
            Ok(s) => s,
            Err(_) => {
                    
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };


        if let Err(_) = stream.play() {
                    
            set_status(ProcessStatus::Error, CommandType::None);
            return;
        }



        if update_global_stream(stream) != 0 {
                    
            set_status(ProcessStatus::Error, CommandType::None);
            return;
        }


        set_status(ProcessStatus::Success, CommandType::None);
    });
}


pub fn set_sample_rate(new_rate: u32) {
    
    thread::spawn(move || {
        set_status(ProcessStatus::InProgress, CommandType::SetSampleRate);

        if let Some(stream_arc) = STREAM.get() {
            match stream_arc.lock() {
                Ok(mut stream_lock) => *stream_lock = None,
                Err(_) => {
                    set_status(ProcessStatus::Error, CommandType::None);
                    return;
                },
            }
        }

        let host = cpal::default_host();
        let device = match host.default_output_device() {
            Some(d) => d,
            None => {
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };

        let mut supported_config = match device.default_output_config() {
            Ok(cfg) => cfg.config(),
            Err(_) => {
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };


        supported_config.sample_rate = new_rate;

        let buffer = match AUDIO_BUFFER.get() {
            Some(b) => Arc::clone(b),
            None => {
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };
        let pos = match AUDIO_POSITION.get() {
            Some(p) => Arc::clone(p),
            None => {
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };

        let stream = match build_output_stream(
            &device,
            &supported_config,
            Arc::clone(&buffer),
            Arc::clone(&pos)
        ) {
            Ok(s) => s,
            Err(_) => {
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            },
        };

        if let Err(_) = stream.play() {
            set_status(ProcessStatus::Error, CommandType::None);
            return;
        }
        

        if update_global_stream(stream) != 0 {
            set_status(ProcessStatus::Error, CommandType::None);
            return;
        }


        set_status(ProcessStatus::Success, CommandType::None);
    });
    
}






pub fn stop_audio(){
    set_status(ProcessStatus::InProgress, CommandType::Stop);
    PLAYBACK_STATUS.store(false, Ordering::SeqCst);
    set_status(ProcessStatus::Success, CommandType::None);
}


pub fn play_audio(
    path: String,
    milliseconds_position : u32
) {

    thread::spawn(move || {

        set_status(ProcessStatus::InProgress, CommandType::Play);

        let wav_file_data = match read_wav_file(path)
        {
            Some(o) => o,
            None => {
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            }
        };

        let buffer = AUDIO_BUFFER.get_or_init(|| Arc::new(Mutex::new(Vec::new())));
    
        let mut buf = match buffer.lock(){
            Ok(o) => o,
            Err(_) => {
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            }
        };

        *buf = wav_file_data.samples;

        let pos = AUDIO_POSITION.get_or_init(|| Arc::new(Mutex::new(0)));

        let mut pos_guard = match pos.lock() {
            Ok(p) => p,
            Err(_) => {
                set_status(ProcessStatus::Error, CommandType::None);
                return;
            }
        };


        let channels = wav_file_data.channel_count as usize;

        let frame_pos = ((milliseconds_position as f64 / 1000.0)
            * wav_file_data.sample_rate as f64) as usize;

        let target_pos = frame_pos * channels;

        *pos_guard = target_pos.min(buf.len());

    

        PLAYBACK_STATUS.store(true, Ordering::SeqCst);


        set_status(ProcessStatus::Success, CommandType::None);

    });

    
}