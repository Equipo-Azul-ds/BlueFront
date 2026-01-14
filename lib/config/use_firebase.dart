/// Compile-time switch to enable/disable Firebase features.
///
/// Esto es solo para poder compilar la aplicacion en chrome-web
const bool kUseFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: false);
