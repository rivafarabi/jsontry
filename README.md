# JSONTry Viewer

JSONTry (pronounced "jay-son-tree") is an experimental JSON viewer application built with Flutter for macOS and Windows. Its primary goal is to benchmark Flutter's performance when handling large JSON data files, making it a valuable tool for developers interested in high-performance desktop applications. JSONTry serves as an alternative to Dadroit JSON Viewer, with some parts of the code "vibe coded" for rapid prototyping and creative solutions.

## Features

### 🚀 Performance
- **Large File Support**: Optimized for JSON files up to 1GB+ with streaming and compute isolate processing
- **Lazy Loading**: Tree nodes are loaded on-demand for better memory efficiency
- **Search (WIP)**: Real-time search across keys and values with highlighting (work in progress)

### 🎨 Modern UI
- **Native Look**: Uses native UI components for macOS and Windows
- **Dark/Light Theme**: Automatic theme detection and support

### 🔍 Advanced Features
- **Tree View**: Hierarchical display of JSON structure with expand/collapse
- **Context Menu**: Right-click to copy keys, values, or paths
- **Search**: Filter JSON nodes by key or value
- **Type Indicators**: Visual badges showing data types (Object, Array, String, Number, etc.)
- **Performance Metrics**: Shows file size, load time, and node count

## Installation

### Prerequisites
- Flutter SDK (>=3.4.0)
- For macOS: Xcode and macOS 10.15+
- For Windows: Visual Studio with C++ tools

### Build Instructions

1. Install dependencies:
```bash
flutter pub get
```

2. Build for your platform:

**macOS:**
```bash
flutter build macos --release
```

**Windows:**
```bash
flutter build windows --release
```

3. Run the application (debug):
```bash
flutter run -d macos  # For macOS
flutter run -d windows  # For Windows
```

## Usage

1. **Open JSON File**: Click the folder icon in the toolbar or use the "Open JSON File" button
2. **Navigate**: Click expand/collapse icons to explore the JSON structure
3. **Search**: Use the search bar to filter nodes by key or value
4. **Copy Data**: Right-click any node to copy its key, value, or path
5. **View Status**: Check the status bar for file information and performance metrics

## Performance Features

### Large File Handling
- Files >50MB are processed using compute isolates to prevent UI blocking
- Streaming approach for very large files
- Memory-efficient tree node structure

### Search Optimization
- Real-time filtering with debouncing
- Efficient string matching algorithms
- Maintains tree structure during search

### UI Performance
- Virtual scrolling for large datasets
- Lazy loading of tree nodes
- Optimized rendering with Flutter's widget tree

