// lib/widgets/offline_indicator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod/offline_cache_provider.dart';

class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityStatusProvider);
    final pendingSyncCount = ref.watch(pendingSyncItemsCountProvider);

    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text(
            'You\'re offline',
            style: TextStyle(color: Colors.orange[700], fontSize: 12),
          ),
          const Spacer(),
          pendingSyncCount.when(
            data: (count) => count > 0 
                ? Text(
                    '$count pending sync',
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}