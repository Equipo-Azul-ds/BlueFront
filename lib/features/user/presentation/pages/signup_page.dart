import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../blocs/auth_bloc.dart';
import 'account_type_page.dart';
import 'avatar_picker_page.dart';

class SignUpPage extends StatefulWidget {
  final String? initialType; // 'teacher' o 'student'
  const SignUpPage({super.key, this.initialType});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _type = 'student';
  bool _obscure = true;
  String _avatarUrl = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>();
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Crear cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _inputDecoration('Nombre'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      // Avatar selector
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _avatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(_avatarUrl)
                              : null,
                          child: _avatarUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        title: const Text('Avatar'),
                        subtitle: const Text('Elige un avatar (recomendado para estudiantes)'),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await Navigator.of(context).push<String>(
                              MaterialPageRoute(builder: (_) => const AvatarPickerPage()),
                            );
                            if (picked != null) {
                              setState(() => _avatarUrl = picked);
                            }
                          },
                          child: const Text('Elegir'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _userNameCtrl,
                        decoration: _inputDecoration('Nombre de usuario'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: _inputDecoration('Correo electrónico'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          final email = v.trim();
                          return email.contains('@') ? null : 'Correo no válido';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: _inputDecoration('Password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure,
                        decoration: _inputDecoration('Confirmar contraseña'),
                        validator: (v) => (v != _passwordCtrl.text) ? 'Las contraseñas no coinciden' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Tipo de cuenta', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _typeChip('student', 'Estudiante', Icons.emoji_people),
                          const SizedBox(width: 8),
                          _typeChip('teacher', 'Profesor', Icons.school),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: auth.isLoading ? Colors.grey.shade400 : AppColor.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Crear cuenta'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final selected = await Navigator.of(context).push<String>(
                            MaterialPageRoute(builder: (_) => const AccountTypePage()),
                          );
                          if (selected != null) {
                            setState(() => _type = selected);
                          }
                        },
                        child: const Text('¿No estás seguro? Elige tipo de cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>();
    // Requerir avatar seleccionado para ambos roles (teacher/student)
    if (_avatarUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige un avatar para continuar')),
      );
      return;
    }
    auth
        .signup(
          userName: _userNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          userType: _type,
          avatarUrl: _avatarUrl,
          name: _nameCtrl.text.trim(),
        )
        .then((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    }).catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _typeChip(String value, String label, IconData icon) {
    final selected = _type == value;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
        ),
        selected: selected,
        selectedColor: AppColor.secundary.withOpacity(0.18),
        onSelected: (_) => setState(() => _type = value),
      ),
    );
  }
}
