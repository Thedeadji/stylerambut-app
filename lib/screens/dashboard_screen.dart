import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/hairstyle_labels.dart';
import '../models/history_entry.dart';
import '../services/guest_session.dart';
import '../services/history_store.dart';
import 'history_screen.dart';
import 'history_result_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitAppDialog(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF3D3D3D),
        body: SafeArea(
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF9CA8C2).withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF9CA8C2).withValues(alpha: 0.08),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/settings'),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  'assets/icon/settingbutton.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Welcome Text
                    ValueListenableBuilder<bool>(
                      valueListenable: GuestSession.instance.isGuestNotifier,
                      builder: (context, isGuest, _) {
                        if (isGuest) {
                          return const Text(
                            'kamu menggunakan mode guest',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          );
                        }

                        final user = FirebaseAuth.instance.currentUser;
                        final displayName =
                            user?.displayName ??
                            user?.email?.split('@')[0] ??
                            'Pengguna';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selamat Datang,',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // Last Result Title
                    const Text(
                      'Hasil Terakhir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Result Card
                    ValueListenableBuilder<List<HistoryEntry>>(
                      valueListenable: HistoryStore.instance.entries,
                      builder: (context, entries, child) {
                        if (entries.isEmpty) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 36,
                              horizontal: 16,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Belum ada riwayat deteksi. Ambil foto terlebih dahulu.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }

                        final lastEntry = entries.first;

                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(lastEntry.result.imagePath),
                                  width: 100,
                                  height: 115,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const ColoredBox(
                                        color: Color(0xFFE8E8E8),
                                        child: SizedBox(
                                          width: 100,
                                          height: 115,
                                          child: Icon(
                                            Icons.person,
                                            size: 48,
                                            color: Colors.black45,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bentuk wajah :',
                                      style: TextStyle(
                                        color: Color(0xFFFFC107),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      HairstyleLabels.displayFaceShape(
                                        lastEntry.result.faceShape.label,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Kepadatan Rambut :',
                                      style: TextStyle(
                                        color: Color(0xFFFFC107),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      HairstyleLabels.displayHairDensity(
                                        lastEntry.result.hairDensity.label,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Pilihan Gaya Rambut :',
                                      style: TextStyle(
                                        color: Color(0xFFFFC107),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      HairstyleLabels.formatHairstyleName(
                                        lastEntry.style,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  HistoryResultScreen(
                                                    entry: lastEntry,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFFC107,
                                          ),
                                          foregroundColor: Colors.black,
                                          minimumSize: const Size(80, 26),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 0,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 0,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Lihat Hasil',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // Fitur Cepat Title
                    const Text(
                      'Fitur Cepat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Fitur Cepat Cards Row
                    Row(
                      children: [
                        _buildFeatureCard(
                          iconPath: 'assets/icon/hairstyle_icon.png',
                          label: 'Gaya Rambut',
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed('/hairstyle_gallery');
                          },
                          leftMargin: 0,
                          rightMargin: 6,
                        ),
                        _buildFeatureCard(
                          iconPath: 'assets/icon/faceshape_icon.png',
                          label: 'Bentuk Wajah',
                          onTap: () {
                            Navigator.pushNamed(context, '/faceshape_info');
                          },
                          leftMargin: 6,
                          rightMargin: 6,
                        ),
                        _buildFeatureCard(
                          iconPath: 'assets/icon/lightbulb_icon.png',
                          label: 'Cara Kerja',
                          onTap: () {
                            Navigator.of(context).pushNamed('/how_it_works');
                          },
                          leftMargin: 6,
                          rightMargin: 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Custom Floating Bottom Navigation
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                    left: 30,
                    right: 30,
                  ),
                  child: SizedBox(
                    height: 76,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Dark rounded background
                        Container(
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Left Tab (Menu)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor: Colors.white24,
                                  highlightColor: Colors.white10,
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icon/homebutton.png',
                                          width: 22,
                                          height: 22,
                                          color: const Color(0xFFFFC107),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Menu',
                                          style: TextStyle(
                                            color: Color(0xFFFFC107),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          width: 28,
                                          height: 2,
                                          color: const Color(0xFFFFC107),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Space for floating camera button in the center
                              const SizedBox(width: 50),
                              // Right Tab (History)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor: Colors.white24,
                                  highlightColor: Colors.white10,
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => const HistoryScreen(),
                                        transitionDuration: Duration.zero,
                                        reverseTransitionDuration:
                                            Duration.zero,
                                        settings: const RouteSettings(
                                          name: '/history',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icon/historybutton.png',
                                          width: 22,
                                          height: 22,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'History',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ), // balance vertical space with the left tab underline
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Floating Camera Button overlapping top
                        Positioned(
                          top: -10,
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/detection'),
                            child: Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFC107),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFC107,
                                    ).withValues(alpha: 0.8),
                                    spreadRadius: 6,
                                    blurRadius: 18,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset('assets/icon/camerabutton.png'),
                                  Image.asset('assets/icon/camerabutton.png'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExitAppDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Anda akan keluar dari aplikasi'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Widget _buildFeatureCard({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    required double leftMargin,
    required double rightMargin,
  }) {
    return Expanded(
      child: Container(
        height: 90,
        margin: EdgeInsets.only(left: leftMargin, right: rightMargin),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconPath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
