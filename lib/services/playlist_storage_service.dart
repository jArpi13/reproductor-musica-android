import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Playlist.dart';
import '../models/Song.dart';

class PlaylistStorageService {
  static const String _playlistsKey = 'custom_playlists';

  /// Guarda todas las playlists personalizadas
  Future<bool> savePlaylists(List<Playlist> playlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Filtrar solo las playlists custom (las de artistas y allSongs se regeneran)
      final customPlaylists = playlists
          .where((p) => p.type == PlaylistType.custom)
          .toList();
      
      // Convertir a JSON
      final jsonList = customPlaylists.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      // Guardar
      final success = await prefs.setString(_playlistsKey, jsonString);
      
      if (success) {
        print('✅ ${customPlaylists.length} playlists guardadas');
      }
      
      return success;
    } catch (e) {
      print('❌ Error guardando playlists: $e');
      return false;
    }
  }

  /// Carga todas las playlists personalizadas
  Future<List<Playlist>> loadPlaylists(List<Song> allSongs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_playlistsKey);
      
      if (jsonString == null) {
        print('ℹ️ No hay playlists guardadas');
        return [];
      }
      
      // Decodificar JSON
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      // Convertir a objetos Playlist
      final playlists = jsonList
          .map((json) => Playlist.fromJson(json, allSongs))
          .toList();
      
      print('✅ ${playlists.length} playlists cargadas');
      return playlists;
      
    } catch (e) {
      print('❌ Error cargando playlists: $e');
      return [];
    }
  }

  /// Guarda una sola playlist
  Future<bool> savePlaylist(Playlist playlist, List<Playlist> existingPlaylists) async {
    try {
      // Buscar si ya existe
      final index = existingPlaylists.indexWhere((p) => p.id == playlist.id);
      
      if (index != -1) {
        // Actualizar existente
        existingPlaylists[index] = playlist;
      } else {
        // Agregar nueva
        existingPlaylists.add(playlist);
      }
      
      return await savePlaylists(existingPlaylists);
    } catch (e) {
      print('❌ Error guardando playlist: $e');
      return false;
    }
  }

  /// Elimina una playlist
  Future<bool> deletePlaylist(String playlistId, List<Playlist> existingPlaylists) async {
    try {
      existingPlaylists.removeWhere((p) => p.id == playlistId);
      return await savePlaylists(existingPlaylists);
    } catch (e) {
      print('❌ Error eliminando playlist: $e');
      return false;
    }
  }

  /// Limpia todas las playlists guardadas
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_playlistsKey);
    } catch (e) {
      print('❌ Error limpiando playlists: $e');
      return false;
    }
  }
}
