class JsonNode {
  final String? key;
  final dynamic value;
  final JsonNodeType type;
  final int depth;
  final String path;
  final bool isExpanded;
  final bool isSelected;
  final List<JsonNode>? children;

  JsonNode({
    this.key,
    required this.value,
    required this.type,
    required this.depth,
    required this.path,
    this.isExpanded = false,
    this.isSelected = false,
    this.children,
  });

  bool get isCollapsible {
    if (type == JsonNodeType.object) {
      return value is Map<String, dynamic> && (value as Map<String, dynamic>).isNotEmpty;
    } else if (type == JsonNodeType.array) {
      return value is List && (value as List).isNotEmpty;
    } else {
      return false;
    }
  }

  JsonNode copyWith({
    String? key,
    dynamic value,
    JsonNodeType? type,
    int? depth,
    String? path,
    bool? isExpanded,
    bool? isSelected,
    List<JsonNode>? children,
  }) {
    return JsonNode(
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      depth: depth ?? this.depth,
      path: path ?? this.path,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
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
