import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mindmapping/utils/global.color.dart';

class SocialLogin extends StatelessWidget {
  const SocialLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          child: Text(
            '-- Or sign in with --',
            style: TextStyle(
              color: GlobalColor.textColor,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        
        const SizedBox(height: 15,),
        SizedBox(
          width: MediaQuery.of(context).size.width *0.8,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset('assets/images/google.svg', height: 30,),
                  
                ),
              ),
          
              SizedBox(width: 10,),
              Expanded(
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset('assets/images/facebook.svg', height: 30,),
                  
                ),
              ),
              
              SizedBox(width: 10,),
              Expanded(
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/images/instagram.svg', 
                    height: 30
                    ),
                  
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}