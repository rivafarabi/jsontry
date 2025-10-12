import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../providers/json_provider.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  void _onSubmitted(String value) {
    if (value.length >= 3 || value.isEmpty) {
      if (UniversalPlatform.isMacOS) {
        Provider.of<JsonProvider>(context, listen: false).search(value);
      } else {
        context.read<JsonProvider>().search(value);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isMacOS) {
      return _buildMacOSSearchBar(context);
    } else if (UniversalPlatform.isWindows) {
      return _buildWindowsSearchBar(context);
    } else {
      return _buildMaterialSearchBar(context);
    }
  }

  Widget _buildMacOSSearchBar(BuildContext context) {
    return Consumer<JsonProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: MacosTheme.of(context).canvasColor,
            border: Border(
              bottom: BorderSide(
                color: MacosTheme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: MacosSearchField(
                  maxLines: 1,
                  placeholder: 'Search keys and values (min 3 characters)...',
                  onChanged: (value) {
                    if (value.length >= 3 || value.isEmpty) {
                      provider.search(value);
                    }
                  },
                  controller: _searchController,
                ),
              ),
              const SizedBox(width: 8),
              if (provider.searchQuery.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    provider.searchResultsCount > 0 ? '${provider.currentSearchIndex + 1}/${provider.searchResultsCount}' : '0/0',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 4),
                MacosIconButton(
                  icon: const MacosIcon(CupertinoIcons.chevron_up),
                  onPressed: provider.searchResultsCount > 0 ? () => provider.previousSearchResult(context) : null,
                ),
                MacosIconButton(
                  icon: const MacosIcon(CupertinoIcons.chevron_down),
                  onPressed: provider.searchResultsCount > 0 ? () => provider.nextSearchResult(context) : null,
                ),
                const SizedBox(width: 4),
                MacosIconButton(
                  icon: const MacosIcon(CupertinoIcons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.search('');
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWindowsSearchBar(BuildContext context) {
    return Consumer<JsonProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: fluent.FluentTheme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: fluent.TextBox(
                  controller: _searchController,
                  placeholder: 'Search keys and values (min 3 characters)...',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(fluent.FluentIcons.search),
                  ),
                  suffix: context.read<JsonProvider>().isSearching ? const fluent.ProgressRing() : null,
                  onSubmitted: _onSubmitted,
                ),
              ),
              if (provider.searchQuery.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    provider.searchResultsCount > 0 ? '${provider.currentSearchIndex + 1}/${provider.searchResultsCount}' : '0/0',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 4),
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.chevron_up),
                  onPressed: provider.searchResultsCount > 0 ? () => provider.previousSearchResult(context) : null,
                ),
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.chevron_down),
                  onPressed: provider.searchResultsCount > 0 ? () => provider.nextSearchResult(context) : null,
                ),
                const SizedBox(width: 4),
                const SizedBox(width: 8),
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<JsonProvider>().search('');
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaterialSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search keys and values (min 3 characters)...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  if (value.length >= 3 || value.isEmpty) {
                    context.read<JsonProvider>().search(value);
                  }
                },
                onSubmitted: _onSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.clear,
                size: 18,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                _searchController.clear();
                context.read<JsonProvider>().search('');
              },
            ),
          ),
        ],
      ),
    );
  }
}
