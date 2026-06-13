import 'package:flutter/material.dart';

const Color _backgroundColor = Color(0xFF2F2F2F);
const Color _cardColor = Color(0xFF333333);
const Color _accentColor = Color(0xFFFFC107);

class FaceShapeInfoScreen extends StatelessWidget {
  const FaceShapeInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: _accentColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Bentuk Wajah',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Pelajari deskripsi tiga bentuk wajah yang umum: Oval, Kotak, dan Bulat. Gunakan informasi ini untuk memilih gaya rambut yang sesuai.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              _ShapeCard(
                title: 'Oval',
                subtitle:
                    'Wajah oval memiliki proporsi seimbang di mana panjang wajah kira-kira 1.5 kali lebarnya. Dahi sedikit lebih lebar daripada kontur yang membulat. Bentuk ini dianggap paling serbaguna untuk styling rambut.',
                icon: Icons.circle,
              ),
              const SizedBox(height: 12),

              _ShapeCard(
                title: 'Kotak',
                subtitle:
                    'Wajah kotak ditandai dengan garis rahang yang tegas dan dahi yang relatif lebar, sehingga lebar wajah mendekati panjangnya. Gaya yang melembutkan sudut-sudut wajah (layer, poni samping) biasanya cocok.',
                icon: Icons.crop_square,
              ),
              const SizedBox(height: 12),

              _ShapeCard(
                title: 'Bulat',
                subtitle:
                    'Wajah bulat memiliki lebar dan panjang yang hampir sama dengan kontur lembut dan rahang kurang menonjol. Pilih gaya yang memberi ilusi wajah lebih panjang, seperti layer panjang dan volume di atas.',
                icon: Icons.circle_outlined,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeCard extends StatelessWidget {
  const _ShapeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
