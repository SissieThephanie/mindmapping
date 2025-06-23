import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindmapping/View/Navigation/navbar.dart';
import 'package:mindmapping/View/Navigation/profil.dart';
import 'package:mindmapping/View/login.view.dart';
import 'package:mindmapping/View/widgets/social.login.dart';
import 'package:mindmapping/utils/global.color.dart';
import 'package:get/get.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Méthode pour créer le profil utilisateur initial dans Firestore
  Future<void> _createUserProfile(User user) async {
    try {
      final userProfileData = {
        'name': nameController.text.trim(),
        'email': user.email ?? '',
        'phone': '',
        'bio': '',
        'organization': '',
        'profileImageUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isProfileComplete': false, // Indicateur pour savoir si le profil est complet
      };

      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .set(userProfileData);

      print('Profil utilisateur créé dans Firestore');
    } catch (e) {
      print('Erreur lors de la création du profil: $e');
      // Ne pas bloquer l'inscription si la création du profil échoue
    }
  }

  // Méthode de création de compte avec gestion d'état et contexte sécurisé
  createUserWithEmailAndPassword() async {
    if (!mounted) return;
    
    // Vérifier que les mots de passe correspondent
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        isLoading = true;
      });
      
      // Créer le compte utilisateur
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      
      // Mettre à jour le profil avec le nom
      await userCredential.user?.updateDisplayName(nameController.text.trim());
      
      // Créer le profil utilisateur dans Firestore
      if (userCredential.user != null) {
        await _createUserProfile(userCredential.user!);
      }
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // MODIFICATION PRINCIPALE: Rediriger vers la page profil au lieu de Navbar
        _showWelcomeDialog();
      }
      
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'Le mot de passe est trop faible. Utilisez au moins 8 caractères avec des chiffres et des lettres.';
            break;
          case 'email-already-in-use':
            errorMessage = 'Un compte existe déjà avec cet email.';
            break;
          case 'invalid-email':
            errorMessage = 'Format d\'email invalide.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'L\'inscription par email est désactivée.';
            break;
          default:
            errorMessage = 'Erreur lors de la création du compte: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Une erreur inattendue s\'est produite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Dialog de bienvenue avec options
  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.celebration,
                color: GlobalColor.mainColor,
              ),
              const SizedBox(width: 8),
              const Text('Bienvenue !'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre compte a été créé avec succès, ${nameController.text.trim()} !',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Que souhaitez-vous faire maintenant ?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.off(() => const Navbar());
              },
              child: Text(
                'Continuer plus tard',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.off(() => const ProfileView());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColor.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Compléter mon profil',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      'MindMapping',
                      style: TextStyle(
                        color: GlobalColor.mainColor,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                  Text(
                    'Créer un compte',
                    style: TextStyle(
                      color: GlobalColor.mainColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Name input
                  TextFormField(
                    controller: nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) {
                        return 'Veuillez saisir votre nom complet';
                      }
                      if (text.trim().length < 2) {
                        return 'Le nom doit contenir au moins 2 caractères';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Nom complet",
                      prefixIcon: Icon(Icons.person),
                      hintText: "Ex: Jean Dupont",
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Email input
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) {
                        return 'Veuillez saisir votre email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text.trim())) {
                        return 'Veuillez saisir un email valide';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      hintText: "votre@email.com",
                    ),
                  ),

                  const SizedBox(height: 10),
                  
                  // Password input
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    validator: (text) {
                      if (text == null || text.isEmpty) {
                        return 'Veuillez saisir votre mot de passe';
                      }
                      if (text.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Mot de passe",
                      prefixIcon: Icon(Icons.lock),
                      hintText: "Au moins 6 caractères",
                    ),
                  ),

                  const SizedBox(height: 10),
                  
                  // Confirm Password input
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    validator: (text) {
                      if (text == null || text.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      if (text != passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: "Confirmer le mot de passe",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // SignUp button
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () {
                        if (_formKey.currentState!.validate()) {
                          createUserWithEmailAndPassword();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColor.mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.1),
                      ),
                      child: isLoading 
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Créer mon compte',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  const SocialLogin(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 50,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Vous avez déjà un compte ? '),
            InkWell(
              onTap: () {
                Get.to(() => const LoginView());
              },
              child: Text(
                'Se connecter',
                style: TextStyle(
                  color: GlobalColor.mainColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}