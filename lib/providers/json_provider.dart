import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/utils/path_utils.dart';
import 'package:jsontry/utils/search_controller.dart';
import 'package:window_manager/window_manager.dart';

class JsonProvider extends ChangeNotifier {
  List<JsonNode> _nodes = [];
  List<JsonNode> _flattenNodes = [];
  int _totalNodes = 0;
  String? _lastScrolledPath;
  String _searchQuery = '';
  List<String> _searchResults = []; // Paths of matching nodes
  int _currentSearchIndex = -1;
  String? _filePath;
  String? _fileName;
  int _fileSize = 0;
  DateTime? _loadTime;
  Duration? _loadDuration;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  Timer? _searchDebounceTimer;
  final ScrollController _scrollController = ScrollController();
  final SearchController _searchController = SearchController();
  final double _estimatedItemHeight = 25;

  // Performance tracking
  int _expandedPathsCount = 0;
  Duration? _lastExpansionDuration;

  // Getters
  List<JsonNode> get nodes => _flattenNodes; // Return flattened nodes for rendering
  int get totalNodes => _totalNodes;
  ScrollController get scrollController => _scrollController;
  double get estimatedItemHeight => _estimatedItemHeight;
  String get searchQuery => _searchQuery;
  List<String> get searchResults => _searchResults;
  int get currentSearchIndex => _currentSearchIndex;
  int get searchResultsCount => _searchResults.length;
  String? get filePath => _filePath;
  String? get fileName => _fileName;
  int get fileSize => _fileSize;
  DateTime? get loadTime => _loadTime;
  Duration? get loadDuration => _loadDuration;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;

  // Performance getters
  int get expandedPathsCount => _expandedPathsCount;
  Duration? get lastExpansionDuration => _lastExpansionDuration;

  String get fileSizeFormatted {
    if (_fileSize < 1024) return '$_fileSize B';
    if (_fileSize < 1024 * 1024) return '${(_fileSize / 1024).toStringAsFixed(1)} KB';
    if (_fileSize < 1024 * 1024 * 1024) return '${(_fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(_fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get windowTitle {
    if (_fileName != null) {
      return '$_fileName - JSONTry';
    } else if (_filePath == 'Clipboard Content') {
      return 'CLIPBOARD - JSONTry';
    }
    return 'JSONTry';
  }

  /// Recursively flatten the tree structure based on expansion state
  /// This is used to provide a flat list of nodes for rendering in the tree view
  List<JsonNode> _getFlattenNodes(List<JsonNode> nodes) {
    List<JsonNode> flatList = [];

    for (var node in nodes) {
      flatList.add(node);
      if (node.isExpanded && node.children != null) {
        flatList.addAll(_getFlattenNodes(node.children!));
      }
    }

    return flatList;
  }

  Future<void> loadJsonFile() async {
    try {
      // Clear previous data first to prevent memory accumulation
      clearData();

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
        _fileName = result.files.single.name;
        _fileSize = await file.length();

        windowManager.setTitle(windowTitle);

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
      // Clear previous data first to prevent memory accumulation
      clearData();

      _isLoading = true;
      _error = null;
      _filePath = 'Clipboard Content';
      _fileName = null;
      _fileSize = jsonString.length;
      notifyListeners();

      final stopwatch = Stopwatch()..start();
      _loadTime = DateTime.now();

      final jsonData = jsonDecode(jsonString);
      _nodes = _parseJsonToNodes(jsonData);
      _flattenNodes = _getFlattenNodes(_nodes);

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

  Future<void> loadJsonFromFile(String filePath) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final file = File(filePath);
      _filePath = filePath;
      _fileName = file.path.split('/').last;
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
    } catch (e) {
      _error = 'Error loading file: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSmallJsonFile(File file) async {
    final content = await file.readAsString();
    final jsonData = jsonDecode(content);
    _nodes = _parseJsonToNodes(jsonData);
    _flattenNodes = _getFlattenNodes(_nodes);
    _totalNodes = _countTotalNodes(_nodes);
  }

  Future<void> _loadLargeJsonFile(File file) async {
    // For very large files, we implement a streaming approach
    // This is a simplified version - in a real app, you'd want to parse incrementally
    final content = await file.readAsString();

    // Parse in compute isolate to avoid blocking UI
    final jsonData = await compute(jsonDecode, content);
    _nodes = _parseJsonToNodes(jsonData);
    _flattenNodes = _getFlattenNodes(_nodes);
    _totalNodes = _countTotalNodes(_nodes);
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

  int _countTotalNodes(List<JsonNode> nodes) {
    int count = 0;
    for (JsonNode node in nodes) {
      count++;
      if (node.children != null) {
        count += _countTotalNodes(node.children!);
      }
    }
    return count;
  }

  void toggleNode(String path, {bool skipFlatten = false}) {
    _nodes = _updateNodeExpansion(_nodes, path);

    if (!skipFlatten) _flattenNodes = _getFlattenNodes(_nodes);

    notifyListeners();
  }

  List<JsonNode> _updateNodeExpansion(List<JsonNode> nodes, String targetPath, {bool? forceExpand}) {
    return nodes.map((node) {
      if (node.path == targetPath) {
        bool newExpanded = forceExpand ?? !node.isExpanded;
        return node.copyWith(isExpanded: newExpanded);
      } else if (node.children != null && targetPath.startsWith(node.path)) {
        // Only traverse children if the target path could be in this subtree
        return node.copyWith(children: _updateNodeExpansion(node.children!, targetPath, forceExpand: forceExpand));
      }
      return node;
    }).toList();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();

    // Cancel any existing timer
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      _searchResults.clear();
      _currentSearchIndex = -1;
      _isSearching = false;
      notifyListeners();
      return;
    }

    // Start loading indicator
    _isSearching = true;
    notifyListeners();

    // Set up debounced search with 500ms delay
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    try {
      final results = _searchController.search(_nodes, _searchQuery);
      _searchResults = results;
      _currentSearchIndex = results.isNotEmpty ? 0 : -1;
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearData() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    _nodes.clear();
    _flattenNodes.clear();
    _searchQuery = '';
    _searchResults.clear();
    _currentSearchIndex = -1;
    _filePath = null;
    _fileName = null;
    _fileSize = 0;
    _loadTime = null;
    _loadDuration = null;
    _isSearching = false;
    _error = null;
    _expandedPathsCount = 0;
    _lastExpansionDuration = null;
    notifyListeners();
  }

  @visibleForTesting
  void collectParentPaths(String targetPath, Set<String> pathsToExpand) {
    // Handle array notation paths like "users[0].name"
    final segments = getPathSegments(targetPath);

    // Build all parent paths (e.g., for "a.b.c" we need to expand "a" and "a.b")
    String currentPath = '';
    for (int i = 0; i < segments.length - 1; i++) {
      if (currentPath.isEmpty) {
        currentPath = segments[i].toString();
      } else {
        // Reconstruct path properly handling array indices
        if (segments[i] is int) {
          currentPath += '[${segments[i]}]';
        } else {
          currentPath += '.${segments[i]}';
        }
      }
      pathsToExpand.add(currentPath);
    }
  }

  @visibleForTesting
  List<JsonNode> expandPathsBatch(List<JsonNode> nodes, Set<String> pathsToExpand) {
    return nodes.map((node) {
      // Check if this node's path should be expanded
      bool shouldExpand = pathsToExpand.contains(node.path);

      // Process children if they exist and this path might contain targets
      List<JsonNode>? updatedChildren;
      if (node.children != null) {
        // Only traverse children if any target path starts with this node's path
        bool hasChildTargets = pathsToExpand.any((path) => path.startsWith(node.path) && path.length > node.path.length);

        if (hasChildTargets) {
          updatedChildren = expandPathsBatch(node.children!, pathsToExpand);
        } else {
          updatedChildren = node.children;
        }
      }

      // Return updated node if expansion state changed or children were updated
      if (shouldExpand && !node.isExpanded) {
        return node.copyWith(isExpanded: true, children: updatedChildren);
      } else if (updatedChildren != node.children) {
        return node.copyWith(children: updatedChildren);
      }

      return node;
    }).toList();
  }

  void nextSearchResult(BuildContext context) {
    if (_searchResults.isNotEmpty) {
      if (_currentSearchIndex < _searchResults.length - 1) {
        _currentSearchIndex++;
      } else {
        _currentSearchIndex = 0;
      }

      _scrollToCurrentSearchResult(context);
      notifyListeners();
    }
  }

  void previousSearchResult(BuildContext context) {
    if (_searchResults.isNotEmpty) {
      if (_currentSearchIndex > 0) {
        _currentSearchIndex--;
      } else {
        _currentSearchIndex = _searchResults.length - 1;
      }

      _scrollToCurrentSearchResult(context);
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

  void _scrollToCurrentSearchResult(BuildContext context) {
    final currentPath = currentSearchResultPath;
    if (currentPath != null && currentPath != _lastScrolledPath) {
      _lastScrolledPath = currentPath;

      // Find the index of the current search result in the flattened node list
      final index = _findNodeIndex(_nodes, currentPath, 0, skipFlatten: false);
      if (index != -1 && _scrollController.hasClients) {
        _flattenNodes = _getFlattenNodes(_nodes);
        // Calculate the scroll offset
        final targetOffset = index * _estimatedItemHeight - (MediaQuery.of(context).size.height / 2) + (_estimatedItemHeight * 2);
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        final clampedOffset = targetOffset.clamp(0.0, maxScrollExtent);

        // Use a slight delay to ensure the widget is fully rendered
        _scrollController.jumpTo(clampedOffset);
      }
    }
  }

  int _findNodeIndex(List<JsonNode> nodes, String targetPath, int currentIndex, {bool skipFlatten = true}) {
    final targetPathSegments = getPathSegments(targetPath);

    for (var node in nodes) {
      if (node.path == targetPath) {
        return currentIndex;
      }

      currentIndex++;

      final currentPathSegments = getPathSegments(node.path);

      if (targetPathSegments.length < currentPathSegments.length) {
        if (node.isExpanded && node.children != null) {
          currentIndex += _countVisibleChildren(node.children!);
        }

        continue;
      }

      final fragmentedPath = targetPathSegments.sublist(0, currentPathSegments.length);

      if (!listEquals(currentPathSegments, fragmentedPath)) {
        if (node.isExpanded && node.children != null) {
          currentIndex += _countVisibleChildren(node.children!);
        }

        continue;
      }

      if (!node.isExpanded && node.children != null) {
        toggleNode(node.path, skipFlatten: skipFlatten);
        node = node.copyWith(isExpanded: true);
      }

      // If node is expanded and has children, search in children
      if (node.isExpanded && node.children != null) {
        final childIndex = _findNodeIndex(node.children!, targetPath, currentIndex);
        if (childIndex != -1) {
          return childIndex;
        }
        // Add the count of visible children to the current index
        currentIndex += _countVisibleChildren(node.children!);
      }
    }
    return -1; // Not found
  }

  int _countVisibleChildren(List<JsonNode> children) {
    int count = 0;
    for (final child in children) {
      count++;
      if (child.isExpanded && child.children != null) {
        count += _countVisibleChildren(child.children!);
      }
    }
    return count;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    super.dispose();
  }
}
