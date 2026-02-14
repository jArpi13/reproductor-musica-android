import 'dart:io';
import 'package:flutter/material.dart';

class ArtistCircle extends StatelessWidget {
  final String artistName;
  final String? imagePath;
  final VoidCallback onTap;

  const ArtistCircle({
    super.key,
    required this.artistName,
    this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Círculo con imagen o ícono
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: imagePath == null
                    ? LinearGradient(
                        colors: [Colors.purple[700]!, Colors.purple[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: imagePath != null
                    ? DecorationImage(
                        image: FileImage(File(imagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: imagePath == null
                  ? const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 35,
                    )
                  : null,
            ),

            const SizedBox(height: 6),

            // Nombre del artista
            Text(
              artistName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
