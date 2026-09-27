import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:bhart/services/supabase_service.dart';
import 'package:bhart/screens/home_screen.dart';
import 'package:bhart/screens/login_screen.dart';
import 'package:bhart/screens/merchant/merchant_dashboard.dart';
import 'package:bhart/screens/merchant/merchant_alerts.dart';
import 'package:bhart/screens/buyer/buyer_feed.dart';

/// Notifies GoRouter whenever Supabase's auth state changes (sign in, sign
/// out, token refresh, session expiry) so the `redirect` callback below gets
/// re-evaluated even when nothing calls context.go() directly — e.g. if a
/// session silently expires while the user is sitting on /merchant.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Mirrors the Next.js app/ routes:
///   /                -> Home
///   /login           -> LoginPage
///   /merchant         -> MerchantDashboard (guarded, like merchant/layout.tsx useEffect)
///   /merchant/alerts  -> MarketAlerts
///   /buyer            -> BuyerFeed
final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(SupabaseService.client.auth.onAuthStateChange),
  redirect: (context, state) {
    final loggedIn = SupabaseService.currentSession != null;
    final goingToMerchant = state.matchedLocation.startsWith('/merchant');
    final goingToLogin = state.matchedLocation == '/login';

    // Same guard as merchant/layout.tsx: no session -> bounce to /login
    if (goingToMerchant && !loggedIn) return '/login';
    // Optional nicety: already logged in and hitting /login -> skip straight to /merchant
    if (goingToLogin && loggedIn) return '/merchant';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/merchant', builder: (context, state) => const MerchantDashboard()),
    GoRoute(path: '/merchant/alerts', builder: (context, state) => const MerchantAlerts()),
    GoRoute(path: '/buyer', builder: (context, state) => const BuyerFeed()),
  ],
);