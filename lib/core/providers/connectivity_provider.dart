import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _isConnected(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  final initialResult = await connectivity.checkConnectivity();
  yield _isConnected(initialResult);

  yield* connectivity.onConnectivityChanged.map(_isConnected).distinct();
});
