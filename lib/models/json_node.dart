class JsonNode {
  final String? key;
  final dynamic value;
  final JsonNodeType type;
  final int depth;
  final JsonNode? parent;
  bool isExpanded;
  bool isSelected;
  List<JsonNode>? children;

  JsonNode({
    this.key,
    required this.value,
    required this.type,
    required this.depth,
    this.parent,
    this.isExpanded = false,
    this.isSelected = false,
    this.children,
  });

  bool get isCollapsible => children != null && children!.isNotEmpty;

  /// Absolute path (e.g. "data.items[0].name"), derived by walking [parent]
  /// references rather than stored, so it doesn't cost memory per node.
  String get path {
    final segments = <String>[];
    JsonNode? node = this;
    while (node != null) {
      final key = node.key;
      if (key != null) segments.add(key);
      node = node.parent;
    }

    final buffer = StringBuffer();
    for (var i = segments.length - 1; i >= 0; i--) {
      final segment = segments[i];
      if (segment.startsWith('[')) {
        buffer.write(segment);
      } else {
        if (buffer.isNotEmpty) buffer.write('.');
        buffer.write(segment);
      }
    }
    return buffer.toString();
  }
}

enum JsonNodeType {
  object,
  array,
  string,
  number,
  boolean,
  nullValue,
}
