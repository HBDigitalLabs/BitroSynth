import 'package:flutter/material.dart';

import "../common_types.dart";
import '../wrappers/synth_wrapper.dart';
import '../wrappers/playback_wrapper.dart';
import '../utils.dart';


class AudioSettingsPage extends StatefulWidget {
    final SynthWrapper synthWrapper;
    final PlaybackEngineWrapper playbackEngineWrapper;

    const AudioSettingsPage({
      super.key,
      required this.synthWrapper,
      required this.playbackEngineWrapper
    });
    
    @override
    State<AudioSettingsPage> createState() => _AudioSettingsPageState();
}

class _AudioSettingsPageState extends State<AudioSettingsPage> {

  static const Map<String, int> _sampleRates = {
      "11.025 kHz (Lo-Fi / Fast Render)" : 11025,
      "22.05 kHz (Low Quality)"          : 22050,
      "32 kHz (Legacy)"                  : 32000,
      "44.1 kHz (CD / Music)"            : 44100,
      "48 kHz (Studio / Video)"          : 48000,
      "88.2 kHz (High Quality)"          : 88200,
      "96 kHz (High Quality)"            : 96000,
      "176.4 kHz (Ultra / Offline)"      : 176400,
      "192 kHz (Ultra / Offline)"        : 192000 
  };

  final List<String> _drowdownMenuItems = _sampleRates.keys.toList();

  AudioBitDepth _audioBitDepth = AudioBitDepth.Bit16;

  late String _dropdownValue;



  Future<void> apply() async {
    int? newSampleRate = _sampleRates[_dropdownValue];
    if (newSampleRate != null) {
      widget.synthWrapper.setSampleRate(newSampleRate);
      await widget.playbackEngineWrapper.setSampleRate(newSampleRate);
    }
    else {
      if (!mounted) return;
      showMessage(context,"Error: The sampling rate could not be adjusted.");
    }



    widget.synthWrapper.setBitStatus(_audioBitDepth);

    if (!mounted) return;
    Navigator.pop(context);
  }


  
  @override
  void initState() {
    super.initState();
    _dropdownValue = _drowdownMenuItems[3];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300 || constraints.maxHeight < 300) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Window is too small',
                style: TextStyle(color: AppColors.text),
              ),
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 400,
            ),
            child: Column(
              children: [
                // CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      color: AppColors.surface,
                      child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Sample Rate",
                                style: TextStyle(color: AppColors.text),
                              ),

                              DropdownButton<String>(
                                dropdownColor: AppColors.surfaceAlt,
                                style: const TextStyle(color: AppColors.text),
                                value: _dropdownValue,
                                icon: const Icon(Icons.arrow_downward),
                                elevation: 16,
                                underline: Container(
                                  height: 2,
                                  color: AppColors.outline,
                                ),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() => _dropdownValue = value);
                                  }
                                },
                                items: _drowdownMenuItems
                                    .map(
                                      (value) => DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                "Bit Depth",
                                style: TextStyle(color: AppColors.text),
                              ),

                              RadioGroup<AudioBitDepth>(
                                groupValue: _audioBitDepth,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _audioBitDepth = value);
                                  }
                                },
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: const Text(
                                        '16 Bit',
                                        style: TextStyle(color: AppColors.text),
                                      ),
                                      leading: Radio<AudioBitDepth>(
                                        value: AudioBitDepth.Bit16,
                                        fillColor: WidgetStateColor.resolveWith(
                                          (states) => states.contains(WidgetState.selected)
                                              ? AppColors.accent
                                              : AppColors.fullBlack,
                                        ),
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text(
                                        '8 Bit',
                                        style: TextStyle(color: AppColors.text),
                                      ),
                                      leading: Radio<AudioBitDepth>(
                                        value: AudioBitDepth.Bit8,
                                        fillColor: WidgetStateColor.resolveWith(
                                          (states) => states.contains(WidgetState.selected)
                                              ? AppColors.accent
                                              : AppColors.fullBlack,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        
                    ),
                  ),
                ),

                // APPLY BUTTON
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: apply,
                      child: const Text("APPLY"),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}