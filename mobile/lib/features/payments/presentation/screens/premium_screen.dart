import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/subscription_plan_model.dart';
import '../providers/payment_providers.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(subscriptionPlansProvider);
    final subscription = ref.watch(currentSubscriptionProvider);

    return AppScreen(
      title: 'Premium',
      actions: <Widget>[
        IconButton(
          tooltip: 'Payment history',
          onPressed: () => context.go(AppRoutes.payments),
          icon: const Icon(Icons.receipt_long_outlined),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'FitTrack Premium',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          subscription.when(
            data: (value) => Text(
              value.isPremium
                  ? 'Current plan: Premium (${value.status})'
                  : 'Current plan: Free',
            ),
            error: (error, stackTrace) => Text(error.toString()),
            loading: () => const LinearProgressIndicator(),
          ),
          const SizedBox(height: 20),
          plans.when(
            data: (items) => Column(
              children: items
                  .map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanCard(plan: plan),
                    ),
                  )
                  .toList(growable: false),
            ),
            error: (error, stackTrace) => Text(error.toString()),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final SubscriptionPlanModel plan;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.code == 'premium';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(plan.priceLabel),
              ],
            ),
            const SizedBox(height: 12),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            if (isPremium) ...<Widget>[
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Start test checkout',
                icon: Icons.workspace_premium_outlined,
                onPressed: () => context.go(AppRoutes.checkout),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
