import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';

class BMIWidget extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String userId;

  BMIWidget({required this.firestore, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
      child: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching data.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No profile data found.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var weight = double.tryParse(userData['weight'] ?? '0') ?? 0;
          var height = double.tryParse(userData['height'] ?? '0') ?? 0;

          double bmi = weight / ((height / 100) * (height / 100));
          int bmiRounded = bmi.round();

          String bmiCategory = '';
          double bmiPercentage = 0;

          if (bmi < 18.5) {
            bmiCategory = "Underweight";
            bmiPercentage = bmi / 18.5;
          } else if (bmi >= 18.5 && bmi <= 24.9) {
            bmiCategory = "Normal weight";
            bmiPercentage = (bmi - 18.5) / (24.9 - 18.5);
          } else if (bmi >= 25 && bmi <= 29.9) {
            bmiCategory = "Overweight";
            bmiPercentage = (bmi - 25) / (29.9 - 25);
          } else {
            bmiCategory = "Obesity";
            bmiPercentage = (bmi - 30) / (40 - 30);
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BMI (Body Mass Index)",
                    style: TextStyle(
                        color: TColor.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "You have $bmiCategory",
                    style: TextStyle(
                        color: TColor.white.withOpacity(0.7),
                        fontSize: 12),
                  ),
                  Text(
                    "estimated to $bmiRounded",
                    style: TextStyle(
                        color: TColor.white.withOpacity(0.7),
                        fontSize: 12),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.02),
                  SizedBox(
                    width: 120,
                    height: 35,
                    child: RoundButton(
                      title: "View More",
                      type: RoundButtonType.bgSGradient,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(),
                    startDegreeOffset: 250,
                    borderData: FlBorderData(show: true),
                    sectionsSpace: 1,
                    centerSpaceRadius: 0,
                    sections: [
                      PieChartSectionData(
                        value: bmiPercentage * 100,
                        color: TColor.secondaryColor1,
                        title: '$bmiRounded',
                        radius: 50,
                        titleStyle: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: (1 - bmiPercentage) * 100,
                        color: Colors.white.withOpacity(0.6),
                        radius: 50,
                        title: '',
                        titleStyle: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
