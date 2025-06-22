import 'package:cloud_firestore/cloud_firestore.dart';

class MindMapProject {
  String id;
  String userId;
  String title;
  String description;
  String template;
  Timestamp createdAt;
  Timestamp lastModified;
  List<Map<String, dynamic>> nodes;
  List<Map<String, dynamic>> connections;

  MindMapProject({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.template,
    required this.createdAt,
    required this.lastModified,
    required this.nodes,
    required this.connections,
  });

  MindMapProject.fromJson(Map<String, Object?> json) 
  : this(
      id: json['id']! as String,
      userId: json['userId']! as String,
      title: json['title']! as String,
      description: json['description']! as String,
      template: json['template']! as String,
      createdAt: json['createdAt']! as Timestamp,
      lastModified: json['lastModified']! as Timestamp,
      nodes: (json['nodes'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      connections: (json['connections'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
    );

  MindMapProject copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? template,
    Timestamp? createdAt,
    Timestamp? lastModified,
    List<Map<String, dynamic>>? nodes,
    List<Map<String, dynamic>>? connections,
  }) {
    return MindMapProject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      template: template ?? this.template,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      nodes: nodes ?? this.nodes,
      connections: connections ?? this.connections,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "id": id,
      "userId": userId,
      "title": title,
      "description": description,
      "template": template,
      "createdAt": createdAt,
      "lastModified": lastModified,
      "nodes": nodes,
      "connections": connections,
    };
  }
}