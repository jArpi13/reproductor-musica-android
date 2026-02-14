import 'package:flutter/material.dart';
import '../models/Song.dart';
import '../services/playlist_manager_service.dart';

class AddToPlaylistDialog extends StatefulWidget {
  final Song song;

  const AddToPlaylistDialog({
    super.key,
    required this.song,
  });

  @override
  State<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  final PlaylistManagerService _playlistManager = PlaylistManagerService();
  final Map<String, bool> _selections = {};

  @override
  void initState() {
    super.initState();
    // Inicializar el estado de cada playlist (si la canción ya está agregada)
    for (var playlist in _playlistManager.customPlaylists) {
      _selections[playlist.id] =
          _playlistManager.isSongInPlaylist(playlist.id, widget.song);
    }
  }

  void _togglePlaylist(String playlistId) {
    setState(() {
      final isCurrentlyInPlaylist = _selections[playlistId] ?? false;

      if (isCurrentlyInPlaylist) {
        // Quitar de la playlist
        _playlistManager.removeSongFromPlaylist(playlistId, widget.song);
        _selections[playlistId] = false;
      } else {
        // Agregar a la playlist
        _playlistManager.addSongToPlaylist(playlistId, widget.song);
        _selections[playlistId] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlists = _playlistManager.customPlaylists;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        'Agregar a playlist',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: playlists.isEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.library_music_outlined,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes playlists',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea una para comenzar',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final isSelected = _selections[playlist.id] ?? false;

                  return CheckboxListTile(
                    title: Text(
                      playlist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${playlist.songs.length} ${playlist.songs.length == 1 ? 'canción' : 'canciones'}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                    value: isSelected,
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                    onChanged: (bool? value) {
                      _togglePlaylist(playlist.id);
                    },
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
