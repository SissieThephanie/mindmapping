import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindmapping/View/Navigation/mind_map_editor.dart';

class Create extends StatelessWidget {
  const Create({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateController());
    
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
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Iconsax.arrow_left_2),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Créer un Mind Map',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Organisez vos idées visuellement',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Formulaire de création
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre du projet
                    Text(
                      'Titre du projet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller.titleController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Planification projet...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Iconsax.text, color: Color(0xFF6C63FF)),
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Description
                    Text(
                      'Description (optionnel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller.descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Décrivez votre mind map...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Iconsax.note_text, color: Color(0xFF6C63FF)),
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Sélection de template
                    Text(
                      'Choisir un template',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    Obx(() => Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      children: controller.templates.map((template) => 
                        _buildTemplateCard(template, controller)
                      ).toList(),
                    )),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Options avancées
              
              
              const SizedBox(height: 40),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ElevatedButton(
                        onPressed: () => controller.createMindMap(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.add_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Créer le Mind Map',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(MindMapTemplate template, CreateController controller) {
    final isSelected = controller.selectedTemplate.value?.id == template.id;
    
    return GestureDetector(
      onTap: () => controller.selectedTemplate.value = template,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 100,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              template.icon,
              size: 32,
              color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              template.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6C63FF),
            size: 20,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF6C63FF),
        ),
      ],
    );
  }
}

// Modèle de template
class MindMapTemplate {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  MindMapTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}

// Contrôleur pour gérer l'état
class CreateController extends GetxController {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  
  final Rx<MindMapTemplate?> selectedTemplate = Rx<MindMapTemplate?>(null);
  final RxBool isCollaborative = false.obs;
  final RxBool enableNotifications = true.obs;
  final RxBool autoSave = true.obs;
  
  final List<MindMapTemplate> templates = [
    MindMapTemplate(
      id: 'blank',
      name: 'Vierge',
      
      icon: Iconsax.note,
      description: 'Commencer avec une carte vierge',
    ),
    MindMapTemplate(
      id: 'business',
      name: 'Business',
      icon: Iconsax.briefcase,
      description: 'Template pour projets business',
    ),
    MindMapTemplate(
      id: 'education',
      name: 'Éducation',
      icon: Iconsax.book,
      description: 'Pour l\'apprentissage et les cours',
    ),
    MindMapTemplate(
      id: 'project',
      name: 'Projet',
      icon: Iconsax.task_square,
      description: 'Planification de projet',
    ),
    MindMapTemplate(
      id: 'brainstorm',
      name: 'Brainstorm',
      icon: Iconsax.lamp,
      description: 'Session de brainstorming',
    ),
    MindMapTemplate(
      id: 'decision',
      name: 'Décision',
      icon: Iconsax.diagram,
      description: 'Prise de décision',
    ),
  ];
  
  @override
  void onInit() {
    super.onInit();
    // Sélectionner le template vierge par défaut
    selectedTemplate.value = templates.first;
  }
  
  void createMindMap() {
    if (titleController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer un titre pour votre mind map',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    // Ici vous pouvez ajouter la logique de création
    // Par exemple, sauvegarder en base de données, naviguer vers l'éditeur, etc.
    
    Get.snackbar(
      'Succès',
      'Mindmapping "${titleController.text}" créé avec succès!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    // Naviguer vers l'éditeur de mind map
    Get.to(() => MindMapEditor(
      projectTitle: titleController.text,
      projectDescription: descriptionController.text,
      templateId: selectedTemplate.value?.id ?? 'blank',
    ));
    
    // Ou retourner à l'accueil
    Get.back();
  }
  
  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
