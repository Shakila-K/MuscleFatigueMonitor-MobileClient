import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/consts/colors.dart';
import 'package:muscle_fatigue_monitor/models/user_model.dart';
import 'package:muscle_fatigue_monitor/services/pdf_service.dart';
import 'package:muscle_fatigue_monitor/services/user_provider.dart';
import 'package:muscle_fatigue_monitor/widgets/button_long.dart';
import 'package:muscle_fatigue_monitor/widgets/emg_graph.dart';
import 'package:provider/provider.dart';


class UserScreen extends StatelessWidget {
  final UserModel user;
  const UserScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {

    final userProvider = context.watch<UserProvider>();

    double maxMFY = user.mfSeries.isNotEmpty ? user.mfSeries.map((e) => e.value).reduce((a, b) => a > b ? a : b)*1.25 : 0.001;

    return Scaffold(
      backgroundColor: AppColors().backgroundBlack,
      appBar: AppBar(
        title: Text("User Info"),
        backgroundColor: AppColors().backgroundBlack,
      ),
      body: SingleChildScrollView(
        child: Wrap(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text('Username: ${user.userId}'),
            ),
            ListTile(
              title: Text('Gender: ${user.gender}'),
            ),
            ListTile(
              title: Text('Age: ${user.age} years'),
            ),
            ListTile(
              title: Text('Height: ${user.height} cm'),
            ),
            ListTile(
              title: Text('Weight: ${user.weight} kg'),
            ),
            ListTile(
              title: Text('Muscle Fatigue Index: ${user.threshold == 0 ? "N/A" : user.threshold}'),
            ),

            ListTile(
              title: Text('EMG Signal ${(user.readings.isEmpty)? ": N/A" : "" }'),
            ),

            if(user.readings.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: SizedBox(
                  width: (user.readings.last.timestamp.inSeconds - user.readings.first.timestamp.inSeconds) * 50 + 50,
                  child: EmgGraph(sensorValues: user.readings, timeStamp: user.readings.last.timestamp, lastvalues: false,)
                ),
              )
            ),

            ListTile(
              title: Text('Muscle Fatigue Variation ${(user.mfSeries.isEmpty)? ": N/A" : "" }'),
            ),


            if(user.mfSeries.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: SizedBox(
                  width: (user.mfSeries.last.timestamp.inSeconds - user.mfSeries.first.timestamp.inSeconds) * 50 + 50,
                  child: EmgGraph(sensorValues: user.mfSeries, timeStamp: user.mfSeries.last.timestamp, lastvalues: false, maximumY: maxMFY,)
                ),
              )
            ),
        
        
            Visibility(
              visible: user.readings.isNotEmpty,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                margin: EdgeInsets.only(top: 50),
                height: 70,
                child: ButtonLong(
                  backgroundColor: AppColors().appGreen,
                  prefix: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(Icons.print),
                  ), 
                  text: "Print Data", 
                  onPressed: () async{
                    final pdfData = await PdfService().generateUserReport(
                      userId: user.userId.toString(),
                      gender: user.gender,
                      age: user.age,
                      height: user.height,
                      weight: user.weight,
                      emgValues: user.readings,
                      mfValues: user.mfSeries,
                      threshold: user.threshold,
                    );

                    await PdfService().sharePdf(pdfData, '${user.userId}_report');

                  }
                ),
              ),
            ),
        
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              margin: EdgeInsets.only(top: 20),
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
            ),
            Container(
              height: 150,
              child: Text(''),
            ),
          ],
        ),
      ),
    );
  }
}