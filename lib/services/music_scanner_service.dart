import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';
import '../models/Song.dart';
import '../models/Lyrics.dart';

class MusicScannerService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  
  // Ruta específica donde buscaremos las canciones
  static const String musicFolderPath = '/storage/emulated/0/Music/Music';

  /// Escanea la carpeta específica y retorna una lista de objetos Song
  Future<List<Song>> scanMusicFolder() async {
    final List<Song> songs = [];

    print('🔍 Escaneando carpeta: $musicFolderPath');

    try {
      // ✨ OBTENER TODAS LAS CANCIONES DEL DISPOSITIVO
      final List<SongModel> audioFiles = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      // ✨ FILTRAR SOLO LAS DE TU CARPETA ESPECÍFICA
      final filteredSongs = audioFiles.where((song) {
        return song.data.startsWith(musicFolderPath);
      }).toList();

      print('✅ Se encontraron ${filteredSongs.length} canciones en $musicFolderPath');

      for (var audioFile in filteredSongs) {
        try {
          // Filtrar solo .mp3 y .flac
          final String path = audioFile.data.toLowerCase();
          if (path.endsWith('.mp3') || path.endsWith('.flac')) {
            
            // ✨ CALCULAR BITRATE
            final bitrate = await _calculateBitrate(audioFile.data, audioFile.duration ?? 0);
            
            // ✨ SEPARAR ARTISTAS
            List<String> artistsList = ['Artista Desconocido'];
            if (audioFile.artist != null && audioFile.artist != '<unknown>') {
              // Separar por comas, " & ", " and ", " y "
              final artistString = audioFile.artist!;
              artistsList = artistString
                  .replaceAll(' & ', ', ')
                  .replaceAll(' and ', ', ')
                  .replaceAll(' y ', ', ')
                  .split(',')
                  .map((artist) => artist.trim())
                  .where((artist) => artist.isNotEmpty)
                  .toList();
            }
            
            // ✨ EXTRAER LYRICS DE ARCHIVO .lrc EXTERNO
            Lyrics? lyrics;
            try {
              // Buscar archivo .lrc con el mismo nombre que la canción
              final lrcPath = audioFile.data.replaceAll(RegExp(r'\.(mp3|flac)$', caseSensitive: false), '.lrc');
              final lrcFile = File(lrcPath);
              
              if (await lrcFile.exists()) {
                final lyricsText = await lrcFile.readAsString();
                if (lyricsText.isNotEmpty) {
                  lyrics = Lyrics.parse(lyricsText);
                  print('  🎤 Lyrics encontradas (${lyrics.isSynced ? "sincronizadas" : "texto plano"})');
                }
              }
            } catch (e) {
              print('  ⚠️ Error leyendo lyrics: $e');
            }
            
            // ✨ CREAR EL OBJETO SONG
            final song = Song(
              title: audioFile.title,
              artists: artistsList,
              album: audioFile.album ?? 'Álbum Desconocido',
              duration: audioFile.duration ?? 0,
              lyrics: lyrics,
              bitrate: bitrate,
              filePath: audioFile.data,
              dominantColor: null,
              albumArtUri: audioFile.uri,  // URI de la carátula
              audioId: audioFile.id,  // ID para QueryArtworkWidget
            );

            songs.add(song);
            print('  📀 $song');
          }
        } catch (e) {
          print('  ⚠️ Error al procesar ${audioFile.title}: $e');
        }
      }

      print('✅ Se crearon ${songs.length} objetos Song');
    } catch (e) {
      print('❌ Error al escanear: $e');
    }

    return songs;
  }

  /// Calcula el bitrate aproximado basándose en el tamaño del archivo y duración
  Future<int> _calculateBitrate(String filePath, int durationMs) async {
    try {
      if (durationMs == 0) return 0;
      
      final file = File(filePath);
      final fileSize = await file.length(); // bytes
      final durationSeconds = durationMs / 1000;
      
      // bitrate (kbps) = (fileSize * 8) / (duration * 1000)
      final bitrateKbps = (fileSize * 8) ~/ (durationSeconds * 1000);
      
      return bitrateKbps.toInt();
    } catch (e) {
      print('  ⚠️ Error calculando bitrate: $e');
      return 0;
    }
  }
}
