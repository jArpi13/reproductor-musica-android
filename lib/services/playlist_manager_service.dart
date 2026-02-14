import '../models/Playlist.dart';
import '../models/Song.dart';
import 'playlist_storage_service.dart';

class PlaylistManagerService {
  // Singleton
  static final PlaylistManagerService _instance = PlaylistManagerService._internal();
  factory PlaylistManagerService() => _instance;
  PlaylistManagerService._internal();

  final PlaylistStorageService _storage = PlaylistStorageService();
  List<Playlist> _customPlaylists = [];

  /// Obtener todas las playlists personalizadas
  List<Playlist> get customPlaylists => _customPlaylists;

  /// Cargar playlists desde storage
  Future<void> loadPlaylists(List<Song> allSongs) async {
    _customPlaylists = await _storage.loadPlaylists(allSongs);
    print('✅ Cargadas ${_customPlaylists.length} playlists personalizadas');
  }

  /// Crear una nueva playlist
  Future<Playlist> createPlaylist(String name) async {
    final playlist = Playlist(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      songs: [],
      type: PlaylistType.custom,
    );

    _customPlaylists.add(playlist);
    await _saveAll();
    
    print('✅ Playlist creada: $name');
    return playlist;
  }

  /// Eliminar una playlist
  Future<void> deletePlaylist(String playlistId) async {
    _customPlaylists.removeWhere((p) => p.id == playlistId);
    await _saveAll();
    print('🗑️ Playlist eliminada');
  }

  /// Agregar canción a playlist
  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlist = _customPlaylists.firstWhere((p) => p.id == playlistId);
    
    // Verificar que no esté duplicada
    if (!playlist.songs.any((s) => s.filePath == song.filePath)) {
      playlist.songs.add(song);
      await _saveAll();
      print('➕ Canción "${song.title}" agregada a "${playlist.name}"');
    } else {
      print('⚠️ La canción ya está en la playlist');
    }
  }

  /// Quitar canción de playlist
  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    final playlist = _customPlaylists.firstWhere((p) => p.id == playlistId);
    playlist.songs.removeWhere((s) => s.filePath == song.filePath);
    await _saveAll();
    print('➖ Canción "${song.title}" removida de "${playlist.name}"');
  }

  /// Renombrar playlist
  Future<void> renamePlaylist(String playlistId, String newName) async {
    final playlist = _customPlaylists.firstWhere((p) => p.id == playlistId);
    playlist.name = newName;
    await _saveAll();
    print('✏️ Playlist renombrada a: $newName');
  }

  /// Verificar si una canción está en una playlist específica
  bool isSongInPlaylist(String playlistId, Song song) {
    final playlist = _customPlaylists.firstWhere((p) => p.id == playlistId);
    return playlist.songs.any((s) => s.filePath == song.filePath);
  }

  /// Guardar todas las playlists
  Future<void> _saveAll() async {
    await _storage.savePlaylists(_customPlaylists);
  }

  /// Obtener playlist por ID
  Playlist? getPlaylistById(String id) {
    try {
      return _customPlaylists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
