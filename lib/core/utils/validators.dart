//Aqui valiamos los formularios

String? validateTitle(String? titulo) {
  if (titulo == null || titulo.isEmpty) return 'El titulo es obligatorio!';
  if (titulo.length < 3) return 'El titulo debe tener al menos 3 caracteres';
  return null;
}

String? validateDescription(String? descripcion) {
  if (descripcion != null && descripcion.length > 200)
    return 'La descripcion no puede tener mas de 200 caracteres';
  return null;
}
