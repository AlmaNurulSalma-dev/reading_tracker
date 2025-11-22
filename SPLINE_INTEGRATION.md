# Spline 3D Integration Guide

This document explains how to create, export, and integrate Spline 3D scenes into the Reading Tracker app.

## Overview

The Reading Tracker app uses [Spline](https://spline.design) to display interactive 3D elements, primarily the bookshelf header on the dashboard. Spline allows you to create stunning 3D scenes that can be embedded directly in Flutter apps.

## Package Setup

The app uses the `spline_flutter` package which is already configured in `pubspec.yaml`:

```yaml
dependencies:
  spline_flutter: ^0.0.2
```

## Creating a Spline Scene

### Step 1: Design Your Scene

1. Go to [Spline](https://spline.design) and create a free account
2. Create a new project
3. Design your 3D bookshelf scene

### Recommended Scene Structure for Bookshelf

```
Scene
├── Camera (positioned to view bookshelf)
├── Lighting
│   ├── Ambient Light (soft, pastel tones)
│   └── Directional Light (subtle shadows)
├── Bookshelf
│   ├── Shelf_1
│   ├── Shelf_2
│   └── Shelf_3
├── Books (group)
│   ├── Book_1 (interactive)
│   ├── Book_2 (interactive)
│   ├── Book_3 (interactive)
│   └── ... more books
└── Background (gradient or solid color)
```

### Design Tips

1. **Use Pastel Colors** - Match the app's color palette:
   - Primary Pink: `#F7CFD8`
   - Secondary Yellow: `#F4F8D3`
   - Tertiary Teal: `#A6D6D6`
   - Accent Purple: `#8E7DBE`

2. **Keep It Simple** - Complex scenes may affect performance on mobile devices

3. **Optimize Meshes** - Use low-poly models for better performance

4. **Set Up Camera** - Position camera to show the bookshelf from a pleasing angle

## Adding Interactivity

### Mouse/Touch Events

1. Select an object (e.g., a book)
2. Go to the Events panel
3. Add events:
   - **Mouse Down** - When user taps
   - **Mouse Hover** - When user hovers (desktop)
   - **Mouse Up** - When user releases tap

### Variables

Create variables in Spline to control scene state:

1. Open the Variables panel
2. Add variables:
   - `bookCount` (Number) - Number of books to display
   - `highlightedBook` (Number) - Currently highlighted book index
   - `animationProgress` (Number) - For custom animations

### States

Use states to create different scene configurations:

1. **Default** - Normal bookshelf view
2. **Highlighted** - A book is selected
3. **Empty** - No books (for new users)

## Exporting Your Scene

### Method 1: Cloud Export (Recommended for Development)

1. Click **Export** in Spline
2. Select **Web Content**
3. Choose **Public URL**
4. Copy the URL (format: `https://prod.spline.design/xxxxx/scene.splinecode`)

Use in Flutter:
```dart
SplineBookshelf.fromUrl(
  url: 'https://prod.spline.design/xxxxx/scene.splinecode',
  height: 200,
)
```

### Method 2: Local Asset Export (Recommended for Production)

1. Click **Export** in Spline
2. Select **Code Export**
3. Download the `.splinecode` file
4. Place it in `assets/spline/` directory
5. Run `flutter pub get` to update assets

Use in Flutter:
```dart
SplineBookshelf.fromAsset(
  assetPath: 'assets/spline/bookshelf.splinecode',
  height: 200,
)
```

## Integration in Flutter

### Basic Usage

```dart
import 'package:reading_tracker/widgets/widgets.dart';

// In your widget build method:
SplineBookshelf(
  height: 200,
  splineUrl: 'https://prod.spline.design/xxxxx/scene.splinecode',
  onSceneLoaded: () {
    print('3D scene loaded!');
  },
  onError: (error) {
    print('Failed to load scene: $error');
  },
)
```

### With Local Asset

```dart
SplineBookshelf(
  height: 200,
  splineAsset: 'assets/spline/bookshelf.splinecode',
  showLoadingIndicator: true,
)
```

### Using Placeholder (Default)

While developing or if Spline scene is not ready:

```dart
SplineBookshelf(
  height: 200,
  usePlaceholder: true, // Shows 2D fallback
)
```

### Custom Placeholder

```dart
SplineBookshelf(
  height: 200,
  usePlaceholder: true,
  customPlaceholder: Container(
    color: Colors.blue,
    child: Center(child: Text('Custom Placeholder')),
  ),
)
```

## Interacting with the Scene

### Using SplineBookshelfController

```dart
class _MyWidgetState extends State<MyWidget> {
  final _controller = SplineBookshelfController();

  void _highlightBook(int index) {
    _controller.setVariable('highlightedBook', index);
    _controller.triggerEvent('highlight', 'Book_$index');
  }

  @override
  Widget build(BuildContext context) {
    return SplineBookshelf(
      splineUrl: '...',
      onSceneLoaded: () {
        // Controller is ready to use
      },
    );
  }
}
```

### Triggering Events

```dart
// Trigger a mouse down event on a book
_controller.triggerEvent('mouseDown', 'Book_1');

// Trigger hover effect
_controller.triggerEvent('mouseHover', 'Book_2');
```

### Setting Variables

```dart
// Update book count display
_controller.setVariable('bookCount', 5);

// Set animation progress
_controller.setVariable('animationProgress', 0.5);
```

## Dashboard Integration

The dashboard uses `SplineBookshelf` as the header. To enable the real 3D scene:

1. Export your Spline scene
2. Update `dashboard_screen.dart`:

```dart
// Replace placeholder with actual Spline scene
Widget _buildSplineHeader() {
  return SplineBookshelf(
    height: 200,
    splineUrl: 'YOUR_SPLINE_URL_HERE',
    // Or use local asset:
    // splineAsset: 'assets/spline/bookshelf.splinecode',
    usePlaceholder: false,
    onBookTap: (bookIndex) {
      // Navigate to book detail
      _navigateToBook(bookIndex);
    },
  );
}
```

## Performance Optimization

### Mobile Performance Tips

1. **Reduce Polygon Count** - Keep meshes under 10,000 polygons total
2. **Limit Animations** - Use simple animations, avoid complex physics
3. **Optimize Textures** - Use compressed textures, max 1024x1024
4. **Reduce Lights** - Use 1-2 lights maximum
5. **Disable Shadows** - Or use simple shadow maps

### Loading Strategy

```dart
// Lazy load Spline scene
SplineBookshelf(
  splineUrl: '...',
  showLoadingIndicator: true,
  onSceneLoaded: () {
    // Hide any skeleton loaders
    setState(() => _sceneReady = true);
  },
)
```

## Troubleshooting

### Scene Not Loading

1. Check internet connection (for cloud URLs)
2. Verify URL is correct and public
3. Check asset path is correct in pubspec.yaml
4. Run `flutter clean && flutter pub get`

### Performance Issues

1. Reduce scene complexity
2. Lower texture resolution
3. Disable unnecessary animations
4. Test on target device early

### Black Screen

1. Ensure camera is positioned correctly in Spline
2. Check lighting setup
3. Verify objects are visible to camera

### Touch Events Not Working

1. Ensure events are configured in Spline
2. Check object names match exactly
3. Verify event type (mouseDown vs click)

## File Structure

```
reading_tracker/
├── assets/
│   └── spline/
│       ├── bookshelf.splinecode     # Main bookshelf scene
│       ├── single_book.splinecode   # Individual book (optional)
│       └── README.md                # Asset documentation
├── lib/
│   └── widgets/
│       └── spline_bookshelf.dart    # Spline widget wrapper
└── SPLINE_INTEGRATION.md            # This file
```

## Resources

- [Spline Official Documentation](https://docs.spline.design/)
- [spline_flutter Package](https://pub.dev/packages/spline_flutter)
- [Spline YouTube Tutorials](https://www.youtube.com/@spaboratory)
- [Spline Community](https://community.spline.design/)

## Example Scenes

For inspiration, check out these community Spline scenes:

1. **Bookshelf Scene** - Search "bookshelf" on Spline community
2. **Library Scene** - Search "library" for more elaborate setups
3. **Book Animation** - Search "book" for animated book openings

## Support

If you encounter issues:

1. Check this documentation first
2. Review Spline's official docs
3. Test with the placeholder to isolate issues
4. Check Flutter console for error messages
