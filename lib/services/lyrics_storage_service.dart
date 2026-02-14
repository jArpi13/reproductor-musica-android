import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Lyrics.dart';
import '../models/Song.dart';

class LyricsStorageService {
  static final LyricsStorageService _instance =
      LyricsStorageService._internal();
  factory LyricsStorageService() => _instance;
  LyricsStorageService._internal();

  static const String _storageKey = 'downloaded_lyrics';

  /// Guarda las letras de una canción
  Future<void> saveLyrics(Song song) async {
    if (song.lyrics == null || !song.isLyricsDownloaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final allLyrics = await _loadAllLyrics();

      // Usar filePath como clave única
      final key = song.filePath;

      // Serializar las letras
      final lyricsData = _serializeLyrics(song.lyrics!);
      allLyrics[key] = lyricsData;

      // Guardar en SharedPreferences
      await prefs.setString(_storageKey, json.encode(allLyrics));

      print('✓ Letras guardadas para: ${song.title}');
    } catch (e) {
      print('Error guardando letras: $e');
    }
  }

  /// Carga las letras de una canción si existen
  Future<Lyrics?> loadLyrics(String filePath) async {
    try {
      final allLyrics = await _loadAllLyrics();

      if (!allLyrics.containsKey(filePath)) {
        return null;
      }

      final lyricsData = allLyrics[filePath] as Map<String, dynamic>;
      return _deserializeLyrics(lyricsData);
    } catch (e) {
      print('Error cargando letras: $e');
      return null;
    }
  }

  /// Elimina las letras de una canción
  Future<void> deleteLyrics(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allLyrics = await _loadAllLyrics();

      allLyrics.remove(filePath);

      await prefs.setString(_storageKey, json.encode(allLyrics));
      print('✓ Letras eliminadas para: $filePath');
    } catch (e) {
      print('Error eliminando letras: $e');
    }
  }

  /// Verifica si hay letras guardadas para una canción
  Future<bool> hasLyrics(String filePath) async {
    final allLyrics = await _loadAllLyrics();
    return allLyrics.containsKey(filePath);
  }

  /// Guarda letras para múltiples canciones (bulk save)
  Future<void> saveLyricsBulk(List<Song> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allLyrics = await _loadAllLyrics();

      for (final song in songs) {
        if (song.lyrics != null && song.isLyricsDownloaded) {
          final key = song.filePath;
          final lyricsData = _serializeLyrics(song.lyrics!);
          allLyrics[key] = lyricsData;
        }
      }

      await prefs.setString(_storageKey, json.encode(allLyrics));
      print('✓ Letras guardadas para ${songs.length} canciones');
    } catch (e) {
      print('Error guardando letras bulk: $e');
    }
  }

  /// Carga todas las letras almacenadas
  Future<Map<String, dynamic>> _loadAllLyrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) {
        return {};
      }

      return Map<String, dynamic>.from(json.decode(jsonString));
    } catch (e) {
      print('Error cargando todas las letras: $e');
      return {};
    }
  }

  /// Serializa un objeto Lyrics a JSON
  Map<String, dynamic> _serializeLyrics(Lyrics lyrics) {
    if (lyrics.isSynced && lyrics.syncedLines != null) {
      // Letras sincronizadas
      return {
        'type': 'synced',
        'lines': lyrics.syncedLines!.map((line) {
          return {
            'timestamp': line.timestamp.inMilliseconds,
            'text': line.text,
          };
        }).toList(),
      };
    } else {
      // Letras planas
      return {'type': 'plain', 'text': lyrics.plainText ?? ''};
    }
  }

  /// Deserializa JSON a objeto Lyrics
  Lyrics _deserializeLyrics(Map<String, dynamic> data) {
    final type = data['type'] as String;

    if (type == 'synced') {
      final linesData = data['lines'] as List<dynamic>;
      final syncedLines = linesData.map((lineData) {
        final timestamp = Duration(milliseconds: lineData['timestamp'] as int);
        final text = lineData['text'] as String;
        return LyricLine(timestamp: timestamp, text: text);
      }).toList();

      return Lyrics(syncedLines: syncedLines);
    } else {
      return Lyrics(plainText: data['text'] as String);
    }
  }

  /// Limpia todas las letras almacenadas
  Future<void> clearAllLyrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('✓ Todas las letras eliminadas');
    } catch (e) {
      print('Error limpiando letras: $e');
    }
  }

  /// Obtiene estadísticas de letras almacenadas
  Future<Map<String, int>> getStats() async {
    final allLyrics = await _loadAllLyrics();

    int syncedCount = 0;
    int plainCount = 0;

    for (final lyricsData in allLyrics.values) {
      final data = lyricsData as Map<String, dynamic>;
      if (data['type'] == 'synced') {
        syncedCount++;
      } else {
        plainCount++;
      }
    }

    return {
      'total': allLyrics.length,
      'synced': syncedCount,
      'plain': plainCount,
    };
  }
}
