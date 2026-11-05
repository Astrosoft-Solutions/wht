import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';

final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) => r.any((c) => c != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
});

/// Slides a "You're offline" strip in above the app when the device loses its connection.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOnlineProvider).value == false;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: offline
              ? Material(
                  color: const Color(0xFF37474F),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: Gaps.l),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text("You're offline. Changes will fail until you reconnect.",
                              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: offline, child: child),
        ),
      ],
    );
  }
}
