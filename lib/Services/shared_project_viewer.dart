import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindmapping/Services/firebase_mind_service.dart';
import 'package:mindmapping/View/Navigation/mind_map_editor.dart';

class SharedProjectViewer extends StatelessWidget {
  const SharedProjectViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SharedProjectController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projet Partagé'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Code de partage',
                hintText: 'Entrez le code reçu...',
                prefixIcon: Icon(Iconsax.link),
              ),
              onSubmitted: (value) => controller.loadSharedProject(value),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.sharedProject.value != null) {
                return MindMapEditor(
                  projectTitle: controller.sharedProject.value!['title'],
                  projectDescription: controller.sharedProject.value!['description'],
                  existingProjectId: controller.sharedProject.value!['id'],
                );
              }

              return const Center(
                child: Text('Entrez un code de partage pour voir le projet'),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class SharedProjectController extends GetxController {
  final FirebaseMindMapService _firebaseService = Get.find<FirebaseMindMapService>();
  
  final Rx<Map<String, dynamic>?> sharedProject = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoading = false.obs;

  Future<void> loadSharedProject(String shareToken) async {
    if (shareToken.trim().isEmpty) return;

    try {
      isLoading.value = true;
      final project = await _firebaseService.getSharedProject(shareToken.trim());
      
      if (project != null) {
        sharedProject.value = project;
      } else {
        Get.snackbar('Erreur', 'Code de partage invalide ou projet non trouvé');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger le projet partagé');
    } finally {
      isLoading.value = false;
    }
  }
}