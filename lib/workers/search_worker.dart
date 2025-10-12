import 'dart:isolate';
import 'dart:async';
import '../providers/json_provider.dart';

class SearchRequest {
  final List<JsonNode> nodes;
  final String query;
  final SendPort responsePort;

  SearchRequest(this.nodes, this.query, this.responsePort);
}

class SearchResponse {
  final List<String> results;
  final String? error;

  SearchResponse(this.results, [this.error]);
}

class SearchWorker {
  late Isolate _isolate;
  late SendPort _sendPort;
  late ReceivePort _receivePort;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  Future<void> init() async {
    if (_isInitialized) return;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_searchIsolateEntryPoint, _receivePort.sendPort);
    
    // Wait for the isolate to send back its SendPort
    _sendPort = await _receivePort.first;
    _isInitialized = true;
    _initCompleter.complete();
  }

  Future<List<String>> search(List<JsonNode> nodes, String query) async {
    if (!_isInitialized) {
      await _initCompleter.future;
    }

    final responsePort = ReceivePort();
    final request = SearchRequest(nodes, query, responsePort.sendPort);
    
    _sendPort.send(request);
    
    final SearchResponse response = await responsePort.first;
    responsePort.close();
    
    if (response.error != null) {
      throw Exception('Search error: ${response.error}');
    }
    
    return response.results;
  }

  void dispose() {
    if (_isInitialized) {
      _isolate.kill(priority: Isolate.immediate);
      _receivePort.close();
    }
  }

  static void _searchIsolateEntryPoint(SendPort mainSendPort) {
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    isolateReceivePort.listen((message) {
      if (message is SearchRequest) {
        try {
          final results = _performSearch(message.nodes, message.query);
          message.responsePort.send(SearchResponse(results));
        } catch (e) {
          message.responsePort.send(SearchResponse([], e.toString()));
        }
      }
    });
  }

  static List<String> _performSearch(List<JsonNode> nodes, String query) {
    final List<String> results = [];
    _findMatchesInNodes(nodes, query.toLowerCase(), results);
    return results;
  }

  static void _findMatchesInNodes(List<JsonNode> nodes, String query, List<String> results) {
    for (final JsonNode node in nodes) {
      bool matches = false;

      // Check if key matches
      if (node.key != null && node.key!.toLowerCase().contains(query)) {
        matches = true;
      }

      // Check if value matches (for primitive values)
      if (node.type != JsonNodeType.object && node.type != JsonNodeType.array) {
        final String valueString = node.value?.toString().toLowerCase() ?? '';
        if (valueString.contains(query)) {
          matches = true;
        }
      }

      if (matches) {
        results.add(node.path);
      }

      // Check children recursively
      if (node.children != null) {
        _findMatchesInNodes(node.children!, query, results);
      }
    }
  }
}
