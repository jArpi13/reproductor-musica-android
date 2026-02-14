import 'package:flutter/material.dart';
import '../services/playlist_manager_service.dart';

class CreatePlaylistDialog extends StatefulWidget {
  const CreatePlaylistDialog({super.key});

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  final TextEditingController _nameController = TextEditingController();
  final PlaylistManagerService _playlistManager = PlaylistManagerService();
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateAndCreate() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorText = 'El nombre no puede estar vacío';
      });
      return;
    }

    // Verificar si ya existe una playlist con ese nombre
    final existingPlaylist = _playlistManager.customPlaylists
        .where((p) => p.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;

    if (existingPlaylist != null) {
      setState(() {
        _errorText = 'Ya existe una playlist con ese nombre';
      });
      return;
    }

    // Crear la playlist
    _playlistManager.createPlaylist(name);

    // Cerrar el diálogo y retornar true para indicar éxito
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        'Nueva Playlist',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Nombre de la playlist',
          hintStyle: TextStyle(color: Colors.grey[600]),
          errorText: _errorText,
          errorStyle: const TextStyle(color: Colors.redAccent),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent),
          ),
        ),
        onChanged: (value) {
          if (_errorText != null) {
            setState(() {
              _errorText = null;
            });
          }
        },
        onSubmitted: (value) => _validateAndCreate(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        ElevatedButton(
          onPressed: _validateAndCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
