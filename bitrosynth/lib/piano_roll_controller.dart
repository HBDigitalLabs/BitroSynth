import 'package:flutter/material.dart';
import "common_types.dart";
import 'widgets/transport_button.dart';
import 'piano_roll.dart';

class PianoRollController extends StatefulWidget {
    final PianoRoll pianoRoll;
    final ScrollController yScrollController;
    final ScrollController xScrollController;


    const PianoRollController({
      super.key,
      required this.pianoRoll,
      required this.yScrollController,
      required this.xScrollController
    });
    
    @override
    State<PianoRollController> createState() => _PianoRollControllerState();
}
    
class _PianoRollControllerState extends State<PianoRollController> {

  bool _isAddButtonEnabled = false;
  bool _isDeleteButtonEnabled = true;
  late final List<String> _drowdownMenuItems;
  late String _dropdownValue;

  
  void enableAddMode(){
    widget.pianoRoll.mode = PianoRollMode.add;
    setState(() {
      _isAddButtonEnabled = false;
      _isDeleteButtonEnabled = true;
    });
  }
  void enableDeleteMode(){
    widget.pianoRoll.mode = PianoRollMode.delete;
    setState(() {
      _isAddButtonEnabled = true;
      _isDeleteButtonEnabled = false;
    });
  }

  void updateYScrollPosition(double value)
    => widget.yScrollController.jumpTo(value);
  
  void updateXScrollPosition(double value)
    => widget.xScrollController.jumpTo(value);
  

  @override
  void initState() {
    super.initState();
    _drowdownMenuItems = [
      widget.pianoRoll.waveformTypeToString(WaveformType.pinkNoise),
      widget.pianoRoll.waveformTypeToString(WaveformType.sawtooth),
      widget.pianoRoll.waveformTypeToString(WaveformType.sine),
      widget.pianoRoll.waveformTypeToString(WaveformType.square),
      widget.pianoRoll.waveformTypeToString(WaveformType.triangle),
      widget.pianoRoll.waveformTypeToString(WaveformType.whiteNoise),
    ];
    _dropdownValue = _drowdownMenuItems[2];
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(2, 4, 2, 4),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 2),
        ),
      ),
      child: Row(
        spacing: 2,
        children: [

          SizedBox(width: 5,),

          IconToolButton(
            icon: Icons.add_circle_outline,
            color: AppColors.text,
            width: 50,
            height: 35,
            onPressed: enableAddMode,
            enabled: _isAddButtonEnabled,
          ),

          IconToolButton(
            icon: Icons.remove_circle_outline,
            color: AppColors.text,
            width: 50,
            height: 35,
            onPressed: enableDeleteMode,
            enabled: _isDeleteButtonEnabled,
          ),

          Container(
            margin: EdgeInsetsGeometry.symmetric(horizontal: 6),
            height: 25,
            width: 2,
            color: AppColors.outline,
          ),


          DropdownButton<String>(
            dropdownColor: AppColors.surfaceAlt,
            style: TextStyle(color: AppColors.text,),
            value: _dropdownValue,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            underline: Container(height: 2, color: AppColors.outline),
            onChanged: (String? value) {
              if(value != null){
                widget.pianoRoll.addWaveformType = 
                  widget.pianoRoll.stringToWaveformType(value);
                setState(() => _dropdownValue = value);
              }
            },
            items: _drowdownMenuItems.map<DropdownMenuItem<String>>(
              (String value) 
                => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value)
                  )
                ).toList(),
          ),

          Expanded(
            flex: 1,
            child: SizedBox()
            ),

          // Left
          IconToolButton(
            icon: Icons.arrow_back,
            color: AppColors.text,
            width: 35,
            height: 35,
            onPressed: () => updateXScrollPosition(widget.xScrollController.offset - 80),
          ),

          // Right
          IconToolButton(
            icon: Icons.arrow_forward,
            color: AppColors.text,
            width: 35,
            height: 35,
            onPressed: () => updateXScrollPosition(widget.xScrollController.offset + 80),
          ),

          // Up
          IconToolButton(
            icon: Icons.arrow_upward,
            color: AppColors.text,
            width: 35,
            height: 35,
            onPressed: () => updateYScrollPosition(widget.yScrollController.offset - 80),
          ),

          // Down
          IconToolButton(
            icon: Icons.arrow_downward,
            color: AppColors.text,
            width: 35,
            height: 35,
            onPressed: () => updateYScrollPosition(widget.yScrollController.offset + 80),
          ),

          SizedBox(width: 5,)

        ],
      ),
    );
  }
}