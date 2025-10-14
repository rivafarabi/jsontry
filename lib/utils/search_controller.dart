import 'package:jsontry/models/json_node.dart';

class SearchController {
  List<String> search(List<JsonNode> nodes, String query) {
    if (query.length < 2) return [];

    final results = <String>[];
    final lowerQuery = query.toLowerCase();

    // Use a simple iterative approach instead of building indexes
    _searchInNodes(nodes, lowerQuery, results);

    return results;
  }

  void _searchInNodes(List<JsonNode> nodes, String query, List<String> results) {
    for (final node in nodes) {
      // Check if key or value matches
      bool matches = false;

      // Check key match
      if (node.key?.toLowerCase().contains(query) ?? false) {
        matches = true;
      }

      // Check value match (for primitives only to avoid memory overhead)
      if (!matches && node.type != JsonNodeType.object && node.type != JsonNodeType.array) {
        if (node.value.toString().toLowerCase().contains(query)) {
          matches = true;
        }
      }

      if (matches) {
        results.add(node.path);
      }

      // Recursively search children without building indexes
      if (node.children != null) {
        _searchInNodes(node.children!, query, results);
      }
    }
  }

  void clear() {
    // No memory structures to clear in this simple implementation
  }
}
