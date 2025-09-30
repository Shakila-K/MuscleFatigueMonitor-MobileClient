
import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';
import 'package:muscle_fatigue_monitor/consts/screen_size.dart';
import 'package:muscle_fatigue_monitor/screens/record_threshold.dart';
import 'package:muscle_fatigue_monitor/screens/record_muscle_fatigue.dart';
import 'package:muscle_fatigue_monitor/screens/users_screen.dart';
import 'package:muscle_fatigue_monitor/services/user_provider.dart';
import 'package:muscle_fatigue_monitor/services/websocket_provider.dart';
import 'package:muscle_fatigue_monitor/widgets/button_long.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late TextEditingController ipAddressController;

  @override
  void initState() {
    super.initState();
    ipAddressController = TextEditingController();
  }

  @override
  void dispose() {
    ipAddressController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
      
  final ipV4Regex = RegExp(
    r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );

  String? validateIpAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an IP address.';
    }
    if (!ipV4Regex.hasMatch(value)) {
      return 'Please enter a valid IPv4 address.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {

    final ws = context.watch<WebSocketProvider>();
    final userProvider = context.watch<UserProvider>();

    Future<void> connectDeviceDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors().backgroundBlack,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Connect device", style: TextStyle(fontSize: 20, color: AppColors().appWhite),),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close, color: AppColors().appWhite,))
            ],
          ),
          
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Enter the ip address shown on the device.', style: TextStyle(fontSize: 14, color: AppColors().appWhite.withAlpha(240)),),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: ipAddressController,
                    validator: (value) => validateIpAddress(value),
                    cursorColor: AppColors().appWhite,
                    style: TextStyle(color: AppColors().appWhite),
                    keyboardType: TextInputType.numberWithOptions(
                      signed: false,
                      decimal: true
                    ),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(      
                        borderSide: BorderSide(color: AppColors().appGrey),   
                      ),  
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors().appWhite),
                      ),  
                      
             
                    ),
                  )
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: <Widget>[
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: (){
                  Navigator.of(context).pop();
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().appRed.withAlpha(200),
                  foregroundColor: AppColors().appWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10)
                  )
                ),
                child: Text("Cancel")
              ),
            ),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: (){
                  if(_formKey.currentState!.validate()){
                    final ws = context.read<WebSocketProvider>();
                    ws.connect(ipAddressController.text.trim());
                    Navigator.of(context).pop();
                  }
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().appBlue,
                  foregroundColor: AppColors().appWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10)
                  )
                ),
                child: Text("Connect")
              ),
            ),
            
          ],
        );
      },
    );
  }

    return Scaffold(
      backgroundColor: AppColors().backgroundBlack,
      appBar: AppBar(
        title: 
          Text("Muscle Fatigue Monitor", 
            style: TextStyle(
              color: AppColors().appWhite, 
              fontWeight: FontWeight.bold),
          ),
        backgroundColor: AppColors().backgroundBlack,
      ),

      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: ScreenSize().width(context)*0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors().appWhite.withAlpha(50)),
                color: AppColors().appGrey.withAlpha(20)
              ),
              width: 80,
              height: 80,
              child: IconButton(
                icon: Icon(userProvider.hasCurrentUser() ? Icons.person : Icons.person_off),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => UsersScreen())
                  );
                }, 
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(userProvider.user != null ? "User ID: ${userProvider.user!.userId}, ${userProvider.user!.gender}" : "No user selected",
                style: TextStyle(
                  color: AppColors().appGrey,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ws.isConnected ? "Device connected." : "Device not connected.",
                    style: TextStyle(
                      color: AppColors().appGrey
                    ),
                  ),
              
                  TextButton(
                    onPressed: () async {
                          if(ws.isConnected){
                              ws.disconnect(false);
                          } else if(!ws.isConnected || !ws.isConnecting) {
                            connectDeviceDialog();
                          }
                      }, 
                    child: Text(ws.isConnected ? "Disconnect?" : "Connect?",
                      style: TextStyle(
                        color: AppColors().appWhite
                      ),
                    )
                  ),
              
                  if(ws.isConnecting || ws.retryCount!=0) 
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors().appWhite,
                      )
                    ),
                  ),
                ],
              ),
            ),

            

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: ButtonLong(
                prefix: Container(
                  margin: EdgeInsets.only(right: 10),
                  width: 25,
                  height: 25,
                  child: Image.asset("assets/icons/button.png", color: AppColors().appWhite,)
                ),
                text: "Record Fatigue Index",
                onPressed: () {
                  if(!ws.isConnected){
                    toastification.dismissAll();
                    toastification.show(
                      context: context, // optional if you use ToastificationWrapper
                      title: Text('Device not connected!'),
                      description: Text("Please connect the EMG device and try again."),
                      type: ToastificationType.error,
                      style: ToastificationStyle.fillColored,
                      alignment: Alignment.bottomCenter,
                      animationDuration: const Duration(milliseconds: 300),
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  } else if(!userProvider.hasCurrentUser()){
                    toastification.dismissAll();
                    toastification.show(
                      context: context,
                      title: Text('User not selected!'),
                      description: Text("Please select a user and try again."),
                      type: ToastificationType.error,
                      style: ToastificationStyle.fillColored,
                      alignment: Alignment.bottomCenter,
                      animationDuration: const Duration(milliseconds: 300),
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  }else{
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => RecordThreshold())
                    );
                  }
                },
              ),
            ),

            if(userProvider.user != null && userProvider.user!.threshold != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: ButtonLong(
                prefix: Container(
                  margin: EdgeInsets.only(right: 10),
                  width: 25,
                  height: 25,
                  // child: Image.asset("assets/icons/button.png", color: AppColors().appWhite,)
                  child: Icon(Icons.fitness_center, color: AppColors().appWhite, size: 22,),
                ),
                backgroundColor: AppColors().appGreen,
                text: "Record Muscle Fatigue",
                onPressed: () {
                  if(!ws.isConnected){
                    toastification.dismissAll();
                    toastification.show(
                      context: context, // optional if you use ToastificationWrapper
                      title: Text('Device not connected!'),
                      description: Text("Please connect the EMG device and try again."),
                      type: ToastificationType.error,
                      style: ToastificationStyle.fillColored,
                      alignment: Alignment.bottomCenter,
                      animationDuration: const Duration(milliseconds: 300),
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  } else{
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => RecordMuscleFatigue())
                    );
                  }
                },
              ),
            ),

            Text("Start recording to capture muscle activity baseline.",
              style: TextStyle(
                color: AppColors().appGrey
              ),
            )
            
          ],
        ),
      ),
    );
  }
}