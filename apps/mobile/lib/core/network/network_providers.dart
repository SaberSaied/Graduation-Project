import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'dio_client.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthInterceptor(storage);
});

final dioClientProvider = Provider<DioClient>((ref) {
  final authInterceptor = ref.watch(authInterceptorProvider);
  return DioClient(authInterceptor: authInterceptor);
});
