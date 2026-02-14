import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ArtistImageService {
  // Ruta original donde están las imágenes de los artistas
  static const String artistImagesPath = '/storage/emulated/0/Music/img';

  /// Obtiene la ruta de la imagen de un artista
  /// Busca primero en la carpeta de la app, luego en Music/img
  Future<String?> getArtistImagePath(String artistName) async {
    try {
      // Normalizar el nombre: "Billie Eilish" → "billieeilish"
      final normalizedName = artistName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      
      final fileName = '$normalizedName.png';
      
      // 1. Buscar en la carpeta de la aplicación (imágenes descargadas)
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final appImagesDir = path.join(appDir.path, 'artist_images');
        final appFilePath = path.join(appImagesDir, fileName);
        final appFile = File(appFilePath);
        
        if (await appFile.exists()) {
          print('✅ Imagen encontrada (descargada) para $artistName: $appFilePath');
          return appFilePath;
        }
      } catch (e) {
        // Continuar con la búsqueda en Music/img
      }
      
      // 2. Buscar en Music/img (imágenes originales)
      final musicFilePath = '$artistImagesPath/$fileName';
      final musicFile = File(musicFilePath);
      
      if (await musicFile.exists()) {
        print('✅ Imagen encontrada (original) para $artistName: $musicFilePath');
        return musicFilePath;
      } else {
        print('! No hay imagen para $artistName');
        return null;
      }
    } catch (e) {
      print('❌ Error buscando imagen de $artistName: $e');
      return null;
    }
  }

  /// Obtiene las imágenes de múltiples artistas
  Future<Map<String, String?>> getArtistsImages(List<String> artists) async {
    final Map<String, String?> imagesMap = {};
    
    for (var artist in artists) {
      imagesMap[artist] = await getArtistImagePath(artist);
    }
    
    return imagesMap;
  }

  /// Verifica si existe la carpeta de imágenes
  bool imagesFolderExists() {
    final dir = Directory(artistImagesPath);
    return dir.existsSync();
  }

  /// Lista todas las imágenes disponibles en la carpeta
  Future<List<String>> listAvailableImages() async {
    try {
      final dir = Directory(artistImagesPath);
      
      if (!dir.existsSync()) {
        print('❌ La carpeta $artistImagesPath no existe');
        return [];
      }

      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.png'))
          .map((entity) => entity.path)
          .toList();

      print('✅ Se encontraron ${files.length} imágenes de artistas');
      return files;
    } catch (e) {
      print('❌ Error listando imágenes: $e');
      return [];
    }
  }
}
