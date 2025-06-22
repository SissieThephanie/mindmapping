import 'package:flutter/material.dart';
import 'package:mindmapping/View/Navigation/navbar.dart';
import 'package:mindmapping/utils/global.color.dart';

class SaveBtn extends StatelessWidget {
  const SaveBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Navbar()),
        );
      },

      child: Container(
        alignment: Alignment.center,
        height: 50,
        decoration: BoxDecoration(
          color: GlobalColor.mainColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Text(
          'Save',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}