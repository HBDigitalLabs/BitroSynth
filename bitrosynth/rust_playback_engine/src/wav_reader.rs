use hound::WavReader;

pub struct WavFileData{
    pub samples: Vec<f32>,
    pub sample_rate : u32,
    pub channel_count: u8,
}

pub fn read_wav_file(path: String) -> Option<WavFileData>{
    let mut reader = match WavReader::open(path) {
        Ok(r) => r,
        Err(_) => return None,
    };

    let spec = reader.spec();

    let samples: Vec<f32> = match spec.sample_format {
        hound::SampleFormat::Float => {
            reader.samples::<f32>()
                  .filter_map(|s| s.ok())
                  .collect()
        }
        hound::SampleFormat::Int => {
            match spec.bits_per_sample {
                8 => reader.samples::<i16>()
                           .filter_map(|s| s.ok())
                           .map(|s| (s as f32 - 128.0) / 128.0)
                           .collect(),
                16 => reader.samples::<i16>()
                            .filter_map(|s| s.ok())
                            .map(|s| s as f32 / i16::MAX as f32)
                            .collect(),
                _ => return None,
            }
        }
    };

    let data = WavFileData{
        samples: samples,
        sample_rate: spec.sample_rate,
        channel_count: spec.channels as u8,
    };

    return Some(data);
}