import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ArtistImageDownloadService {
  static final ArtistImageDownloadService _instance =
      ArtistImageDownloadService._internal();
  factory ArtistImageDownloadService() => _instance;
  ArtistImageDownloadService._internal();

  /// Obtiene la ruta donde se guardarán las imágenes de artistas
  Future<String> _getArtistImagesPath() async {
    // Usar el directorio de la aplicación en lugar de Music/img
    final appDir = await getApplicationDocumentsDirectory();
    final artistImagesDir = Directory(path.join(appDir.path, 'artist_images'));
    
    // Crear directorio si no existe
    if (!await artistImagesDir.exists()) {
      await artistImagesDir.create(recursive: true);
    }
    
    return artistImagesDir.path;
  }

  /// Descarga la imagen del artista usando la API de Last.fm
  Future<String?> downloadArtistImage(String artistName) async {
    try {
      print('🎤 Buscando imagen para artista: $artistName');

      // 1. Intentar con Deezer primero (mejores imágenes)
      final deezerUrl = await _searchDeezer(artistName);
      if (deezerUrl != null) {
        final path = await _downloadAndSaveImage(deezerUrl, artistName);
        if (path != null) return path;
      }

      // 2. Buscar en Last.fm
      final imageUrl = await _searchLastFm(artistName);
      if (imageUrl != null) {
        final path = await _downloadAndSaveImage(imageUrl, artistName);
        if (path != null) return path;
      }

      // 3. Fallback: buscar en MusicBrainz
      final mbUrl = await _searchMusicBrainz(artistName);
      if (mbUrl != null) {
        return await _downloadAndSaveImage(mbUrl, artistName);
      }

      return null;
    } catch (e) {
      print('❌ Error descargando imagen de artista: $e');
      return null;
    }
  }

  /// Busca en Deezer API (mejores imágenes de artistas)
  Future<String?> _searchDeezer(String artistName) async {
    try {
      final encodedArtist = Uri.encodeComponent(artistName);
      final url = Uri.parse(
        'https://api.deezer.com/search/artist?q=$encodedArtist&limit=1',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          final artist = data['data'][0];
          
          // Deezer proporciona diferentes tamaños de imagen
          // picture_xl (1000x1000), picture_big (500x500), picture_medium (250x250)
          final imageUrl = artist['picture_xl'] ?? 
                          artist['picture_big'] ?? 
                          artist['picture_medium'] ?? 
                          artist['picture'];
          
          if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('artist-')) {
            print('✅ Imagen encontrada en Deezer (XL): $imageUrl');
            return imageUrl;
          }
        }
      }
    } catch (e) {
      print('⚠️ Error en Deezer: $e');
    }
    return null;
  }

  /// Busca en Last.fm API
  Future<String?> _searchLastFm(String artistName) async {
    try {
      // API Key pública de Last.fm (puedes usar esta o registrar la tuya)
      const apiKey = 'b25b959554ed76058ac220b7b2e0a026';
      final encodedArtist = Uri.encodeComponent(artistName);
      final url = Uri.parse(
        'https://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=$encodedArtist&api_key=$apiKey&format=json',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['artist'] != null && data['artist']['image'] != null) {
          final images = data['artist']['image'] as List;
          
          // Buscar primero 'mega' (la más grande), luego 'extralarge'
          String? megaUrl;
          String? extralargeUrl;
          String? largeUrl;
          
          for (var img in images) {
            final size = img['size'] ?? '';
            final url = img['#text'] ?? '';
            
            if (url.isNotEmpty && !url.contains('placeholder')) {
              if (size == 'mega') megaUrl = url;
              else if (size == 'extralarge') extralargeUrl = url;
              else if (size == 'large') largeUrl = url;
            }
          }
          
          final imageUrl = megaUrl ?? extralargeUrl ?? largeUrl;
          if (imageUrl != null) {
            // Mejorar la calidad de la URL (300x300 → mayor resolución)
            final highQualityUrl = imageUrl
                .replaceAll('/300x300/', '/500x500/')
                .replaceAll('/174s/', '/500x500/')
                .replaceAll('/64s/', '/500x500/');
            
            print('✅ Imagen encontrada en Last.fm (${megaUrl != null ? 'mega' : extralargeUrl != null ? 'extralarge' : 'large'}): $highQualityUrl');
            return highQualityUrl;
          }
        }
      }
    } catch (e) {
      print('⚠️ Error en Last.fm: $e');
    }
    return null;
  }

  /// Busca en MusicBrainz (alternativa)
  Future<String?> _searchMusicBrainz(String artistName) async {
    try {
      final encodedArtist = Uri.encodeComponent(artistName);
      final url = Uri.parse(
        'https://musicbrainz.org/ws/2/artist/?query=artist:$encodedArtist&fmt=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'MusicPlayer/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['artists'] != null && (data['artists'] as List).isNotEmpty) {
          // Artista encontrado pero MusicBrainz no proporciona imágenes directamente
          // Necesitaríamos integrar con Fanart.tv u otro servicio
          print('⚠️ MusicBrainz encontrado pero sin imagen directa');
        }
      }
    } catch (e) {
      print('⚠️ Error en MusicBrainz: $e');
    }
    return null;
  }

  /// Descarga y guarda la imagen
  Future<String?> _downloadAndSaveImage(
    String imageUrl,
    String artistName,
  ) async {
    try {
      print('📥 Descargando imagen desde: $imageUrl');

      // Descargar imagen
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('❌ Error descargando imagen: ${response.statusCode}');
        return null;
      }

      print('📦 Imagen descargada: ${response.bodyBytes.length} bytes');
      
      // Validar que la imagen tenga contenido real (no placeholder)
      // Las imágenes placeholder de Last.fm suelen ser muy pequeñas (~4KB)
      if (response.bodyBytes.isEmpty || response.bodyBytes.length < 5000) {
        print('⚠️ Imagen muy pequeña (posible placeholder), rechazando');
        return null;
      }

      // Obtener directorio de imágenes de artistas
      final artistImagesPath = await _getArtistImagesPath();

      // Limpiar nombre del artista para el archivo
      final cleanName = _cleanArtistName(artistName);
      final filePath = path.join(artistImagesPath, '$cleanName.png');

      // Guardar imagen
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      // Verificar que se guardó correctamente
      final exists = await file.exists();
      final size = await file.length();
      
      print('✅ Imagen guardada en: $filePath');
      print('📊 Tamaño del archivo: $size bytes');
      print('📁 Archivo existe: $exists');
      
      return exists ? filePath : null;
    } catch (e) {
      print('❌ Error guardando imagen: $e');
      return null;
    }
  }

  /// Limpia el nombre del artista para usarlo como nombre de archivo
  String _cleanArtistName(String artistName) {
    return artistName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .replaceAll(RegExp(r'\s+'), '');
  }
}
