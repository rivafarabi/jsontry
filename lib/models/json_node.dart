class JsonNode {
  final String? key;
  final dynamic value;
  final JsonNodeType type;
  final int depth;
  final String path;
  final bool isExpanded;
  final List<JsonNode>? children;

  JsonNode({
    this.key,
    required this.value,
    required this.type,
    required this.depth,
    required this.path,
    this.isExpanded = false,
    this.children,
  });

  JsonNode copyWith({
    String? key,
    dynamic value,
    JsonNodeType? type,
    int? depth,
    String? path,
    bool? isExpanded,
    List<JsonNode>? children,
  }) {
    return JsonNode(
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      depth: depth ?? this.depth,
      path: path ?? this.path,
      isExpanded: isExpanded ?? this.isExpanded,
      children: children ?? this.children,
    );
  }

  JsonNode withoutChildren() {
    return JsonNode(
      key: key,
      value: value,
      type: type,
      depth: depth,
      path: path,
      isExpanded: isExpanded,
    );
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
