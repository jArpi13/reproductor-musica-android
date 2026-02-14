import 'Song.dart';

enum PlaylistType {
  allSongs,  // Todo el repertorio
  artist,    // Canciones de un artista
  custom,    // Playlist creada manualmente
}

class Playlist {
  String id;
  String name;
  List<Song> songs;
  int currentIndex;
  PlaylistType type;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
    this.currentIndex = 0,
    required this.type,
  });

  // ========== GETTERS ==========
  
  /// Obtiene la canción actual
  Song? get currentSong {
    if (songs.isEmpty || currentIndex < 0 || currentIndex >= songs.length) {
      return null;
    }
    return songs[currentIndex];
  }

  /// Cantidad de canciones
  int get length => songs.length;

  /// Verifica si hay una siguiente canción
  bool get hasNext => currentIndex < songs.length - 1;

  /// Verifica si hay una canción anterior
  bool get hasPrevious => currentIndex > 0;

  // ========== NAVEGACIÓN ==========

  /// Obtiene la siguiente canción y actualiza el índice
  Song? getNext() {
    if (hasNext) {
      currentIndex++;
      return currentSong;
    }
    return null;
  }

  /// Obtiene la canción anterior y actualiza el índice
  Song? getPrevious() {
    if (hasPrevious) {
      currentIndex--;
      return currentSong;
    }
    return null;
  }

  /// Salta a una canción específica por índice
  Song? jumpTo(int index) {
    if (index >= 0 && index < songs.length) {
      currentIndex = index;
      return currentSong;
    }
    return null;
  }

  // ========== MODIFICACIÓN ==========

  /// Agrega una canción al final
  void addSong(Song song) {
    songs.add(song);
  }

  /// Elimina una canción
  void removeSong(Song song) {
    final index = songs.indexOf(song);
    if (index != -1) {
      songs.removeAt(index);
      // Ajustar currentIndex si es necesario
      if (currentIndex >= songs.length) {
        currentIndex = songs.length - 1;
      }
    }
  }

  /// Reordena canciones (útil para drag & drop)
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= songs.length ||
        newIndex < 0 || newIndex >= songs.length) {
      return;
    }
    
    final song = songs.removeAt(oldIndex);
    songs.insert(newIndex, song);
    
    // Ajustar currentIndex si movimos la canción actual
    if (currentIndex == oldIndex) {
      currentIndex = newIndex;
    } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
      currentIndex--;
    } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
      currentIndex++;
    }
  }

  // ========== PERSISTENCIA (JSON) ==========

  /// Convierte la playlist a JSON para guardar
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((song) => song.filePath).toList(), // Solo guardamos los paths
      'currentIndex': currentIndex,
      'type': type.name,
    };
  }

  /// Crea una playlist desde JSON
  static Playlist fromJson(Map<String, dynamic> json, List<Song> allSongs) {
    // Reconstruir las canciones desde los paths
    final List<String> paths = List<String>.from(json['songs']);
    final List<Song> playlistSongs = paths
        .map((path) => allSongs.firstWhere(
              (song) => song.filePath == path,
              orElse: () => Song(
                title: 'Desconocido',
                artists: ['Desconocido'],
                album: 'Desconocido',
                duration: 0,
                bitrate: 0,
                filePath: path,
              ),
            ))
        .toList();

    return Playlist(
      id: json['id'],
      name: json['name'],
      songs: playlistSongs,
      currentIndex: json['currentIndex'] ?? 0,
      type: PlaylistType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PlaylistType.custom,
      ),
    );
  }

  @override
  String toString() {
    return 'Playlist(name: "$name", songs: ${songs.length}, type: ${type.name})';
  }
}