List<dynamic> getPathSegments(String path) {
  if (path.isEmpty) return [];
  final segments = <dynamic>[];
  final regex = RegExp(r'([^\.\[\]]+)|\[(\d+)\]');
  for (final match in regex.allMatches(path)) {
    if (match.group(1) != null) {
      segments.add(match.group(1)!);
    } else if (match.group(2) != null) {
      segments.add(int.parse(match.group(2)!));
    }
  }
  return segments;
}
