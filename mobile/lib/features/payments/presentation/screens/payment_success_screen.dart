import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/payment_providers.dart';

class PaymentSuccessScreen extends ConsumerWidget {
  const PaymentSuccessScreen({
    required this.paymentId,
    super.key,
  });

  final String? paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = paymentId == null
        ? null
        : ref.watch(paymentStatusProvider(paymentId!));

    return AppScreen(
      title: 'Payment success',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Icon(Icons.check_circle_outline, size: 72),
          const SizedBox(height: 16),
          Text(
            'Premium activated',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Your test payment was confirmed successfully.'),
          const SizedBox(height: 20),
          if (payment != null)
            payment.when(
              data: (value) => Card(
                child: ListTile(
                  title: Text(value.amountLabel),
                  subtitle: Text('Status: ${value.status}'),
                  trailing: Text(value.mode),
                ),
              ),
              error: (error, stackTrace) => Text(error.toString()),
              loading: () => const LinearProgressIndicator(),
            ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Payment history',
            icon: Icons.receipt_long_outlined,
            onPressed: () => context.go(AppRoutes.payments),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Back to Premium',
            icon: Icons.workspace_premium_outlined,
            onPressed: () => context.go(AppRoutes.premium),
          ),
        ],
      ),
    );
  }
}
