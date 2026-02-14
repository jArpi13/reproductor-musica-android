import 'dart:convert';
import 'package:http/http.dart' as http;

class AlbumArtService {
  static final AlbumArtService _instance = AlbumArtService._internal();
  factory AlbumArtService() => _instance;
  AlbumArtService._internal();

  /// Busca carátula del álbum usando la API de iTunes
  /// Retorna URL de imagen en alta calidad (600x600 o más)
  Future<String?> searchAlbumArt({
    required String trackTitle,
    required String artistName,
    String? albumName,
  }) async {
    try {
      // Limpiar nombres para búsqueda
      final cleanTrack = _cleanSearchTerm(trackTitle);
      final cleanArtist = _cleanSearchTerm(artistName);
      final cleanAlbum = albumName != null ? _cleanSearchTerm(albumName) : '';

      // Primero intentar con álbum + artista (más preciso)
      if (cleanAlbum.isNotEmpty) {
        final albumUrl = await _searchItunes('$cleanAlbum $cleanArtist', cleanArtist);
        if (albumUrl != null) return albumUrl;
      }

      // Luego intentar con canción + artista
      final trackUrl = await _searchItunes('$cleanTrack $cleanArtist', cleanArtist);
      if (trackUrl != null) return trackUrl;

      // Finalmente solo artista
      final artistUrl = await _searchItunes(cleanArtist, cleanArtist);
      return artistUrl;
    } catch (e) {
      print('❌ Error buscando carátula: $e');
      return null;
    }
  }

  /// Busca en la API de iTunes con verificación de artista
  Future<String?> _searchItunes(String query, [String? expectedArtist]) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=$encodedQuery&media=music&entity=song&limit=5',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['resultCount'] > 0) {
          // Buscar coincidencia que tenga el artista correcto
          for (var result in data['results']) {
            final artistName = (result['artistName'] ?? '').toString().toLowerCase();
            
            // Si se proporcionó artista esperado, verificar coincidencia
            if (expectedArtist != null) {
              final cleanExpected = expectedArtist.toLowerCase().trim();
              if (!artistName.contains(cleanExpected) && !cleanExpected.contains(artistName)) {
                continue; // No coincide, intentar siguiente resultado
              }
            }
            
            // iTunes devuelve imágenes de 100x100, pero podemos obtener versiones más grandes
            String artworkUrl = result['artworkUrl100'] ?? '';
            
            if (artworkUrl.isNotEmpty) {
              // Cambiar a máxima calidad disponible (1200x1200 o la que esté disponible)
              artworkUrl = artworkUrl.replaceAll('100x100bb', '1200x1200bb');
              print('🎨 Carátula encontrada para "$artistName": $artworkUrl');
              return artworkUrl;
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Error en búsqueda iTunes: $e');
    }
    return null;
  }

  /// Limpia términos de búsqueda para mejorar resultados
  String _cleanSearchTerm(String term) {
    return term
        .trim()
        // Remover información entre paréntesis (remasters, ediciones, etc)
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        // Remover años
        .replaceAll(RegExp(r'\d{4}'), '')
        // Remover palabras comunes que interfieren
        .replaceAll(RegExp(r'\b(remaster|remix|edit|version|deluxe|explicit)\b', caseSensitive: false), '')
        // Limpiar espacios extras
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Busca carátula usando Deezer API (alternativa)
  Future<String?> searchDeezerAlbumArt({
    required String trackTitle,
    required String artistName,
  }) async {
    try {
      final cleanTrack = _cleanSearchTerm(trackTitle);
      final cleanArtist = _cleanSearchTerm(artistName);
      final query = Uri.encodeComponent('$cleanTrack $cleanArtist');
      
      final url = Uri.parse('https://api.deezer.com/search?q=$query&limit=1');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          final track = data['data'][0];
          final album = track['album'];
          
          // Deezer tiene varias calidades: cover_small, cover_medium, cover_big, cover_xl
          final artworkUrl = album['cover_xl'] ?? album['cover_big'] ?? album['cover_medium'];
          
          if (artworkUrl != null && artworkUrl.isNotEmpty) {
            print('🎨 Carátula Deezer encontrada: $artworkUrl');
            return artworkUrl;
          }
        }
      }
    } catch (e) {
      print('⚠️ Error en búsqueda Deezer: $e');
    }
    return null;
  }

  /// Busca carátula intentando múltiples fuentes
  Future<String?> searchAlbumArtMultiSource({
    required String trackTitle,
    required String artistName,
    String? albumName,
  }) async {
    // Intentar iTunes primero (mejor calidad generalmente)
    final itunesUrl = await searchAlbumArt(
      trackTitle: trackTitle,
      artistName: artistName,
      albumName: albumName,
    );
    
    if (itunesUrl != null) return itunesUrl;

    // Si falla, intentar Deezer
    final deezerUrl = await searchDeezerAlbumArt(
      trackTitle: trackTitle,
      artistName: artistName,
    );

    return deezerUrl;
  }
}
