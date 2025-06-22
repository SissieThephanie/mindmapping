import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindmapping/Services/firebase_mind_service.dart';
import 'package:mindmapping/View/Navigation/mind_map_editor.dart';

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProjectListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Projets'),
        actions: [
          IconButton(
            onPressed: () => controller.refreshProjects(),
            icon: const Icon(Iconsax.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.projects.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.document, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun projet trouvé',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Créez votre premier mind map !',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.projects.length,
          itemBuilder: (context, index) {
            final project = controller.projects[index];
            return ProjectCard(
              project: project,
              onTap: () => controller.openProject(project['id']),
              onDelete: () => controller.deleteProject(project['id']),
              onDuplicate: () => controller.duplicateProject(project['id']),
              onShare: () => controller.shareProject(project['id']),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.createNewProject(),
        child: const Icon(Iconsax.add),
      ),
    );
  }
}

class ProjectListController extends GetxController {
  final FirebaseMindMapService _firebaseService = Get.find<FirebaseMindMapService>();
  
  final RxList<Map<String, dynamic>> projects = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      isLoading.value = true;
      final userProjects = await _firebaseService.getUserProjects();
      projects.assignAll(userProjects);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les projets');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProjects() async {
    await loadProjects();
  }

  void createNewProject() {
    Get.dialog(
      AlertDialog(
        title: const Text('Nouveau Projet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Titre du projet',
                hintText: 'Mon mind map',
              ),
              onChanged: (value) => _newProjectTitle = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
              ),
              onChanged: (value) => _newProjectDescription = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => MindMapEditor(
                projectTitle: _newProjectTitle,
                projectDescription: _newProjectDescription,
              ));
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void openProject(String projectId) {
    Get.to(() => MindMapEditor(existingProjectId: projectId));
  }

  Future<void> deleteProject(String projectId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Supprimer le projet'),
        content: const Text('Cette action est irréversible. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      try {
        final success = await _firebaseService.deleteProject(projectId);
        if (success) {
          projects.removeWhere((p) => p['id'] == projectId);
          Get.snackbar('Succès', 'Projet supprimé');
        }
      } catch (e) {
        Get.snackbar('Erreur', 'Impossible de supprimer le projet');
      }
    }
  }

  Future<void> duplicateProject(String projectId) async {
    try {
      final newProjectId = await _firebaseService.duplicateProject(projectId);
      if (newProjectId != null) {
        await refreshProjects();
        Get.snackbar('Succès', 'Projet dupliqué');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de dupliquer le projet');
    }
  }

  void shareProject(String projectId) async {
    try {
      final success = await _firebaseService.shareProject(projectId);
      if (success) {
        final project = await _firebaseService.getProject(projectId);
        final shareToken = project?['shareToken'];
        
        if (shareToken != null) {
          Get.dialog(
            AlertDialog(
              title: const Text('Partager le projet'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Code de partage:'),
                  const SizedBox(height: 10),
                  SelectableText(
                    shareToken,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de partager le projet');
    }
  }

  String _newProjectTitle = '';
  String _newProjectDescription = '';
}

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onShare;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF6C63FF),
          child: Icon(Iconsax.diagram, color: Colors.white),
        ),
        title: Text(
          project['title'] ?? 'Projet sans titre',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project['description']?.isNotEmpty ?? false)
              Text(project['description']),
            const SizedBox(height: 4),
            Text(
              'Modifié: ${_formatDate(project['lastModified'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onShare,
              child: const Row(
                children: [
                  Icon(Iconsax.share),
                  SizedBox(width: 8),
                  Text('Partager'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: onDuplicate,
              child: const Row(
                children: [
                  Icon(Iconsax.copy),
                  SizedBox(width: 8),
                  Text('Dupliquer'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: onDelete,
              child: const Row(
                children: [
                  Icon(Iconsax.trash, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Date invalide';
    }
  }
}
