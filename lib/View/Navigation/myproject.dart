// Modifications complètes pour myproject.dart avec correction Firestore Timestamp

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindmapping/Services/project_storage.dart';
import 'package:mindmapping/View/Navigation/create.dart';
import 'package:mindmapping/View/Navigation/mind_map_editor.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ajout de l'import Firestore

class Myproject extends StatelessWidget {
  const Myproject({super.key});

  @override
  Widget build(BuildContext context) {
    final projectStorage = Get.put(ProjectStorage());
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Charger les projets lorsque le widget est initialisé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId != null) {
        projectStorage.projects.clear();
        projectStorage.fetchProjectsFromFirestore(userId);
      }
    });


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes Projets',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gérez vos mind maps',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Stats Cards
              Obx(() => Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Projets',
                      '${projectStorage.projects.length}',
                      Iconsax.folder_2,
                      const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      'Récents',
                      '${projectStorage.getRecentProjects(limit: 7).length}',
                      Iconsax.clock,
                      const Color(0xFF00D4AA),
                    ),
                  ),
                ],
              )),
              
              const SizedBox(height: 30),
              
              // Section Projets Récents
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Projets Récents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAllProjects(projectStorage),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Liste des projets
              
              Obx(() {
                final projectStorage = Get.find<ProjectStorage>();
                
                if (projectStorage.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (projectStorage.errorMessage.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 50),
                        SizedBox(height: 16),
                        Text(
                          projectStorage.errorMessage.value,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final userId = FirebaseAuth.instance.currentUser?.uid;
                            if (userId != null) {
                              projectStorage.fetchProjectsFromFirestore(userId);
                            }
                          },
                          child: Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

              final recentProjects = projectStorage.getRecentProjects();
              
              if (recentProjects.isEmpty) {
                return _buildEmptyState();
              }
              
              return Column(
                children: recentProjects.map((project) => 
                  _buildProjectCard(project, projectStorage)
                ).toList(),
              );
            }),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Iconsax.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun projet pour le moment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Créez votre premier mind map pour commencer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const Create()),
            icon: const Icon(Iconsax.add_circle),
            label: const Text('Créer un projet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, ProjectStorage storage) {
    // Conversion sécurisée du Timestamp en DateTime
   DateTime lastModified;
  try {
    if (project['lastModified'] is Timestamp) {
      lastModified = (project['lastModified'] as Timestamp).toDate();
    } else if (project['lastModified'] is String) {
      lastModified = DateTime.parse(project['lastModified'] as String);
    } else if (project['lastModified'] == null) {
      // Si lastModified est null, utilisez createdAt ou la date actuelle
      lastModified = project['createdAt'] is Timestamp 
          ? (project['createdAt'] as Timestamp).toDate()
          : DateTime.now();
    } else {
      lastModified = DateTime.now();
    }
  } catch (e) {
    // print('Erreur lors de la conversion de la date: $e');
    lastModified = DateTime.now();
  }
  
  final String timeAgo = _getTimeAgo(lastModified);
    
    // Obtenir la couleur en fonction du template
    final Color bgColor = _getTemplateColor(project['template']);
    final Color iconColor = _getTemplateIconColor(project['template']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          onTap: () => _openProject(project),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _getTemplateIcon(project['template']),
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title'] ?? 'Sans titre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (project['description'] != null && 
                          project['description'].toString().isNotEmpty)
                        Text(
                          project['description'].toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(
                    Iconsax.more,
                    color: Colors.grey[600],
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Iconsax.edit),
                        title: Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => _openProject(project),
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Iconsax.copy),
                        title: Text('Dupliquer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => _duplicateProject(project, storage),
                    ),
                    // Renommage
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Iconsax.text),
                        title: Text('Renommer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => _renameProject(project, storage),
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Iconsax.share),
                        title: Text('Partager'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => _shareProject(project),
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Iconsax.trash, color: Colors.red),
                        title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => _deleteProject(project, storage),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openProject(Map<String, dynamic> project) {
    Get.to(() => MindMapEditor(
      projectTitle: project['title'] ?? 'Sans titre',
      projectDescription: project['description']?.toString() ?? '',
      templateId: project['template'] ?? 'default',
      existingProjectId: project['id'],
    ));
  }

  void _renameProject(Map<String, dynamic> project, ProjectStorage storage) {
  final titleController = TextEditingController(text: project['title']?.toString() ?? '');
  final descriptionController = TextEditingController(text: project['description']?.toString() ?? '');

  Get.dialog(
    AlertDialog(
      title: const Text('Renommer le projet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newTitle = titleController.text.trim();
            if (newTitle.isNotEmpty) {
              try {
                // Fermer le dialog
                Get.back();
                
                // Afficher un indicateur de chargement
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );
                
                // Renommer le projet
                storage.renameProject(
                  project['id'],
                  newTitle,
                  newDescription: descriptionController.text.trim(),
                );
                
                // Fermer l'indicateur de chargement
                Get.back();
                
                // Get.snackbar(
                //   'Succès',
                //   'Projet renommé avec succès',
                //   backgroundColor: Colors.green,
                //   colorText: Colors.white,
                //   icon: const Icon(Icons.check, color: Colors.white),
                // );
              } catch (e) {
                // Fermer l'indicateur de chargement
                if (Get.isDialogOpen ?? false) Get.back();
                
                print('Erreur lors du renommage: $e');
                // Get.snackbar(
                //   'Erreur',
                //   'Impossible de renommer le projet: $e',
                //   backgroundColor: Colors.red,
                //   colorText: Colors.white,
                //   icon: const Icon(Icons.error, color: Colors.white),
                // );
              }
            } else {
              Get.snackbar(
                'Erreur',
                'Le titre ne peut pas être vide',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            }
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    ),
  );
}

  void _duplicateProject(Map<String, dynamic> project, ProjectStorage storage) async {
  try {
    // Afficher un indicateur de chargement
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Duplication en cours...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    
    // print('Duplication du projet: ${project['id']} - ${project['title']}');
    await storage.duplicateProject(project);
    
    // Fermer l'indicateur de chargement
    Get.back();
    
    Get.snackbar(
      'Succès',
      'Projet "${project['title']}" dupliqué avec succès',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.copy, color: Colors.white),
    );
    
  } catch (e) {
    // Fermer l'indicateur de chargement
    if (Get.isDialogOpen ?? false) Get.back();
    
    // print('Erreur lors de la duplication: $e');
    // Get.snackbar(
    //   'Erreur',
    //   'Impossible de dupliquer le projet: $e',
    //   backgroundColor: Colors.red,
    //   colorText: Colors.white,
    //   icon: const Icon(Icons.error, color: Colors.white),
    //   duration: const Duration(seconds: 5),
    // );
  }
}

  void _shareProject(Map<String, dynamic> project) {
    Get.snackbar(
      'Partage',
      'Fonctionnalité de partage à implémenter',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _deleteProject(Map<String, dynamic> project, ProjectStorage storage) {
  Get.dialog(
    AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700]),
          const SizedBox(width: 10),
          const Text('Supprimer le projet'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Êtes-vous sûr de vouloir supprimer ce projet ?'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getTemplateIcon(project['template']),
                  color: _getTemplateIconColor(project['template']),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title'] ?? 'Sans titre',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (project['description'] != null &&
                          project['description'].toString().isNotEmpty)
                        Text(
                          project['description'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cette action est irréversible.',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              // Fermer le dialog de confirmation
              Get.back();
              
              // Afficher un indicateur de chargement
              Get.dialog(
                AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text('Suppression en cours...'),
                    ],
                  ),
                ),
                barrierDismissible: false,
              );
              
              // Supprimer le projet
              final projectId = project['id']?.toString();
              if (projectId == null || projectId.isEmpty) {
                throw Exception('ID de projet invalide');
              }
              
              // print('Suppression du projet: $projectId');
              await storage.deleteProject(projectId);
              
              // Fermer l'indicateur de chargement
              Get.back();
              
              // Get.snackbar(
              //   'Supprimé',
              //   'Projet "${project['title']}" supprimé avec succès',
              //   backgroundColor: Colors.red,
              //   colorText: Colors.white,
              //   icon: const Icon(Icons.delete, color: Colors.white),
              // );
              
            } catch (e) {
              // Fermer l'indicateur de chargement si ouvert
              if (Get.isDialogOpen ?? false) Get.back();
              
              print('Erreur lors de la suppression: $e');
              // Get.snackbar(
              //   'Erreur',
              //   'Impossible de supprimer le projet: $e',
              //   backgroundColor: Colors.red,
              //   colorText: Colors.white,
              //   icon: const Icon(Icons.error, color: Colors.white),
              //   duration: const Duration(seconds: 5),
              // );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}

  void _showAllProjects(ProjectStorage storage) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header du bottom sheet
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tous les projets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Liste des projets
            Expanded(
              child: Obx(() => storage.projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.folder_open,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun projet trouvé',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: storage.projects.length,
                      itemBuilder: (context, index) {
                        final project = storage.projects[index];
                        return _buildProjectCard(project, storage);
                      },
                    )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  IconData _getTemplateIcon(String? template) {
    switch (template) {
      case 'business':
        return Iconsax.briefcase;
      case 'education':
        return Iconsax.book;
      case 'project':
        return Iconsax.task_square;
      case 'brainstorm':
        return Iconsax.lamp;
      case 'decision':
        return Iconsax.diagram;
      default:
        return Iconsax.note;
    }
  }

  Color _getTemplateColor(String? template) {
    switch (template) {
      case 'business':
        return Colors.blue[100]!;
      case 'education':
        return Colors.green[100]!;
      case 'project':
        return Colors.orange[100]!;
      case 'brainstorm':
        return Colors.purple[100]!;
      case 'decision':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getTemplateIconColor(String? template) {
    switch (template) {
      case 'business':
        return Colors.blue;
      case 'education':
        return Colors.green;
      case 'project':
        return Colors.orange;
      case 'brainstorm':
        return Colors.purple;
      case 'decision':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}