import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';

class ButtonLong extends StatelessWidget {
  final Widget? prefix;
  final String text;
  final void Function() onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ButtonLong({
    super.key,
    this.prefix,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed, 
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(20),
          ),
          backgroundColor: backgroundColor ?? AppColors().appBlue,
          foregroundColor: foregroundColor ?? AppColors().appWhite,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(prefix != null) ...[
              prefix!,
            ],
            Text(text, 
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}