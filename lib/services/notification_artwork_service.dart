import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NotificationArtworkService {
  static final NotificationArtworkService _instance = NotificationArtworkService._internal();
  factory NotificationArtworkService() => _instance;
  NotificationArtworkService._internal();

  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Map<int, String> _artworkCache = {};

  /// Obtiene la ruta del archivo de artwork para notificaciones
  /// Copia la imagen del audio al directorio de cache si no existe
  Future<String?> getNotificationArtworkUri(int audioId) async {
    try {
      // Verificar si ya está en cache
      if (_artworkCache.containsKey(audioId)) {
        final cachedPath = _artworkCache[audioId]!;
        if (await File(cachedPath).exists()) {
          return cachedPath;
        }
      }

      // Obtener artwork desde on_audio_query
      final Uint8List? artworkData = await _audioQuery.queryArtwork(
        audioId,
        ArtworkType.AUDIO,
        quality: 100,
        size: 512,
      );

      if (artworkData == null || artworkData.isEmpty) {
        print('⚠️ No hay artwork para audioId: $audioId');
        return null;
      }

      // Guardar en directorio de cache
      final Directory tempDir = await getTemporaryDirectory();
      final String artworkDir = '${tempDir.path}/artwork';
      
      // Crear directorio si no existe
      final Directory dir = Directory(artworkDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Guardar archivo
      final String filePath = '$artworkDir/artwork_$audioId.jpg';
      final File file = File(filePath);
      await file.writeAsBytes(artworkData);

      // Guardar en cache
      _artworkCache[audioId] = filePath;

      print('✅ Artwork guardado: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error obteniendo artwork para notificación: $e');
      return null;
    }
  }

  /// Limpia artworks antiguos del cache (opcional)
  Future<void> clearOldArtworks() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String artworkDir = '${tempDir.path}/artwork';
      final Directory dir = Directory(artworkDir);
      
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _artworkCache.clear();
        print('✅ Cache de artworks limpiado');
      }
    } catch (e) {
      print('❌ Error limpiando cache: $e');
    }
  }
}

