import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as ffi;
import 'dart:io' show Platform, Directory;
import '../common_types.dart';
import '../utils.dart';
import 'package:path/path.dart' as path;

enum PlaybackCommandType {
    none(0),
    init(1),
    play(2),
    stop(3),
    deInit(4),
    setSampleRate(5);

    final int value;
    const PlaybackCommandType(this.value);
}



class PlaybackEngineWrapper {

  late final void Function() _init;
  late final void Function() _deInit;
  late final void Function(int) _setSampleRate;

  late final int Function() _getProcessStatus;
  late final int Function() _getCurrentCommand;

  late final void Function(
    ffi.Pointer<ffi.Char>,
    int
  ) _playAudio;
  late final void Function() stopAudio;

  Future<ProcessStatus> waitForCompletion() async {
    while (_getCurrentCommand() != PlaybackCommandType.none.value) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_getProcessStatus() == ProcessStatus.unsuccessful.value) {
      return ProcessStatus.unsuccessful;
    } else {
      return ProcessStatus.successful;
    }
  }


  Future<ProcessStatus> init() async {
    _init();

    return await waitForCompletion();

  }

  Future<ProcessStatus> deInit() async {
    _deInit();

    return await waitForCompletion();
    
  }

  Future<ProcessStatus> setSampleRate(int newSampleRate) async {
    _setSampleRate(newSampleRate);

    return await waitForCompletion();
    
  }

  Future<ProcessStatus> playAudio(
    String inputPath,
    int millisecondsPosition
  ) async {
    final ffi.Pointer<ffi.Char> cInputPath = inputPath.toNativeUtf8().cast<ffi.Char>();

    _playAudio(
      cInputPath,
      millisecondsPosition
    );

    final status = await waitForCompletion();
    

    ffi.malloc.free(cInputPath);

    return status;
    
  }




  PlaybackEngineWrapper(){

    final String libraryName;

    if (Platform.isMacOS) {
      libraryName = 'librust_playback_engine.dylib';
    } else if (Platform.isWindows) {
      libraryName = 'rust_playback_engine.dll';
    } else {
      libraryName = 'librust_playback_engine.so';
    }
    
    final dylib = openBundledLibrary(libraryName);

    stopAudio = dylib.lookupFunction
      <
        ffi.Void Function(),
        void Function()
      > ('stop_audio');

    _playAudio = dylib.lookupFunction
      <
        ffi.Void Function(
          ffi.Pointer<ffi.Char>,
          ffi.Uint32
        ),
        void Function(
          ffi.Pointer<ffi.Char>,
          int
        )
      > ('play_audio');

    _setSampleRate = dylib.lookupFunction
      <
        ffi.Void Function(
          ffi.Uint32
        ),
        void Function(
          int
        )
      > ('set_sample_rate');

    _init = dylib.lookupFunction
      <
        ffi.Void Function(),
        void Function()
      > ('init');

    _deInit = dylib.lookupFunction
      <
        ffi.Void Function(),
        void Function()
      > ('de_init');

    _getCurrentCommand = dylib.lookupFunction
      <
        ffi.Int Function(),
        int Function()
      > ('get_current_command');

    _getProcessStatus = dylib.lookupFunction
      <
        ffi.Int Function(),
        int Function()
      > ('get_process_status');


  }
}
