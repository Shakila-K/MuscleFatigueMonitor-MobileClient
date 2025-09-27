import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';
import 'package:muscle_fatigue_monitor/models/user_model.dart';
import 'package:muscle_fatigue_monitor/screens/add_user.dart';
import 'package:muscle_fatigue_monitor/screens/user_screen.dart';
import 'package:muscle_fatigue_monitor/services/user_provider.dart';
import 'package:provider/provider.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final userProvider = context.watch<UserProvider>();

    List<UserModel> users = userProvider.getAllUsers();

    return Scaffold(
      backgroundColor: AppColors().backgroundBlack,
      appBar: AppBar(
        title: Text("Select user"),
        backgroundColor: AppColors().backgroundBlack,
      ),
      body: users.isEmpty
          ? Center(
              child: Text(
                "No users found",
                style: TextStyle(
                  color: AppColors().appGrey,
                  fontSize: 18,
                ),
              ),
            )
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    'User ID: ${users[index].userId}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Gender : ${users[index].gender}", style: TextStyle(color: AppColors().appGrey),),
                          SizedBox(width: 20,),
                          Text("Height : ${users[index].height} cm", style: TextStyle(color: AppColors().appGrey),),
                          SizedBox(width: 20,),
                          Text("Weight : ${users[index].weight} kg", style: TextStyle(color:AppColors().appGrey),),
                          
                        ],
                      ),
                      Row(
                        children: [
                          Text("Threshold : ${users[index].threshold == 0 ? "N/A" : users[index].threshold}", style: TextStyle(color: AppColors().appGrey),),
                          SizedBox(width: 20,),
                          Text("MFI : ${users[index].mfi == 0 ? "N/A" : users[index].mfi}", style: TextStyle(color: AppColors().appGrey),),
                        ],
                      )
                    ],
                  ),
                  minVerticalPadding: 15,
                  selected: userProvider.user?.userId == users[index].userId,
                  selectedTileColor: AppColors().appGrey.withAlpha(40),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => UserScreen(user: users[index])),
                    );
                  },
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
        child: FloatingActionButton(
          onPressed: (){
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AddUser())
            );
          },
          backgroundColor: AppColors().appBlue,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}