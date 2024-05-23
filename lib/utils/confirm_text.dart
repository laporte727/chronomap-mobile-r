import 'package:flutter/material.dart';

class ConfirmText extends StatelessWidget {
  final String? confirmText;
  final Color confirmColor;

  const ConfirmText({
    required this.confirmText,
    required this.confirmColor,

    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: confirmColor),
      ),
      child: Center(
        child: Text(
          confirmText??"",
          style: TextStyle(
            fontSize: 18,
            color: confirmColor,
          ),
        ),
      ),
    );
  }
}