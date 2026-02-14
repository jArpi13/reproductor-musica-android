import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/Song.dart';

class AlbumArtWidget extends StatelessWidget {
  final Song song;
  final double size;
  final BorderRadius? borderRadius;

  const AlbumArtWidget({
    super.key,
    required this.song,
    this.size = 50,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    // Si tiene URL HD, usarla con cache
    if (song.albumArtUrlHD != null && song.albumArtUrlHD!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: song.albumArtUrlHD!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: song.dominantColor ?? Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildLocalArtwork(),
        ),
      );
    }

    // Fallback a carátula local
    return _buildLocalArtwork();
  }

  Widget _buildLocalArtwork() {
    final radius = borderRadius ?? BorderRadius.circular(8);

    // Si tenemos audioId, usarlo
    if (song.audioId != null) {
      return ClipRRect(
        borderRadius: radius,
        child: QueryArtworkWidget(
          id: song.audioId!,
          type: ArtworkType.AUDIO,
          artworkWidth: size,
          artworkHeight: size,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: _buildPlaceholder(),
        ),
      );
    }

    // Si tenemos albumArtUri, intentar extraer el ID
    if (song.albumArtUri != null) {
      try {
        // El URI puede ser como: content://media/external/audio/media/12345
        final uriParts = song.albumArtUri!.split('/');
        if (uriParts.isNotEmpty) {
          final lastPart = uriParts.last;
          final id = int.tryParse(lastPart);
          if (id != null) {
            return ClipRRect(
              borderRadius: radius,
              child: QueryArtworkWidget(
                id: id,
                type: ArtworkType.AUDIO,
                artworkWidth: size,
                artworkHeight: size,
                artworkFit: BoxFit.cover,
                nullArtworkWidget: _buildPlaceholder(),
              ),
            );
          }
        }
      } catch (e) {
        // Silencioso, simplemente usar placeholder
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: song.dominantColor ?? Colors.grey[800],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(Icons.music_note, color: Colors.white, size: size * 0.5),
    );
  }
}
