class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({required this.timestamp, required this.text});

  /// Parsea una línea LRC: [00:12.50]Texto de la línea
  static LyricLine? fromLRC(String line) {
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.?(\d{2})?\](.*)');
    final match = regex.firstMatch(line);

    if (match == null) return null;

    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final centiseconds = match.group(3) != null ? int.parse(match.group(3)!) : 0;
    final text = match.group(4)!.trim();

    final timestamp = Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: centiseconds * 10,
    );

    return LyricLine(timestamp: timestamp, text: text);
  }
}

class Lyrics {
  final String? plainText;
  final List<LyricLine>? syncedLines;
  final bool isSynced;

  Lyrics({
    this.plainText,
    this.syncedLines,
  }) : isSynced = syncedLines != null && syncedLines.isNotEmpty;

  /// Parsea lyrics desde formato LRC o texto plano
  static Lyrics parse(String? lyricsText) {
    if (lyricsText == null || lyricsText.isEmpty) {
      return Lyrics();
    }

    // Intentar parsear como LRC
    final lines = lyricsText.split('\n');
    final syncedLines = <LyricLine>[];

    for (var line in lines) {
      final lyricLine = LyricLine.fromLRC(line);
      if (lyricLine != null && lyricLine.text.isNotEmpty) {
        syncedLines.add(lyricLine);
      }
    }

    // Si se parsearon líneas sincronizadas, retornar como synced
    if (syncedLines.isNotEmpty) {
      return Lyrics(syncedLines: syncedLines);
    }

    // Si no, es texto plano
    return Lyrics(plainText: lyricsText);
  }

  /// Obtiene la línea actual según la posición de reproducción
  int getCurrentLineIndex(Duration position) {
    if (syncedLines == null || syncedLines!.isEmpty) return -1;

    for (int i = syncedLines!.length - 1; i >= 0; i--) {
      if (position >= syncedLines![i].timestamp) {
        return i;
      }
    }

    return -1;
  }
}
