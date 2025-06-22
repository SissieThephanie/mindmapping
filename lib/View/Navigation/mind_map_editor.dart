import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindmapping/Services/data_service.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:mindmapping/Services/project_storage.dart';

// Énumération pour les formes
enum NodeShape {
  circle,
  rectangle,
  square,
  diamond,
  triangle,
  hexagon,
  ellipse,
  trapezoid,
  parallelogram,
  star,
}
// Extension pour NodeShape - à ajouter après la ligne 25
extension NodeShapeExtension on NodeShape {
  IconData get icon {
    switch (this) {
      case NodeShape.circle:
        return Icons.circle_outlined;
      case NodeShape.rectangle:
        return Icons.rectangle_outlined;
      case NodeShape.square:
        return Icons.square_outlined;
      case NodeShape.diamond:
        return Icons.diamond_outlined;
      case NodeShape.triangle:
        return Icons.change_history_outlined;
      case NodeShape.hexagon:
        return Icons.hexagon_outlined;
      case NodeShape.ellipse:
        return Icons.crop_rotate;
      case NodeShape.trapezoid:
        return Icons.crop_landscape_outlined;
      case NodeShape.parallelogram:
        return Icons.crop_rotate_outlined;
      case NodeShape.star:
        return Icons.star_outline;
    }
  }

  String get displayName {
    switch (this) {
      case NodeShape.circle:
        return 'Cercle';
      case NodeShape.rectangle:
        return 'Rectangle';
      case NodeShape.square:
        return 'Carré';
      case NodeShape.diamond:
        return 'Losange';
      case NodeShape.triangle:
        return 'Triangle';
      case NodeShape.hexagon:
        return 'Hexagone';
      case NodeShape.ellipse:
        return 'Ellipse';
      case NodeShape.trapezoid:
        return 'Trapèze';
      case NodeShape.parallelogram:
        return 'Parallélogramme';
      case NodeShape.star:
        return 'Étoile';
    }
  }
}
class MindMapEditor extends StatelessWidget {
  final String? projectTitle;
  final String? projectDescription;
  final String? templateId;
  final String? existingProjectId;

  const MindMapEditor({
    super.key,
    this.projectTitle,
    this.projectDescription,
    this.templateId,
    this.existingProjectId, 
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MindMapEditorController(
      title: projectTitle ?? 'Nouveau Mind Map',
      description: projectDescription ?? '',
      template: templateId ?? 'blank',
      existingProjectId: existingProjectId,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // Dans MindMapEditor - remplacez la section AppBar par celle-ci :

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => _showSaveDialog(controller),
          icon: const Icon(Iconsax.arrow_left_2, color: Colors.black87),
          tooltip: 'Retour',
        ),
        title: GestureDetector(
          onTap: () => controller.showProjectRenameDialog(),
          child: Obx(() => Text(
            controller.projectTitle.value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          )),
        ),
        actions: [
          IconButton(
            onPressed: () => controller.showProjectRenameDialog(),
            icon: const Icon(Iconsax.edit, color: Colors.black54),
            tooltip: 'Modifier le projet',
          ),
          IconButton(
            onPressed: () => controller.undo(),
            icon: const Icon(Iconsax.undo, color: Colors.black54),
          ),
          IconButton(
            onPressed: () => controller.redo(),
            icon: const Icon(Iconsax.redo, color: Colors.black54),
          ),
          PopupMenuButton(
            icon: const Icon(Iconsax.export, color: Color(0xFF6C63FF)),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Iconsax.document_download),
                  title: Text('Exporter en PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => controller.exportToPdf(),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Iconsax.gallery_export),
                  title: Text('Exporter en Image'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => controller.exportToImage(),
              ),
            ],
          ),
          // Bouton de sauvegarde supprimé
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            height: 60,
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  _buildToolButton(
                    icon: Iconsax.add_circle,
                    label: 'Ajouter',
                    onTap: () => controller.addNode(),
                  ),
                  _buildToolButton(
                    icon: Iconsax.link,
                    label: 'Lier',
                    onTap: () => controller.toggleLinkMode(),
                  ),
                  _buildToolButton(
                    icon: Iconsax.text,
                    label: 'Texte',
                    onTap: () => controller.showTextEditor(),
                  ),
                  _buildToolButton(
                    icon: Iconsax.shapes,
                    label: 'Forme',
                    onTap: () => controller.showShapePicker(),
                  ),
                  _buildToolButton(
                    icon: Iconsax.color_swatch,
                    label: 'Couleurs',
                    onTap: () => controller.showColorPicker(),
                  ),
                  _buildToolButton(
                    icon: Iconsax.size,
                    label: 'Taille',
                    onTap: () => controller.showSizeEditor(),
                  ),
                  _buildToolButton(
                    icon: Iconsax.trash,
                    label: 'Supprimer',
                    onTap: () => controller.deleteSelected(),
                  ),
                ],
              ),
            ),
          ),
          
          // Canvas
          Expanded(
            child: Obx(() => RepaintBoundary(
              key: controller.canvasKey,
              child: GestureDetector(
                onTapDown: (details) => controller.onCanvasTap(details.localPosition),
                onPanStart: (details) => controller.onPanStart(details.localPosition),
                onPanUpdate: (details) => controller.onPanUpdate(details.localPosition),
                onPanEnd: (details) => controller.onPanEnd(),
                child: CustomPaint(
                  painter: MindMapPainter(
                    nodes: controller.nodes,
                    connections: controller.connections,
                    selectedNodeId: controller.selectedNodeId.value,
                    isLinkMode: controller.isLinkMode.value,
                  ),
                  size: Size.infinite,
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Remplacez la méthode _showSaveDialog dans MindMapEditor par celle-ci :

void _showSaveDialog(MindMapEditorController controller) {
  // Vérifier s'il y a des modifications non sauvegardées
  if (!controller.hasUnsavedChanges.value) {
    // Pas de modifications, quitter directement
    Get.back();
    return;
  }

  // Il y a des modifications, demander à l'utilisateur
  Get.dialog(
    AlertDialog(
      title: const Text('Sauvegarder le projet ?'),
      content: const Text('Vous avez des modifications non sauvegardées. Voulez-vous les sauvegarder avant de quitter ?'),
      actions: [
        TextButton(
          onPressed: () {
            Get.back(); // Fermer le dialog
            Get.back(); // Retourner à l'écran précédent SANS sauvegarder
          },
          child: const Text('Non', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () {
            Get.back(); // Fermer le dialog
            // Ne pas quitter, rester sur l'éditeur
          },
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () async {
            Get.back(); // Fermer le dialog
            
            // Sauvegarder puis quitter
            controller.saveProject();
            
            // Attendre un peu pour que la sauvegarde se termine
            await Future.delayed(Duration(milliseconds: 500));
            
            // Quitter seulement si la sauvegarde a réussi
            if (!controller.hasUnsavedChanges.value) {
              Get.back(); // Retourner à l'écran précédent
            }
          },
          child: const Text('Oui'),
        ),
      ],
    ),
  );
}
}

// Modèle pour les nœuds amélioré
class MindMapNode {
  final String id;
  Offset position;
  String text;
  Color backgroundColor;
  Color textColor;
  double width;
  double height;
  NodeShape shape;
  bool isSelected;
  double fontSize;
  FontWeight fontWeight;

  MindMapNode({
    required this.id,
    required this.position,
    this.text = 'Nouveau nœud',
    this.backgroundColor = const Color(0xFF6C63FF),
    this.textColor = Colors.white,
    this.width = 120.0,
    this.height = 80.0,
    this.shape = NodeShape.rectangle,
    this.isSelected = false,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w600,
  });
  // Méthode copyWith à ajouter dans la classe MindMapNode
MindMapNode copyWith({
  String? id,
  Offset? position,
  String? text,
  Color? backgroundColor,
  Color? textColor,
  double? width,
  double? height,
  NodeShape? shape,
  bool? isSelected,
  double? fontSize,
  FontWeight? fontWeight,
}) {
  return MindMapNode(
    id: id ?? this.id,
    position: position ?? this.position,
    text: text ?? this.text,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    textColor: textColor ?? this.textColor,
    width: width ?? this.width,
    height: height ?? this.height,
    shape: shape ?? this.shape,
    isSelected: isSelected ?? this.isSelected,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
  );
}

  // Méthode pour vérifier si un point est dans le nœud
  bool containsPoint(Offset point) {
    final rect = Rect.fromCenter(
      center: position,
      width: width,
      height: height,
    );
    
    switch (shape) {
      case NodeShape.circle:
      case NodeShape.ellipse:
        final dx = (point.dx - position.dx) / (width / 2);
        final dy = (point.dy - position.dy) / (height / 2);
        return (dx * dx + dy * dy) <= 1;
      case NodeShape.diamond:
        final dx = (point.dx - position.dx).abs() / (width / 2);
        final dy = (point.dy - position.dy).abs() / (height / 2);
        return (dx + dy) <= 1;
      default:
        return rect.contains(point);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': {'x': position.dx, 'y': position.dy},
      'text': text,
      'backgroundColor': backgroundColor.value,
      'textColor': textColor.value,
      'width': width,
      'height': height,
      'shape': shape.index,
      'fontSize': fontSize,
      'fontWeight': fontWeight.index,
    };
  }
  // Méthode toMap à ajouter dans la classe MindMapNode
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'position': {'x': position.dx, 'y': position.dy},
    'text': text,
    'backgroundColor': backgroundColor.value,
    'textColor': textColor.value,
    'width': width,
    'height': height,
    'shape': shape.index,
    'fontSize': fontSize,
    'fontWeight': fontWeight.index,
    'isSelected': isSelected,
  };
}

  static MindMapNode fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id'],
      position: Offset(json['position']['x'], json['position']['y']),
      text: json['text'],
      backgroundColor: Color(json['backgroundColor']),
      textColor: Color(json['textColor']),
      width: json['width'],
      height: json['height'],
      shape: NodeShape.values[json['shape']],
      fontSize: json['fontSize'],
      fontWeight: FontWeight.values[json['fontWeight']],
    );
  }
}

// Modèle pour les connexions
class MindMapConnection {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  Color color;
  double strokeWidth;

  MindMapConnection({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.color = const Color(0xFF6C63FF),
    this.strokeWidth = 2.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  static MindMapConnection fromJson(Map<String, dynamic> json) {
    return MindMapConnection(
      id: json['id'],
      fromNodeId: json['fromNodeId'],
      toNodeId: json['toNodeId'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}



// Painter personnalisé pour dessiner le mind map
// Classe MindMapPainter à ajouter avant la classe MindMapEditorController
class MindMapPainter extends CustomPainter {
  final List<MindMapNode> nodes;
  final List<MindMapConnection> connections;
  final String selectedNodeId;
  final bool isLinkMode;

  final int _nodesHash;
  final int _connectionsHash;

  MindMapPainter({
    required this.nodes,
    required this.connections,
    required this.selectedNodeId,
    required this.isLinkMode,
  }) : _nodesHash = _calculateNodesHash(nodes),
       _connectionsHash = _calculateConnectionsHash(connections);

  // Méthode pour calculer le hash des nœuds
  static int _calculateNodesHash(List<MindMapNode> nodes) {
    return Object.hashAll(nodes.map((node) => Object.hash(
      node.id,
      node.position.dx.round(),
      node.position.dy.round(),
      node.text,
      node.backgroundColor.value,
      node.shape,
      node.isSelected,
    )));
  }

  // Méthode pour calculer le hash des connexions
  static int _calculateConnectionsHash(List<MindMapConnection> connections) {
    return Object.hashAll(connections.map((conn) => Object.hash(
      conn.id,
      conn.fromNodeId,
      conn.toNodeId,
      conn.color.value,
    )));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner les connexions d'abord
    for (final connection in connections) {
      _drawConnection(canvas, connection);
    }

    // Dessiner les nœuds
    for (final node in nodes) {
      _drawNode(canvas, node);
    }
  }

  void _drawConnection(Canvas canvas, MindMapConnection connection) {
  final fromNode = nodes.firstWhereOrNull((n) => n.id == connection.fromNodeId);
  final toNode = nodes.firstWhereOrNull((n) => n.id == connection.toNodeId);

  if (fromNode == null || toNode == null) return;

  final paint = Paint()
    ..color = connection.color
    ..strokeWidth = connection.strokeWidth
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  // Dessiner une ligne courbe pour un meilleur visuel
  final path = Path()
    ..moveTo(fromNode.position.dx, fromNode.position.dy)
    ..cubicTo(
      fromNode.position.dx + (toNode.position.dx - fromNode.position.dx) / 3,
      fromNode.position.dy,
      toNode.position.dx - (toNode.position.dx - fromNode.position.dx) / 3,
      toNode.position.dy,
      toNode.position.dx,
      toNode.position.dy,
    );

  canvas.drawPath(path, paint);
}

  void _drawNode(Canvas canvas, MindMapNode node) {
    final rect = Rect.fromCenter(
      center: node.position,
      width: node.width,
      height: node.height,
    );

    // Peinture pour le fond
    final backgroundPaint = Paint()
      ..color = node.backgroundColor
      ..style = PaintingStyle.fill;

       // Peinture pour la bordure (seulement si sélectionné)
    Paint? borderPaint;
    if (node.id == selectedNodeId) {
      borderPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
    }

    // Dessiner la forme selon le type
    switch (node.shape) {
      case NodeShape.circle:
        canvas.drawCircle(node.position, node.width / 2, backgroundPaint);
        if (borderPaint != null) {
          canvas.drawCircle(node.position, node.width / 2, borderPaint);
        }
        break;
      case NodeShape.rectangle:
      case NodeShape.square:
        canvas.drawRect(rect, backgroundPaint);
        if (borderPaint != null) {
          canvas.drawRect(rect, borderPaint);
        }
        break;
      default:
        canvas.drawRect(rect, backgroundPaint);
        if (borderPaint != null) {
          canvas.drawRect(rect, borderPaint);
        }
    }

    // Dessiner le texte (optimisé)
    _drawNodeText(canvas, node);
  }
  void _drawNodeText(Canvas canvas, MindMapNode node) {
    final textSpan = TextSpan(
      text: node.text,
      style: TextStyle(
        color: node.textColor,
        fontSize: node.fontSize,
        fontWeight: node.fontWeight,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: node.width - 10);
    
    final textOffset = Offset(
      node.position.dx - textPainter.width / 2,
      node.position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

    @override
  bool shouldRepaint(covariant MindMapPainter oldDelegate) {
    // Seulement repaindre si quelque chose a vraiment changé
    return oldDelegate._nodesHash != _nodesHash ||
           oldDelegate._connectionsHash != _connectionsHash ||
           oldDelegate.selectedNodeId != selectedNodeId ||
           oldDelegate.isLinkMode != isLinkMode;
  }
}

// Contrôleur mis à jour pour l'éditeur
class MindMapEditorController extends GetxController {

  Color _getRandomColor() {
  final colors = [
    const Color(0xFF6C63FF),
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF45B7D1),
    const Color(0xFF96CEB4),
    const Color(0xFFFECA57),
    const Color(0xFFFF9FF3),
    const Color(0xFF54A0FF),
    const Color(0xFFE17055),
    const Color(0xFF74B9FF),
  ];
  
  return colors[math.Random().nextInt(colors.length)];
}

  final RxString projectTitle = ''.obs;
  final RxString projectDescription = ''.obs;
  final RxString templateId = ''.obs;

  final String? existingProjectId;
  final MindMapDataService _dataService = MindMapDataService();

  final GlobalKey canvasKey = GlobalKey();
  
  final RxList<MindMapNode> nodes = <MindMapNode>[].obs;
  final RxList<MindMapConnection> connections = <MindMapConnection>[].obs;

  final RxBool hasUnsavedChanges = false.obs;
  String _initialProjectState = '';
  
  final RxString selectedNodeId = ''.obs;
  final RxBool isLinkMode = false.obs;
  final RxString linkFromNodeId = ''.obs;
  Timer? _updateTimer;
  
  MindMapNode? draggedNode;
  Offset? dragOffset;

  // Date de création pour les projets existants
  String? _createdAt;

  MindMapEditorController({
    required String title,
    required String description,
    required String template,
    this.existingProjectId,
  }) {
    projectTitle.value = title;
    projectDescription.value = description;
    templateId.value = template;
    
    if (existingProjectId != null) {
      _loadExistingProject();
    } else {
      _createCentralNode();
    }
  }
  @override
  void onInit() {
    super.onInit();
    // Enregistrer l'état initial après le chargement
    _saveInitialState();
    
    // Écouter les changements dans les nœuds et connexions
    ever(nodes, (_) => _markAsModified());
    ever(connections, (_) => _markAsModified());
    ever(projectTitle, (_) => _markAsModified());
    ever(projectDescription, (_) => _markAsModified());
  }

  void _saveInitialState() {
    // Attendre que le projet soit complètement chargé
    Future.delayed(Duration(milliseconds: 100), () {
      _initialProjectState = _getCurrentProjectState();
      hasUnsavedChanges.value = false;
    });
  }
  
  String _getCurrentProjectState() {
    final nodesData = nodes.map((node) => node.toMap()).toList();
    final connectionsData = connections.map((conn) => conn.toJson()).toList();
    
    return {
      'title': projectTitle.value,
      'description': projectDescription.value,
      'nodes': nodesData,
      'connections': connectionsData,
    }.toString();
  }
  
  void _markAsModified() {
    final currentState = _getCurrentProjectState();
    hasUnsavedChanges.value = currentState != _initialProjectState;
  }
  
  void _markAsSaved() {
    _initialProjectState = _getCurrentProjectState();
    hasUnsavedChanges.value = false;
  }

  void _loadExistingProject() async {
    try {
      print('Début du chargement du projet: $existingProjectId');
      
      if (_dataService.currentUserId == null) {
        print('Utilisateur non connecté');
        Get.snackbar(
          'Erreur',
          'Vous devez être connecté pour charger ce projet',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        _createCentralNode();
        return;
      }

      // Utiliser la nouvelle méthode pour récupérer les données brutes
      final projectData = await _dataService.getProjectData(existingProjectId!);
      
      if (projectData != null) {
        print('Données du projet récupérées: ${projectData['title']}');
        
        // Mettre à jour les informations du projet
        projectTitle.value = projectData['title'] ?? 'Projet sans titre';
        projectDescription.value = projectData['description'] ?? '';
        templateId.value = projectData['template'] ?? 'blank';
        
        // Récupérer la date de création
        if (projectData['createdAt'] != null) {
          if (projectData['createdAt'] is Timestamp) {
            _createdAt = (projectData['createdAt'] as Timestamp).toDate().toIso8601String();
          } else if (projectData['createdAt'] is String) {
            _createdAt = projectData['createdAt'];
          }
        }
        
        // Charger les nœuds avec validation
        nodes.clear();
        if (projectData['nodes'] != null && projectData['nodes'] is List) {
          final nodesList = projectData['nodes'] as List;
          print('Chargement de ${nodesList.length} nœuds');
          
          for (final nodeData in nodesList) {
            try {
              if (nodeData is Map<String, dynamic>) {
                final node = _createNodeFromData(nodeData);
                if (node != null) {
                  nodes.add(node);
                }
              }
            } catch (e) {
              print('Erreur lors du chargement d\'un nœud: $e');
            }
          }
        }
        
        // Charger les connexions avec validation
        connections.clear();
        if (projectData['connections'] != null && projectData['connections'] is List) {
          final connectionsList = projectData['connections'] as List;
          print('Chargement de ${connectionsList.length} connexions');
          
          for (final connData in connectionsList) {
            try {
              if (connData is Map<String, dynamic>) {
                final connection = _createConnectionFromData(connData);
                if (connection != null) {
                  connections.add(connection);
                }
              }
            } catch (e) {
              print('Erreur lors du chargement d\'une connexion: $e');
            }
          }
        }
        
        // Si aucun nœud n'a été chargé, créer un nœud central
        if (nodes.isEmpty) {
          print('Aucun nœud chargé, création du nœud central');
          _createCentralNode();
        }
        
        print('Projet chargé avec succès: ${nodes.length} nœuds, ${connections.length} connexions');
        
      } else {
        print('Impossible de récupérer les données du projet');
        Get.snackbar(
          'Erreur',
          'Impossible de charger le projet',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        _createCentralNode();
      }
    } catch (e) {
      print('Erreur lors du chargement du projet: $e');
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _createCentralNode();
    }
  }

  MindMapNode? _createNodeFromData(Map<String, dynamic> nodeData) {
    try {
      // Validation des données requises
      if (nodeData['id'] == null || 
          nodeData['position'] == null ||
          nodeData['text'] == null) {
        print('Données de nœud incomplètes: $nodeData');
        return null;
      }

      final position = nodeData['position'];
      if (position is! Map || position['x'] == null || position['y'] == null) {
        print('Position invalide pour le nœud: $position');
        return null;
      }

      return MindMapNode(
        id: nodeData['id'].toString(),
        position: Offset(
          (position['x'] as num).toDouble(),
          (position['y'] as num).toDouble(),
        ),
        text: nodeData['text'].toString(),
        backgroundColor: Color(nodeData['backgroundColor'] ?? 0xFF6C63FF),
        textColor: Color(nodeData['textColor'] ?? 0xFFFFFFFF),
        width: (nodeData['width'] as num?)?.toDouble() ?? 120.0,
        height: (nodeData['height'] as num?)?.toDouble() ?? 80.0,
        shape: NodeShape.values[nodeData['shape'] ?? 0],
        fontSize: (nodeData['fontSize'] as num?)?.toDouble() ?? 14.0,
        fontWeight: FontWeight.values[nodeData['fontWeight'] ?? 0],
      );
    } catch (e) {
      print('Erreur lors de la création du nœud: $e');
      return null;
    }
  }

  MindMapConnection? _createConnectionFromData(Map<String, dynamic> connData) {
    try {
      // Validation des données requises
      if (connData['id'] == null || 
          connData['fromNodeId'] == null ||
          connData['toNodeId'] == null) {
        print('Données de connexion incomplètes: $connData');
        return null;
      }

      return MindMapConnection(
        id: connData['id'].toString(),
        fromNodeId: connData['fromNodeId'].toString(),
        toNodeId: connData['toNodeId'].toString(),
        color: Color(connData['color'] ?? 0xFF6C63FF),
        strokeWidth: (connData['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      );
    } catch (e) {
      print('Erreur lors de la création de la connexion: $e');
      return null;
    }
  }

  void _createCentralNode() {
    final centralNode = MindMapNode(
      id: 'central',
      position: const Offset(200, 300),
      text: projectTitle.value.isNotEmpty ? projectTitle.value : 'Idée Centrale',
      backgroundColor: const Color(0xFF6C63FF),
      textColor: Colors.white,
      width: 150.0,
      height: 100.0,
      shape: NodeShape.circle,
      fontSize: 16.0,
    );
    nodes.add(centralNode);
    print('Nœud central créé');
  }

  // Remplacez la méthode saveProject dans MindMapEditorController par celle-ci :

  void saveProject() async {
    try {
      print('Début de la sauvegarde du projet');
      
      final userId = _dataService.currentUserId;
      if (userId == null) {
        Get.snackbar('Erreur', 'Vous devez être connecté pour sauvegarder');
        return;
      }

      // Validation des données
      if (projectTitle.value.trim().isEmpty) {
        Get.snackbar('Erreur', 'Le titre du projet ne peut pas être vide');
        return;
      }

      if (nodes.isEmpty) {
        Get.snackbar('Erreur', 'Le projet doit contenir au moins un nœud');
        return;
      }

      // Afficher un indicateur de chargement
      Get.dialog(
        AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Sauvegarde en cours...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      print('Préparation des données pour la sauvegarde');
      print('Nombre de nœuds: ${nodes.length}');
      print('Nombre de connexions: ${connections.length}');

      final nodesData = nodes.map((node) {
        final data = node.toMap();
        print('Nœud à sauvegarder: ${data['id']} - ${data['text']}');
        return data;
      }).toList();
      
      final connectionsData = connections.map((conn) {
        final data = conn.toJson();
        print('Connexion à sauvegarder: ${data['id']} (${data['fromNodeId']} -> ${data['toNodeId']})');
        return data;
      }).toList();

      // Sauvegarder dans Firestore
      final projectId = await _dataService.saveProjectFromController(
        projectId: existingProjectId,
        title: projectTitle.value,
        description: projectDescription.value,
        template: templateId.value,
        nodes: nodesData,
        connections: connectionsData,
        existingCreatedAt: _createdAt,
      );

      // Fermer l'indicateur de chargement
      Get.back();

      if (projectId == null) {
        print('Échec de la sauvegarde - projectId null');
        Get.snackbar(
          'Erreur', 
          'Impossible de sauvegarder le projet',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      print('Projet sauvegardé avec l\'ID: $projectId');

      // Mettre à jour les données locales si nécessaire
      try {
        final projectData = {
          'id': projectId,
          'title': projectTitle.value,
          'description': projectDescription.value,
          'template': templateId.value,
          'nodes': nodesData,
          'connections': connectionsData,
          'userId': userId,
          if (_createdAt != null) 'createdAt': _createdAt,
          'lastModified': DateTime.now().toIso8601String(),
        };

        // Sauvegarder localement
        final projectStorage = ProjectStorage.instance;
        projectStorage.saveProject(projectData);
        
        // Rafraîchir la liste
        await projectStorage.fetchProjectsFromFirestore(userId);
        
        print('Sauvegarde locale terminée');
      } catch (localError) {
        print('Erreur lors de la sauvegarde locale: $localError');
        // Ne pas afficher d'erreur car la sauvegarde Firestore a réussi
      }

      // Marquer comme sauvé (NOUVEAU)
      _markAsSaved();

      Get.snackbar(
        'Succès', 
        'Projet sauvegardé avec succès !',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      
      print('Erreur during saveProject: $e');
      print('Stack trace: ${StackTrace.current}');
      Get.snackbar(
        'Erreur', 
        'Erreur lors de la sauvegarde: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void showProjectRenameDialog() {
    final titleController = TextEditingController(text: projectTitle.value);
    final descriptionController = TextEditingController(text: projectDescription.value);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Modifier le projet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du projet',
                hintText: 'Entrez le titre...',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Entrez la description...',
              ),
              maxLines: 3,
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
              projectTitle.value = titleController.text.trim();
              projectDescription.value = descriptionController.text.trim();
              
              // Mettre à jour le nœud central
              final centralNodeIndex = nodes.indexWhere((n) => n.id == 'central');
              if (centralNodeIndex != -1) {
                nodes[centralNodeIndex] = nodes[centralNodeIndex].copyWith(
                  text: projectTitle.value,
                );
                nodes.refresh();
              }
              
              Get.back();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
}

  void addNode() {
    final newNode = MindMapNode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: Offset(
        100 + math.Random().nextDouble() * 300,
        100 + math.Random().nextDouble() * 400,
      ),
      text: 'Nouvelle idée',
      backgroundColor: _getRandomColor(),
      textColor: Colors.white,
      width: 120.0,
      height: 80.0,
      shape: NodeShape.rectangle,
      fontSize: 14.0,
    );
    nodes.add(newNode);
  }

  void onCanvasTap(Offset position) {
    // Vérifier si on clique sur un nœud
    MindMapNode? tappedNode;
    for (final node in nodes) {
      if (node.containsPoint(position)) {
        tappedNode = node;
        break;
      }
    }

    if (tappedNode != null) {
      if (isLinkMode.value) {
        _handleLinkModeNodeTap(tappedNode);
      } else {
        _selectNode(tappedNode.id);
      }
    } else {
      // Clic sur le canvas vide
      if (isLinkMode.value) {
        isLinkMode.value = false;
        linkFromNodeId.value = '';
      } else {
        selectedNodeId.value = '';
      }
    }
  }

  void _handleLinkModeNodeTap(MindMapNode node) {
    if (linkFromNodeId.value.isEmpty) {
      linkFromNodeId.value = node.id;
      Get.snackbar('Mode liaison', 'Sélectionnez le nœud de destination');
    } else {
      if (linkFromNodeId.value != node.id) {
        _createConnection(linkFromNodeId.value, node.id);
      }
      isLinkMode.value = false;
      linkFromNodeId.value = '';
    }
  }

  void _createConnection(String fromId, String toId) {
    // Vérifier si la connexion existe déjà
    final existingConnection = connections.firstWhereOrNull(
      (conn) => (conn.fromNodeId == fromId && conn.toNodeId == toId) ||
                (conn.fromNodeId == toId && conn.toNodeId == fromId),
    );

    if (existingConnection == null) {
      final connection = MindMapConnection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromNodeId: fromId,
        toNodeId: toId,
      );
      connections.add(connection);
    }
  }

  void _selectNode(String nodeId) {
    selectedNodeId.value = nodeId;
  }

  void onPanStart(Offset position) {
    for (final node in nodes) {
      if (node.containsPoint(position)) {
        draggedNode = node;
        dragOffset = position - node.position;
        break;
      }
    }
  }

  void onPanUpdate(Offset position) {
     if (draggedNode != null && dragOffset != null) {
      // Annuler le timer précédent
      _updateTimer?.cancel();
      
      // Mettre à jour la position
      draggedNode!.position = position - dragOffset!;
      
      // Programmer une mise à jour avec délai
      _updateTimer = Timer(const Duration(milliseconds: 16), () {
        nodes.refresh();
      });
    }
  }

  void onPanEnd() {
    draggedNode = null;
    dragOffset = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    
    // Force une dernière mise à jour
    nodes.refresh();
  }
  @override
  void onClose() {
    _updateTimer?.cancel();
    super.onClose();
  }

  void toggleLinkMode() {
    isLinkMode.value = !isLinkMode.value;
    linkFromNodeId.value = '';
    if (isLinkMode.value) {
      Get.snackbar('Mode liaison', 'Sélectionnez deux nœuds à connecter');
    }
  }

  // Nouvelle méthode pour changer la forme d'un nœud
  void showShapePicker() {
    if (selectedNodeId.value.isEmpty) {
      Get.snackbar('Erreur', 'Sélectionnez un nœud pour changer la forme');
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Choisir une forme'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: NodeShape.values.length,
            itemBuilder: (context, index) {
              final shape = NodeShape.values[index];
              return GestureDetector(
                onTap: () {
                  final node = nodes.firstWhereOrNull((n) => n.id == selectedNodeId.value);
                  if (node != null) {
                    final updatedNode = node.copyWith(shape: shape);
                    final nodeIndex = nodes.indexWhere((n) => n.id == selectedNodeId.value);
                    nodes[nodeIndex] = updatedNode;
                    nodes.refresh();
                  }
                  Get.back();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(shape.icon, size: 30, color: const Color(0xFF6C63FF)),
                      const SizedBox(height: 5),
                      Text(
                        shape.displayName,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void showTextEditor() {
    if (selectedNodeId.value.isEmpty) {
      Get.snackbar('Erreur', 'Sélectionnez un nœud pour modifier le texte');
      return;
    }

    final node = nodes.firstWhereOrNull((n) => n.id == selectedNodeId.value);
    if (node != null) {
      final textController = TextEditingController(text: node.text);
      
      Get.dialog(
        AlertDialog(
          title: const Text('Modifier le texte'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Entrez votre texte...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final updatedNode = node.copyWith(text: textController.text);
                final nodeIndex = nodes.indexWhere((n) => n.id == selectedNodeId.value);
                nodes[nodeIndex] = updatedNode;
                nodes.refresh();
                Get.back();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void showColorPicker() {
    if (selectedNodeId.value.isEmpty) {
      Get.snackbar('Erreur', 'Sélectionnez un nœud pour changer les couleurs');
      return;
    }

    final node = nodes.firstWhereOrNull((n) => n.id == selectedNodeId.value);
    if (node == null) return;

    final backgroundColors = [
      const Color(0xFF6C63FF),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFECA57),
      const Color(0xFFFF9FF3),
      const Color(0xFF54A0FF),
    ];

    final textColors = [
      Colors.white,
      Colors.black,
      Colors.grey[800]!,
      const Color(0xFF2C3E50),
    ];

    Get.dialog(
      AlertDialog(
        title: const Text('Personnaliser les couleurs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Couleur de fond:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: backgroundColors.map((color) => GestureDetector(
                onTap: () {
                  final updatedNode = node.copyWith(backgroundColor: color);
                  final nodeIndex = nodes.indexWhere((n) => n.id == selectedNodeId.value);
                  nodes[nodeIndex] = updatedNode;
                  nodes.refresh();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: node.backgroundColor == color ? Colors.black : Colors.grey.shade300,
                      width: node.backgroundColor == color ? 3 : 1,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Couleur du texte:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: textColors.map((color) => GestureDetector(
                onTap: () {
                  final updatedNode = node.copyWith(textColor: color);
                  final nodeIndex = nodes.indexWhere((n) => n.id == selectedNodeId.value);
                  nodes[nodeIndex] = updatedNode;
                  nodes.refresh();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: node.textColor == color ? const Color(0xFF6C63FF) : Colors.grey.shade300,
                      width: node.textColor == color ? 3 : 1,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Nouvelle méthode pour ajuster la taille
  void showSizeEditor() {
    if (selectedNodeId.value.isEmpty) {
      Get.snackbar('Erreur', 'Sélectionnez un nœud pour modifier la taille');
      return;
    }

    final node = nodes.firstWhereOrNull((n) => n.id == selectedNodeId.value);
    if (node == null) return;

    final widthController = TextEditingController(text: node.width.toString());
    final heightController = TextEditingController(text: node.height.toString());
    final fontSizeController = TextEditingController(text: node.fontSize.toString());

    Get.dialog(
      AlertDialog(
        title: const Text('Modifier la taille'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widthController,
              decoration: const InputDecoration(
                labelText: 'Largeur',
                suffixText: 'px',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: heightController,
              decoration: const InputDecoration(
                labelText: 'Hauteur',
                suffixText: 'px',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: fontSizeController,
              decoration: const InputDecoration(
                labelText: 'Taille du texte',
                suffixText: 'px',
              ),
              keyboardType: TextInputType.number,
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
              final width = double.tryParse(widthController.text) ?? node.width;
              final height = double.tryParse(heightController.text) ?? node.height;
              final fontSize = double.tryParse(fontSizeController.text) ?? node.fontSize;

              final updatedNode = node.copyWith(
                width: width.clamp(50.0, 500.0),
                height: height.clamp(30.0, 300.0),
                fontSize: fontSize.clamp(8.0, 32.0),
              );
              
              final nodeIndex = nodes.indexWhere((n) => n.id == selectedNodeId.value);
              nodes[nodeIndex] = updatedNode;
              nodes.refresh();
              Get.back();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  

  void deleteSelected() {
    if (selectedNodeId.value.isEmpty) {
      Get.snackbar('Erreur', 'Sélectionnez un nœud à supprimer');
      return;
    }

    if (selectedNodeId.value == 'central') {
      Get.snackbar('Erreur', 'Impossible de supprimer le nœud central');
      return;
    }

    // Supprimer les connexions liées au nœud
    connections.removeWhere((conn) => 
      conn.fromNodeId == selectedNodeId.value || 
      conn.toNodeId == selectedNodeId.value
    );

    // Supprimer le nœud
    nodes.removeWhere((node) => node.id == selectedNodeId.value);
    selectedNodeId.value = '';
  }

  // Dans mind_map_editor.dart, remplacez la méthode deleteProject du contrôleur par celle-ci :

void deleteProject() async {
  if (existingProjectId == null || existingProjectId!.isEmpty) {
    Get.snackbar('Erreur', 'Aucun projet à supprimer');
    return;
  }

  final result = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('Supprimer le projet'),
      content: Text('Êtes-vous sûr de vouloir supprimer le projet "${projectTitle.value}" ?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
        )
      ],
    ),
  );

  if (result == true) {
    try {
      // Afficher un indicateur de chargement
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Suppression en cours...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Supprimer de Firestore
      final success = await _dataService.deleteProject(existingProjectId!);
      
      // Fermer l'indicateur de chargement
      Get.back();
      
      if (success) {
        // Supprimer du stockage local
        final projectStorage = ProjectStorage.instance;
        projectStorage.deleteProject(existingProjectId!);
        
        // Rafraîchir la liste des projets
        if (_dataService.currentUserId != null) {
          await projectStorage.fetchProjectsFromFirestore(_dataService.currentUserId!);
        }
        
        Get.back(); // Retour à l'écran précédent
        Get.snackbar(
          'Succès', 
          'Projet supprimé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Erreur', 
          'Impossible de supprimer le projet',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      if (Get.isDialogOpen == true) Get.back();
      
      print('Erreur suppression: $e');
      Get.snackbar(
        'Erreur', 
        'Erreur lors de la suppression: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

  void undo() {
    // Implémentation de l'annulation
    Get.snackbar('Info', 'Fonction d\'annulation à implémenter');
  }

  void redo() {
    // Implémentation de la restauration
    Get.snackbar('Info', 'Fonction de restauration à implémenter');
  }

  void exportToPdf() {
    // Implémentation de l'export PDF
    Get.snackbar(
      'Export PDF',
      'Fonctionnalité d\'export PDF à implémenter',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  void exportToImage() {
    // Implémentation de l'export Image
    Get.snackbar(
      'Export Image',
      'Fonctionnalité d\'export Image à implémenter',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
}
