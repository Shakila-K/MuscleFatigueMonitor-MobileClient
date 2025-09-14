import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';

class GraphDataInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String data;
  final Color iconColor;
  const GraphDataInfo({
    super.key,
    required this.icon,
    required this.title,
    required this.data,
    required this.iconColor
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        height: 110,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors().appGrey.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors().appGrey.withAlpha(50))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10,),
                Text(title,)
              ],
            ),
            const SizedBox(height: 10),
            Text(data, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),)
          ],
        ),
      ),

    );
  }
}