#[repr(i32)]
pub enum CommandType {
    None = 0,
    Init = 1,
    Play = 2,
    Stop = 3,
    DeInit = 4,
    SetSampleRate = 5
}

#[repr(i32)]
pub enum ProcessStatus {
    InProgress = 1,
    Success = 0,
    Error = -1,
}