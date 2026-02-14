import 'package:just_audio/just_audio.dart';
import '../models/Playlist.dart';
import '../models/Song.dart';
import '../main.dart'; // Para acceder a audioHandler global

class AudioPlayerService {
  // ========== SINGLETON ==========
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // ========== GETTERS ==========
  
  /// Canción actual
  Song? get currentSong => audioHandler.currentSong;
  
  /// Playlist actual
  Playlist? get currentPlaylist => audioHandler.currentPlaylist;
  
  /// ¿Está reproduciendo?
  bool get isPlaying => audioHandler.isPlaying;
  
  /// Modo shuffle
  bool get isShuffleEnabled => audioHandler.isShuffleEnabled;
  
  /// Modo repeat
  LoopMode get loopMode => audioHandler.loopMode;

  // ========== STREAMS (para actualizar UI en tiempo real) ==========
  
  /// Stream de la canción actual
  Stream<Song?> get currentSongStream => audioHandler.currentSongStream;
  
  /// Stream de posición (0:00 → 3:45)
  Stream<Duration> get positionStream => audioHandler.positionStream;
  
  /// Stream de duración total (3:45)
  Stream<Duration?> get durationStream => audioHandler.durationStream;
  
  /// Stream del estado del reproductor
  Stream<PlayerState> get playerStateStream => audioHandler.playerStateStream;
  
  /// Stream del índice actual
  Stream<int?> get currentIndexStream => audioHandler.currentIndexStream;

  // ========== MÉTODOS PRINCIPALES ==========

  /// Configura y carga una playlist completa
  Future<void> setPlaylist(Playlist playlist, {int startIndex = 0}) async {
    await audioHandler.setPlaylist(playlist, startIndex: startIndex);
  }

  // ========== CONTROLES DE REPRODUCCIÓN ==========

  /// Reproducir
  Future<void> play() async {
    await audioHandler.play();
  }

  /// Pausar
  Future<void> pause() async {
    await audioHandler.pause();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    await audioHandler.togglePlayPause();
  }

  /// Siguiente canción
  Future<void> next() async {
    await audioHandler.next();
  }

  /// Canción anterior
  Future<void> previous() async {
    await audioHandler.previous();
  }

  /// Saltar a una posición específica en la canción
  Future<void> seek(Duration position) async {
    await audioHandler.seek(position);
  }

  /// Saltar a una canción específica por índice
  Future<void> jumpToIndex(int index) async {
    await audioHandler.jumpToIndex(index);
  }

  // ========== MODOS DE REPRODUCCIÓN ==========

  /// Activar/desactivar shuffle
  Future<void> setShuffleMode(bool enabled) async {
    await audioHandler.toggleShuffleMode(enabled);
  }

  /// Configurar modo de repetición
  Future<void> setLoopMode(LoopMode mode) async {
    await audioHandler.setLoopMode(mode);
  }

  /// Cicla entre los modos de repetición
  Future<void> toggleLoopMode() async {
    await audioHandler.toggleLoopMode();
  }

  // ========== UTILIDADES ==========

  /// Obtiene la posición actual
  Duration get currentPosition => audioHandler.currentPosition;

  /// Obtiene la duración total
  Duration? get currentDuration => audioHandler.currentDuration;

  /// Detener completamente
  Future<void> stop() async {
    await audioHandler.stop();
  }
}
