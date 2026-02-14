import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/Song.dart';
import '../models/Lyrics.dart';
import '../services/audio_player_service.dart';
import '../services/album_art_service.dart';
import '../services/lyrics_service.dart';
import '../services/lyrics_storage_service.dart';
import '../widgets/album_art_widget.dart';
import 'all_playlists_screen.dart';

class ReproductorScreen extends StatefulWidget {
  const ReproductorScreen({super.key});

  @override
  State<ReproductorScreen> createState() => _ReproductorScreenState();
}

class _ReproductorScreenState extends State<ReproductorScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  final ScrollController _lyricsScrollController = ScrollController();
  bool _isImageMode = true;

  void _toggleMode() {
    setState(() {
      _isImageMode = !_isImageMode;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getQualityLabel(int bitrate) {
    if (bitrate >= 1000) return 'Muy Alta';
    if (bitrate >= 700) return 'Alta';
    if (bitrate >= 320) return 'Buena';
    if (bitrate >= 192) return 'Media';
    return 'Baja';
  }

  String _getFileExtension(String filePath) {
    return filePath.split('.').last.toUpperCase();
  }

  Future<void> _downloadAlbumArt(Song song) async {
    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Buscando carátula HD...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final albumArtService = AlbumArtService();
      final hdUrl = await albumArtService.searchAlbumArt(
        trackTitle: song.title,
        artistName: song.artists.join(', '),
        albumName: song.album,
      );

      if (hdUrl != null) {
        setState(() {
          song.albumArtUrlHD = hdUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Carátula HD descargada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró carátula HD'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar carátula: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _downloadLyrics(Song song) async {
    // Mostrar diálogo de confirmación con información
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud_download, color: Colors.blue[300]),
            const SizedBox(width: 12),
            const Text(
              'Descargar letras',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              song.artists.join(', '),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.data_usage,
              'Consumo estimado',
              '~5-15 KB',
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.speed,
              'Tiempo estimado',
              '1-3 segundos',
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.lyrics, 'Fuente', 'LRCLIB.net', Colors.blue),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[300], size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Se buscarán letras con timestamps (sincronizadas) o simples',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Descargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Mostrar diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Buscando letras...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Conectando con LRCLIB.net',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );

    try {
      final lyricsService = LyricsService();
      final lyrics = await lyricsService.searchLyrics(
        trackTitle: song.title,
        artistName: song.artists.join(', '),
        albumName: song.album,
        durationSeconds: (song.duration / 1000).round(),
      );

      // Cerrar diálogo de progreso
      if (mounted) Navigator.pop(context);

      if (lyrics != null) {
        setState(() {
          song.lyrics = lyrics;
          song.isLyricsDownloaded = true;
        });

        // Guardar letras en almacenamiento persistente
        final storageService = LyricsStorageService();
        await storageService.saveLyrics(song);

        if (mounted) {
          final lyricsType = lyrics.isSynced ? 'sincronizadas ⏱️' : 'simples';
          final lineCount = lyrics.isSynced
              ? lyrics.syncedLines!.length
              : lyrics.plainText!.split('\n').length;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[300]),
                  const SizedBox(width: 12),
                  const Text(
                    '¡Descarga exitosa!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.lyrics,
                    'Tipo',
                    'Letras $lyricsType',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.format_list_numbered,
                    'Líneas',
                    '$lineCount líneas',
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.save,
                    'Estado',
                    'Guardado localmente',
                    Colors.orange,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[300]),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                      'No se encontraron letras',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'No hay letras disponibles para esta canción en LRCLIB.net',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar diálogo de progreso si está abierto
      if (mounted) Navigator.pop(context);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red[300]),
                const SizedBox(width: 12),
                const Text(
                  'Error',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No se pudo descargar las letras',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.toString(),
                    style: TextStyle(color: Colors.red[200], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verifica tu conexión a internet',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Song?>(
      stream: _audioService.currentSongStream,
      builder: (context, snapshot) {
        final currentSong = snapshot.data;
        final bgColor = currentSong?.dominantColor ?? Colors.grey[900];

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Fondo degradado
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bgColor!.withOpacity(0.8), Colors.black],
                  ),
                ),
              ),

              // Blur
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),

              // Contenido
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      children: [
                        _buildHeader(currentSong),
                        const SizedBox(height: 10),
                        _isImageMode
                            ? _buildImageMode(currentSong)
                            : _buildLyricsMode(currentSong),
                        const SizedBox(height: 20),
                        _buildModeToggleButtons(),
                        const SizedBox(height: 16),
                        _buildPlaybackControls(currentSong),
                        const SizedBox(height: 20),
                        _buildAdditionalButtons(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Song? currentSong) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bitrate y extensión
                    if (currentSong != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${currentSong.bitrate} kbps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getFileExtension(currentSong.filePath),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '• ${_getQualityLabel(currentSong.bitrate)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    const Text(
                      'Reproduciendo ahora',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    StreamBuilder<int?>(
                      stream: _audioService.currentIndexStream,
                      builder: (context, indexSnapshot) {
                        final currentIndex = (indexSnapshot.data ?? 0) + 1;
                        final totalSongs =
                            _audioService.currentPlaylist?.length ?? 0;
                        return Text(
                          'Canción $currentIndex de $totalSongs',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 26),
                color: Colors.white,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentSong != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                currentSong.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                currentSong.artists.join(', '),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageMode(Song? currentSong) {
    if (currentSong == null) {
      return Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.music_note,
          color: Colors.white,
          size: 100,
        ),
      );
    }

    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (currentSong.dominantColor ?? Colors.black).withOpacity(0.6),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          AlbumArtWidget(
            song: currentSong,
            size: 300,
            borderRadius: BorderRadius.circular(20),
          ),
          // Botón para buscar/actualizar carátula HD - SIEMPRE VISIBLE
          Positioned(
            bottom: 10,
            right: 10,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentSong.albumArtUrlHD != null
                      ? Colors.green.withOpacity(0.8)
                      : Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  currentSong.albumArtUrlHD != null
                      ? Icons.refresh
                      : Icons.download,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              tooltip: currentSong.albumArtUrlHD != null
                  ? 'Reemplazar carátula'
                  : 'Descargar carátula HD',
              onPressed: () => _downloadAlbumArt(currentSong),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsMode(Song? currentSong) {
    final lyrics = currentSong?.lyrics;

    if (lyrics == null) {
      return Column(
        children: [
          Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: const Center(
              child: Text(
                'Sin letra disponible',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Botón para descargar letras - MÁS VISIBLE
          ElevatedButton.icon(
            onPressed: () => _downloadLyrics(currentSong!),
            icon: const Icon(Icons.cloud_download),
            label: const Text('Buscar letras online'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      );
    }

    // Si son lyrics sincronizadas
    if (lyrics.isSynced) {
      return _buildSyncedLyrics(currentSong, lyrics);
    }

    // Si es texto plano
    return _buildPlainTextLyrics(currentSong, lyrics);
  }

  // Lyrics sincronizadas con scroll automático
  Widget _buildSyncedLyrics(Song? currentSong, Lyrics lyrics) {
    return StreamBuilder<Duration>(
      stream: _audioService.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final currentLineIndex = lyrics.getCurrentLineIndex(position);

        // Auto-scroll para mantener la línea activa centrada (estilo Spotify)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentLineIndex >= 0 &&
              _lyricsScrollController.hasClients &&
              lyrics.syncedLines!.isNotEmpty) {
            // Altura del contenedor de letras
            const containerHeight = 300.0;
            // Altura aproximada de cada línea
            const lineHeight = 50.0;
            
            // Calcular offset para centrar la línea activa
            final targetOffset = (currentLineIndex * lineHeight) - 
                                (containerHeight / 2) + 
                                (lineHeight / 2);
            
            _lyricsScrollController.animateTo(
              targetOffset.clamp(
                0.0,
                _lyricsScrollController.position.maxScrollExtent,
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });

        return Column(
          children: [
            Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: ListView.builder(
                controller: _lyricsScrollController,
                itemCount: lyrics.syncedLines!.length,
                itemBuilder: (context, index) {
                  final line = lyrics.syncedLines![index];
                  final isActive = index == currentLineIndex;
                  final isPast = index < currentLineIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      line.text,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : isPast
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white.withOpacity(0.6),
                        fontSize: isActive ? 18 : 16,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Botón para actualizar letras - MÁS VISIBLE
            if (currentSong != null)
              ElevatedButton.icon(
                onPressed: () => _downloadLyrics(currentSong),
                icon: Icon(
                  currentSong.isLyricsDownloaded
                      ? Icons.cloud_done
                      : Icons.cloud_download,
                ),
                label: Text(
                  currentSong.isLyricsDownloaded
                      ? 'Letras descargadas ✓'
                      : 'Buscar letras online',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentSong.isLyricsDownloaded
                      ? Colors.green
                      : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Lyrics texto plano scrollable
  Widget _buildPlainTextLyrics(Song? currentSong, Lyrics lyrics) {
    final lyricsLines = lyrics.plainText!.split('\n');

    return Column(
      children: [
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: ListView.builder(
            itemCount: lyricsLines.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  lyricsLines[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Botón para actualizar letras - MÁS VISIBLE
        if (currentSong != null)
          ElevatedButton.icon(
            onPressed: () => _downloadLyrics(currentSong),
            icon: Icon(
              currentSong.isLyricsDownloaded
                  ? Icons.cloud_done
                  : Icons.cloud_download,
            ),
            label: Text(
              currentSong.isLyricsDownloaded
                  ? 'Letras descargadas ✓'
                  : 'Buscar letras online',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentSong.isLyricsDownloaded
                  ? Colors.green
                  : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeToggleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeButton('Modo Imagen', _isImageMode, () {
          if (!_isImageMode) _toggleMode();
        }),
        const SizedBox(width: 16),
        _buildModeButton('Modo Lyrics', !_isImageMode, () {
          if (_isImageMode) _toggleMode();
        }),
      ],
    );
  }

  Widget _buildModeButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(isActive ? 1 : 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(Song? currentSong) {
    return Column(
      children: [
        // Barra de progreso
        StreamBuilder<Duration>(
          stream: _audioService.positionStream,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration?>(
              stream: _audioService.durationStream,
              builder: (context, durationSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = durationSnapshot.data ?? Duration.zero;
                final progress = duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                          thumbColor: Colors.white,
                          overlayColor: Colors.white.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (value) {
                            final newPosition = Duration(
                              milliseconds: (value * duration.inMilliseconds)
                                  .toInt(),
                            );
                            _audioService.seek(newPosition);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),

        const SizedBox(height: 20),

        // Botones
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 48),
              color: Colors.white,
              onPressed: () => _audioService.previous(),
            ),
            const SizedBox(width: 30),
            StreamBuilder<PlayerState>(
              stream: _audioService.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                return GestureDetector(
                  onTap: () => _audioService.togglePlayPause(),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 30),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 48),
              color: Colors.white,
              onPressed: () => _audioService.next(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StreamBuilder<bool>(
            stream: Stream.periodic(
              const Duration(milliseconds: 100),
            ).map((_) => _audioService.isShuffleEnabled),
            builder: (context, snapshot) {
              final isShuffleEnabled = snapshot.data ?? false;
              return _buildControlButton(
                Icons.shuffle,
                isShuffleEnabled,
                () => _audioService.setShuffleMode(!isShuffleEnabled),
              );
            },
          ),
          StreamBuilder<LoopMode>(
            stream: Stream.periodic(
              const Duration(milliseconds: 100),
            ).map((_) => _audioService.loopMode),
            builder: (context, snapshot) {
              final loopMode = snapshot.data ?? LoopMode.off;
              final isActive = loopMode != LoopMode.off;
              final icon = loopMode == LoopMode.one
                  ? Icons.repeat_one
                  : Icons.repeat;
              return _buildControlButton(
                icon,
                isActive,
                () => _audioService.toggleLoopMode(),
              );
            },
          ),
          _buildControlButton(Icons.queue_music, false, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllPlaylistsScreen(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(isActive ? 0.6 : 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(isActive ? 1 : 0.6),
          size: 24,
        ),
      ),
    );
  }
}
