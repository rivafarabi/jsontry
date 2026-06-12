import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
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
  JsonNode? _selectedNode;
  final ScrollController _scrollController = ScrollController();
  final SearchController _searchController = SearchController();
  final double _estimatedItemHeight = 26;

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
  JsonNode? get selectedNode => _selectedNode;

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

  void handleContextMenuAction(String action, JsonNode node) {
    switch (action) {
      case 'Copy Key':
        if (node.key != null) {
          Clipboard.setData(ClipboardData(text: node.key!));
        }
        break;
      case 'Copy Value':
      case 'Formatted Value':
        String valueText;
        if (node.type == JsonNodeType.object || node.type == JsonNodeType.array) {
          valueText = const JsonEncoder.withIndent('  ').convert(_nodeToPlainValue(node));
        } else if (node.type == JsonNodeType.string) {
          valueText = node.value.toString();
        } else {
          valueText = node.value.toString();
        }
        Clipboard.setData(ClipboardData(text: valueText));
        break;
      case 'Minified Value':
        String minifiedValue;
        if (node.type == JsonNodeType.object || node.type == JsonNodeType.array) {
          minifiedValue = jsonEncode(_nodeToPlainValue(node));
        } else {
          minifiedValue = node.value.toString();
        }
        Clipboard.setData(ClipboardData(text: minifiedValue));
        break;
      case 'Copy Path':
        Clipboard.setData(ClipboardData(text: node.path));
        break;
      case 'Expand':
      case 'Collapse':
        toggleNode(node.path);
        break;
    }
  }

  /// Reconstructs a plain Map/List/scalar from a node's subtree, for clipboard export.
  dynamic _nodeToPlainValue(JsonNode node) {
    switch (node.type) {
      case JsonNodeType.object:
        return {for (final child in node.children!) child.key!: _nodeToPlainValue(child)};
      case JsonNodeType.array:
        return node.children!.map(_nodeToPlainValue).toList();
      default:
        return node.value;
    }
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

  List<JsonNode> _parseJsonToNodes(dynamic json, {String? parentKey, int depth = 0, JsonNode? parent}) {
    List<JsonNode> nodes = [];

    if (json is Map<String, dynamic>) {
      // For objects, create a node for the object itself
      if (parentKey != null) {
        final node = JsonNode(
          key: parentKey,
          value: null,
          type: JsonNodeType.object,
          depth: depth,
          parent: parent,
        );
        node.children = _parseObjectChildren(json, depth + 1, node);
        nodes.add(node);
      } else {
        // Root object
        nodes.addAll(_parseObjectChildren(json, depth, parent));
      }
    } else if (json is List) {
      // For arrays
      if (parentKey != null) {
        final node = JsonNode(
          key: parentKey,
          value: null,
          type: JsonNodeType.array,
          depth: depth,
          parent: parent,
        );
        node.children = _parseArrayChildren(json, depth + 1, node);
        nodes.add(node);
      } else {
        // Root array
        nodes.addAll(_parseArrayChildren(json, depth, parent));
      }
    } else {
      // Primitive values
      nodes.add(_createPrimitiveNode(parentKey, json, depth, parent));
    }

    return nodes;
  }

  List<JsonNode> _parseObjectChildren(Map<String, dynamic> obj, int depth, JsonNode? parent) {
    List<JsonNode> children = [];
    obj.forEach((key, value) {
      children.addAll(_parseJsonToNodes(value, parentKey: key, depth: depth, parent: parent));
    });
    return children;
  }

  List<JsonNode> _parseArrayChildren(List list, int depth, JsonNode? parent) {
    List<JsonNode> children = [];
    for (int i = 0; i < list.length; i++) {
      children.addAll(_parseJsonToNodes(list[i], parentKey: '[$i]', depth: depth, parent: parent));
    }
    return children;
  }

  JsonNode _createPrimitiveNode(String? key, dynamic value, int depth, JsonNode? parent) {
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
      parent: parent,
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

  void selectNode(JsonNode node) {
    if (_selectedNode?.path == node.path) return;

    _selectedNode?.isSelected = false;
    node.isSelected = true;
    _selectedNode = node;

    notifyListeners();
  }

  void toggleNode(String path, {bool skipFlatten = false}) {
    _toggleNodeExpansion(_nodes, path);

    if (!skipFlatten) {
      _flattenNodes = _getFlattenNodes(_nodes);
    }

    notifyListeners();
  }

  /// Mutates the expansion state of the node at [targetPath] in place. Returns
  /// true once the node is found, so the search can stop early.
  bool _toggleNodeExpansion(List<JsonNode> nodes, String targetPath, {bool? forceExpand}) {
    for (final node in nodes) {
      if (node.path == targetPath) {
        node.isExpanded = forceExpand ?? !node.isExpanded;
        return true;
      } else if (node.children != null && targetPath.startsWith(node.path)) {
        // Only traverse children if the target path could be in this subtree
        if (_toggleNodeExpansion(node.children!, targetPath, forceExpand: forceExpand)) {
          return true;
        }
      }
    }
    return false;
  }

  void expandAll() {
    if (_nodes.isEmpty) return;

    _setExpansionRecursive(_nodes, true);
    _flattenNodes = _getFlattenNodes(_nodes);

    notifyListeners();
  }

  void collapseAll() {
    if (_nodes.isEmpty) return;

    _setExpansionRecursive(_nodes, false);
    _flattenNodes = _getFlattenNodes(_nodes);

    notifyListeners();
  }

  void _setExpansionRecursive(List<JsonNode> nodes, bool expanded) {
    for (final node in nodes) {
      if (node.children != null && node.children!.isNotEmpty) {
        node.isExpanded = expanded;
        _setExpansionRecursive(node.children!, expanded);
      }
    }
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
    for (final node in nodes) {
      if (pathsToExpand.contains(node.path)) {
        node.isExpanded = true;
      }

      if (node.children != null) {
        // Only traverse children if any target path starts with this node's path
        bool hasChildTargets = pathsToExpand.any((path) => path.startsWith(node.path) && path.length > node.path.length);

        if (hasChildTargets) {
          expandPathsBatch(node.children!, pathsToExpand);
        }
      }
    }

    return nodes;
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

    for (final node in nodes) {
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
