import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AccountCtaPage extends StatefulWidget {
  final String selectedType; // 'teacher' o 'student'
  const AccountCtaPage({super.key, required this.selectedType});

  @override
  State<AccountCtaPage> createState() => _AccountCtaPageState();
}

class _AccountCtaPageState extends State<AccountCtaPage> {
  String? _workplace;
  final TextEditingController _ageCtrl = TextEditingController();

  @override
  void dispose() {
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.selectedType == 'teacher';
    final accentColor = isTeacher ? const Color(0xFFE53935) : const Color(0xFF43A047);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: 1,
                backgroundColor: Colors.grey.shade200,
                color: AppColor.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _heroCard(isTeacher, accentColor),
                      const SizedBox(height: 24),
                      Text(
                        isTeacher ? 'Crea tu cuenta como profesor' : 'Crea tu cuenta como estudiante',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isTeacher
                            ? 'Inicia sesión o regístrate para crear retos, asignarlos y seguir el progreso.'
                            : 'Inicia sesión o regístrate para jugar, competir y seguir tus logros.',
                        style: const TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: (isTeacher || _isAgeValid())
                                  ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                );
                                    }
                                  : null,
                              child: const Text(
                                'Iniciar sesión',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: (isTeacher || _isAgeValid())
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => SignUpPage(initialType: widget.selectedType),
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Text(
                                'Crear cuenta',
                                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Completa tu perfil y empieza a jugar.',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workplaceGrid() {
    final tiles = [
      _WorkTile(label: 'Escuela', color: const Color(0xFFE53935), value: 'school'),
      _WorkTile(label: 'Educación superior', color: const Color(0xFF1565C0), value: 'higher'),
      _WorkTile(label: 'Empresa', color: const Color(0xFFF5A623), value: 'business'),
      _WorkTile(label: 'Otro', color: const Color(0xFF2E7D32), value: 'other'),
    ];
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles.map((t) => _buildTile(t)).toList(),
    );
  }

  Widget _heroCard(bool isTeacher, Color accentColor) {
    if (isTeacher) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(Icons.school, size: 80, color: accentColor),
            const SizedBox(height: 16),
            const Text(
              '¿Qué describe mejor tu entorno?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona el tipo de institución para personalizar tu experiencia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 18),
            _workplaceGrid(),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: Icon(Icons.emoji_events, size: 80, color: accentColor),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Cuántos años tienes?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tu edad para adaptar la experiencia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Edad',
              hintText: 'Ej: 18',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAgeValid() ? AppColor.primary : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isAgeValid()
                ? () {
                    FocusScope.of(context).unfocus();
                    setState(() {});
                  }
                : null,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  bool _isAgeValid() {
    final value = int.tryParse(_ageCtrl.text.trim());
    return value != null && value >= 5 && value <= 120;
  }

  Widget _buildTile(_WorkTile tile) {
    final isSelected = _workplace == tile.value;
    return InkWell(
      onTap: () {
        setState(() {
          _workplace = tile.value;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: tile.color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: Icon(
                Icons.circle,
                size: 12,
                color: Colors.white.withOpacity(isSelected ? 1 : 0.6),
              ),
            ),
            Center(
              child: Text(
                tile.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.check, color: tile.color, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkTile {
  final String label;
  final Color color;
  final String value;
  const _WorkTile({required this.label, required this.color, required this.value});
}