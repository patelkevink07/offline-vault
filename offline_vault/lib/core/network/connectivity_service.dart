import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides reactive connectivity state monitoring.
///
/// Wraps [connectivity_plus] to give a clean API for checking whether
/// the device is online, on Wi-Fi, or on mobile data.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Stream that emits whenever the connectivity state changes.
  Stream<ConnectivityState> get stateChanges {
    return _connectivity.onConnectivityChanged.map(_mapResults);
  }

  /// One-shot check of the current connectivity state.
  Future<ConnectivityState> currentState() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }

  /// Whether the device currently has any network connection.
  Future<bool> get isOnline async {
    final state = await currentState();
    return state.isOnline;
  }

  /// Whether the device is connected via Wi-Fi.
  Future<bool> get isWifi async {
    final state = await currentState();
    return state.isWifi;
  }

  /// Whether the device is connected via mobile data.
  Future<bool> get isMobileData async {
    final state = await currentState();
    return state.isMobile;
  }

  ConnectivityState _mapResults(List<ConnectivityResult> results) {
    final hasWifi = results.contains(ConnectivityResult.wifi);
    final hasMobile = results.contains(ConnectivityResult.mobile);
    final hasEthernet = results.contains(ConnectivityResult.ethernet);
    final hasVpn = results.contains(ConnectivityResult.vpn);

    if (hasWifi || hasEthernet) {
      return ConnectivityState.wifi;
    } else if (hasMobile) {
      return ConnectivityState.mobile;
    } else if (hasVpn) {
      return ConnectivityState.wifi;
    } else {
      return ConnectivityState.offline;
    }
  }
}

/// Simplified connectivity state for the app.
enum ConnectivityState {
  /// Connected via Wi-Fi or Ethernet.
  wifi,

  /// Connected via mobile/cellular data.
  mobile,

  /// No network connection available.
  offline;

  /// Whether the device has any network connection.
  bool get isOnline => this != offline;

  /// Whether the connection is Wi-Fi or Ethernet.
  bool get isWifi => this == wifi;

  /// Whether the connection is mobile/cellular.
  bool get isMobile => this == mobile;
}

/// Riverpod provider for [ConnectivityService].
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Riverpod provider that streams the current [ConnectivityState].
final connectivityStateProvider = StreamProvider<ConnectivityState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.stateChanges;
});
