import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindmapping/View/Navigation/navbar.dart';
import 'package:mindmapping/View/login.view.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // En cours de vérification de l'état d'authentification
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Si l'utilisateur est connecté, afficher la page d'accueil
        if (snapshot.hasData && snapshot.data != null) {
          return const Navbar();
        }
        
        // Si l'utilisateur n'est pas connecté, afficher la page de connexion
        return const LoginView();
      },
    );
  }
}