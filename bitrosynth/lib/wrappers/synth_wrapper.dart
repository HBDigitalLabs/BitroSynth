import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as ffi;
import 'dart:io' show Platform, Directory;
import '../common_types.dart';
import '../utils.dart';
import 'package:path/path.dart' as path;

enum SynthCommandType {
    none(0),
    synthesizeAudio(1),
    set8BitStatus(2),
    getSampleRate(3),
    setSampleRate(4);

    final int value;
    const SynthCommandType(this.value);
}

class SynthWrapper {

  late final int Function(
    ffi.Pointer<ffi.Pointer<ffi.Pointer<ffi.Char>>>,
    ffi.Pointer<ffi.Uint32>,
    int,
    ffi.Pointer<ffi.Char>,
  ) _synthesizeAudio;

  late final int Function() getSampleRate;
  late final void Function(int) setSampleRate;
  late final void Function(int) _set8BitStatus;
  

  late final int Function() _getProcessStatus;
  late final int Function() _getCurrentCommand;

  Future<ProcessStatus> waitForCompletion() async {
    while (_getCurrentCommand() != SynthCommandType.none.value) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_getProcessStatus() == ProcessStatus.unsuccessful.value) {
      return ProcessStatus.unsuccessful;
    } else {
      return ProcessStatus.successful;
    }
  }


  

  void setBitStatus(AudioBitDepth newBitDepth){
    if (newBitDepth == AudioBitDepth.Bit8){
      _set8BitStatus(1);
    }
    else{
      _set8BitStatus(0);
    }
  }

 
  Future<ProcessStatus> synthesizeAudio(
    List<List<String>> data,
    String outputPath,
  ) async {

    final outerSize = data.length;
    final outerPtr = ffi.calloc<ffi.Pointer<ffi.Pointer<ffi.Char>>>(outerSize);
    final sizesPtr = ffi.calloc<ffi.Uint32>(outerSize);

    final innerPtrs = <ffi.Pointer<ffi.Pointer<ffi.Char>>>[];

    for (var i = 0; i < data.length; i++) {
      final innerList = data[i];
      sizesPtr[i] = innerList.length;

      final innerPtr = ffi.calloc<ffi.Pointer<ffi.Char>>(innerList.length);
      for (var j = 0; j < innerList.length; j++) {
        innerPtr[j] = innerList[j].toNativeUtf8().cast<ffi.Char>();
      }

      outerPtr[i] = innerPtr;
      innerPtrs.add(innerPtr);
    }

    final cOutputPath = outputPath.toNativeUtf8().cast<ffi.Char>();

    _synthesizeAudio(
      outerPtr,
      sizesPtr,
      outerSize,
      cOutputPath,
    );

    final status = await waitForCompletion();

    for (var innerPtr in innerPtrs) {
      for (var j = 0; j < sizesPtr[innerPtrs.indexOf(innerPtr)]; j++) {
        ffi.calloc.free(innerPtr[j]);
      }
      ffi.calloc.free(innerPtr);
    }

    ffi.calloc.free(outerPtr);
    ffi.calloc.free(sizesPtr);
    ffi.calloc.free(cOutputPath);

    return status;
  }



  SynthWrapper(){

    final String libraryName;

    if (Platform.isMacOS) {
      libraryName = 'librust_synthesize_engine.dylib';
    } else if (Platform.isWindows) {
      libraryName = 'rust_synthesize_engine.dll';
    } else {
      libraryName = 'librust_synthesize_engine.so';
    }
    
    
    final dylib = openBundledLibrary(libraryName);
    
    setSampleRate = dylib.lookupFunction
      <
        ffi.Void Function(ffi.Uint32),
        void Function(int)
      >
      ('set_sample_rate');

    getSampleRate = dylib.lookupFunction
      <
        ffi.Uint32 Function(),
        int Function()
      >
      ('get_sample_rate');


    _set8BitStatus = dylib.lookupFunction
      <
        ffi.Void Function(ffi.UnsignedChar),
        void Function(int)
      >
      ('set_8_bit_status');


    _synthesizeAudio = dylib.lookupFunction
      <
        ffi.Int32 Function(
          ffi.Pointer<ffi.Pointer<ffi.Pointer<ffi.Char>>>,  // data
          ffi.Pointer<ffi.Uint32>,                          // sizes_array
          ffi.Uint32,                                       // outer_size
          ffi.Pointer<ffi.Char>,                            // output path
        ),

        int Function(
          ffi.Pointer<ffi.Pointer<ffi.Pointer<ffi.Char>>>,
          ffi.Pointer<ffi.Uint32>,
          int,
          ffi.Pointer<ffi.Char>,
        )

      >
      ('synthesize_audio');

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
