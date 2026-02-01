import 'package:flutter/material.dart';
import "common_types.dart";


enum WaveformType {
    sine,
    square,
    triangle,
    sawtooth,
    whiteNoise,
    pinkNoise
}

enum PianoRollMode{
    add,
    delete
}

class GestureDetectorValues{
  int dragCurrentCol = 0;
  bool isDragging = false;
  int dragStartCol = 0;
  int dragRow = 0;
  Offset localPosition = Offset(0,0);
}


class Note {
  final WaveformType waveform;
  final String noteName;
  final int startCol;
  final int rowIndex;
  final int lengthInCols;

  const Note({
    required this.waveform,
    required this.noteName,
    required this.startCol,
    required this.rowIndex,
    required this.lengthInCols,
  });

  Map<String, dynamic> toJson(PianoRoll pianoRoll) => {
        'noteName': noteName,
        'startCol': startCol,
        'lengthInCols': lengthInCols,
        'waveform': pianoRoll.waveformTypeToString(waveform),
      };

  static Note? fromJson(Map<String, dynamic> m, PianoRoll pianoRoll) {
    final noteName = m['noteName'] as String?;
    if (noteName == null) return null;

    final startCol = (m['startCol'] as num?)?.toInt() ?? 0;
    final lengthInCols = (m['lengthInCols'] as num?)?.toInt() ?? 1;
    final waveformStr = (m['waveform'] as String?) ?? 'Sine';

    final waveform = pianoRoll.stringToWaveformType(waveformStr);
    final rowIndex = PianoRoll.noteNames.indexOf(noteName);
    if (rowIndex == -1) return null;

    return Note(
      waveform: waveform,
      noteName: noteName,
      startCol: startCol,
      rowIndex: rowIndex,
      lengthInCols: lengthInCols,
    );
  }


  
}
 
class PianoRoll extends CustomPainter {
  final GestureDetectorValues mouseValues;
  final Listenable repaintNotifier;

  PianoRoll(
    this.mouseValues,
    this.repaintNotifier
  ) : super(repaint: repaintNotifier){
    width = cols * cellWidth;
    height = rows * cellHeight;
    cellMs = 60000 ~/ (_tempo * _gridDivision);
  }

  final List<Note> notes = [];

  static const List<String> noteNames = [
        "B8",  "A#8", "A8",  "G#8", "G8",  "F#8", "F8",  "E8",
        "D#8", "D8",  "C#8", "C8",

        "B7",  "A#7", "A7",  "G#7", "G7",  "F#7", "F7",  "E7",
        "D#7", "D7",  "C#7", "C7",

        "B6",  "A#6", "A6",  "G#6", "G6",  "F#6", "F6",  "E6",
        "D#6", "D6",  "C#6", "C6",

        "B5",  "A#5", "A5",  "G#5", "G5",  "F#5", "F5",  "E5",
        "D#5", "D5",  "C#5", "C5",

        "B4",  "A#4", "A4",  "G#4", "G4",  "F#4", "F4",  "E4",
        "D#4", "D4",  "C#4", "C4",

        "B3",  "A#3", "A3",  "G#3", "G3",  "F#3", "F3",  "E3",
        "D#3", "D3",  "C#3", "C3",

        "B2",  "A#2", "A2",  "G#2", "G2",  "F#2", "F2",  "E2",
        "D#2", "D2",  "C#2", "C2",

        "B1",  "A#1", "A1",  "G#1", "G1",  "F#1", "F1",  "E1",
        "D#1", "D1",  "C#1", "C1",

        "B0",  "A#0", "A0",  "G#0", "G0",  "F#0", "F0",  "E0",
        "D#0", "D0",  "C#0", "C0"
      ];

  double cols = 64;
  final int rows = noteNames.length;


  final double cellWidth = 20;
  final double cellHeight = 20;


  final int _tempo = 120;
  final int _gridDivision = 4;
  late final int cellMs;
    
  PianoRollMode mode = PianoRollMode.add;
  WaveformType addWaveformType = WaveformType.sine;

  
  late double width;
  late double height;

  List<String> convertPianoRollToSynthInput(){

    List<String> outputPerRow = [];

    final int noteCount = notes.length;
    if (noteCount == 0) {
      return outputPerRow;
    }


    for (int row = 0; row < rows; ++row) {

        String rowOutput = "";
        int currentGlobalCol = 0;

        List<Note> rowNotes = [];
        for (Note note in notes) {

            if (note.rowIndex == row) {
                rowNotes.add(note);
            }

        }

        if (rowNotes.isEmpty) continue;
        

        rowNotes.sort((a, b) => a.startCol.compareTo(b.startCol));



        for (Note note in rowNotes) {
            int noteGlobalStart = note.startCol;

            if (noteGlobalStart > currentGlobalCol) {
                int gapLength = noteGlobalStart - currentGlobalCol;
                rowOutput += "C0_${cellMs * gapLength}_0_Silence>";
            }

            rowOutput += 
              "${note.noteName}_${cellMs * note.lengthInCols}_1_${waveformTypeToString(note.waveform)}>";

            currentGlobalCol = noteGlobalStart + note.lengthInCols;
        }
        


        if (rowOutput.isNotEmpty && rowOutput.endsWith('>')) {
          rowOutput = rowOutput.substring(0, rowOutput.length - 1);
        }

        outputPerRow.add(rowOutput);
    }

    return outputPerRow;
  }

  String waveformTypeToString(WaveformType type){
    
      switch(type)
      {
        case WaveformType.sine:       return "Sine";
        case WaveformType.square:     return "Square";
        case WaveformType.triangle:   return "Triangle";
        case WaveformType.sawtooth:   return "Sawtooth";
        case WaveformType.whiteNoise: return "WhiteNoise";
        case WaveformType.pinkNoise:  return "PinkNoise";
      }


  }


  WaveformType stringToWaveformType(String value) {


    switch(value)
    {
      case "Sine":       return  WaveformType.sine;
      case "Square":     return WaveformType.square;
      case "Triangle" :   return WaveformType.triangle;
      case "Sawtooth":   return WaveformType.sawtooth;
      case "WhiteNoise": return  WaveformType.whiteNoise;
      default:  return WaveformType.pinkNoise;
    }


  }
  


  @override
  void paint(Canvas canvas, Size size) {
    final paintForPianoRoll = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final paintForNoteRect = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    final waveformNameTextStyle = TextStyle(
      color: AppColors.darkText,
      fontSize: 12,
    );

    final noteNameTextStyle = TextStyle(
      color: AppColors.text,
      fontSize: 12,
    );
    
    final Paint backgroundPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    int rowIndex = 0;
    for (String noteName in noteNames) {

        final double y = rowIndex * cellHeight;

        canvas.drawLine(
          Offset(2, y),
          Offset(cols * cellWidth,y),
          paintForPianoRoll
        );

        final textSpan = TextSpan(
          text: noteName,
          style: noteNameTextStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        final offset = Offset(2, y);
        textPainter.paint(canvas, offset);

        ++rowIndex;
    }

    for(int columnIndex = 0;columnIndex <= cols;++columnIndex){
        final double x = columnIndex * cellWidth;
        
        canvas.drawLine(
          Offset(x,0),
          Offset(x,rows * cellHeight),
          paintForPianoRoll
        );
    }

    

    
    for(Note note in notes){

        final double rectWidth = note.lengthInCols * cellWidth;
        final double rectX = note.startCol * cellWidth;
        final double rectY = note.rowIndex * cellHeight;

        final Rect noteRect = Rect.fromLTWH(
          rectX,
          rectY,
          rectWidth,
          cellHeight
        );

        canvas.drawRect(noteRect, paintForNoteRect);


        String waveformTypeString = waveformTypeToString(note.waveform);

        final textSpan = TextSpan(
          text: waveformTypeString,
          style: waveformNameTextStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();




        if(textPainter.width > rectWidth){
            final double avgCharWidth = textPainter.width / waveformTypeString.length;
            final int charsThatFit = (rectWidth / avgCharWidth).toInt();

            if(charsThatFit > 0) {
              waveformTypeString = waveformTypeString.substring(0, charsThatFit - 1);
            } else {
              waveformTypeString = "";
            }

            textPainter.text = TextSpan(
              text: waveformTypeString,
              style: waveformNameTextStyle
            );
        
            textPainter.layout();
        }

        final double textX = rectX + 2;

        final double textY =
          rectY + (cellHeight - textPainter.height) / 2;

        textPainter.paint(
          canvas,
          Offset(textX, textY)
        );

    }

    if(mouseValues.isDragging && mode == PianoRollMode.add){
        final int length = 
          (mouseValues.dragCurrentCol >= mouseValues.dragStartCol)
          ? (mouseValues.dragCurrentCol - mouseValues.dragStartCol + 1)
          : 1;

        final strokeRectPaint = Paint()
          ..color = AppColors.accent
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

        final double rectWidth = length * cellWidth;
        final double rectX = mouseValues.dragStartCol * cellWidth;
        final double rectY = mouseValues.dragRow * cellHeight;

        final Rect noteRect = Rect.fromLTWH(
          rectX,
          rectY,
          rectWidth,
          cellHeight
        );

        canvas.drawRect(noteRect, strokeRectPaint);

    }
    
  }



  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
