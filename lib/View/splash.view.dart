import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mindmapping/View/widgets/auth.view.dart';
import 'package:mindmapping/utils/global.color.dart';
import 'package:get/get.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 1) , (){
      Get.to(AuthWrapper());
    });
    return Scaffold( 
      backgroundColor: GlobalColor.mainColor,
      body: Center(
        child: Text(
          'Mindmapping',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold ,

          ),
        ) ,
        )
    );
  }
}