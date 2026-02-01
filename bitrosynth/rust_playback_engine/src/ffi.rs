use std::ffi::{CStr, c_char, c_int, c_uint};
use crate::global_state::{CURRENT_STATUS,CURRENT_COMMAND};
use crate::{common_types::{CommandType, ProcessStatus}, utils::set_status};


// -------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn get_process_status() -> c_int {
    return CURRENT_STATUS.load(std::sync::atomic::Ordering::SeqCst) as c_int;
}

#[unsafe(no_mangle)]
pub extern "C" fn get_current_command() -> c_int {
    return CURRENT_COMMAND.load(std::sync::atomic::Ordering::SeqCst) as c_int;
}

// -------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn init() {
    crate::audio_control::init();
}

#[unsafe(no_mangle)]
pub extern "C" fn de_init() {
    crate::audio_control::de_init();
}


#[unsafe(no_mangle)]
pub extern "C" fn set_sample_rate(c_sample_rate : c_uint){


    set_status(ProcessStatus::InProgress, CommandType::SetSampleRate);

    let new_rate: u32 = match u32::try_from(c_sample_rate){
        Ok(o) => o,
        Err(_) => {
            set_status(ProcessStatus::Error, CommandType::None);
            return;
        }
    };

    crate::audio_control::set_sample_rate(new_rate);
}


#[unsafe(no_mangle)]
pub extern "C" fn play_audio(
    c_path: *const c_char,
    c_milliseconds_position : c_uint
) {

    set_status(ProcessStatus::InProgress, CommandType::Play);
                    

    let path: String;

    if c_path.is_null() {
        
        set_status(ProcessStatus::Error, CommandType::None);
        return;
              
    }

    unsafe {
        let c_str = CStr::from_ptr(c_path);
        match c_str.to_str() {
            Ok(str_slice) => path = str_slice.to_string(),
            Err(_) => {
                set_status(ProcessStatus::Error, CommandType::None);  
                return;
            }
        }
    }

    let milliseconds_position: u32 = match u32::try_from(c_milliseconds_position){
        Ok(o) => o,
        Err(_) => {
                    
            set_status(ProcessStatus::Error, CommandType::None);
            return;
        },
    };
    

    crate::audio_control::play_audio(
        path,
        milliseconds_position
    );
    
}

#[unsafe(no_mangle)]
pub extern "C" fn stop_audio(){
    crate::audio_control::stop_audio();
}