import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'piano_roll_preview_painter.dart';
import 'piano_roll.dart';
import 'utils.dart';
import 'wrappers/playback_wrapper.dart';
import 'widgets/transport_button.dart';
import 'piano_roll_floating_window.dart';
import 'wrappers/synth_wrapper.dart';
import 'pages/audio_settings_page.dart';
import 'pages/about_page.dart';
import 'common_types.dart';

void main() => runApp(const MainApp());


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BitroSynth',
      home: const MainPage(title: 'BitroSynth'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  final ValueNotifier<int> _pianoRollRepaintNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _pianoRollVisible = ValueNotifier(true);
  final ValueNotifier<String> _statusBar = ValueNotifier("Ready");
  final ValueNotifier<String> _timerStatus = ValueNotifier("00:00:00:000");

  final List<PianoRollFloatingWindow> _pianoRollFloatingWindows = [];

  final PlaybackEngineWrapper _playbackEngineWrapper = PlaybackEngineWrapper();
  final SynthWrapper _synthWrapper = SynthWrapper();
  
  Timer? _timer;

  int _currentPianoRoll = 0;
  int _currentMillisecondsPosition = 0;

  bool _playbackStatus = false;
  bool _isDeletePianoRoll = false;
  bool _exportAudioStatus = false;
  bool _openJsonStatus = false;



  final ButtonStyle _menuButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      
      if (states.contains(WidgetState.pressed)) return AppColors.surfacePressed;

      if (states.contains(WidgetState.hovered)) return AppColors.surfaceHover;

      return AppColors.background;
    }),
    foregroundColor: WidgetStateProperty.all(AppColors.text),
  );


  @override
  void initState() {
    super.initState();
    playbackEngineInit();
    _pianoRollFloatingWindows.add(
      PianoRollFloatingWindow(
        repaintNotifier: _pianoRollRepaintNotifier,
        visible: _pianoRollVisible,
      )
    );
  }

  @override
  void dispose() {

    _playbackEngineWrapper.deInit();
    _statusBar.dispose();
    _timerStatus.dispose();
    _pianoRollRepaintNotifier.dispose();
    _pianoRollVisible.dispose();

    super.dispose();
  }

  Future<void> playbackEngineInit() async {
    _statusBar.value = "Initializing...";
  
  
    await Future.delayed(Duration.zero);

    final status = await _playbackEngineWrapper.init();

    _statusBar.value = "Ready";

    if(status == ProcessStatus.unsuccessful){
      
      if(!mounted) return;
      await showAlertDialog(context, "Error", "The audio playback engine could not be started.");

      if(!mounted) return;
      Navigator.pop(context);

    }

  }



  Future<void> open() async {
    if (_playbackStatus || _exportAudioStatus) return;
    setState(() => _openJsonStatus = true);

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      
      setState(() => _openJsonStatus = false);
      return; 
    }

    final filePath = result.files.single.path!;
    try {
      final jsonString = await File(filePath).readAsString();
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) throw FormatException('Top-level JSON is not a List');

      _pianoRollFloatingWindows.clear();

      for (final windowEntry in decoded) {
        if (windowEntry is! Map) continue;

        final notesList = windowEntry['notes'];
        final PianoRollFloatingWindow newWindow = PianoRollFloatingWindow(
          repaintNotifier: _pianoRollRepaintNotifier,
          visible: _pianoRollVisible,
        );

        newWindow.pianoRoll.cols = 
          (windowEntry['cols'] as num?)?.toDouble() ?? 64;
        newWindow.pianoRoll.width = 
          (windowEntry['width'] as num?)?.toDouble() ?? newWindow.pianoRoll.cols * newWindow.pianoRoll.cellWidth;
        newWindow.pianoRoll.height = 
          (windowEntry['height'] as num?)?.toDouble() ?? newWindow.pianoRoll.rows * newWindow.pianoRoll.cellHeight;

        if (notesList is List) {
          for (final noteMap in notesList) {
            if (noteMap is! Map<String, dynamic>) continue;
            final note = Note.fromJson(Map<String, dynamic>.from(noteMap), newWindow.pianoRoll);
            if (note != null) newWindow.pianoRoll.notes.add(note);
          }
        }

        _pianoRollFloatingWindows.add(newWindow);
      }

      setState(() {
        _currentPianoRoll = 0;
        _pianoRollVisible.value = false;
      });

      _pianoRollRepaintNotifier.value++;

      if (mounted){
        showMessage(context, "The file has been opened.");
      }

    } catch (_) {
      if (mounted) {
        showMessage(context, "Error: An error occurred while opening the file.");
      }
    } finally {
      
      setState(() => _openJsonStatus = false);
    }
  }




  Future<void> save() async {
    String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Piano Roll Datas',
      type: FileType.custom,
      allowedExtensions: ['json'],
      fileName: 'piano_roll.json',
    );

    if (path == null) return;

    try {
      final dataToSave = _pianoRollFloatingWindows.map((window) {
        return {
          'cols': window.pianoRoll.cols,
          'width': window.pianoRoll.width,
          'height': window.pianoRoll.height,
          'notes': window.pianoRoll.notes.map((n) => n.toJson(window.pianoRoll)).toList(),
        };
      }).toList();

      final jsonString = jsonEncode(dataToSave);
      await File(path).writeAsString(jsonString);

      if (!mounted) return;
      showMessage(context, "The file has been saved.");
    } catch (_) {
      if (!mounted) return;
      showMessage(context, "Error: An error occurred while saving the file.");
    }
  }



  Future<void> exportAudio() async {
    if(_playbackStatus || _openJsonStatus) return;

    _pianoRollVisible.value = false;
    setState(() => _exportAudioStatus = true);

    String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Audio',
      type: FileType.custom,
      allowedExtensions: ['wav'],
      fileName: 'output.wav',
    );

    if (path != null) {

      _statusBar.value = "Processing...";

      final List<List<String>> allPianoRolls = _pianoRollFloatingWindows
        .map((window) => window.pianoRoll.convertPianoRollToSynthInput())
        .toList();

      final synthStatus = await _synthWrapper.synthesizeAudio(
        allPianoRolls,
        path,
      );

      if (synthStatus == ProcessStatus.unsuccessful) {
        if (mounted) {
          showMessage(context, "Error: The synthesis failed.");
          _statusBar.value = "The process failed.";
        }
      }
      else{
        _statusBar.value = "The process successful.";
      }
    }

    setState(() => _exportAudioStatus = false);

    _pianoRollVisible.value = true;
  }

  Future<void> play() async {
    if (_playbackStatus || _exportAudioStatus || _openJsonStatus) return;

    _statusBar.value = "Processing...";
    _pianoRollVisible.value = false;

    final List<List<String>> allPianoRolls = _pianoRollFloatingWindows
        .map((window) => window.pianoRoll.convertPianoRollToSynthInput())
        .toList();

    final synthStatus = await _synthWrapper.synthesizeAudio(
      allPianoRolls,
      "temp.wav",
    );

    if (synthStatus == ProcessStatus.unsuccessful) {
      if (mounted) {
        showMessage(context, "Error: The synthesis failed.");
        _statusBar.value = "The process failed.";
      }
      return;
    }

    setState(() => _playbackStatus = true);


    final playbackStart = DateTime.now().millisecondsSinceEpoch - _currentMillisecondsPosition;

    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!_playbackStatus) {
        timer.cancel();
        return;
      }

      _currentMillisecondsPosition =
          DateTime.now().millisecondsSinceEpoch - playbackStart;

      _timerStatus.value = formatTime(_currentMillisecondsPosition);
    });


    final playbackStatus = await _playbackEngineWrapper.playAudio(
      "temp.wav",
      _currentMillisecondsPosition,
    );

    if (playbackStatus == ProcessStatus.unsuccessful) {
      if (mounted) {
        showMessage(context, "Error: Playback failed.");
        _statusBar.value = "The process failed.";
      }
    }
    else{
      _statusBar.value = "The process successful.";
    }

  }



  void stop() {
    _playbackEngineWrapper.stopAudio();
    _timer?.cancel();
    _currentMillisecondsPosition = 0;
    setState(() => _playbackStatus = false);

    _statusBar.value = "The audio stopped.";
    
  }

  Future<void> seek() async {
    if (_playbackStatus) return;

    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            
            if (constraints.maxHeight < 200 || constraints.maxWidth < 300) {
              return Center(
                child: Material(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Window is too small',
                      style: TextStyle(color: AppColors.text),
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: AppColors.surfaceAlt,
              title: const Text(
                'Seek Position',
                style: TextStyle(
                  color: AppColors.text,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 260,
                  maxWidth: 400,
                ),
                child: TextField(
                  cursorColor: AppColors.accent,
                  controller: controller,
                  style: const TextStyle(
                    color: AppColors.text,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter start milliseconds (0 - ${0xFFFFFFFF})',
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.text),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(controller.text),
                  child: const Text(
                    'Ok',
                    style: TextStyle(color: AppColors.text),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final value = int.parse(result);
      if (value < 0 || value > 0xFFFFFFFF) {
        throw const FormatException();
      }

      _currentMillisecondsPosition = value;

      if (mounted) {
        showMessage(context, 'Seeked to milliseconds $value');
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Invalid value. Must be 0 - ${0xFFFFFFFF}');
      }
    }
  }



  void addPianoRoll() {
    if (_playbackStatus || _exportAudioStatus) return;

    setState(() 
        => _pianoRollFloatingWindows.add(
              PianoRollFloatingWindow(
                repaintNotifier: _pianoRollRepaintNotifier,
                visible: _pianoRollVisible,
              )
          )
      );
  }

  Future<void> removePianoRoll(int index) async {
    if (_playbackStatus || _exportAudioStatus) return;

    if(1 < _pianoRollFloatingWindows.length){
      final bool? result = await showYesNoDialog(
        context,
        "Are you really sure you want to delete it? This action is irreversible."
      );
      if(result == true){
        setState(() {
          _pianoRollFloatingWindows.removeAt(index);

          if (_currentPianoRoll >= _pianoRollFloatingWindows.length) {
            _currentPianoRoll = _pianoRollFloatingWindows.length - 1;
          }
        });
      }
    }
    
  }



  String formatTime(int totalMs) {
    final int ms = totalMs % 1000;
    final int totalSeconds = totalMs ~/ 1000;
    final int seconds = totalSeconds % 60;
    final int totalMinutes = totalSeconds ~/ 60;
    final int minutes = totalMinutes % 60;
    final int hours = totalMinutes ~/ 60;

    final paddedMs = ms.toString().padLeft(3, '0');
    final paddedSeconds = seconds.toString().padLeft(2, '0');
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    final paddedHours = hours.toString().padLeft(2, '0');

    if (hours >= 100) {
      return '100+:$paddedMinutes:$paddedSeconds:$paddedMs';
    }

    return '$paddedHours:$paddedMinutes:$paddedSeconds:$paddedMs';
  }

  

  

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.fullBlack,
      bottomNavigationBar: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.outline, width: 2),
          )
        ),
        child: Align(
          alignment: AlignmentGeometry.centerLeft,
          child: ValueListenableBuilder(
            valueListenable: _statusBar,
            builder: (_, value, _) => Text(
              value,
              style: TextStyle(color: AppColors.text),
            ),
          ),
        )
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight < 520 || constraints.maxWidth < 520) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: AppColors.fullBlack,
                  child: Text(
                    'Window is too small',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }

            return Container(
              color: AppColors.background,
              child: Column(
                children: [
                  /// ───────── MENU BAR ─────────
                  Container(
                    height: 30,
                    alignment: Alignment.centerLeft,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      border: Border(
                        bottom: BorderSide(color: AppColors.outline, width: 2),
                      ),
                    ),
                    child: MenuBar(
                      style: MenuStyle(
                        backgroundColor:
                            WidgetStateProperty.all(AppColors.background),
                      ),
                      children: [
                        SubmenuButton(
                          style: _menuButtonStyle,
                          menuStyle: MenuStyle(
                            backgroundColor:
                                WidgetStateProperty.all(AppColors.background),
                          ),
                          menuChildren: [
                            MenuItemButton(
                              style: _menuButtonStyle,
                              onPressed: _playbackStatus || _exportAudioStatus
                                  ? null
                                  : open,
                              child: const Text("Open"),
                            ),
                            MenuItemButton(
                              style: _menuButtonStyle,
                              onPressed: save,
                              child: const Text("Save"),
                            ),
                            MenuItemButton(
                              style: _menuButtonStyle,
                              onPressed: _playbackStatus ||
                                      _openJsonStatus ||
                                      _exportAudioStatus
                                  ? null
                                  : exportAudio,
                              child: const Text("Export Audio"),
                            ),
                          ],
                          child: const Text("File"),
                        ),

                        SubmenuButton(
                          style: _menuButtonStyle,
                          menuStyle: MenuStyle(
                            backgroundColor:
                                WidgetStateProperty.all(AppColors.background),
                          ),
                          menuChildren: [
                            MenuItemButton(
                              style: _menuButtonStyle,
                              onPressed: _playbackStatus || _exportAudioStatus
                                  ? null
                                  : () => showDialog(
                                        context: context,
                                        builder: (_) => AudioSettingsPage(
                                          synthWrapper: _synthWrapper,
                                          playbackEngineWrapper:
                                              _playbackEngineWrapper,
                                        ),
                                      ),
                              child: const Text("Audio"),
                            ),
                          ],
                          child: const Text("Settings"),
                        ),

                        SubmenuButton(
                          style: _menuButtonStyle,
                          menuStyle: MenuStyle(
                            backgroundColor:
                                WidgetStateProperty.all(AppColors.background),
                          ),
                          menuChildren: [
                            MenuItemButton(
                              style: _menuButtonStyle,
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => const AboutPage(),
                              ),
                              child: const Text("About"),
                            ),
                          ],
                          child: const Text("Help"),
                        ),
                      ],
                    ),
                  ),

                  /// ───────── TOOL BAR ─────────
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      border: Border(
                        bottom: BorderSide(color: AppColors.outline, width: 2),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconToolButton(
                          icon: Icons.play_arrow_rounded,
                          color: AppColors.accent,
                          width: 40,
                          height: 40,
                          onPressed: play,
                          enabled: !(_playbackStatus ||
                              _exportAudioStatus ||
                              _openJsonStatus),
                        ),
                        const SizedBox(width: 5),

                        IconToolButton(
                          icon: Icons.stop_rounded,
                          color: AppColors.text,
                          width: 40,
                          height: 40,
                          onPressed: stop,
                          enabled: _playbackStatus,
                        ),
                        const SizedBox(width: 5),

                        IconToolButton(
                          icon: Icons.fast_forward_rounded,
                          color: AppColors.text,
                          width: 40,
                          height: 40,
                          onPressed: seek,
                          enabled: !_playbackStatus,
                        ),

                        const VerticalDivider(
                          color: AppColors.surfaceAlt,
                          indent: 12,
                          endIndent: 12,
                          width: 30,
                        ),

                        IconToolButton(
                          icon: Icons.add_circle_outline,
                          color: AppColors.text,
                          width: 40,
                          height: 40,
                          onPressed: addPianoRoll,
                          enabled:
                              !(_playbackStatus || _exportAudioStatus),
                        ),
                        const SizedBox(width: 5),

                        IconToolButton(
                          icon: Icons.delete_forever_outlined,
                          color: _isDeletePianoRoll
                              ? AppColors.red
                              : AppColors.text,
                          width: 40,
                          height: 40,
                          onPressed: () => setState(
                              () => _isDeletePianoRoll = !_isDeletePianoRoll),
                          enabled:
                              !(_playbackStatus || _exportAudioStatus),
                        ),

                        const VerticalDivider(
                          color: AppColors.surfaceAlt,
                          indent: 12,
                          endIndent: 12,
                          width: 30,
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.fullBlack,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.outline, width: 1),
                          ),
                          child: ValueListenableBuilder(
                            valueListenable: _timerStatus,
                            builder: (_, value, __) => Text(
                              value,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontFamily: 'ShareTechMono',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ───────── MAIN CONTENT ─────────
                  Expanded(
                    child: Stack(
                      children: [
                        ListView.builder(
                          itemCount: _pianoRollFloatingWindows.length,
                          itemBuilder: (context, index) {
                            return Card(
                              color: AppColors.surfaceAlt,
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: InkWell(
                                onTap: () async {
                                  if (_playbackStatus ||
                                      _exportAudioStatus) {
                                    return;
                                  }

                                  if (_isDeletePianoRoll) {
                                    await removePianoRoll(index);
                                  } else {
                                    _pianoRollRepaintNotifier.value++;
                                    _pianoRollVisible.value = true;
                                    if (_currentPianoRoll != index) {
                                      setState(() =>
                                          _currentPianoRoll = index);
                                    }
                                  }
                                },
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        ' Piano Roll ${index + 1}',
                                        style: TextStyle(
                                            color: AppColors.text),
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 100,
                                      child: CustomPaint(
                                        painter: PianoRollPreviewPainter(
                                          _pianoRollRepaintNotifier,
                                          _pianoRollFloatingWindows[index]
                                              .pianoRoll,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        ValueListenableBuilder<bool>(
                          valueListenable: _pianoRollVisible,
                          builder: (_, visible, __) => Visibility(
                            visible: visible,
                            child: _pianoRollFloatingWindows[
                                _currentPianoRoll],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

    );
     
    
  }
}
