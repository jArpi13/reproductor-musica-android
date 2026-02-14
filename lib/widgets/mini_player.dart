import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../models/Song.dart';
import '../screens/reproductor_screen.dart';
import 'album_art_widget.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService();

    return StreamBuilder<Song?>(
      stream: audioService.currentSongStream,
      builder: (context, songSnapshot) {
        final song = songSnapshot.data;

        // Si no hay canción, no mostrar nada
        if (song == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReproductorScreen(),
              ),
            );
          },
          child: Container(
            height: 70,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Carátula pequeña
                AlbumArtWidget(
                  song: song,
                  size: 50,
                  borderRadius: BorderRadius.circular(8),
                ),

                const SizedBox(width: 12),

                // Información de la canción
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Artistas
                      Text(
                        song.artists.join(', '),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Progreso y tiempo
                StreamBuilder<Duration>(
                  stream: audioService.positionStream,
                  builder: (context, posSnapshot) {
                    final position = posSnapshot.data ?? Duration.zero;

                    return StreamBuilder<Duration?>(
                      stream: audioService.durationStream,
                      builder: (context, durSnapshot) {
                        final duration = durSnapshot.data ?? Duration.zero;

                        return Text(
                          '${_formatDuration(position)} - ${_formatDuration(duration)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(width: 12),

                // Botón Play/Pause
                StreamBuilder<bool>(
                  stream: audioService.playerStateStream.map(
                    (state) => state.playing,
                  ),
                  builder: (context, playingSnapshot) {
                    final isPlaying = playingSnapshot.data ?? false;

                    return GestureDetector(
                      onTap: () => audioService.togglePlayPause(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Formatea Duration a mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
