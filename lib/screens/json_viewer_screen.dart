import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../providers/json_provider.dart';
import '../widgets/json_tree_view.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/status_bar.dart';

class JsonViewerScreen extends StatelessWidget {
  const JsonViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isMacOS) {
      return _buildMacOSLayout(context);
    } else if (UniversalPlatform.isWindows) {
      return _buildWindowsLayout(context);
    } else {
      return _buildMaterialLayout(context);
    }
  }

  Widget _buildMacOSLayout(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Open...',
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
                  onSelected: () => _openJsonFile(context),
                ),
                PlatformMenuItem(
                  label: 'Open from Clipboard...',
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyV, meta: true, shift: true),
                  onSelected: () => _openFromClipboard(context),
                ),
              ],
            ),
          ],
        ),
      ],
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
    return fluent.NavigationView(
      appBar: fluent.NavigationAppBar(
        title: const Text('JsonTry Viewer'),
        actions: fluent.Row(
          mainAxisAlignment: fluent.MainAxisAlignment.end,
          children: [
            fluent.IconButton(
              icon: const Icon(fluent.FluentIcons.folder_open),
              onPressed: () => context.read<JsonProvider>().loadJsonFile(),
            ),
          ],
        ),
      ),
      pane: fluent.NavigationPane(
        selected: 0,
        items: [
          fluent.PaneItem(
            icon: const Icon(fluent.FluentIcons.document),
            title: const Text('JSON Viewer'),
            body: _buildMainContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JsonTry Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => context.read<JsonProvider>().loadJsonFile(),
          ),
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
    if (provider.isLoading) {
      if (UniversalPlatform.isMacOS) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProgressCircle(),
              SizedBox(height: 16),
              Text('Loading JSON file...'),
            ],
          ),
        );
      } else if (UniversalPlatform.isWindows) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              fluent.ProgressRing(),
              SizedBox(height: 16),
              Text('Loading JSON file...'),
            ],
          ),
        );
      } else {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading JSON file...'),
            ],
          ),
        );
      }
    }

    if (provider.error != null) {
      if (UniversalPlatform.isMacOS) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MacosIcon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: MacosColors.systemRedColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MacosColors.systemRedColor),
              ),
              const SizedBox(height: 24),
              PushButton(
                controlSize: ControlSize.large,
                child: const Text('Try Again'),
                onPressed: () => provider.loadJsonFile(),
              ),
            ],
          ),
        );
      } else if (UniversalPlatform.isWindows) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                fluent.FluentIcons.error,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              fluent.Button(
                child: const Text('Try Again'),
                onPressed: () => provider.loadJsonFile(),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade300),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => provider.loadJsonFile(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      }
    }

    if (provider.nodes.isEmpty) {
      if (UniversalPlatform.isMacOS) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MacosIcon(
                CupertinoIcons.doc_text,
                size: 64,
                color: MacosColors.systemGrayColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'No JSON file loaded',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click the folder icon to open a JSON file',
                style: TextStyle(color: MacosColors.systemGrayColor),
              ),
              const SizedBox(height: 24),
              PushButton(
                controlSize: ControlSize.large,
                child: const Text('Open JSON File'),
                onPressed: () => provider.loadJsonFile(),
              ),
            ],
          ),
        );
      } else if (UniversalPlatform.isWindows) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                fluent.FluentIcons.document,
                size: 64,
                color: fluent.Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No JSON file loaded',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click the folder icon to open a JSON file',
                style: TextStyle(color: fluent.Colors.grey),
              ),
              const SizedBox(height: 24),
              fluent.Button(
                child: const Text('Open JSON File'),
                onPressed: () => provider.loadJsonFile(),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No JSON file loaded',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Click the folder icon to open a JSON file',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => provider.loadJsonFile(),
                icon: const Icon(Icons.folder_open),
                label: const Text('Open JSON File'),
              ),
            ],
          ),
        );
      }
    }

    return const JsonTreeView();
  }

  Future<void> _openJsonFile(BuildContext context) async {
    await context.read<JsonProvider>().loadJsonFile();
  }

  Future<void> _openFromClipboard(BuildContext context) async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        await context.read<JsonProvider>().loadJsonFromString(clipboardData.text!);
      } else {
        if (context.mounted) {
          _showErrorDialog(context, 'Clipboard is empty or does not contain text.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to read from clipboard: $e');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (UniversalPlatform.isMacOS) {
      showMacosAlertDialog(
        context: context,
        builder: (context) => MacosAlertDialog(
          appIcon: const MacosIcon(CupertinoIcons.exclamationmark_triangle),
          title: const Text('Error'),
          message: Text(message),
          primaryButton: PushButton(
            controlSize: ControlSize.large,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
