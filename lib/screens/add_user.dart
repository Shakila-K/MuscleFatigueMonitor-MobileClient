import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';
import 'package:muscle_fatigue_monitor/services/user_provider.dart';
import 'package:muscle_fatigue_monitor/widgets/button_long.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class AddUser extends StatefulWidget {
  const AddUser({super.key});

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController userIdController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController ageController;

  List<String> genders = ["male", "female"];

  late String gender;

  @override
  void initState() {
    super.initState();
    userIdController = TextEditingController();
    heightController = TextEditingController();
    weightController = TextEditingController();
    ageController = TextEditingController();
    gender = genders[0];
  }

  @override
  void dispose() {
    userIdController.dispose();
    heightController.dispose();
    weightController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final userProvider = context.watch<UserProvider>();
    
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors().backgroundBlack,
        appBar: AppBar(
          title: Text("Add User"),
          backgroundColor: AppColors().backgroundBlack,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                TextFormField(
                  keyboardType: TextInputType.number,
                  controller: userIdController,
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    labelStyle: TextStyle(color: AppColors().appGrey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors().appGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors().appBlue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a user ID';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20),

                TextFormField(
                  keyboardType: TextInputType.number,
                  controller: ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(color: AppColors().appGrey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors().appGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors().appBlue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an age';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          labelStyle: TextStyle(color: AppColors().appGrey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors().appGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors().appBlue),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter height';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          labelStyle: TextStyle(color: AppColors().appGrey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors().appGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors().appBlue),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter weight';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Gender:",
                      style: TextStyle(color: AppColors().appGrey, fontSize: 16),
                    ),
                    const SizedBox(width: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: genders[0],
                          groupValue: gender,
                          fillColor: WidgetStatePropertyAll(AppColors().appBlue),
                          onChanged: (value) {
                            setState(() => gender = value!);
                          },
                        ),
                        Text("Male", style: TextStyle(color: AppColors().appGrey, fontSize: 16)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: genders[1],
                          groupValue: gender,
                          fillColor: WidgetStatePropertyAll(AppColors().appBlue),
                          onChanged: (value) {
                            setState(() => gender = value!);
                          },
                        ),
                        Text("Female", style: TextStyle(color: AppColors().appGrey, fontSize: 16)),
                      ],
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: ButtonLong(
                    prefix: Container(
                      margin: EdgeInsets.only(right: 10),
                      width: 25,
                      height: 25,
                      child: Icon(Icons.save, size: 22,)
                    ),
                    text: "Save User",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if(userProvider.userExists(int.parse(userIdController.text.trim()))){
                          toastification.show(
                            context: context, // optional if you use ToastificationWrapper
                            title: Text('User ID already exist!'),
                            description: Text("Please change the user id and try again."),
                            type: ToastificationType.error,
                            style: ToastificationStyle.fillColored,
                            alignment: Alignment.bottomCenter,
                            animationDuration: const Duration(milliseconds: 300),
                            autoCloseDuration: const Duration(seconds: 3),
                          );
                          return;
                        } else {
                          userProvider.addUser(
                            userId: int.parse(userIdController.text.trim()),
                            gender: gender,
                            age: int.parse(ageController.text.trim()),
                            height: double.parse(heightController.text.trim()),
                            weight: double.parse(weightController.text.trim()),
                          );
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                ),
          
              ],
            ),
          ),
        ),
      ),
    );
  }
}