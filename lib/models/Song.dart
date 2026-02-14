import 'dart:ui';
import 'Lyrics.dart';

class Song {
  String title;
  List<String> artists;
  String album;
  int duration; // Duración en milisegundos
  Lyrics? lyrics; // Letras locales o descargadas
  bool isLyricsDownloaded; // true si las letras fueron descargadas de internet
  int bitrate;
  String filePath; // Sin ? porque es obligatorio
  Color? dominantColor;
  String? albumArtUri; // URI de la carátula del álbum (local)
  String? albumArtUrlHD; // URL de carátula HD descargada de internet
  int? audioId; // ID del archivo de audio para QueryArtworkWidget

  // Constructor
  Song({
    required this.title,
    required this.artists,
    required this.album,
    required this.duration,
    this.lyrics,
    this.isLyricsDownloaded = false,
    required this.bitrate,
    required this.filePath,
    this.dominantColor,
    this.albumArtUri,
    this.albumArtUrlHD,
    this.audioId,
  });

  // Getter para ID único basado en filePath
  String get id => filePath.hashCode.toString();

  // Métodos estáticos para operaciones con listas de canciones
  
  /// Calcula la duración total de una lista de canciones en milisegundos
  static int getTotalDuration(List<Song> songs) {
    return songs.fold<int>(0, (sum, song) => sum + song.duration);
  }

  /// Formatea la duración total de una lista de canciones
  /// Retorna formato: "X h Y min Z seg" o "Y min Z seg" o "Z seg"
  static String getFormattedTotalDuration(List<Song> songs) {
    final totalMs = getTotalDuration(songs);
    final totalSeconds = totalMs ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '$hours h $minutes min $seconds seg';
    } else if (minutes > 0) {
      return '$minutes min $seconds seg';
    } else {
      return '$seconds seg';
    }
  }

  @override
  String toString() {
    return 'Song(title: "$title", artists: ${artists.join(", ")}, bitrate: ${bitrate}kbps)';
  }
}
