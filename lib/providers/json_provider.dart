import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

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
}

enum JsonNodeType {
  object,
  array,
  string,
  number,
  boolean,
  nullValue,
}

class JsonProvider extends ChangeNotifier {
  List<JsonNode> _nodes = [];
  String _searchQuery = '';
  List<String> _searchResults = []; // Paths of matching nodes
  int _currentSearchIndex = -1;
  String? _filePath;
  int _fileSize = 0;
  DateTime? _loadTime;
  Duration? _loadDuration;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<JsonNode> get nodes => _nodes; // Always return all nodes, no filtering
  String get searchQuery => _searchQuery;
  List<String> get searchResults => _searchResults;
  int get currentSearchIndex => _currentSearchIndex;
  int get searchResultsCount => _searchResults.length;
  String? get filePath => _filePath;
  int get fileSize => _fileSize;
  DateTime? get loadTime => _loadTime;
  Duration? get loadDuration => _loadDuration;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get fileSizeFormatted {
    if (_fileSize < 1024) return '$_fileSize B';
    if (_fileSize < 1024 * 1024) return '${(_fileSize / 1024).toStringAsFixed(1)} KB';
    if (_fileSize < 1024 * 1024 * 1024) return '${(_fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(_fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> loadJsonFile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: false,
        withReadStream: true,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        _filePath = result.files.single.path;
        _fileSize = await file.length();

        final stopwatch = Stopwatch()..start();
        _loadTime = DateTime.now();

        // For large files (> 50MB), use streaming approach
        if (_fileSize > 50 * 1024 * 1024) {
          await _loadLargeJsonFile(file);
        } else {
          await _loadSmallJsonFile(file);
        }

        stopwatch.stop();
        _loadDuration = stopwatch.elapsed;

        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error loading file: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadJsonFromString(String jsonString) async {
    try {
      _isLoading = true;
      _error = null;
      _filePath = 'Clipboard Content';
      _fileSize = jsonString.length;
      notifyListeners();

      final stopwatch = Stopwatch()..start();
      _loadTime = DateTime.now();

      final jsonData = jsonDecode(jsonString);
      _nodes = _parseJsonToNodes(jsonData);

      stopwatch.stop();
      _loadDuration = stopwatch.elapsed;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error parsing JSON from clipboard: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSmallJsonFile(File file) async {
    final content = await file.readAsString();
    final jsonData = jsonDecode(content);
    _nodes = _parseJsonToNodes(jsonData);
  }

  Future<void> _loadLargeJsonFile(File file) async {
    // For very large files, we implement a streaming approach
    // This is a simplified version - in a real app, you'd want to parse incrementally
    final content = await file.readAsString();

    // Parse in compute isolate to avoid blocking UI
    final jsonData = await compute(_parseJsonInIsolate, content);
    _nodes = _parseJsonToNodes(jsonData);
  }

  static dynamic _parseJsonInIsolate(String content) {
    return jsonDecode(content);
  }

  List<JsonNode> _parseJsonToNodes(dynamic json, {String? parentKey, int depth = 0, String path = ''}) {
    List<JsonNode> nodes = [];

    if (json is Map<String, dynamic>) {
      // For objects, create a node for the object itself
      if (parentKey != null) {
        nodes.add(JsonNode(
          key: parentKey,
          value: json,
          type: JsonNodeType.object,
          depth: depth,
          path: path,
          children: _parseObjectChildren(json, depth + 1, path),
        ));
      } else {
        // Root object
        nodes.addAll(_parseObjectChildren(json, depth, path));
      }
    } else if (json is List) {
      // For arrays
      if (parentKey != null) {
        nodes.add(JsonNode(
          key: parentKey,
          value: json,
          type: JsonNodeType.array,
          depth: depth,
          path: path,
          children: _parseArrayChildren(json, depth + 1, path),
        ));
      } else {
        // Root array
        nodes.addAll(_parseArrayChildren(json, depth, path));
      }
    } else {
      // Primitive values
      nodes.add(_createPrimitiveNode(parentKey, json, depth, path));
    }

    return nodes;
  }

  List<JsonNode> _parseObjectChildren(Map<String, dynamic> obj, int depth, String parentPath) {
    List<JsonNode> children = [];
    obj.forEach((key, value) {
      final currentPath = parentPath.isEmpty ? key : '$parentPath.$key';
      children.addAll(_parseJsonToNodes(value, parentKey: key, depth: depth, path: currentPath));
    });
    return children;
  }

  List<JsonNode> _parseArrayChildren(List list, int depth, String parentPath) {
    List<JsonNode> children = [];
    for (int i = 0; i < list.length; i++) {
      final currentPath = '$parentPath[$i]';
      children.addAll(_parseJsonToNodes(list[i], parentKey: '[$i]', depth: depth, path: currentPath));
    }
    return children;
  }

  JsonNode _createPrimitiveNode(String? key, dynamic value, int depth, String path) {
    JsonNodeType type;
    if (value == null) {
      type = JsonNodeType.nullValue;
    } else if (value is String) {
      type = JsonNodeType.string;
    } else if (value is num) {
      type = JsonNodeType.number;
    } else if (value is bool) {
      type = JsonNodeType.boolean;
    } else {
      type = JsonNodeType.string; // fallback
    }

    return JsonNode(
      key: key,
      value: value,
      type: type,
      depth: depth,
      path: path,
    );
  }

  void toggleNode(String path) {
    _nodes = _updateNodeExpansion(_nodes, path);
    notifyListeners();
  }

  List<JsonNode> _updateNodeExpansion(List<JsonNode> nodes, String targetPath, {bool? forceExpand}) {
    return nodes.map((node) {
      if (node.path == targetPath) {
        bool newExpanded = forceExpand ?? !node.isExpanded;
        return node.copyWith(isExpanded: newExpanded);
      } else if (node.children != null) {
        return node.copyWith(children: _updateNodeExpansion(node.children!, targetPath, forceExpand: forceExpand));
      }
      return node;
    }).toList();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _searchResults.clear();
    _currentSearchIndex = -1;

    if (_searchQuery.isNotEmpty) {
      _findMatches(_nodes);
      if (_searchResults.isNotEmpty) {
        _currentSearchIndex = 0;
        // Expand all paths that contain search matches
        _expandSearchPaths();
      }
    }
    notifyListeners();
  }

  void _findMatches(List<JsonNode> nodes) {
    for (JsonNode node in nodes) {
      bool matches = false;

      // Check if key matches
      if (node.key != null && node.key!.toLowerCase().contains(_searchQuery)) {
        matches = true;
      }

      // Check if value matches (for primitive values)
      if (node.type != JsonNodeType.object && node.type != JsonNodeType.array) {
        String valueString = node.value?.toString().toLowerCase() ?? '';
        if (valueString.contains(_searchQuery)) {
          matches = true;
        }
      }

      if (matches) {
        _searchResults.add(node.path);
      }

      // Check children recursively
      if (node.children != null) {
        _findMatches(node.children!);
      }
    }
  }

  void _expandSearchPaths() {
    for (String path in _searchResults) {
      _expandParentPaths(path);
    }
  }

  void _expandParentPaths(String targetPath) {
    // Extract all parent paths from the target path
    List<String> pathSegments = [];
    List<String> segments = targetPath.split('.');

    // Build all parent paths (e.g., for "a.b.c" we need to expand "a" and "a.b")
    String currentPath = '';
    for (int i = 0; i < segments.length - 1; i++) {
      if (currentPath.isEmpty) {
        currentPath = segments[i];
      } else {
        currentPath += '.${segments[i]}';
      }
      pathSegments.add(currentPath);
    }

    // Expand all parent paths
    for (String parentPath in pathSegments) {
      _nodes = _updateNodeExpansion(_nodes, parentPath, forceExpand: true);
    }
  }

  void nextSearchResult() {
    if (_searchResults.isNotEmpty && _currentSearchIndex < _searchResults.length - 1) {
      _currentSearchIndex++;
      notifyListeners();
    }
  }

  void previousSearchResult() {
    if (_searchResults.isNotEmpty && _currentSearchIndex > 0) {
      _currentSearchIndex--;
      notifyListeners();
    }
  }

  String? get currentSearchResultPath {
    if (_currentSearchIndex >= 0 && _currentSearchIndex < _searchResults.length) {
      return _searchResults[_currentSearchIndex];
    }
    return null;
  }

  bool isSearchMatch(String nodePath) {
    return _searchResults.contains(nodePath);
  }

  bool isCurrentSearchResult(String nodePath) {
    return currentSearchResultPath == nodePath;
  }

  void clearData() {
    _nodes.clear();
    _searchQuery = '';
    _filePath = null;
    _fileSize = 0;
    _loadTime = null;
    _loadDuration = null;
    _error = null;
    notifyListeners();
  }
}
