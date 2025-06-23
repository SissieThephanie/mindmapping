import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Ajoutez cette dépendance dans pubspec.yaml

class ProjectStorage extends GetxController {
  static ProjectStorage get instance => Get.find();
  
  final _storage = GetStorage();
  final _uuid = const Uuid();
  final RxList<Map<String, dynamic>> projects = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadProjects(); // Charge depuis le cache local
  
    // Si l'utilisateur est connecté, rafraîchir depuis Firestore
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      fetchProjectsFromFirestore(userId);
    }
  }
  
  void renameProject(String projectId, String newTitle, {String? newDescription}) async {
  try {
    final project = getProject(projectId);
    if (project != null) {
      final updatedProject = Map<String, dynamic>.from(project);
      updatedProject['title'] = newTitle;
      if (newDescription != null) {
        updatedProject['description'] = newDescription;
      }
      updatedProject['lastModified'] = DateTime.now().toIso8601String();
      
      // Sauvegarder localement d'abord
      saveProject(updatedProject);
      
      // Puis sauvegarder dans Firestore
      await saveProjectToFirestore(updatedProject);
      
      // print('Projet renommé avec succès: $projectId');
    } else {
      throw Exception('Projet introuvable: $projectId');
    }
  } catch (e) {
    // print('Erreur lors du renommage du projet: $e');
    rethrow;
  }
}
  
  // Méthode pour obtenir tous les projets
  List<Map<String, dynamic>> getAllProjects() {
    try {
      return projects.toList();
    } catch (e) {
      print('Erreur lors de la récupération de tous les projets: $e');
      return [];
    }
  }

  // Méthode helper pour convertir les dates de façon sécurisée
  DateTime _convertToDateTime(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('Erreur lors du parsing de la date: $dateValue');
        return DateTime.now();
      }
    } else {
      return DateTime.now();
    }
  }

  // Méthode helper pour convertir en String ISO
  String _convertToISOString(dynamic dateValue) {
    return _convertToDateTime(dateValue).toIso8601String();
  }

  Future<void> fetchProjectsFromFirestore(String userId) async {
    try {
      isLoading(true);
      errorMessage('');
      
      final snapshot = await FirebaseFirestore.instance
        .collection('mindmap_projects')
        .where('userId', isEqualTo: userId)
        .get();

      final firestoreProjects = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Conversion sécurisée des Timestamps en utilisant les helpers
        data['createdAt'] = _convertToISOString(data['createdAt'] ?? DateTime.now());
        data['lastModified'] = _convertToISOString(data['lastModified'] ?? data['createdAt']);
        
        return data;
      }).toList();

      projects.value = firestoreProjects.cast<Map<String, dynamic>>();
      _storage.write('mindmap_projects', projects.toList());
    } catch (e) {
      errorMessage('Erreur lors du chargement: ${e.toString()}');
      print('Erreur lors de la récupération depuis Firestore: $e');
    } finally {
      isLoading(false);
    }
  }
  
  void loadProjects() {
    final savedProjects = _storage.read<List>('mindmap_projects') ?? [];
    projects.value = savedProjects.cast<Map<String, dynamic>>();
  }
  
  void saveProject(Map<String, dynamic> projectData) {
    // CORRECTION: S'assurer qu'il y a un ID avant de sauvegarder
    if (projectData['id'] == null || projectData['id'].toString().isEmpty) {
      projectData['id'] = _uuid.v4(); // Générer un nouvel ID si manquant
      print('ID généré pour le projet: ${projectData['id']}');
    }
    
    final existingIndex = projects.indexWhere((p) => p['id'] == projectData['id']);
    if (existingIndex != -1) {
      projects[existingIndex] = projectData; // Mise à jour
      print('Projet mis à jour: ${projectData['id']}');
    } else {
      projects.add(projectData); // Ajout
      print('Nouveau projet ajouté: ${projectData['id']}');
    }
    _storage.write('mindmap_projects', projects.toList());
  }
  
  Future<void> saveProjectToFirestore(Map<String, dynamic> projectData) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // S'assurer que l'userId est présent
      projectData['userId'] = userId;
      
      final projectRef = FirebaseFirestore.instance.collection('mindmap_projects');
      
      // Convertir les dates en Timestamp si nécessaire
      if (projectData['createdAt'] is String) {
        projectData['createdAt'] = Timestamp.fromDate(DateTime.parse(projectData['createdAt']));
      }
      
      if (projectData['lastModified'] is String) {
        projectData['lastModified'] = Timestamp.fromDate(DateTime.parse(projectData['lastModified']));
      }

      // CORRECTION: Vérifier si le document existe dans Firestore
      final projectId = projectData['id']?.toString();
      if (projectId == null || projectId.isEmpty) {
        // Nouveau projet
        final docRef = await projectRef.add({
          ...projectData,
          'createdAt': FieldValue.serverTimestamp(),
          'lastModified': FieldValue.serverTimestamp(),
        });
        projectData['id'] = docRef.id;
        print('Nouveau projet créé dans Firestore: ${docRef.id}');
      } else {
        // Vérifier si le document existe
        final docSnapshot = await projectRef.doc(projectId).get();
        if (docSnapshot.exists) {
          // Mettre à jour
          await projectRef.doc(projectId).update({
            ...projectData,
            'lastModified': FieldValue.serverTimestamp(),
          });
          // print('Projet mis à jour dans Firestore: $projectId');
        } else {
          // Le document n'existe pas, le créer avec l'ID spécifié
          await projectRef.doc(projectId).set({
            ...projectData,
            'createdAt': FieldValue.serverTimestamp(),
            'lastModified': FieldValue.serverTimestamp(),
          });
          // print('Projet créé dans Firestore avec ID: $projectId');
        }
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde dans Firestore: $e');
      rethrow; // CORRECTION: utiliser rethrow au lieu de throw
    }
  }

  Future<void> syncWithFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await fetchProjectsFromFirestore(userId);
    }
  }

  Future<void> deleteProjectFromFirestore(String projectId) async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    if (projectId.isEmpty) {
      throw Exception('ID de projet invalide');
    }

    print('Tentative de suppression du projet: $projectId');

    // Vérifier d'abord si le document existe
    final docRef = FirebaseFirestore.instance
        .collection('mindmap_projects')
        .doc(projectId);
        
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      print('Le document n\'existe pas dans Firestore: $projectId');
      // Supprimer quand même de la liste locale si il existe
      projects.removeWhere((project) => project['id'] == projectId);
      _storage.write('mindmap_projects', projects.toList());
      projects.refresh();
      return;
    }

    // Supprimer de Firestore
    await docRef.delete();
    print('Projet supprimé de Firestore: $projectId');

    // Supprimer de la liste locale
    projects.removeWhere((project) => project['id'] == projectId);
    
    // Sauvegarder la nouvelle liste localement
    _storage.write('mindmap_projects', projects.toList());
    
    // Rafraîchir la liste reactive
    projects.refresh();
    
    print('Projet supprimé complètement: $projectId');
    
  } catch (e) {
    print('Erreur lors de la suppression du projet: $e');
    errorMessage.value = 'Erreur lors de la suppression: $e';
    rethrow;
  }
}

  Future<void> deleteProject(String projectId) async {
    await deleteProjectFromFirestore(projectId);
  }

  // CORRECTION: Méthode pour dupliquer un projet avec gestion d'ID appropriée
  Future<void> duplicateProject(Map<String, dynamic> originalProject) async {
    try {
      final duplicatedProject = Map<String, dynamic>.from(originalProject);
      
      // CORRECTION: Générer un nouvel ID au lieu de le supprimer
      duplicatedProject['id'] = _uuid.v4();
      duplicatedProject['title'] = '${originalProject['title']} (copie)';
      duplicatedProject['createdAt'] = DateTime.now().toIso8601String();
      duplicatedProject['lastModified'] = DateTime.now().toIso8601String();
      
      print('Duplication du projet avec nouvel ID: ${duplicatedProject['id']}');
      
      // Sauvegarder localement d'abord
      saveProject(duplicatedProject);
      
      // Puis sauvegarder dans Firestore
      await saveProjectToFirestore(duplicatedProject);
      
      print('Projet dupliqué avec succès: ${duplicatedProject['id']}');
      
    } catch (e) {
      print('Erreur lors de la duplication: $e');
      rethrow; // CORRECTION: utiliser rethrow au lieu de throw
    }
  }
  
  // CORRECTION: Méthode getProject avec gestion d'erreur plus claire
  Map<String, dynamic>? getProject(String? projectId) {
    if (projectId == null || projectId.isEmpty) {
      print('ID de projet null ou vide fourni à getProject');
      return null;
    }
    
    try {
      final project = projects.firstWhereOrNull(
        (project) => project['id'] == projectId
      );
      
      if (project == null) {
        print('Projet introuvable avec ID: $projectId');
        print('Projets disponibles: ${projects.map((p) => p['id']).toList()}');
      }
      
      return project;
    } catch (e) {
      print('Erreur lors de la récupération du projet $projectId: $e');
      return null;
    }
  }
  
  // Méthode helper pour obtenir un projet de façon sécurisée
  Map<String, dynamic> getProjectSafe(String projectId) {
    final project = getProject(projectId);
    if (project == null) {
      throw Exception('Projet introuvable: $projectId');
    }
    return project;
  }
  
  List<Map<String, dynamic>> getRecentProjects({int limit = 5}) {
    final sortedProjects = List<Map<String, dynamic>>.from(projects);
    sortedProjects.sort((a, b) {
      final aDate = _convertToDateTime(a['lastModified'] ?? a['createdAt']);
      final bDate = _convertToDateTime(b['lastModified'] ?? b['createdAt']);
      return bDate.compareTo(aDate);
    });
    
    return sortedProjects.take(limit).toList();
  }
}