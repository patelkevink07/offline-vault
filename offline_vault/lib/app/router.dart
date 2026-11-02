import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/auth_repository.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/gallery/presentation/gallery_screen.dart';
import '../features/groups/presentation/groups_home_screen.dart';
import '../features/groups/presentation/join_group_screen.dart';
import '../features/members/presentation/members_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/sync_centre/presentation/sync_centre_screen.dart';
import '../features/upload/presentation/upload_screen.dart';
import '../features/viewer/presentation/viewer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;

      final isLoggingIn = state.matchedLocation == '/sign-in';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!hasCompletedOnboarding) {
        return isOnboarding ? null : '/onboarding';
      }

      final isOfflineGuest = prefs.getBool('offline_guest_mode') ?? false;
      if (isOfflineGuest) {
        authRepo.setGuest(true);
      }

      final isAuthenticated = authRepo.isAuthenticated;

      if (!isAuthenticated && !isLoggingIn) {
        return '/sign-in';
      }

      if (isAuthenticated && (isLoggingIn || isOnboarding)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const GroupsHomeScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/group/:groupId',
        builder: (context, state) => GalleryScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/group/:groupId/folder/:folderId',
        builder: (context, state) => GalleryScreen(
          groupId: state.pathParameters['groupId']!,
          folderId: state.pathParameters['folderId'],
        ),
      ),
      GoRoute(
        path: '/group/:groupId/upload',
        builder: (context, state) => UploadScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/group/:groupId/members',
        builder: (context, state) => MembersScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/viewer/:fileId',
        builder: (context, state) => FileViewerScreen(
          fileId: state.pathParameters['fileId']!,
          groupId: state.uri.queryParameters['groupId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/sync',
        builder: (context, state) => const SyncCentreScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
