#[repr(i32)]
pub enum CommandType {
    None = 0,
    SynthesizeAudio = 1,
    Set8BitStatus = 2,
    GetSampleRate = 3,
    SetSampleRate = 4
}

#[repr(i32)]
pub enum ProcessStatus {
    InProgress = 1,
    Success = 0,
    Error = -1,
}