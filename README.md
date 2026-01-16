# Trivvy

Kahoot-style quizzes, plantillas rápidas y un modo desafío single-player en Flutter. Listo para Android, iOS, web y desktop con gradientes, animaciones y confetti incluidos.

## Por qué es distinto
- Editor visual de quizzes con portada, categorías, visibilidad y temas.
- Plantillas precargadas (verdadero/falso, presentación interactiva, trivia visual) para crear en segundos.
- Modo desafío single-player con flujo de intentos, envío de respuestas y resumen final.
- Gestión de medios: carga/lectura/eliminación de imágenes y archivos (HTTP + storage provider).
- Integraciones listas: escáner QR/cámara, video player, grids irregulares, animaciones y confetti.
- Inyección de dependencias con `provider` + `get_it` y rutas declarativas en `MaterialApp`.

## Requisitos
- Flutter 3.24+/Dart 3.9 (el `environment` está en `sdk: ^3.9.2`).
- Android SDK o Xcode si compilas para móvil; Chrome/Edge para web.
- Backend HTTP accesible (por defecto: `https://backcomun-production.up.railway.app`).

## Configuración rápida
1) Instala dependencias:
```bash
flutter pub get
```
2) Define la URL del backend (opcional si usas la predeterminada):
```bash
# reemplaza por tu endpoint
--dart-define=API_BASE_URL=https://tu-backend.com
```
3) Ejecuta:
```bash
# Android (emulador o dispositivo conectado)
flutter run -d <id_dispositivo> --dart-define=API_BASE_URL=https://tu-backend.com

# Web
flutter run -d chrome --web-renderer html --dart-define=API_BASE_URL=https://tu-backend.com
```

## Cómo se usa
- Dashboard: lista tus quizzes, permite editar, duplicar, eliminar y cargar portadas desde el storage.
- Crear/editar: `/create` abre el editor; `/questionEditor` edita preguntas específicas.
- Plantillas: `/templateSelector` devuelve un `Quiz` prearmado listo para publicar.
- Modo desafío: `SinglePlayerChallenge` consume `SinglePlayerGameRepository` para iniciar intentos, enviar respuestas y mostrar resultados.
- Media: `MediaEditorBloc` maneja subida, lectura y borrado de archivos usando `UploadMediaUseCase`, `GetMediaUseCase`, `DeleteMediaUseCase`.

## Estructura rápida
- `lib/main.dart`: tema, rutas, DI (`provider`) y configuración dinámica de backend (`api_config`).
- `lib/common_pages/`: dashboard y selector de plantillas.
- `lib/common_widgets/`: tarjetas, grids, bottom nav, upload widget.
- `lib/features/kahoot/`: editor, repositorios HTTP y entidades de quiz/pregunta/respuesta.
- `lib/features/challenge/`: lógica de single-player (use cases, blocs, repositorio).
- `lib/features/media/`: manejo de medios y storage provider.
- `lib/features/groups/`: gestión de **Grupos** (unirse por código, crear, ranking/leaderboard, asignar quizzes).
- `lib/features/user/`: autenticación, perfil, avatars, selector de backend (Dev/Prod) y **AccessGate** (control de sesión seguro).
- `lib/features/library/`: biblioteca personal, favoritos y descubrimiento.
- `lib/features/gameSession/`: lógica para partidas multijugador en tiempo real.
- `lib/features/subscriptions/`: gestión de planes y pagos.
- `lib/features/discovery/`: feed de contenido público.
- `lib/features/report/`: historial de resultados y estadísticas.
- `assets/`: imágenes y fuente Onest (varios pesos).
- `Producción.postman_collection.json`: colección para probar el backend.

## Variables y build
- `API_BASE_URL`: URL del backend; se pasa con `--dart-define`. Valor por defecto ya apunta al backend en Railway.
- Icono: se genera con `flutter_launcher_icons` usando `assets/images/appIcon.png`.

## Comandos útiles
```bash
# Formato y análisis
flutter analyze
flutter test

# Ejecutar en desktop
flutter run -d windows
flutter run -d macos
flutter run -d linux

# Build release (ejemplos)
flutter build apk --release --dart-define=API_BASE_URL=https://tu-backend.com
flutter build web --release --web-renderer html --dart-define=API_BASE_URL=https://tu-backend.com
```

## Tips de troubleshooting
- Si no carga la portada, revisa que `API_BASE_URL` sea accesible y permita `/storage/file/<mediaId>`.
- Limpia builds atascados: `flutter clean ; flutter pub get`.
- Para iOS, abre `ios/Runner.xcworkspace` y verifica firma de código.

## Autores
Massiel Perozo, Israel Mejias, Daila Arcia, Alejandro Seijas, Jose Briceño (Backend) y Daniel Garcia (Backend)
