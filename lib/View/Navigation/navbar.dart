import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindmapping/View/Navigation/create.dart';
import 'package:mindmapping/View/Navigation/myproject.dart';
import 'package:mindmapping/View/Navigation/profil.dart';
import 'package:mindmapping/View/login.view.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavbarController());
    
    return Scaffold(

      floatingActionButton: Obx(() => Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: AnimatedScale(
          scale: controller.selectedIndex.value == 2 ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF9C88FF),
                  Color(0xFFB794F6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => controller.selectedIndex.value = 0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: AnimatedRotation(
                turns: controller.selectedIndex.value == 2 ? 0.125 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Iconsax.add_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E).withOpacity(0.95),
              const Color(0xFF16213E).withOpacity(0.98),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomAppBar(
            height: 90,
            color: Colors.transparent,
            elevation: 0,
            notchMargin: 8,
            shape: const CircularNotchedRectangle(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // // Home
                  // Flexible(
                  //   child: _buildNavItem(
                  //     controller: controller,
                  //     index: 0,
                  //     icon: Iconsax.home_15,
                  //     activeIcon: Iconsax.home5,
                  //     label: 'Home',
                  //   ),
                  // ),
                  // // Maps
                  // Flexible(
                  //   child: _buildNavItem(
                  //     controller: controller,
                  //     index: 1,
                  //     icon: Iconsax.heart,
                  //     activeIcon: Iconsax.heart,
                  //     label: 'Favoris',
                  //   ),
                  // ),
                  // My Projects
                  Flexible(
                    child: _buildNavItem(
                      controller: controller,
                      index: 1,
                      icon: Iconsax.folder_24,
                      activeIcon: Iconsax.folder5,
                      label: 'Projects',
                    ),
                  ),
                  // Profile
                  Flexible(
                    child: _buildNavItem(
                      controller: controller,
                      index: 2,
                      icon: Iconsax.profile_circle4,
                      activeIcon: Iconsax.profile_circle5,
                      label: 'Profile',
                    ),
                  ),
                  // Logout - Nouvel onglet
                  Flexible(
                    child: _buildLogoutItem(controller: controller),
                  ),
                ],
              ),
            ),
          ),
        ),
      )),
      
      body: Obx(() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: controller.screens[controller.selectedIndex.value],
      )),
    );
  }

  Widget _buildNavItem({
    required NavbarController controller,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = controller.selectedIndex.value == index;
    
    return GestureDetector(
      onTap: () => controller.selectedIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
            ? const Color(0xFF6C63FF).withOpacity(0.2)
            : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected 
                  ? const Color(0xFF6C63FF)
                  : Colors.grey[400],
                size: isSelected ? 24 : 20,
              ),
            ),
            const SizedBox(height: 1),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected 
                    ? const Color(0xFF6C63FF)
                    : Colors.grey[400],
                  fontSize: isSelected ? 10 : 8,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nouveau widget pour le bouton de déconnexion
  Widget _buildLogoutItem({required NavbarController controller}) {
    return GestureDetector(
      onTap: () => controller.showLogoutDialog(Get.context!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.logout,
              color: Colors.red[400],
              size: 20,
            ),
            const SizedBox(height: 1),
            Flexible(
              child: Text(
                'Logout',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavbarController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final screens = [
    const Create(),
    const Myproject(),
    const ProfileView(),
  ];

  // Méthode pour afficher la boîte de dialogue de confirmation de déconnexion
  void showLogoutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Iconsax.logout,
              color: Colors.red[400],
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Déconnexion',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode de déconnexion
  void logout() {
    Get.back();
    Get.snackbar(
      'Déconnexion',
      'Vous avez été déconnecté avec succès',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[400],
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(
        Iconsax.tick_circle,
        color: Colors.white,
      ),
    );
    Get.off(LoginView());
  }
}