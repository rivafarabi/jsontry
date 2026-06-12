import 'package:flutter/material.dart';
import 'package:jsontry/widgets/macos_platform_menu.dart';
import 'package:jsontry/widgets/windows_platform_menu.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:macos_ui/macos_ui.dart' show MacosWindow, MacosScaffold, ContentArea;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:desktop_drop/desktop_drop.dart';
import '../providers/json_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/json_tree_view.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/status_bar.dart';

class JsonViewerScreen extends StatelessWidget {
  const JsonViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget layout;
    if (UniversalPlatform.isMacOS) {
      layout = _buildMacOSLayout(context);
    } else if (UniversalPlatform.isWindows) {
      layout = _buildWindowsLayout(context);
    } else {
      layout = _buildMaterialLayout(context);
    }

    return AppThemeScope(child: layout);
  }

  Widget _buildMacOSLayout(BuildContext context) {
    return MacosPlatformMenu(
      child: MacosWindow(
        child: MacosScaffold(
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return _buildMainContent(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowsLayout(BuildContext context) {
    return WindowsPlatformMenu(
      child: fluent.NavigationView(
        content: _buildMainContent(context),
      ),
    );
  }

  Widget _buildMaterialLayout(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('JSONTry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: 'Open JSON File',
            color: AppTheme.textSecondary(isDark),
            onPressed: () => context.read<JsonProvider>().loadJsonFile(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer<JsonProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Search bar
            const SearchBarWidget(),

            // Main content area
            Expanded(
              child: _buildContentArea(context, provider),
            ),

            // Status bar
            const StatusBar(),
          ],
        );
      },
    );
  }

  Widget _buildContentArea(BuildContext context, JsonProvider provider) {
    return DropTarget(
      onDragDone: (detail) {
        final files = detail.files;
        if (files.isNotEmpty) {
          final file = files.first;
          if (file.path.toLowerCase().endsWith('.json')) {
            provider.loadJsonFromFile(file.path);
          }
        }
      },
      child: _buildContentAreaContent(context, provider),
    );
  }

  Widget _buildContentAreaContent(BuildContext context, JsonProvider provider) {
    final isDark = AppTheme.isDark(context);

    return Container(
      color: AppTheme.background(isDark),
      child: _buildContentState(context, provider, isDark),
    );
  }

  Widget _buildContentState(BuildContext context, JsonProvider provider, bool isDark) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.accent(isDark),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading JSON file...',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(isDark)),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.danger,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(isDark)),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => provider.loadJsonFile(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.nodes.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.data_object_rounded,
                size: 56,
                color: AppTheme.textTertiary(isDark),
              ),
              const SizedBox(height: 16),
              Text(
                'No JSON file loaded',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Drag and drop a JSON file here, or open one to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(isDark)),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => provider.loadJsonFile(),
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Open JSON File'),
              ),
            ],
          ),
        ),
      );
    }

    return const JsonTreeView();
  }
}
