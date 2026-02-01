use std::sync::atomic::{AtomicBool, AtomicI32, AtomicU32};

pub static SAMPLE_RATE  : AtomicU32  = AtomicU32::new(44100);
pub static BIT_8_STATUS : AtomicBool = AtomicBool::new(false);


pub static CURRENT_STATUS : AtomicI32 = AtomicI32::new(0);
pub static CURRENT_COMMAND : AtomicI32 = AtomicI32::new(0);