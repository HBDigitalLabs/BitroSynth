import 'package:flutter/material.dart';
import 'piano_roll.dart';
import "common_types.dart";

 
class PianoRollPreviewPainter extends CustomPainter {
  final Listenable repaintNotifier;
  final PianoRoll pianoRoll;

  PianoRollPreviewPainter(
    this.repaintNotifier,
    this.pianoRoll
  ) : super(repaint: repaintNotifier);
  


  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = AppColors.surfaceAlt
      ..style = PaintingStyle.fill;

    final Paint notePaint = Paint()
      ..color = AppColors.text
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    double xScale = size.width / pianoRoll.cols;
    double yScale = size.height / pianoRoll.rows;


    for(Note note in pianoRoll.notes){
      final double rectX = note.startCol * xScale;
      final double rectY = note.rowIndex * yScale;
      final double rectWidth = note.lengthInCols * xScale;
      final double rectHeight = yScale;

      final rect = Rect.fromLTWH(
        rectX,
        rectY,
        rectWidth,
        rectHeight,
      );

      canvas.drawRect(rect, notePaint);

    }
    
  }



  @override
  bool shouldRepaint(covariant PianoRollPreviewPainter oldDelegate) {
    return oldDelegate.pianoRoll != pianoRoll;
  }

  
}
