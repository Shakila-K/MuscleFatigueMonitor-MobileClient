import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';
import 'package:muscle_fatigue_monitor/models/user_model.dart';
import 'package:muscle_fatigue_monitor/services/user_provider.dart';
import 'package:muscle_fatigue_monitor/widgets/button_long.dart';
import 'package:provider/provider.dart';


class UserScreen extends StatelessWidget {
  final UserModel user;
  const UserScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {

    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors().backgroundBlack,
      appBar: AppBar(
        title: Text("User Info"),
        backgroundColor: AppColors().backgroundBlack,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text('User ID: ${user.userId}'),
            ),
            ListTile(
              title: Text('Gender: ${user.gender}'),
            ),
            ListTile(
              title: Text('Height: ${user.height} cm'),
            ),
            ListTile(
              title: Text('Weight: ${user.weight} kg'),
            ),
            ListTile(
              title: Text('Threshold: ${user.threshold == 0 ? "N/A" : user.threshold}'),
            ),
            ListTile(
              title: Text('Fatigue Index: ${user.mfi == 0 ? "N/A" : user.mfi}'),
            ),
        
            const Spacer(),
        
            Visibility(
              visible: user.reading.isNotEmpty,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                height: 70,
                child: ButtonLong(
                  backgroundColor: AppColors().appGreen,
                  prefix: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(Icons.print),
                  ), 
                  text: "Print Data", 
                  onPressed: (){}
                ),
              ),
            ),
        
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              height: 70,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ButtonLong(
                      prefix: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(Icons.delete, size: 22,),
                      ), 
                      text: "Delete", 
                      backgroundColor: AppColors().appRed,
                      onPressed: (){
                        userProvider.deleteUser(user.userId);
                        Navigator.of(context).pop();
                      }
                    )
                  ),
                  const SizedBox(width: 20,),
                  Expanded(
                    flex: 1,
                    child: ButtonLong(
                      prefix: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(Icons.check),
                      ), 
                      text: "Select", 
                      onPressed: (){
                        userProvider.getUser(user.userId);
                        Navigator.of(context).pop();
                      }
                    )
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}