use std::sync::{Arc, Mutex, OnceLock, atomic::{AtomicBool, AtomicI32}};
use cpal::Stream;

pub static STREAM: OnceLock<Arc<Mutex<Option<Stream>>>> = OnceLock::new();
pub static AUDIO_BUFFER: OnceLock<Arc<Mutex<Vec<f32>>>> = OnceLock::new();
pub static AUDIO_POSITION: OnceLock<Arc<Mutex<usize>>> = OnceLock::new();
pub static PLAYBACK_STATUS: AtomicBool = AtomicBool::new(false);


pub static CURRENT_STATUS : AtomicI32 = AtomicI32::new(0);
pub static CURRENT_COMMAND : AtomicI32 = AtomicI32::new(0);