import 'package:flutter/material.dart';

class GameAutocompleteFormat extends StatefulWidget {
  final List<String> value;
  final TextEditingController searchController;

  const GameAutocompleteFormat({
    required this.value,
    required this.searchController,
    super.key,
  });

  @override
  GameAutocompleteFormatState createState() => GameAutocompleteFormatState();
}

class GameAutocompleteFormatState extends State<GameAutocompleteFormat> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        return widget.value.where((String value) {
          if (textEditingValue.text.isNotEmpty) {
            return value.contains(textEditingValue.text[0].toUpperCase() +
                textEditingValue.text.substring(1).toLowerCase());
          } else {
            return value.contains(textEditingValue.text);
          }
        });
      },
      onSelected: (String selection) {
        widget.searchController.text = selection;
      },
    );
  }
}
