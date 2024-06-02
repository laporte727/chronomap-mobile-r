import 'package:chronomap_mobile/utils/shadowed_container.dart';
import 'package:flutter/material.dart';

class TffFormat extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const TffFormat({
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ShadowedContainer(
      child: TextFormField(
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 16,
            color: Colors.green[900]),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(5.0),
          hintText: hintText,
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              width: 0.5,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class NumberFormat extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const NumberFormat({
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ShadowedContainer(
      child: TextFormField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 16,
            color: Colors.green[900]),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(5.0),
          hintText: hintText,
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              width: 0.5,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}