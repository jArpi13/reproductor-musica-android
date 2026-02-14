import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Solicita permisos de almacenamiento para Android 13+
  Future<bool> requestStoragePermission() async {
    // Solicitar múltiples permisos a la vez
    Map<Permission, PermissionStatus> statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();
    
    final audioGranted = statuses[Permission.audio]?.isGranted ?? false;
    final storageGranted = statuses[Permission.storage]?.isGranted ?? false;
    
    if (audioGranted || storageGranted) {
      print('✅ Permisos concedidos (audio: $audioGranted, storage: $storageGranted)');
      return true;
    }

    print('❌ Permisos denegados');
    return false;
  }

  /// Solicita permiso de notificaciones (Android 13+)
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      print('✅ Permiso de notificaciones concedido');
      return true;
    }
    
    print('⚠️ Permiso de notificaciones denegado');
    return false;
  }

  /// Verifica si ya tenemos los permisos
  Future<bool> hasStoragePermission() async {
    return await Permission.audio.isGranted || 
           await Permission.storage.isGranted;
  }

  /// Verifica si tenemos permiso de notificaciones
  Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }
}
