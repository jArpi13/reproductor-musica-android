import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ColorExtractorService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Extrae el color predominante de la carátula de una canción
  Future<Color?> extractDominantColor(String? albumArtUri) async {
    if (albumArtUri == null) return null;

    try {
      // Obtener el ID del audio desde el URI
      final audioId = int.parse(albumArtUri.split('/').last);

      // Obtener la imagen de la carátula
      final artworkBytes = await _audioQuery.queryArtwork(
        audioId,
        ArtworkType.AUDIO,
        quality: 50, // Calidad baja para procesar más rápido
      );

      if (artworkBytes == null) return null;

      // Generar la paleta de colores directamente
      final imageProvider = MemoryImage(artworkBytes);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
      );

      // Retornar el color dominante o vibrante
      return paletteGenerator.dominantColor?.color ??
          paletteGenerator.vibrantColor?.color ??
          paletteGenerator.mutedColor?.color;
    } catch (e) {
      print('⚠️ Error extrayendo color: $e');
      return null;
    }
  }

  /// Extrae colores de múltiples canciones (optimizado para batch)
  Future<Map<String, Color?>> extractColorsForSongs(
    List<String?> albumArtUris,
  ) async {
    final Map<String, Color?> colors = {};

    for (var uri in albumArtUris) {
      if (uri != null) {
        colors[uri] = await extractDominantColor(uri);
      }
    }

    return colors;
  }
}
