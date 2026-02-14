import 'dart:io';
import 'package:flutter/material.dart';
import '../models/Song.dart';
import '../models/Playlist.dart';
import '../services/audio_player_service.dart';
import '../services/artist_image_download_service.dart';
import '../widgets/song_card.dart';
import '../widgets/mini_player.dart';

class ArtistScreen extends StatefulWidget {
  final String artistName;
  final List<Song> artistSongs;
  final String? artistImagePath;

  const ArtistScreen({
    super.key,
    required this.artistName,
    required this.artistSongs,
    this.artistImagePath,
  });

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  String? _currentImagePath;
  bool _isDownloadingImage = false;
  int _imageKey = 0; // Key para forzar reconstrucción de la imagen

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.artistImagePath;
  }

  void _playSong(int index, BuildContext context) async {
    final audioService = AudioPlayerService();

    // Crear playlist con las canciones del artista
    final playlist = Playlist(
      id: 'artist_${widget.artistName}',
      name: widget.artistName,
      songs: widget.artistSongs,
      type: PlaylistType.artist,
    );

    // Configurar y reproducir
    await audioService.setPlaylist(playlist, startIndex: index);
    await audioService.play();
  }

  Future<void> _downloadArtistImage() async {
    setState(() => _isDownloadingImage = true);

    try {
      final service = ArtistImageDownloadService();
      final imagePath = await service.downloadArtistImage(widget.artistName);

      if (imagePath != null) {
        // Limpiar cache de la imagen anterior si existe
        if (_currentImagePath != null) {
          final oldFile = File(_currentImagePath!);
          if (await oldFile.exists()) {
            FileImage(oldFile).evict();
          }
        }
        
        // Verificar que el archivo existe
        final newFile = File(imagePath);
        final exists = await newFile.exists();
        final size = exists ? await newFile.length() : 0;
        
        print('🖼️ Actualizando imagen en UI:');
        print('   Ruta: $imagePath');
        print('   Existe: $exists');
        print('   Tamaño: $size bytes');
        
        setState(() {
          _currentImagePath = imagePath;
          _isDownloadingImage = false;
          _imageKey++; // Incrementar para forzar reconstrucción
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Imagen del artista descargada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isDownloadingImage = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró imagen para este artista'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isDownloadingImage = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar imagen: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Ver estado actual
    print('🎨 Construyendo ArtistScreen para: ${widget.artistName}');
    print('   _currentImagePath: $_currentImagePath');
    print('   _imageKey: $_imageKey');
    
    // Obtener color predominante de la primera canción o usar morado por defecto
    final headerColor = widget.artistSongs.isNotEmpty
        ? (widget.artistSongs.first.dominantColor ?? Colors.purple[700])
        : Colors.purple[700];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gradiente de fondo
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [headerColor!.withOpacity(0.5), Colors.black],
              ),
            ),
          ),

          // Contenido
          CustomScrollView(
            slivers: [
              // Header con imagen del artista
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // Imagen del artista con botón de descarga
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            key: ValueKey(_imageKey), // Key único para forzar reconstrucción
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _currentImagePath == null
                                  ? LinearGradient(
                                      colors: [
                                        headerColor,
                                        headerColor.withOpacity(0.6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              image: _currentImagePath != null
                                  ? DecorationImage(
                                      image: FileImage(File(_currentImagePath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _currentImagePath == null
                                ? const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          // Botón de descarga
                          Container(
                            decoration: BoxDecoration(
                              color: _currentImagePath != null
                                  ? Colors.green.withOpacity(0.9)
                                  : Colors.blue.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: _isDownloadingImage
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _currentImagePath != null
                                          ? Icons.refresh
                                          : Icons.download,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                              tooltip: _currentImagePath != null
                                  ? 'Actualizar imagen'
                                  : 'Descargar imagen',
                              onPressed:
                                  _isDownloadingImage ? null : _downloadArtistImage,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Nombre del artista
                      Text(
                        widget.artistName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Cantidad de canciones
                      Text(
                        '${widget.artistSongs.length} cancion${widget.artistSongs.length != 1 ? 'es' : ''}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón de reproducir todo
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _playSong(0, context),
                          icon: const Icon(Icons.play_arrow, size: 28),
                          label: const Text(
                            'Reproducir todo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: headerColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Botón shuffle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.shuffle),
                          color: Colors.white,
                          iconSize: 28,
                          onPressed: () async {
                            // TODO: Reproducir en modo aleatorio
                            final audioService = AudioPlayerService();
                            await audioService.setShuffleMode(true);
                            _playSong(0, context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de canciones
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = widget.artistSongs[index];
                    return SongCard(
                      song: song,
                      onTap: () => _playSong(index, context),
                      showArtist:
                          false, // No mostrar artista porque ya sabemos cuál es
                    );
                  }, childCount: widget.artistSongs.length),
                ),
              ),
            ],
          ),

          // MiniPlayer flotante
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: const MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
