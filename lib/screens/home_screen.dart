import 'package:flutter/material.dart';
import '../models/Song.dart';
import '../models/Playlist.dart';
import '../services/music_scanner_service.dart';
import '../services/music_utils_service.dart';
import '../services/artist_image_service.dart';
import '../services/audio_player_service.dart';
import '../services/permission_service.dart';
import '../services/color_extractor_service.dart';
import '../services/playlist_manager_service.dart';
import '../services/lyrics_storage_service.dart';
import '../widgets/artist_circle.dart';
import '../widgets/song_card.dart';
import '../widgets/mini_player.dart';
import '../widgets/create_playlist_dialog.dart';
import 'artist_screen.dart';
import 'playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Servicios
  final MusicScannerService _musicScanner = MusicScannerService();
  final MusicUtilsService _utils = MusicUtilsService();
  final ArtistImageService _imageService = ArtistImageService();
  final AudioPlayerService _audioService = AudioPlayerService();
  final PermissionService _permissionService = PermissionService();
  final ColorExtractorService _colorExtractor = ColorExtractorService();
  final PlaylistManagerService _playlistManager = PlaylistManagerService();

  // Datos
  List<Song> _allSongs = [];
  List<String> _uniqueArtists = [];
  Map<String, String?> _artistImages = {};
  List<Playlist> _customPlaylists = [];

  // Estados
  bool _isLoading = true;
  String _userName = "Ivan";
  String _searchQuery = '';
  List<Song> _filteredSongs = [];
  List<String> _filteredArtists = [];
  List<Playlist> _filteredPlaylists = [];

  @override
  void initState() {
    super.initState();
    _loadMusic();
  }

  void _filterContent(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();

      if (_searchQuery.isEmpty) {
        _filteredSongs = _allSongs;
        _filteredArtists = _uniqueArtists;
        _filteredPlaylists = _customPlaylists;
      } else {
        // Filtrar canciones por título, artista o álbum
        _filteredSongs = _allSongs.where((song) {
          return song.title.toLowerCase().contains(_searchQuery) ||
              song.artists.any((artist) => artist.toLowerCase().contains(_searchQuery)) ||
              song.album.toLowerCase().contains(_searchQuery);
        }).toList();

        // Filtrar artistas
        _filteredArtists = _uniqueArtists.where((artist) {
          return artist.toLowerCase().contains(_searchQuery);
        }).toList();

        // Filtrar playlists
        _filteredPlaylists = _customPlaylists.where((playlist) {
          return playlist.name.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadMusic() async {
    setState(() => _isLoading = true);

    try {
      // 0. Solicitar permisos de almacenamiento
      final hasPermission = await _permissionService.requestStoragePermission();

      if (!hasPermission) {
        print('❌ Permisos de almacenamiento denegados');
        setState(() => _isLoading = false);
        return;
      }

      // 0.1. Solicitar permiso de notificaciones (no bloquea si se niega)
      await _permissionService.requestNotificationPermission();

      // 1. Escanear canciones
      _allSongs = await _musicScanner.scanMusicFolder();

      // 2. Extraer artistas únicos
      _uniqueArtists = _utils.getUniqueArtists(_allSongs);

      // 3. Obtener imágenes de artistas (ahora es async)
      _artistImages = await _imageService.getArtistsImages(_uniqueArtists);

      // 4. Extraer colores predominantes de las carátulas
      print('🎨 Extrayendo colores predominantes...');
      for (var song in _allSongs) {
        if (song.albumArtUri != null) {
          song.dominantColor = await _colorExtractor.extractDominantColor(
            song.albumArtUri,
          );
        }
      }

      // 5. Cargar letras guardadas
      print('📝 Cargando letras guardadas...');
      await _loadSavedLyrics();

      // 6. Cargar playlists personalizadas
      await _playlistManager.loadPlaylists(_allSongs);
      _customPlaylists = _playlistManager.customPlaylists;

      // Inicializar listas filtradas
      _filteredSongs = _allSongs;
      _filteredArtists = _uniqueArtists;
      _filteredPlaylists = _customPlaylists;

      print('✅ HomeScreen cargado:');
      print('   ${_allSongs.length} canciones');
      print('   ${_uniqueArtists.length} artistas');
      print('   ${_customPlaylists.length} playlists personalizadas');
      setState(() {}); // Actualizar UI con los colores
    } catch (e) {
      print('❌ Error cargando música: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadSavedLyrics() async {
    final storageService = LyricsStorageService();

    for (var song in _allSongs) {
      final savedLyrics = await storageService.loadLyrics(song.filePath);

      if (savedLyrics != null) {
        song.lyrics = savedLyrics;
        song.isLyricsDownloaded = true;
      }
    }

    final stats = await storageService.getStats();
    print(
      '   ${stats['total']} letras cargadas (${stats['synced']} sincronizadas, ${stats['plain']} simples)',
    );
  }

  void _playSong(int index) async {
    // Crear playlist con las canciones filtradas
    final playlist = Playlist(
      id: 'filtered',
      name: _searchQuery.isEmpty ? 'Todo mi repertorio' : 'Resultados de búsqueda',
      songs: _filteredSongs,
      type: PlaylistType.allSongs,
    );

    // Configurar y reproducir
    await _audioService.setPlaylist(playlist, startIndex: index);
    await _audioService.play();
    
    // Forzar actualización del UI
    if (mounted) setState(() {});
  }

  void _openArtistScreen(String artistName) {
    // Filtrar canciones del artista
    final artistSongs = _utils.getSongsByArtist(_allSongs, artistName);
    final artistImage = _artistImages[artistName];

    // Navegar a la pantalla del artista
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistScreen(
          artistName: artistName,
          artistSongs: artistSongs,
          artistImagePath: artistImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : Stack(
              children: [
                // Gradiente de fondo dinámico
                StreamBuilder<Song?>(
                  stream: _audioService.currentSongStream,
                  builder: (context, snapshot) {
                    final currentSong = snapshot.data;
                    final bgColor =
                        currentSong?.dominantColor ?? Colors.grey[900];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, bgColor!.withOpacity(0.3)],
                        ),
                      ),
                    );
                  },
                ),

                // Contenido principal
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(),

                        // Barra de búsqueda
                        _buildSearchBar(),

                        const SizedBox(height: 20),

                        // Playlists personalizadas
                        if (_filteredPlaylists.isNotEmpty || _searchQuery.isEmpty)
                          _buildPlaylistsSection(),

                        const SizedBox(height: 20),

                        // Artistas disponibles
                        if (_filteredArtists.isNotEmpty) _buildArtistsSection(),

                        const SizedBox(height: 20),

                        // Título de "Todo mi repertorio"
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Todo mi repertorio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Estadísticas: cantidad y duración total
                        _buildRepertoireStats(),

                        const SizedBox(height: 12),

                        // Lista de canciones
                        _buildSongsList(),

                        // Espacio para el MiniPlayer
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola $_userName',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Bienvenido de vuelta',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar en biblioteca',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
              ),
              onChanged: _filterContent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Artistas disponibles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filteredArtists.length,
            itemBuilder: (context, index) {
              final artist = _filteredArtists[index];
              final imagePath = _artistImages[artist];

              return ArtistCircle(
                artistName: artist,
                imagePath: imagePath,
                onTap: () => _openArtistScreen(artist),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Playlists',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const CreatePlaylistDialog(),
                  );
                  if (result == true) {
                    setState(() {
                      _customPlaylists = _playlistManager.customPlaylists;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _filteredPlaylists.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _searchQuery.isEmpty
                      ? 'Crea tu primera playlist presionando +'
                      : 'No se encontraron playlists',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              )
            : SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _filteredPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = _filteredPlaylists[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlaylistScreen(playlist: playlist),
                          ),
                        );
                        // Refrescar playlists al volver
                        setState(() {
                          _customPlaylists = _playlistManager.customPlaylists;
                        });
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 160,
                              height: 140,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.purple.shade600,
                                    Colors.purple.shade900,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.library_music,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              playlist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${playlist.songs.length} ${playlist.songs.length == 1 ? 'canción' : 'canciones'}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildRepertoireStats() {
    final songCount = _filteredSongs.length;
    final durationText = Song.getFormattedTotalDuration(_filteredSongs);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.music_note, color: Colors.grey[400], size: 16),
          const SizedBox(width: 6),
          Text(
            '$songCount ${songCount == 1 ? 'canción' : 'canciones'}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.access_time, color: Colors.grey[400], size: 16),
          const SizedBox(width: 6),
          Text(
            durationText,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_filteredSongs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Text(
            _searchQuery.isEmpty ? 'No hay canciones' : 'No se encontraron canciones',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _filteredSongs.asMap().entries.map((entry) {
        final index = entry.key;
        final song = entry.value;

        return SongCard(song: song, onTap: () => _playSong(index));
      }).toList(),
    );
  }
}
