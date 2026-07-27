import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/checkout_session_model.dart';
import '../providers/payment_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  CheckoutSessionModel? _session;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Checkout',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Stripe test payment',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Cards are entered only on Stripe Checkout in test mode. FitTrack stores only Stripe IDs and payment status.',
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          PrimaryButton(
            label: _session == null ? 'Create test payment' : 'Recreate session',
            icon: Icons.payment_outlined,
            onPressed: _isLoading ? null : _createCheckoutSession,
          ),
          if (_session != null) ...<Widget>[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Payment created',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Payment ID: ${_session!.paymentId}'),
                    Text('Status: ${_session!.status}'),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Open Stripe Checkout',
                      icon: Icons.open_in_new,
                      onPressed: _openStripeCheckout,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Confirm test payment',
                      icon: Icons.verified_outlined,
                      onPressed: _isLoading ? null : _confirmTestPayment,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_isLoading) ...<Widget>[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Future<void> _createCheckoutSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await ref
          .read(paymentApiServiceProvider)
          .createCheckoutSession();
      if (!mounted) {
        return;
      }
      setState(() => _session = session);
      ref.invalidate(paymentHistoryProvider);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openStripeCheckout() async {
    final url = _session?.checkoutUrl;
    if (url == null || url.isEmpty) {
      return;
    }

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _confirmTestPayment() async {
    final paymentId = _session?.paymentId;
    if (paymentId == null || paymentId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(paymentApiServiceProvider).confirmTestPayment(paymentId);
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(paymentHistoryProvider);

      if (mounted) {
        context.go('${AppRoutes.paymentSuccess}?paymentId=$paymentId');
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
