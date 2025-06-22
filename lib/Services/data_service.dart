import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindmapping/models/todos.dart';

const String mindMapCollectionRef = "mindmap_projects";

class MindMapDataService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late final CollectionReference<MindMapProject> _mindMapRef;

  MindMapDataService() {
    _mindMapRef = _firestore.collection(mindMapCollectionRef).withConverter<MindMapProject>(
      fromFirestore: (snapshot, _) => MindMapProject.fromJson(snapshot.data()!),
      toFirestore: (project, _) => project.toJson(),
    );
  }

  // Obtenir l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;

  // Récupérer tous les projets de l'utilisateur connecté
  Stream<QuerySnapshot<MindMapProject>> getUserProjects() {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    return _mindMapRef
        .where('userId', isEqualTo: currentUserId)
        .orderBy('lastModified', descending: true)
        .snapshots();
  }

  // CORRECTION PRINCIPALE : Récupérer un projet spécifique
  Future<MindMapProject?> getProject(String projectId) async {
    try {
      if (currentUserId == null) {
        print('Utilisateur non connecté');
        return null;
      }

      if (projectId.isEmpty) {
        print('ProjectId vide');
        return null;
      }

      print('Tentative de récupération du projet: $projectId');
      final doc = await _mindMapRef.doc(projectId).get();
      
      if (!doc.exists) {
        print('Document $projectId n\'existe pas');
        return null;
      }

      final project = doc.data();
      if (project == null) {
        print('Document $projectId a des données nulles');
        return null;
      }

      // Vérification du propriétaire
      if (project.userId != currentUserId) {
        print('L\'utilisateur ne possède pas le projet $projectId');
        return null;
      }

      print('Projet récupéré avec succès: ${project.title}');
      return project;
    } catch (e) {
      print('Erreur lors de la récupération du projet: $e');
      return null;
    }
  }

  // CORRECTION : Sauvegarder un nouveau projet
  Future<String?> saveProject(MindMapProject project) async {
    try {
      if (currentUserId == null) {
        print('Utilisateur non connecté pour la sauvegarde');
        return null;
      }

      // Créer un nouveau projet avec l'ID utilisateur
      final projectWithUserId = project.copyWith(
        userId: currentUserId,
        lastModified: Timestamp.now(),
      );
      
      print('Sauvegarde du projet: ${projectWithUserId.title}');
      final docRef = await _mindMapRef.add(projectWithUserId);
      
      // Mettre à jour l'ID du document
      await docRef.update({'id': docRef.id});
      
      print('Projet sauvegardé avec l\'ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      return null;
    }
  }

  // CORRECTION : Mettre à jour un projet existant
  Future<bool> updateProject(String projectId, MindMapProject project) async {
    try {
      if (currentUserId == null) {
        print('Utilisateur non connecté pour la mise à jour');
        return false;
      }

      if (projectId.isEmpty) {
        print('ProjectId vide pour la mise à jour');
        return false;
      }

      // Vérifier que le projet appartient à l'utilisateur
      final existingProject = await getProject(projectId);
      if (existingProject == null) {
        print('Projet non trouvé pour la mise à jour: $projectId');
        return false;
      }

      if (existingProject.userId != currentUserId) {
        print('L\'utilisateur ne peut pas mettre à jour ce projet');
        return false;
      }

      // Mettre à jour avec la nouvelle date de modification
      final updatedProject = project.copyWith(
        id: projectId,
        userId: currentUserId,
        lastModified: Timestamp.now(),
      );

      print('Mise à jour du projet: $projectId');
      await _mindMapRef.doc(projectId).update(updatedProject.toJson());
      
      print('Projet mis à jour avec succès');
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  // Supprimer un projet
  Future<bool> deleteProject(String projectId) async {
    try {
      if (currentUserId == null) {
        print('Utilisateur non connecté pour la suppression');
        return false;
      }

      if (projectId.isEmpty) {
        print('ProjectId vide pour la suppression');
        return false;
      }

      // Vérifier que le projet appartient à l'utilisateur
      final project = await getProject(projectId);
      if (project == null) {
        print('Projet non trouvé pour la suppression: $projectId');
        return false;
      }

      if (project.userId != currentUserId) {
        print('L\'utilisateur ne peut pas supprimer ce projet');
        return false;
      }

      print('Suppression du projet: $projectId');
      await _mindMapRef.doc(projectId).delete();
      
      print('Projet supprimé avec succès');
      return true;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  // CORRECTION MAJEURE : Méthode saveProjectFromController
  Future<String?> saveProjectFromController({
    String? projectId,
    required String title,
    required String description,
    required String template,
    required List<Map<String, dynamic>> nodes,
    required List<Map<String, dynamic>> connections,
    String? existingCreatedAt,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('Utilisateur non connecté pour saveProjectFromController');
        return null;
      }

      if (title.trim().isEmpty) {
        print('Titre du projet vide');
        return null;
      }

      // Validation des données
      if (nodes.isEmpty) {
        print('Aucun nœud à sauvegarder');
        return null;
      }

      final now = Timestamp.now();
      
      // Créer un objet MindMapProject pour utiliser le converter
      final project = MindMapProject(
        id: projectId ?? '',
        title: title.trim(),
        description: description.trim(),
        template: template,
        nodes: nodes,
        connections: connections,
        lastModified: now,
        createdAt: existingCreatedAt != null
            ? Timestamp.fromDate(DateTime.parse(existingCreatedAt))
            : now,
        userId: userId,
      );

      print('Projet à sauvegarder: ${project.title}');

      if (projectId != null && projectId.isNotEmpty) {
        // Mise à jour d'un projet existant
        print('Mise à jour du projet existant: $projectId');
        
        // Vérifier que le projet existe et appartient à l'utilisateur
        final existingProject = await getProject(projectId);
        if (existingProject == null) {
          print('Le projet à mettre à jour n\'existe pas: $projectId');
          return null;
        }

        if (existingProject.userId != userId) {
          print('L\'utilisateur ne peut pas mettre à jour ce projet');
          return null;
        }

        await _mindMapRef.doc(projectId).set(project);
        print('Projet mis à jour avec succès: $projectId');
        return projectId;
      } else {
        // Création d'un nouveau projet
        print('Création d\'un nouveau projet');
        final docRef = await _mindMapRef.add(project);
        
        // Mettre à jour l'ID dans le document
        final updatedProject = project.copyWith(id: docRef.id);
        await _mindMapRef.doc(docRef.id).set(updatedProject);
        
        print('Nouveau projet créé avec succès: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      print('Erreur Firestore dans saveProjectFromController: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProjectData(String projectId) async {
    try {
      if (currentUserId == null || projectId.isEmpty) {
        return null;
      }

      final doc = await _firestore.collection(mindMapCollectionRef).doc(projectId).get();
      
      if (!doc.exists) {
        print('Document $projectId n\'existe pas');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        print('Données nulles pour le document $projectId');
        return null;
      }

      // Vérifier le propriétaire
      if (data['userId'] != currentUserId) {
        print('L\'utilisateur ne possède pas ce projet');
        return null;
      }

      return data;
    } catch (e) {
      print('Erreur lors de la récupération des données du projet: $e');
      return null;
    }
  }
}