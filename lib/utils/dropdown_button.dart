import 'package:flutter/material.dart';

// Custom Dropdown Button Widget
class CustomDropdownButton extends StatefulWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const CustomDropdownButton({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  @override
  CustomDropdownButtonState createState() => CustomDropdownButtonState();
}

class CustomDropdownButtonState extends State<CustomDropdownButton> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedValue,
      alignment: Alignment.center,
      dropdownColor: Colors.lightBlue[50],
      borderRadius: BorderRadius.circular(20.0),
      onChanged: (String? newValue) {
        setState(() {
          selectedValue = newValue;
          widget.onChanged(newValue);
        });
      },
      items: widget.options.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}