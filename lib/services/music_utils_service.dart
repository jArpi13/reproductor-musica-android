import '../models/Song.dart';

class MusicUtilsService {
  /// Extrae todos los artistas únicos de una lista de canciones
  /// Ejemplo: Si APT tiene ["Rose", "Bruno Mars"], ambos aparecen por separado
  List<String> getUniqueArtists(List<Song> songs) {
    final Set<String> artistsSet = {};
    
    for (var song in songs) {
      // Agregar cada artista individualmente
      artistsSet.addAll(song.artists);
    }
    
    // Convertir a lista y ordenar alfabéticamente
    final artistsList = artistsSet.toList()..sort();
    
    print('✅ Se encontraron ${artistsList.length} artistas únicos');
    for (var artist in artistsList) {
      print('  🎤 $artist');
    }
    
    return artistsList;
  }

  /// Filtra las canciones de un artista específico
  List<Song> getSongsByArtist(List<Song> songs, String artistName) {
    return songs.where((song) => song.artists.contains(artistName)).toList();
  }

  /// Cuenta cuántas canciones tiene cada artista
  Map<String, int> getArtistSongCounts(List<Song> songs) {
    final Map<String, int> counts = {};
    
    for (var song in songs) {
      for (var artist in song.artists) {
        counts[artist] = (counts[artist] ?? 0) + 1;
      }
    }
    
    return counts;
  }

  /// Ordena canciones por título
  List<Song> sortByTitle(List<Song> songs) {
    return songs..sort((a, b) => a.title.compareTo(b.title));
  }

  /// Ordena canciones por artista
  List<Song> sortByArtist(List<Song> songs) {
    return songs..sort((a, b) => a.artists.first.compareTo(b.artists.first));
  }

  /// Formatea la duración en formato mm:ss
  String formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
