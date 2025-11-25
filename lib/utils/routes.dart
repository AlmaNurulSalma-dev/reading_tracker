import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/screens/screens.dart';
import 'package:reading_tracker/services/auth_service.dart';

/// Route path constants for type-safe navigation.
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';

  // Main app routes (with bottom nav)
  static const String dashboard = '/';
  static const String library = '/library';
  static const String logReading = '/log-reading';
  static const String statistics = '/statistics';

  // Detail routes (without bottom nav)
  static const String bookDetail = '/book/:bookId';
  static const String addBook = '/library/add';

  /// Generate book detail path with ID.
  static String bookDetailPath(String bookId) => '/book/$bookId';
}

/// Navigation shell index for bottom navigation.
enum NavTab {
  dashboard(0),
  library(1),
  logReading(2),
  statistics(3);

  final int index;
  const NavTab(this.index);

  static NavTab fromIndex(int index) {
    return NavTab.values.firstWhere(
      (tab) => tab.index == index,
      orElse: () => NavTab.dashboard,
    );
  }

  static NavTab fromLocation(String location) {
    if (location.startsWith('/library')) return NavTab.library;
    if (location.startsWith('/log-reading')) return NavTab.logReading;
    if (location.startsWith('/statistics')) return NavTab.statistics;
    return NavTab.dashboard;
  }
}

/// Global navigator keys for nested navigation.
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// App router configuration with go_router.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    refreshListenable: AuthService.instance,
    redirect: _handleRedirect,
    routes: [
      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const _SplashScreen(),
      ),

      // Auth routes (outside shell)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignUpScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationShell(child: child);
        },
        routes: [
          // Dashboard tab
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),

          // Library tab
          GoRoute(
            path: AppRoutes.library,
            name: 'library',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const LibraryScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),

          // Log Reading tab
          GoRoute(
            path: AppRoutes.logReading,
            name: 'logReading',
            pageBuilder: (context, state) {
              final book = state.extra as Book?;
              return CustomTransitionPage(
                key: state.pageKey,
                child: LogReadingScreen(initialBook: book),
                transitionsBuilder: _fadeTransition,
              );
            },
          ),

          // Statistics tab
          GoRoute(
            path: AppRoutes.statistics,
            name: 'statistics',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const StatisticsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),

      // Book detail (outside shell - full screen)
      GoRoute(
        path: AppRoutes.bookDetail,
        name: 'bookDetail',
        pageBuilder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final book = state.extra as Book?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: _BookDetailWrapper(bookId: bookId, book: book),
            transitionsBuilder: _slideLeftTransition,
          );
        },
      ),

      // Add book (outside shell - full screen)
      GoRoute(
        path: AppRoutes.addBook,
        name: 'addBook',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddBookScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );

  /// Handle authentication redirects.
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = AuthService.instance.isAuthenticated;
    final isLoggingIn = state.matchedLocation == AppRoutes.login;
    final isSigningUp = state.matchedLocation == AppRoutes.signup;
    final isSplash = state.matchedLocation == AppRoutes.splash;

    // If not logged in and trying to access protected route
    if (!isLoggedIn && !isLoggingIn && !isSigningUp && !isSplash) {
      return AppRoutes.login;
    }

    // If logged in and trying to access auth routes
    if (isLoggedIn && (isLoggingIn || isSigningUp)) {
      return AppRoutes.dashboard;
    }

    return null;
  }

  // ============ TRANSITION ANIMATIONS ============

  /// Fade transition for tab switches.
  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
      child: child,
    );
  }

  /// Slide from right transition for detail screens.
  static Widget _slideLeftTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)).animate(animation),
      child: child,
    );
  }

  /// Slide from bottom transition for modals.
  static Widget _slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Scale transition for special screens.
  static Widget _scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

/// Wrapper for BookDetailScreen that handles loading book by ID.
class _BookDetailWrapper extends StatelessWidget {
  final String bookId;
  final Book? book;

  const _BookDetailWrapper({
    required this.bookId,
    this.book,
  });

  @override
  Widget build(BuildContext context) {
    // If book was passed via extra, use it directly
    if (book != null) {
      return BookDetailScreen(book: book!);
    }

    // Otherwise, we would need to fetch the book by ID
    // For now, show error if book not passed
    return Scaffold(
      appBar: AppBar(title: const Text('Book Detail')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Book not found: $bookId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.library),
              child: const Text('Go to Library'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen for invalid routes.
class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'The page you are looking for does not exist.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Splash screen shown while checking auth state.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Main navigation shell with bottom navigation bar.
class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentTab = NavTab.fromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab.index,
        onDestinationSelected: (index) => _onTabSelected(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Log Reading',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }

  void _onTabSelected(BuildContext context, int index) {
    final tab = NavTab.fromIndex(index);

    switch (tab) {
      case NavTab.dashboard:
        context.go(AppRoutes.dashboard);
        break;
      case NavTab.library:
        context.go(AppRoutes.library);
        break;
      case NavTab.logReading:
        context.go(AppRoutes.logReading);
        break;
      case NavTab.statistics:
        context.go(AppRoutes.statistics);
        break;
    }
  }
}

/// Extension methods for easier navigation.
extension GoRouterExtension on BuildContext {
  /// Navigate to book detail screen.
  void goToBookDetail(Book book) {
    go(AppRoutes.bookDetailPath(book.id), extra: book);
  }

  /// Navigate to log reading with optional book.
  void goToLogReading([Book? book]) {
    go(AppRoutes.logReading, extra: book);
  }

  /// Push log reading screen (allows back navigation and returns result).
  Future<T?> pushLogReading<T extends Object?>([Book? book]) {
    return push<T>(AppRoutes.logReading, extra: book);
  }

  /// Navigate to add book screen.
  void goToAddBook() {
    go(AppRoutes.addBook);
  }

  /// Navigate to library.
  void goToLibrary() {
    go(AppRoutes.library);
  }

  /// Navigate to dashboard.
  void goToDashboard() {
    go(AppRoutes.dashboard);
  }

  /// Navigate to statistics.
  void goToStatistics() {
    go(AppRoutes.statistics);
  }

  /// Push book detail screen (allows back navigation).
  void pushBookDetail(Book book) {
    push(AppRoutes.bookDetailPath(book.id), extra: book);
  }

  /// Push add book screen.
  void pushAddBook() {
    push(AppRoutes.addBook);
  }
}
