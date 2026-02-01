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