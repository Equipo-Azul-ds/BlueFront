import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper de storage seguro para tokens/sesión.
class SecureStorage {
	SecureStorage._();

	static const FlutterSecureStorage _storage = FlutterSecureStorage();
	static SecureStorage? _instance;

	static SecureStorage get instance {
		_instance ??= SecureStorage._();
		return _instance!;
	}

	Future<void> write(String key, String value) async {
		await _storage.write(key: key, value: value);
	}

	Future<String?> read(String key) async {
		return _storage.read(key: key);
	}

	Future<void> delete(String key) async {
		await _storage.delete(key: key);
	}

	Future<void> deleteAll() async {
		await _storage.deleteAll();
	}
}
