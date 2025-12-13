import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../kahoot/domain/entities/kahoot.dart';

const int discoverIndex = 1;


class KahootDetailPageDis extends StatefulWidget {
  final Kahoot kahoot;
  const KahootDetailPageDis({super.key, required this.kahoot});

  @override
  State<KahootDetailPageDis> createState() => _KahootDetailPageDisState();
}

class _KahootDetailPageDisState extends State<KahootDetailPageDis> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(widget.kahoot.title, style: const TextStyle(color: AppColor.onPrimary)),
        backgroundColor: AppColor.primary,
        iconTheme: const IconThemeData(color: AppColor.onPrimary),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: AppColor.onPrimary,
            ),
            onPressed: () {

              setState(() {
                _isFavorite = !_isFavorite;
                if (_isFavorite) {
                  print('Kahoot "${widget.kahoot.title}" añadido a favoritos (simulado).');
                } else {
                  print('Kahoot "${widget.kahoot.title}" eliminado de favoritos (simulado).');
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _buildKahootImage(widget.kahoot.kahootImage),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.kahoot.title,
                      style: const TextStyle(
                        color: AppColor.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.star : Icons.star_border,
                      color: AppColor.secundary,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Autor
              Text(
                'Por: ${widget.kahoot.author}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 2),
              // Fecha de Creación
              Text(
                'Creado el: ${widget.kahoot.createdAt.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),


              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: widget.kahoot.themes.map((theme) => _buildThemeChip(theme)).toList(),
              ),
              const SizedBox(height: 20),

              Text(
                'Descripción:',
                style: TextStyle(
                  color: AppColor.secundary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.kahoot.description ?? 'No hay descripción disponible para este Kahoot.',
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 30),


              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Lógica para crear sala multijugador
                    print('Crear Sala Multijugador para ${widget.kahoot.title}');
                  },
                  icon: const Icon(Icons.group, color: AppColor.onPrimary),
                  label: const Text(
                    'Crear Sala (Multijugador)',
                    style: TextStyle(fontSize: 16, color: AppColor.onPrimary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Lógica para jugar individualmente
                    print('Jugar Individualmente ${widget.kahoot.title}');
                  },
                  icon: const Icon(Icons.person, color: AppColor.secundary),
                  label: const Text(
                    'Jugar Individualmente',
                    style: TextStyle(fontSize: 16, color: AppColor.secundary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: AppColor.secundary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  // Widget auxiliar para la imagen
  Widget _buildKahootImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
          ),
        ),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  // Widget auxiliar para la imagen de placeholder
  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 50, color: AppColor.primary.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text('No hay imagen', style: TextStyle(color: AppColor.primary.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para los temas
  Widget _buildThemeChip(String theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        theme.toUpperCase(),
        style: const TextStyle(
          color: AppColor.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}