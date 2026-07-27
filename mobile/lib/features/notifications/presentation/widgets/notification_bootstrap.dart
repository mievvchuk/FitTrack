import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/notification_providers.dart';

class NotificationBootstrap extends ConsumerStatefulWidget {
  const NotificationBootstrap({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState
    extends ConsumerState<NotificationBootstrap> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (authState.status == AuthStatus.authenticated && !_initialized) {
      _initialized = true;
      Future<void>.microtask(() async {
        try {
          await ref.read(fcmNotificationServiceProvider).initialize();
        } catch (_) {
          _initialized = false;
        }
      });
    }

    if (authState.status == AuthStatus.unauthenticated) {
      _initialized = false;
    }

    return widget.child;
  }
}
