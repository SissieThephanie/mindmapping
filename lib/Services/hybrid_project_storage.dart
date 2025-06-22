// hybrid_project_storage.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindmapping/Services/firebase_mind_service.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HybridProjectStorage extends GetxService {
  late SharedPreferences _prefs;
  late FirebaseMindMapService _firebaseService;
  
  static const String _projectsKey = 'mindmap_projects';
  static const String _lastSyncKey = 'last_sync_timestamp';
  
  final RxBool isOnline = true.obs;
  final RxBool isSyncing = false.obs;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    _firebaseService = Get.find<FirebaseMindMapService>();
    
    // Démarrer la synchronisation automatique
    _startAutoSync();
  }
  
  // Sauvegarder un projet (local + Firebase si en ligne)
  Future<bool> saveProject(Map<String, dynamic> projectData) async {
    try {
      // Toujours sauvegarder localement d'abord
      final success = await _saveProjectLocally(projectData);
      
      if (!success) return false;
      
      // Essayer de sauvegarder sur Firebase si en ligne
      if (isOnline.value) {
        try {
          final firebaseSuccess = await _firebaseService.saveProject(projectData);
          if (firebaseSuccess) {
            // Marquer comme synchronisé
            await _markProjectAsSynced(projectData['id']);
          }
        } catch (e) {
          print('Erreur Firebase, projet sauvé localement: $e');
        }
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      return false;
    }
  }
  
  // Sauvegarder localement
  Future<bool> _saveProjectLocally(Map<String, dynamic> projectData) async {
    try {
      final projects = await getLocalProjects();
      
      // Chercher si le projet existe déjà
      final existingIndex = projects.indexWhere((p) => p['id'] == projectData['id']);
      
      if (existingIndex != -1) {
        // Mettre à jour le projet existant
        projects[existingIndex] = projectData;
      } else {
        // Ajouter le nouveau projet
        projects.add(projectData);
      }
      
      // Sauvegarder la liste mise à jour
      final projectsJson = json.encode(projects);
      return await _prefs.setString(_projectsKey, projectsJson);
    } catch (e) {
      print('Erreur sauvegarde locale: $e');
      return false;
    }
  }
  
  // Récupérer les projets locaux
  Future<List<Map<String, dynamic>>> getLocalProjects() async {
    try {
      final projectsJson = _prefs.getString(_projectsKey);
      if (projectsJson == null) return [];
      
      final List<dynamic> projectsList = json.decode(projectsJson);
      return projectsList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur lecture locale: $e');
      return [];
    }
  }
  
  // Récupérer tous les projets (local + Firebase synchronisé)
  Future<List<Map<String, dynamic>>> getAllProjects() async {
    try {
      if (isOnline.value) {
        // Si en ligne, essayer de synchroniser d'abord
        await _syncProjects();
      }
      
      // Retourner les projets locaux (qui incluent maintenant les données Firebase)
      final projects = await getLocalProjects();
      
      // Trier par date de modification (plus récent en premier)
      projects.sort((a, b) {
        final dateA = DateTime.parse(a['lastModified'] ?? '1970-01-01');
        final dateB = DateTime.parse(b['lastModified'] ?? '1970-01-01');
        return dateB.compareTo(dateA);
      });
      
      return projects;
    } catch (e) {
      print('Erreur récupération projets: $e');
      return await getLocalProjects();
    }
  }
  
  // Récupérer un projet spécifique
  Future<Map<String, dynamic>?> getProject(String projectId) async {
    try {
      final projects = await getLocalProjects();
      return projects.firstWhereOrNull((p) => p['id'] == projectId);
    } catch (e) {
      print('Erreur récupération projet: $e');
      return null;
    }
  }
  
  // Supprimer un projet
  Future<bool> deleteProject(String projectId) async {
    try {
      // Supprimer localement
      final projects = await getLocalProjects();
      projects.removeWhere((p) => p['id'] == projectId);
      
      final projectsJson = json.encode(projects);
      final localSuccess = await _prefs.setString(_projectsKey, projectsJson);
      
      // Supprimer sur Firebase si en ligne
      if (isOnline.value) {
        try {
          await _firebaseService.deleteProject(projectId);
        } catch (e) {
          print('Erreur suppression Firebase: $e');
        }
      }
      
      return localSuccess;
    } catch (e) {
      print('Erreur suppression: $e');
      return false;
    }
  }
  
  // Synchroniser les projets entre local et Firebase
  Future<void> _syncProjects() async {
    if (isSyncing.value || !isOnline.value) return;
    
    try {
      isSyncing.value = true;
      
      // Récupérer les projets locaux et Firebase
      final localProjects = await getLocalProjects();
      final firebaseProjects = await _firebaseService.getUserProjects();
      
      // Créer une map des projets Firebase pour un accès rapide
      final firebaseProjectsMap = <String, Map<String, dynamic>>{};
      for (final project in firebaseProjects) {
        firebaseProjectsMap[project['id']] = project;
      }
      
      // Liste des projets synchronisés
      final syncedProjects = <Map<String, dynamic>>[];
      final processedIds = <String>{};
      
      // Traiter les projets locaux
      for (final localProject in localProjects) {
        final projectId = localProject['id'];
        processedIds.add(projectId);
        
        if (firebaseProjectsMap.containsKey(projectId)) {
          // Le projet existe sur Firebase
          final firebaseProject = firebaseProjectsMap[projectId]!;
          
          final localModified = DateTime.parse(localProject['lastModified']);
          final firebaseModified = DateTime.parse(firebaseProject['lastModified']);
          
          if (localModified.isAfter(firebaseModified)) {
            // Local plus récent, uploader vers Firebase
            await _firebaseService.saveProject(localProject);
            syncedProjects.add(localProject);
          } else if (firebaseModified.isAfter(localModified)) {
            // Firebase plus récent, utiliser la version Firebase
            syncedProjects.add(firebaseProject);
          } else {
            // Même date, garder la version locale
            syncedProjects.add(localProject);
          }
        } else {
          // Projet local uniquement, uploader vers Firebase
          await _firebaseService.saveProject(localProject);
          syncedProjects.add(localProject);
        }
      }
      
      // Ajouter les projets Firebase qui n'existent pas localement
      for (final firebaseProject in firebaseProjects) {
        if (!processedIds.contains(firebaseProject['id'])) {
          syncedProjects.add(firebaseProject);
        }
      }
      
      // Sauvegarder les projets synchronisés localement
      final projectsJson = json.encode(syncedProjects);
      await _prefs.setString(_projectsKey, projectsJson);
      
      // Marquer la dernière synchronisation
      await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      
    } catch (e) {
      print('Erreur synchronisation: $e');
    } finally {
      isSyncing.value = false;
    }
  }
  
  // Marquer un projet comme synchronisé
  Future<void> _markProjectAsSynced(String projectId) async {
    try {
      final projects = await getLocalProjects();
      final projectIndex = projects.indexWhere((p) => p['id'] == projectId);
      
      if (projectIndex != -1) {
        projects[projectIndex]['isSynced'] = true;
        projects[projectIndex]['lastSyncAt'] = DateTime.now().toIso8601String();
        
        final projectsJson = json.encode(projects);
        await _prefs.setString(_projectsKey, projectsJson);
      }
    } catch (e) {
      print('Erreur marquage sync: $e');
    }
  }
  
  // Vérifier le statut de connectivité
  Future<void> checkConnectivity() async {
    try {
      // Vous pouvez utiliser connectivity_plus pour vérifier la connectivité
      // Pour le moment, on assume que nous sommes en ligne
      isOnline.value = true;
      
      if (isOnline.value) {
        await _syncProjects();
      }
    } catch (e) {
      isOnline.value = false;
      print('Pas de connectivité: $e');
    }
  }
  
  // Synchronisation automatique périodique
  void _startAutoSync() {
    // Synchroniser toutes les 5 minutes si en ligne
    Stream.periodic(const Duration(minutes: 5)).listen((_) {
      if (isOnline.value && !isSyncing.value) {
        _syncProjects();
      }
    });
  }
  
  // Forcer une synchronisation manuelle
  Future<void> forcSync() async {
    await checkConnectivity();
    if (isOnline.value) {
      await _syncProjects();
      Get.snackbar(
        'Synchronisation',
        'Projets synchronisés avec succès !',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Hors ligne',
        'Impossible de synchroniser sans connexion',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }
  
  // Obtenir les statistiques de synchronisation
  Map<String, dynamic> getSyncStats() {
    return {
      'isOnline': isOnline.value,
      'isSyncing': isSyncing.value,
      'lastSync': _prefs.getInt(_lastSyncKey),
    };
  }
  
  // Nettoyer le cache local
  Future<void> clearLocalCache() async {
    await _prefs.remove(_projectsKey);
    await _prefs.remove(_lastSyncKey);
  }
  
  // Exporter tous les projets
  Future<String> exportAllProjects() async {
    final projects = await getAllProjects();
    return json.encode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'projects': projects,
    });
  }
  
  // Importer des projets
  Future<bool> importProjects(String jsonData) async {
    try {
      final data = json.decode(jsonData);
      final List<dynamic> importedProjects = data['projects'];
      
      for (final projectData in importedProjects) {
        // Générer un nouvel ID pour éviter les conflits
        final newProject = Map<String, dynamic>.from(projectData);
        // ignore: prefer_interpolation_to_compose_strings
        newProject['id'] = DateTime.now().millisecondsSinceEpoch.toString() + 
                         '_import_${importedProjects.indexOf(projectData)}';
        newProject['title'] = '${projectData['title']} (Importé)';
        newProject['lastModified'] = DateTime.now().toIso8601String();
        
        await saveProject(newProject);
      }
      
      return true;
    } catch (e) {
      print('Erreur import: $e');
      return false;
    }
  }
}