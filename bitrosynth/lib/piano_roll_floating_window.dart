import 'package:flutter/material.dart';

import 'widgets/transport_button.dart';
import 'common_types.dart';
import 'piano_roll.dart';
import 'piano_roll_controller.dart';

class PianoRollFloatingWindow extends StatefulWidget {

  final ValueNotifier<bool> visible;
  final ValueNotifier<int> repaintNotifier;
  final GestureDetectorValues _gestureDetectorValues = GestureDetectorValues();

  late final PianoRoll pianoRoll;

  PianoRollFloatingWindow({
    super.key,
    required this.repaintNotifier,
    required this.visible
  }){
    pianoRoll = PianoRoll(
      _gestureDetectorValues,
      repaintNotifier
    );
  }

  @override
  State<PianoRollFloatingWindow> createState() => _PianoRollFloatingWindowState();
}

class _PianoRollFloatingWindowState extends State<PianoRollFloatingWindow> {
  Offset position = const Offset(0, 0);
  Size size = const Size(700, 500);




  final ScrollController _yScrollController = ScrollController();
  final ScrollController _xScrollController = ScrollController();




  void onHorizontalDragStart(DragStartDetails details) { 
                            
    if(widget.pianoRoll.mode == PianoRollMode.add){
      final int col = (details.localPosition.dx / widget.pianoRoll.cellWidth).toInt();
      final int row = (details.localPosition.dy / widget.pianoRoll.cellHeight).toInt();

      widget._gestureDetectorValues.isDragging = true;
      widget._gestureDetectorValues.dragStartCol = col;
      widget._gestureDetectorValues.dragRow = row;
    }
  }

  void onHorizontalDragEnd(DragEndDetails details){
    if(widget._gestureDetectorValues.isDragging)
    {
      final int endCol = 
        (details.localPosition.dx / widget.pianoRoll.cellWidth).toInt();

      if(endCol >= widget.pianoRoll.cols - 1){
        setState(() {
                                  
          widget.pianoRoll.cols += 64;
          widget.pianoRoll.width = widget.pianoRoll.cols * widget.pianoRoll.cellWidth;
          widget.pianoRoll.height = widget.pianoRoll.rows * widget.pianoRoll.cellHeight;
        });

      }

      int length = (endCol >= widget._gestureDetectorValues.dragStartCol) 
        ? (endCol - widget._gestureDetectorValues.dragStartCol + 1)
        : 1;

      Note n = Note(
        lengthInCols: length,
        waveform: widget.pianoRoll.addWaveformType,
        startCol: widget._gestureDetectorValues.dragStartCol,
        rowIndex: widget._gestureDetectorValues.dragRow,
        noteName: PianoRoll.noteNames[widget._gestureDetectorValues.dragRow]
      );

      bool isOverlapping = false;
      for(Note existingNote in widget.pianoRoll.notes){
        if(existingNote.rowIndex == n.rowIndex){
          int existingStart = existingNote.startCol;
          int existingEnd = existingNote.startCol + existingNote.lengthInCols - 1;
          int newStart = n.startCol;
          int newEnd = n.startCol + n.lengthInCols - 1;

          if(!(newEnd < existingStart || newStart > existingEnd)){
            isOverlapping = true;
            break;
          }
        }
      }

      if(!isOverlapping && length > 0){
        widget.pianoRoll.notes.add(n);
      }

      widget._gestureDetectorValues.isDragging = false;

      widget.repaintNotifier.value++;
        
    }
  }

 

                            

                          

  void onHorizontalDragUpdate(DragUpdateDetails details){
    if(widget._gestureDetectorValues.isDragging){

      widget._gestureDetectorValues.dragCurrentCol = 
        (details.localPosition.dx / widget.pianoRoll.cellWidth).toInt();


      widget.repaintNotifier.value++;
    }
  }

  void onTapDown(TapDownDetails details){
    
    if(widget.pianoRoll.mode == PianoRollMode.delete){

      final int col = (details.localPosition.dx / widget.pianoRoll.cellWidth).toInt();
      final int row = (details.localPosition.dy / widget.pianoRoll.cellHeight).toInt();

      widget.pianoRoll.notes.removeWhere((note) =>
        note.rowIndex == row &&
        col >= note.startCol &&
        col < note.startCol + note.lengthInCols
      );

      widget.repaintNotifier.value++;

    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: size.width,
      height: size.height,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: [
            // Title bar
            GestureDetector(
              onPanUpdate: (d) {
                setState(() => position += d.delta);
              },
              child: Container(
                height: 35,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: AppColors.background,
                child: Row(
                  children: [
                    Text("Piano Roll",                    
                        style: const TextStyle(color: AppColors.text)),
                    const Spacer(),
                    IconToolButton(
                      icon: Icons.close,
                      color: AppColors.accent,
                      width: 30,
                      height: 30,
                      onPressed: () => widget.visible.value = false,
                    ),
                  ],
                ),
              ),
            ),
            
            PianoRollController(
              pianoRoll: widget.pianoRoll,
              yScrollController: _yScrollController,
              xScrollController: _xScrollController,
            ),
            
              
            Expanded(
              child: Scrollbar(
                scrollbarOrientation: ScrollbarOrientation.left,
                controller: _yScrollController,
                trackVisibility: true,
                thumbVisibility: true,
                child: SingleChildScrollView(

                  controller: _yScrollController,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(

                    controller: _xScrollController,
                    trackVisibility: true,
                    thumbVisibility: true,

                    child: SingleChildScrollView(

                      scrollDirection: Axis.horizontal,
                      controller: _xScrollController,
                      child: GestureDetector(


                        onHorizontalDragUpdate: onHorizontalDragUpdate,
                        onHorizontalDragStart: onHorizontalDragStart,
                        onHorizontalDragEnd : onHorizontalDragEnd,
                        onTapDown: onTapDown,
                        child: SizedBox(
                          width: widget.pianoRoll.width,
                          height: widget.pianoRoll.height,
                          child: CustomPaint(
                            painter: widget.pianoRoll,
                          ),
                        ),
                      ),
                    ),
                  ),

                ),
              ),

            )
          ],
        ),
      ),
    );
  }
}
