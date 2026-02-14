import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Lyrics.dart';

class LyricsService {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;
  LyricsService._internal();

  // LRCLIB.net - API gratuita para letras sincronizadas
  static const String _lrclibBaseUrl = 'https://lrclib.net/api';

  /// Busca letras sincronizadas (con timestamps) o simples
  /// Retorna Lyrics con timestamps si están disponibles, sino letras simples
  Future<Lyrics?> searchLyrics({
    required String trackTitle,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  }) async {
    try {
      // Intentar LRCLIB primero (mejor fuente para letras sincronizadas)
      final lyrics = await _searchLRCLib(
        trackTitle: trackTitle,
        artistName: artistName,
        albumName: albumName,
        durationSeconds: durationSeconds,
      );

      if (lyrics != null) {
        return lyrics;
      }

      // Si no se encuentra, retornar null
      return null;
    } catch (e) {
      print('Error buscando letras: $e');
      return null;
    }
  }

  /// Busca en LRCLIB.net
  Future<Lyrics?> _searchLRCLib({
    required String trackTitle,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  }) async {
    try {
      // Limpiar términos de búsqueda
      final cleanTrack = _cleanSearchTerm(trackTitle);
      final cleanArtist = _cleanSearchTerm(artistName);
      final cleanAlbum = albumName != null ? _cleanSearchTerm(albumName) : null;

      // Construir URL con parámetros
      final queryParams = {
        'track_name': cleanTrack,
        'artist_name': cleanArtist,
        if (cleanAlbum != null && cleanAlbum.isNotEmpty)
          'album_name': cleanAlbum,
        if (durationSeconds != null) 'duration': durationSeconds.toString(),
      };

      final uri = Uri.parse(
        '$_lrclibBaseUrl/get',
      ).replace(queryParameters: queryParams);

      print('Buscando letras en LRCLIB: $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // LRCLIB retorna syncedLyrics (con timestamps) y plainLyrics (sin timestamps)
        final syncedLyrics = data['syncedLyrics'] as String?;
        final plainLyrics = data['plainLyrics'] as String?;

        // Priorizar letras sincronizadas
        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          print('✓ Letras sincronizadas encontradas');
          return Lyrics.parse(syncedLyrics);
        } else if (plainLyrics != null && plainLyrics.isNotEmpty) {
          print('✓ Letras simples encontradas (sin timestamps)');
          return Lyrics(plainText: plainLyrics);
        }
      } else if (response.statusCode == 404) {
        print('No se encontraron letras en LRCLIB');
      } else {
        print('Error LRCLIB: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      print('Error en _searchLRCLib: $e');
      return null;
    }
  }

  /// Limpia términos de búsqueda para mejorar resultados
  String _cleanSearchTerm(String term) {
    String cleaned = term;

    // Remover contenido entre paréntesis y corchetes
    cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[[^\]]*\]'), '');

    // Remover indicadores de remasters, deluxe, etc.
    final removeTerms = [
      'remaster',
      'remastered',
      'deluxe',
      'edition',
      'version',
      'remix',
      'radio edit',
      'single',
      'album',
      'extended',
    ];

    for (final removeTerm in removeTerms) {
      cleaned = cleaned.replaceAll(
        RegExp(removeTerm, caseSensitive: false),
        '',
      );
    }

    // Remover años (4 dígitos)
    cleaned = cleaned.replaceAll(RegExp(r'\b(19|20)\d{2}\b'), '');

    // Remover caracteres especiales excepto espacios y guiones
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s-]'), '');

    // Limpiar espacios múltiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Busca letras para múltiples canciones (bulk search)
  Future<Map<String, Lyrics>> searchLyricsBulk(
    List<Map<String, dynamic>> songs,
  ) async {
    final results = <String, Lyrics>{};

    for (final songData in songs) {
      final trackTitle = songData['title'] as String;
      final artistName = songData['artist'] as String;
      final albumName = songData['album'] as String?;
      final durationSeconds = songData['duration'] as int?;

      final lyrics = await searchLyrics(
        trackTitle: trackTitle,
        artistName: artistName,
        albumName: albumName,
        durationSeconds: durationSeconds,
      );

      if (lyrics != null) {
        // Usar título + artista como clave única
        final key = '${trackTitle}_${artistName}';
        results[key] = lyrics;
      }

      // Pequeña pausa para no saturar la API
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }
}
