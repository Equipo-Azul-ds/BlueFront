import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AccountTypePage extends StatefulWidget {
  const AccountTypePage({super.key});

  @override
  State<AccountTypePage> createState() => _AccountTypePageState();
}

class _AccountTypePageState extends State<AccountTypePage> {
  String? _selected;
  bool _showCompletion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _showCompletion ? _buildCompletion() : _buildSelector(),
        ),
      ),
    );
  }

  Widget _buildSelector() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: _selected == null ? 0.35 : 0.7,
            color: Colors.green,
            backgroundColor: Colors.green.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.group,
                        color: AppColor.primary,
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¿Qué tipo de cuenta quieres crear?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _choiceCard(
                        title: 'Profesor',
                        color: const Color(0xFFE53935),
                        value: 'teacher',
                        icon: Icons.school,
                      ),
                      _choiceCard(
                        title: 'Estudiante',
                        color: const Color(0xFF43A047),
                        value: 'student',
                        icon: Icons.emoji_people,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected == null ? Colors.grey : AppColor.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _selected == null
                        ? null
                        : () {
                            setState(() {
                              _showCompletion = true;
                            });
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Continuar'),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _choiceCard({required String title, required Color color, required String value, required IconData icon}) {
    final isSelected = _selected == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selected = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isSelected)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.check, color: color, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletion() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: 1,
            color: Colors.green,
            backgroundColor: Colors.green.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 170,
                width: 170,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 100),
              ),
              const SizedBox(height: 28),
              const Text(
                '¡Listo!',
                style: TextStyle(
                  color: AppColor.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selected == 'teacher'
                    ? 'Elegiste Profesor. Ajustaremos el contenido para educadores.'
                    : 'Elegiste Estudiante. ¡Listo para aprender y jugar!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
