import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_medication/src/core/services/network_service.dart';

/// Provider for network connectivity status
final networkStatusProvider = FutureProvider<bool>((ref) async {
  return await NetworkService.hasInternetConnection();
});

/// Provider for Supabase connectivity
final supabaseConnectivityProvider = FutureProvider<bool>((ref) async {
  return await NetworkService.canReachSupabase();
});

/// Provider for detailed network status
final networkStatusDescriptionProvider = FutureProvider<String>((ref) async {
  return await NetworkService.getNetworkStatus();
});

/// Refresh trigger for network status
final networkRefreshProvider = StateProvider<int>((ref) => 0);

/// Combined network status with refresh capability
final refreshableNetworkStatusProvider = FutureProvider<String>((ref) async {
  // Watch the refresh trigger
  ref.watch(networkRefreshProvider);
  return await NetworkService.getNetworkStatus();
});
