import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_screen.dart';
import '../providers/payment_providers.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(paymentHistoryProvider);

    return AppScreen(
      title: 'Payment history',
      child: payments.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No payments yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final payment = items[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(payment.amountLabel),
                  subtitle: Text(
                    '${payment.plan} - ${payment.provider} ${payment.mode}',
                  ),
                  trailing: _StatusChip(status: payment.status),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status),
      avatar: Icon(
        status == 'succeeded'
            ? Icons.check_circle_outline
            : Icons.pending_outlined,
        size: 18,
      ),
    );
  }
}
