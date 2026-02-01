use std::ffi::{CStr, c_char};
use std::sync::atomic::Ordering;

use crate::global_state::{
    CURRENT_COMMAND,
    CURRENT_STATUS
};
use crate::common_types::*;

pub fn set_status(
    status: ProcessStatus,
    current_command: CommandType
){
    CURRENT_STATUS.store(status as i32, Ordering::SeqCst);
    CURRENT_COMMAND.store(current_command as i32,Ordering::SeqCst);
}

pub fn c_char_to_string(c_str_ptr: *const c_char) -> Option<String> {
    if c_str_ptr.is_null() {
        return None;
    }
    unsafe {
        let c_str = CStr::from_ptr(c_str_ptr);
        match c_str.to_str() {
            Ok(str_slice) => Some(str_slice.to_string()),
            Err(_) => None,
        }
    }
}

pub fn note_to_frequency(note: &str) -> Option<f32> {
    match note {
        "C0" => Some(16.35),  "C#0" => Some(17.32), "D0" => Some(18.35),  "D#0" => Some(19.45),
        "E0" => Some(20.60),  "F0" => Some(21.83), "F#0" => Some(23.12), "G0" => Some(24.50),
        "G#0" => Some(25.96), "A0" => Some(27.50), "A#0" => Some(29.14), "B0" => Some(30.87),

        "C1" => Some(32.70),  "C#1" => Some(34.65), "D1" => Some(36.71),  "D#1" => Some(38.89),
        "E1" => Some(41.20),  "F1" => Some(43.65), "F#1" => Some(46.25), "G1" => Some(49.00),
        "G#1" => Some(51.91), "A1" => Some(55.00), "A#1" => Some(58.27), "B1" => Some(61.74),

        "C2" => Some(65.41),  "C#2" => Some(69.30), "D2" => Some(73.42),  "D#2" => Some(77.78),
        "E2" => Some(82.41),  "F2" => Some(87.31), "F#2" => Some(92.50), "G2" => Some(98.00),
        "G#2" => Some(103.83), "A2" => Some(110.00), "A#2" => Some(116.54), "B2" => Some(123.47),

        "C3" => Some(130.81), "C#3" => Some(138.59), "D3" => Some(146.83), "D#3" => Some(155.56),
        "E3" => Some(164.81), "F3" => Some(174.61), "F#3" => Some(185.00), "G3" => Some(196.00),
        "G#3" => Some(207.65), "A3" => Some(220.00), "A#3" => Some(233.08), "B3" => Some(246.94),

        "C4" => Some(261.63), "C#4" => Some(277.18), "D4" => Some(293.66), "D#4" => Some(311.13),
        "E4" => Some(329.63), "F4" => Some(349.23), "F#4" => Some(369.99), "G4" => Some(392.00),
        "G#4" => Some(415.30), "A4" => Some(440.00), "A#4" => Some(466.16), "B4" => Some(493.88),

        "C5" => Some(523.25), "C#5" => Some(554.37), "D5" => Some(587.33), "D#5" => Some(622.25),
        "E5" => Some(659.26), "F5" => Some(698.46), "F#5" => Some(739.99), "G5" => Some(783.99),
        "G#5" => Some(830.61), "A5" => Some(880.00), "A#5" => Some(932.33), "B5" => Some(987.77),

        "C6" => Some(1046.50), "C#6" => Some(1108.73), "D6" => Some(1174.66), "D#6" => Some(1244.51),
        "E6" => Some(1318.51), "F6" => Some(1396.91), "F#6" => Some(1479.98), "G6" => Some(1567.98),
        "G#6" => Some(1661.22), "A6" => Some(1760.00), "A#6" => Some(1864.66), "B6" => Some(1975.53),

        "C7" => Some(2093.00), "C#7" => Some(2217.46), "D7" => Some(2349.32), "D#7" => Some(2489.02),
        "E7" => Some(2637.02), "F7" => Some(2793.83), "F#7" => Some(2959.96), "G7" => Some(3135.96),
        "G#7" => Some(3322.44), "A7" => Some(3520.00), "A#7" => Some(3729.31), "B7" => Some(3951.07),

        "C8" => Some(4186.01), "C#8" => Some(4434.92), "D8" => Some(4698.64), "D#8" => Some(4978.03),
        "E8" => Some(5274.04), "F8" => Some(5587.65), "F#8" => Some(5919.91), "G8" => Some(6271.93),
        "G#8" => Some(6644.88), "A8" => Some(7040.00), "A#8" => Some(7458.62), "B8" => Some(7902.13),

        _ => None,
    }
}
