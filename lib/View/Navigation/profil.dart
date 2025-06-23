import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mindmapping/Services/project_storage.dart';
import 'package:mindmapping/View/Navigation/navbar.dart';
import 'dart:io';
import 'package:mindmapping/utils/global.color.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  
  bool isLoading = false;
  bool isEditing = false;
  bool isFirstTimeSetup = false;
  File? _imageFile;
  String? _profileImageUrl;
  String? _currentUserId;
  int _projectsCount = 0;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Get.put(ProjectStorage()); 
    // Defer the loading to avoid potential scaffold geometry issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  // Méthode pour charger le nombre de projets
  Future<void> _loadProjectsCount() async {
    try {
      final projectStorage = ProjectStorage.instance;
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        if (mounted) {
          setState(() {
            _projectsCount = 0;
          });
        }
        return;
      }

      // Synchroniser avec Firestore d'abord
      await projectStorage.syncWithFirestore();

      // Récupérer tous les projets
      final projects = projectStorage.getAllProjects();

      // Filtrer uniquement les projets de l'utilisateur connecté
      final userProjects = projects.where((p) => p['userId'] == userId).toList();

      if (mounted) {
        setState(() {
          _projectsCount = userProjects.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _projectsCount = 0;
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        
        // Charger les données du profil depuis Firestore
        final doc = await FirebaseFirestore.instance
            .collection('user_profiles')
            .doc(user.uid)
            .get();

        if (mounted) {
          if (doc.exists) {
            final data = doc.data()!;
            _nameController.text = data['name'] ?? user.displayName ?? '';
            _phoneController.text = data['phone'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _organizationController.text = data['organization'] ?? '';
            _profileImageUrl = data['profileImageUrl'] ?? user.photoURL;
            
            // Vérifier si c'est le premier setup
            isFirstTimeSetup = data['isProfileComplete'] == false;
            if (isFirstTimeSetup) {
              setState(() {
                isEditing = true;
              });
            }
          } else {
            // Première connexion, utiliser les données Firebase Auth
            _nameController.text = user.displayName ?? '';
            _profileImageUrl = user.photoURL;
            isFirstTimeSetup = true;
            setState(() {
              isEditing = true;
            });
          }
          
          // Charger le nombre de projets dans tous les cas
          await _loadProjectsCount();
        }
      }
    } catch (e) {
      if (mounted) {
        // Use WidgetsBinding to schedule the snackbar after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorSnackBar('Erreur lors du chargement du profil: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GlobalColor.mainColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${DateTime.now().difference(FirebaseAuth.instance.currentUser?.metadata.creationTime ?? DateTime.now()).inDays}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Jours depuis\nl\'inscription',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$_projectsCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Projets\ncréés',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (image != null && mounted) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
        });
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _profileImageUrl;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_currentUserId}.jpg');

      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorSnackBar('Erreur lors du téléchargement de l\'image: $e');
        });
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Télécharger l'image si nécessaire
      String? imageUrl = await _uploadImage();

      // Vérifier si c'est un nouveau profil
      final doc = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(_currentUserId)
          .get();
      
      bool isNewProfile = !doc.exists;

      final profileData = {
        'name': _nameController.text.trim(),
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'organization': _organizationController.text.trim(),
        'profileImageUrl': imageUrl,
        'isProfileComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Ajouter createdAt seulement si c'est un nouveau profil
      if (isNewProfile) {
        profileData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Sauvegarder dans Firestore
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(_currentUserId)
          .set(profileData, SetOptions(merge: true));

      // Mettre à jour le profil Firebase Auth si nécessaire
      if (_nameController.text.trim().isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text.trim());
      }
      
      if (imageUrl != null) {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(imageUrl);
      }

      if (mounted) {
        setState(() {
          isEditing = false;
          isFirstTimeSetup = false;
          _profileImageUrl = imageUrl;
          _imageFile = null;
        });

        // Schedule the dialog/snackbar after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isFirstTimeSetup) {
            _showWelcomeCompleteDialog();
          } else {
            _showSuccessSnackBar('Profil mis à jour avec succès !');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showWelcomeCompleteDialog() {
    if (!mounted) return;
    
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
                Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              const Text('Profil complété !'),
            ],
          ),
          content: const Text(
            'Votre profil a été configuré avec succès. Vous pouvez maintenant commencer à créer vos mind maps !',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.offAll(() => const Navbar());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColor.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Commencer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: GlobalColor.mainColor.withOpacity(0.1),
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (_profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : null) as ImageProvider?,
          child: _imageFile == null && _profileImageUrl == null
              ? Icon(
                  Icons.person,
                  size: 60,
                  color: GlobalColor.mainColor,
                )
              : null,
        ),
        if (isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GlobalColor.mainColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled && isEditing,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !enabled || !isEditing,
        fillColor: (!enabled || !isEditing) 
            ? Colors.grey.withOpacity(0.1) 
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isFirstTimeSetup ? 'Configurer mon profil' : 'Mon Profil'),
        backgroundColor: GlobalColor.mainColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !isFirstTimeSetup,
        actions: [
          if (!isEditing && !isFirstTimeSetup)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditing = true),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Photo de profil
                    _buildProfileImage(),
                    
                    const SizedBox(height: 30),
                    
                    // Nom complet
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir votre nom';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email (non modifiable)
                    _buildTextField(
                      controller: TextEditingController(
                        text: FirebaseAuth.instance.currentUser?.email ?? ''
                      ),
                      label: 'Email',
                      icon: Icons.email,
                      enabled: false,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Téléphone
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 8) {
                          return 'Numéro de téléphone invalide';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Organisation
                    _buildTextField(
                      controller: _organizationController,
                      label: 'Organisation/Entreprise',
                      icon: Icons.business,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bio
                    _buildTextField(
                      controller: _bioController,
                      label: 'Biographie',
                      icon: Icons.description,
                      maxLines: 3,
                      validator: (value) {
                        if (value != null && value.length > 200) {
                          return 'La biographie ne peut pas dépasser 200 caractères';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Boutons d'action
                    if (isEditing || isFirstTimeSetup) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GlobalColor.mainColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : Text(
                                      isFirstTimeSetup ? 'Terminer la configuration' : 'Sauvegarder',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          if (!isFirstTimeSetup) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading ? null : () {
                                  setState(() {
                                    isEditing = false;
                                    _imageFile = null;
                                  });
                                  _loadUserProfile();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(color: GlobalColor.mainColor),
                                ),
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(
                                    color: GlobalColor.mainColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Statistiques
                    if (!isEditing && !isFirstTimeSetup) 
                      _buildStatisticsCard(),
                  ],
                ),
              ),
            ),
    );
  }
}