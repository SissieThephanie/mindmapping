// firebase_mindmap_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class FirebaseMindMapService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection reference pour les projets
  CollectionReference get _projectsCollection => 
      _firestore.collection('mindmap_projects');
  
  // Obtenir l'ID de l'utilisateur connecté
  String? get _currentUserId => _auth.currentUser?.uid;
  
  // Sauvegarder un projet
  Future<bool> saveProject(Map<String, dynamic> projectData) async {
    try {
      if (_currentUserId == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return false;
      }
      
      // Ajouter l'ID utilisateur aux données
      projectData['userId'] = _currentUserId;
      projectData['lastSyncAt'] = FieldValue.serverTimestamp();
      
      // Si c'est un nouveau projet (pas d'ID), utiliser l'ID généré par Firestore
      if (projectData['id'] == null || projectData['id'].isEmpty) {
        final docRef = await _projectsCollection.add(projectData);
        projectData['id'] = docRef.id;
        // Mettre à jour le document avec son propre ID
        await docRef.update({'id': docRef.id});
      } else {
        // Projet existant, mettre à jour
        await _projectsCollection.doc(projectData['id']).set(
          projectData, 
          SetOptions(merge: true)
        );
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      Get.snackbar('Erreur', 'Échec de la sauvegarde: ${e.toString()}');
      return false;
    }
  }
  
  // Récupérer tous les projets de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserProjects() async {
    try {
      if (_currentUserId == null) return [];
      
      final querySnapshot = await _projectsCollection
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('lastModified', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des projets: $e');
      return [];
    }
  }
  
  // Récupérer un projet spécifique
  Future<Map<String, dynamic>?> getProject(String projectId) async {
    try {
      if (_currentUserId == null) return null;
      
      final docSnapshot = await _projectsCollection.doc(projectId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        // Vérifier que le projet appartient à l'utilisateur connecté
        if (data['userId'] == _currentUserId) {
          return {...data, 'id': docSnapshot.id};
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du projet: $e');
      return null;
    }
  }
  
  // Supprimer un projet
  Future<bool> deleteProject(String projectId) async {
    try {
      if (_currentUserId == null) return false;
      
      // Vérifier que le projet appartient à l'utilisateur
      final project = await getProject(projectId);
      if (project == null || project['userId'] != _currentUserId) {
        Get.snackbar('Erreur', 'Projet non trouvé ou accès refusé');
        return false;
      }
      
      await _projectsCollection.doc(projectId).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      Get.snackbar('Erreur', 'Échec de la suppression: ${e.toString()}');
      return false;
    }
  }
  
  // Écouter les changements en temps réel
  Stream<List<Map<String, dynamic>>> watchUserProjects() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }
    
    return _projectsCollection
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('lastModified', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                })
            .toList());
  }
  
  // Dupliquer un projet
  Future<String?> duplicateProject(String projectId, {String? newTitle}) async {
    try {
      final originalProject = await getProject(projectId);
      if (originalProject == null) return null;
      
      // Créer une copie avec un nouvel ID
      final duplicatedProject = Map<String, dynamic>.from(originalProject);
      duplicatedProject.remove('id'); // Retirer l'ancien ID
      duplicatedProject['title'] = newTitle ?? '${originalProject['title']} - Copie';
      duplicatedProject['createdAt'] = DateTime.now().toIso8601String();
      duplicatedProject['lastModified'] = DateTime.now().toIso8601String();
      
      // Générer de nouveaux IDs pour les nœuds et connexions
      final newNodes = <Map<String, dynamic>>[];
      final nodeIdMapping = <String, String>{};
      
      // Dupliquer les nœuds avec de nouveaux IDs
      if (duplicatedProject['nodes'] != null) {
        for (final nodeData in duplicatedProject['nodes']) {
          final oldId = nodeData['id'];
          final newId = '${DateTime.now().millisecondsSinceEpoch}_${newNodes.length}';
          nodeIdMapping[oldId] = newId;
          
          final newNode = Map<String, dynamic>.from(nodeData);
          newNode['id'] = newId;
          newNodes.add(newNode);
        }
      }
      
      // Dupliquer les connexions avec les nouveaux IDs
      final newConnections = <Map<String, dynamic>>[];
      if (duplicatedProject['connections'] != null) {
        for (final connData in duplicatedProject['connections']) {
          final newConnection = Map<String, dynamic>.from(connData);
          newConnection['id'] = '${DateTime.now().millisecondsSinceEpoch}_conn_${newConnections.length}';
          newConnection['fromNodeId'] = nodeIdMapping[connData['fromNodeId']];
          newConnection['toNodeId'] = nodeIdMapping[connData['toNodeId']];
          newConnections.add(newConnection);
        }
      }
      
      duplicatedProject['nodes'] = newNodes;
      duplicatedProject['connections'] = newConnections;
      
      // Sauvegarder le projet dupliqué
      final success = await saveProject(duplicatedProject);
      if (success) {
        return duplicatedProject['id'];
      }
      return null;
    } catch (e) {
      print('Erreur lors de la duplication: $e');
      return null;
    }
  }
  
  // Partager un projet (rendre public)
  Future<bool> shareProject(String projectId, {bool isPublic = true}) async {
    try {
      await _projectsCollection.doc(projectId).update({
        'isPublic': isPublic,
        'shareToken': isPublic ? _generateShareToken() : null,
        'lastModified': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Erreur lors du partage: $e');
      return false;
    }
  }
  
  // Récupérer un projet partagé via un token
  Future<Map<String, dynamic>?> getSharedProject(String shareToken) async {
    try {
      final querySnapshot = await _projectsCollection
          .where('shareToken', isEqualTo: shareToken)
          .where('isPublic', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du projet partagé: $e');
      return null;
    }
  }
  
  // Générer un token de partage unique
  String _generateShareToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(12, (index) => chars[random % chars.length]).join();
  }
  
  // Synchroniser les projets locaux avec Firebase
  Future<void> syncLocalProjects(List<Map<String, dynamic>> localProjects) async {
    try {
      for (final project in localProjects) {
        // Vérifier si le projet existe déjà sur Firebase
        final existingProject = await getProject(project['id']);
        
        if (existingProject == null) {
          // Nouveau projet local, l'uploader
          await saveProject(project);
        } else {
          // Comparer les dates de modification
          final localModified = DateTime.parse(project['lastModified']);
          final firebaseModified = DateTime.parse(existingProject['lastModified']);
          
          if (localModified.isAfter(firebaseModified)) {
            // Le projet local est plus récent
            await saveProject(project);
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }
  }
}