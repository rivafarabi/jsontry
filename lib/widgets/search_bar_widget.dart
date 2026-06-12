import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/json_provider.dart';
import '../utils/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  void _onSubmitted(String value) {
    final provider = context.read<JsonProvider>();

    // If the query is unchanged from the last search, Enter jumps to the next result
    if (value.isNotEmpty && value.toLowerCase() == provider.searchQuery && provider.searchResultsCount > 0) {
      provider.nextSearchResult();
      return;
    }

    if (value.length >= 3 || value.isEmpty) {
      context.read<JsonProvider>().search(value);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Consumer<JsonProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surface(isDark),
            border: Border(
              bottom: BorderSide(color: AppTheme.border(isDark)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      _onSubmitted(_searchController.text);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary(isDark)),
                    decoration: InputDecoration(
                      hintText: 'Search keys and values (min 3 characters)...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.textSecondary(isDark)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                      suffixIconConstraints: const BoxConstraints(minHeight: 30),
                      suffixIcon: provider.isSearching
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: FittedBox(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    color: AppTheme.accent(isDark),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      if (value.length >= 3 || value.isEmpty) {
                        provider.search(value);
                      }
                    },
                    onSubmitted: _onSubmitted,
                  ),
                ),
              ),
              if (provider.searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant(isDark),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    provider.searchResultsCount > 0 ? '${provider.currentSearchIndex + 1}/${provider.searchResultsCount}' : '0/0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(isDark),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                _SearchIconButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  tooltip: 'Previous match',
                  onPressed: provider.searchResultsCount > 0 ? () => provider.previousSearchResult() : null,
                  isDark: isDark,
                ),
                _SearchIconButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  tooltip: 'Next match',
                  onPressed: provider.searchResultsCount > 0 ? () => provider.nextSearchResult() : null,
                  isDark: isDark,
                ),
                _SearchIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    provider.search('');
                  },
                  isDark: isDark,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SearchIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isDark;

  const _SearchIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      color: AppTheme.textSecondary(isDark),
      disabledColor: AppTheme.textTertiary(isDark).withValues(alpha: 0.4),
    );
  }
}
