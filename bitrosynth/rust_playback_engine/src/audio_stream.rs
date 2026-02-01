use cpal::traits::DeviceTrait;
use std::sync::{Arc, Mutex, atomic::Ordering};

use crate::global_state::STREAM;
use crate::global_state::PLAYBACK_STATUS;



pub fn build_output_stream(
    device: &cpal::Device,
    config: &cpal::StreamConfig,
    buffer: Arc<Mutex<Vec<f32>>>,
    pos: Arc<Mutex<usize>>,
) -> Result<cpal::Stream, ()> {
    device.build_output_stream(
        config,
        {
            let buffer = Arc::clone(&buffer);
            let pos = Arc::clone(&pos);
            move |data: &mut [f32], _: &cpal::OutputCallbackInfo| {

                let unlocked_buffer = match buffer.lock() {
                    Ok(b) => b,
                    Err(_) => return,
                };
                let mut unlocked_pos = match pos.lock() {
                    Ok(p) => p,
                    Err(_) => return,
                };

                for sample in data.iter_mut() {

                    if PLAYBACK_STATUS.load(Ordering::SeqCst) {

                        if *unlocked_pos < unlocked_buffer.len() {

                            *sample = unlocked_buffer[*unlocked_pos];
                            *unlocked_pos += 1;

                        } else {

                            *sample = 0.0;

                        }

                    } else {
                     *sample = 0.0;
                    }

                }
                
            }

        },
        move |err| eprintln!("Stream error: {:?}", err),
        None,
    ).map_err(|_| ())
}

pub fn update_global_stream(new_stream: cpal::Stream) -> i32 {

    let global_arc = STREAM.get_or_init(|| {
        Arc::new(Mutex::new(None))
    });
    match global_arc.lock() {
        Ok(mut global_lock) => {
            *global_lock = Some(new_stream);
            return 0;
        }
        Err(_) => return -1,
        
    }
}
