import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/Song.dart';
import '../models/Playlist.dart';
import 'notification_artwork_service.dart';

class AudioHandlerService extends BaseAudioHandler with QueueHandler, SeekHandler {
  // ========== ATRIBUTOS ==========
  final AudioPlayer _player = AudioPlayer();
  Playlist? _currentPlaylist;
  ConcatenatingAudioSource? _audioSource;
  final NotificationArtworkService _artworkService = NotificationArtworkService();

  // Constructor público
  AudioHandlerService() {
    _init();
  }

  // ========== INICIALIZACIÓN ==========
  void _init() {
    // Escuchar cambios en el reproductor
    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen((index) async {
      if (index != null && _currentPlaylist != null) {
        _currentPlaylist!.currentIndex = index;
        await _updateMediaItem();
      }
    });
  }

  // ========== GETTERS ==========
  Song? get currentSong => _currentPlaylist?.currentSong;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isPlaying => _player.playing;
  bool get isShuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;

  // ========== STREAMS ==========
  Stream<Song?> get currentSongStream {
    return _player.currentIndexStream.map((index) {
      if (index == null || _currentPlaylist == null) return null;
      _currentPlaylist!.currentIndex = index;
      return _currentPlaylist!.currentSong;
    });
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  // ========== CONFIGURACIÓN DE PLAYLIST ==========
  Future<void> setPlaylist(Playlist playlist, {int startIndex = 0}) async {
    try {
      _currentPlaylist = playlist;
      playlist.currentIndex = startIndex;

      // Crear AudioSource para cada canción
      final audioSources = playlist.songs.map((song) {
        return AudioSource.uri(
          Uri.file(song.filePath),
          tag: {
            'title': song.title,
            'artists': song.artists.join(', '),
            'filePath': song.filePath,
          },
        );
      }).toList();

      _audioSource = ConcatenatingAudioSource(children: audioSources);

      await _player.setAudioSource(
        _audioSource!,
        initialIndex: startIndex,
        initialPosition: Duration.zero,
      );

      // Actualizar cola de audio_service (con await para procesar artwork)
      final mediaItems = await Future.wait(
        playlist.songs.map((song) => _songToMediaItem(song)).toList(),
      );
      queue.add(mediaItems);

      // Actualizar item actual
      await _updateMediaItem();

      print('✅ Playlist configurada con notificaciones: ${playlist.name}');
    } catch (e) {
      print('❌ Error configurando playlist: $e');
    }
  }

  // ========== CONTROLES (audio_service override) ==========

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_currentPlaylist?.hasNext ?? false) {
      await _player.seekToNext();
      _currentPlaylist?.getNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_currentPlaylist?.hasPrevious ?? false) {
      await _player.seekToPrevious();
      _currentPlaylist?.getPrevious();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < (_currentPlaylist?.length ?? 0)) {
      await _player.seek(Duration.zero, index: index);
      _currentPlaylist?.jumpTo(index);
    }
  }

  // ========== MÉTODOS ADICIONALES ==========

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    await skipToNext();
  }

  Future<void> previous() async {
    await skipToPrevious();
  }

  Future<void> jumpToIndex(int index) async {
    await skipToQueueItem(index);
  }

  Future<void> toggleShuffleMode(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    playbackState.add(playbackState.value.copyWith(shuffleMode: enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none));
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
    AudioServiceRepeatMode repeatMode;
    switch (mode) {
      case LoopMode.off:
        repeatMode = AudioServiceRepeatMode.none;
        break;
      case LoopMode.one:
        repeatMode = AudioServiceRepeatMode.one;
        break;
      case LoopMode.all:
        repeatMode = AudioServiceRepeatMode.all;
        break;
    }
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  Future<void> toggleLoopMode() async {
    LoopMode nextMode;
    switch (_player.loopMode) {
      case LoopMode.off:
        nextMode = LoopMode.all;
        break;
      case LoopMode.all:
        nextMode = LoopMode.one;
        break;
      case LoopMode.one:
        nextMode = LoopMode.off;
        break;
    }
    await setLoopMode(nextMode);
  }

  Duration get currentPosition => _player.position;
  Duration? get currentDuration => _player.duration;

  // ========== UTILIDADES PRIVADAS ==========

  /// Convierte Song a MediaItem para audio_service
  Future<MediaItem> _songToMediaItem(Song song) async {
    Uri? artUri;
    
    // Obtener artwork para notificación desde el cache
    if (song.audioId != null) {
      try {
        final artworkPath = await _artworkService.getNotificationArtworkUri(song.audioId!);
        if (artworkPath != null) {
          artUri = Uri.file(artworkPath);
          print('🎨 Artwork obtenido para notificación: $artworkPath');
        }
      } catch (e) {
        print('⚠️ Error obteniendo artwork: $e');
      }
    }
    
    return MediaItem(
      id: song.filePath,
      title: song.title,
      artist: song.artists.join(', '),
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      artUri: artUri,
      extras: {
        'dominantColor': song.dominantColor?.value ?? 0xFF424242,
      },
    );
  }

  /// Actualiza el MediaItem actual en la notificación
  Future<void> _updateMediaItem() async {
    if (currentSong != null) {
      final item = await _songToMediaItem(currentSong!);
      print('🔔 Actualizando MediaItem: ${item.title} - ${item.artist}');
      mediaItem.add(item);
    }
  }

  /// Transmite el estado del reproductor a audio_service
  void _broadcastState(PlaybackEvent event) {
    final state = playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentPlaylist?.currentIndex,
    );
    
    print('🔔 Broadcasting state: playing=${state.playing}, position=${state.updatePosition}');
    playbackState.add(state);
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}
