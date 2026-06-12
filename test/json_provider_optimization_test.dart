import 'package:flutter_test/flutter_test.dart';
import 'package:jsontry/models/json_node.dart';
import 'package:jsontry/providers/json_provider.dart';

void main() {
  group('JsonProvider Optimization Tests', () {
    late JsonProvider jsonProvider;

    setUp(() {
      jsonProvider = JsonProvider();
    });

    tearDown(() {
      jsonProvider.dispose();
    });

    test('collectParentPaths should collect unique parent paths', () {
      final pathsToExpand = <String>{};
      
      // Test with simple nested path
      jsonProvider.collectParentPaths('a.b.c', pathsToExpand);
      expect(pathsToExpand, contains('a'));
      expect(pathsToExpand, contains('a.b'));
      expect(pathsToExpand, hasLength(2));
      
      // Test with array notation
      pathsToExpand.clear();
      jsonProvider.collectParentPaths('users[0].name', pathsToExpand);
      expect(pathsToExpand, contains('users'));
      expect(pathsToExpand, contains('users[0]'));
      expect(pathsToExpand, hasLength(2));
    });

    test('collectParentPaths should deduplicate paths', () {
      final pathsToExpand = <String>{};
      
      // Add multiple paths with shared parents
      jsonProvider.collectParentPaths('a.b.c', pathsToExpand);
      jsonProvider.collectParentPaths('a.b.d', pathsToExpand);
      jsonProvider.collectParentPaths('a.e.f', pathsToExpand);
      
      // Should only have unique parent paths
      expect(pathsToExpand, contains('a'));
      expect(pathsToExpand, contains('a.b'));
      expect(pathsToExpand, contains('a.e'));
      expect(pathsToExpand, hasLength(3)); // a, a.b, a.e
    });

    test('expandPathsBatch should efficiently expand multiple paths', () {
      // Create a simple node structure (paths are derived from key/parent chains)
      final rootNode = JsonNode(
        key: 'root',
        value: null,
        type: JsonNodeType.object,
        depth: 1,
        isExpanded: false,
      );

      final parentNode = JsonNode(
        key: 'parent',
        value: null,
        type: JsonNodeType.object,
        depth: 2,
        isExpanded: false,
        parent: rootNode,
      );

      final grandchildNode = JsonNode(
        key: 'grandchild',
        value: 'value',
        type: JsonNodeType.string,
        depth: 3,
        parent: parentNode,
      );

      parentNode.children = [grandchildNode];
      rootNode.children = [parentNode];

      final nodes = [rootNode];
      final pathsToExpand = {'root', 'root.parent'};

      final result = jsonProvider.expandPathsBatch(nodes, pathsToExpand);

      // Root should be expanded
      expect(result.first.isExpanded, isTrue);
      expect(result.first.path, equals('root'));

      // Child (which has path root.parent) should be expanded
      final expandedChild = result.first.children!.first;
      expect(expandedChild.isExpanded, isTrue);
      expect(expandedChild.path, equals('root.parent'));
    });

    test('performance tracking fields exist', () {
      // Just verify the performance tracking fields are accessible
      expect(jsonProvider.expandedPathsCount, equals(0));
      expect(jsonProvider.lastExpansionDuration, isNull);
    });

    test('node.path is correctly derived from parent chain for nested structures', () async {
      const json = '''
      {
        "data": {
          "items": [
            {"name": "first"},
            {"name": "second"}
          ]
        },
        "topLevel": 1
      }
      ''';

      await jsonProvider.loadJsonFromString(json);
      jsonProvider.expandAll();

      final pathToNode = {for (final node in jsonProvider.nodes) node.path: node};

      expect(pathToNode['data'], isNotNull);
      expect(pathToNode['data.items'], isNotNull);
      expect(pathToNode['data.items[0]'], isNotNull);
      expect(pathToNode['data.items[0].name'], isNotNull);
      expect(pathToNode['data.items[0].name']!.value, equals('first'));
      expect(pathToNode['data.items[1].name']!.value, equals('second'));
      expect(pathToNode['topLevel'], isNotNull);
    });
  });
}