import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:prm_project/services/payos_service.dart';
import 'package:prm_project/viewmodels/cart_viewmodel.dart';
import 'package:prm_project/viewmodels/notification_viewmodel.dart';
import 'package:prm_project/views/theme/theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PayosService _payosService = PayosService();
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _holderController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _holderController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _submitCheckout() async {
    if (_formKey.currentState!.validate()) {
      final cartVm = Provider.of<CartViewModel>(context, listen: false);
      final notifVm = Provider.of<NotificationViewModel>(context, listen: false);

      // 1. Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryNeon),
        ),
      );

      // Generate a unique order code for payOS (must be integer, e.g. using seconds from epoch)
      final orderCode = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 2. Call payOS to create payment link
      final paymentData = await _payosService.createPaymentLink(
        orderCode: orderCode,
        totalUsd: cartVm.total,
        itemName: 'Luxura Store Goods',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading indicator
      }

      if (paymentData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to payOS Payment Gateway. Please try again.'),
              backgroundColor: AppTheme.accentRose,
            ),
          );
        }
        return;
      }

      final checkoutUrl = paymentData['checkoutUrl'] as String;
      final amountVnd = paymentData['amount'] as int;

      // 3. Launch the checkout URL in external browser
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the payment page. Please copy the checkout URL.'),
              backgroundColor: AppTheme.accentRose,
            ),
          );
        }
        return;
      }

      // 4. Show the payment status polling dialog
      Timer? pollingTimer;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            // Start the periodic timer to query payOS database
            pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
              final status = await _payosService.getPaymentStatus(orderCode);
              if (status == 'PAID') {
                timer.cancel();
                Navigator.pop(dialogContext); // Close this polling dialog
                _completeOrder(cartVm, notifVm, orderCode);
              }
            });

            final formattedVnd = amountVnd.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},'
            );

            return AlertDialog(
              backgroundColor: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: AppTheme.secondaryTeal),
                  SizedBox(width: 8),
                  Text('payOS QR Checkout', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(color: AppTheme.secondaryTeal),
                  const SizedBox(height: 24),
                  Text(
                    '$formattedVnd VND',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.secondaryTeal),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please complete the transaction in your opened browser window. We are checking the payment status automatically...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () async {
                      // Manual status check click
                      final status = await _payosService.getPaymentStatus(orderCode);
                      if (status == 'PAID') {
                        pollingTimer?.cancel();
                        Navigator.pop(dialogContext);
                        _completeOrder(cartVm, notifVm, orderCode);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment is still pending...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: const Text('CHECK PAYMENT STATUS', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    pollingTimer?.cancel();
                    Navigator.pop(dialogContext); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment cancelled by user.'),
                        backgroundColor: AppTheme.accentRose,
                      ),
                    );
                  },
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.accentRose)),
                ),
              ],
            );
          },
        ).then((_) {
          pollingTimer?.cancel();
        });
      }
    }
  }

  void _completeOrder(CartViewModel cartVm, NotificationViewModel notifVm, int orderCode) async {
    final order = await cartVm.checkout(
      shippingAddress: _addressController.text.trim(),
      cardHolder: _holderController.text.trim(),
      cardNumber: 'payOS-$orderCode',
    );

    if (order != null) {
      await notifVm.addNotification(
        'Order Placed via payOS!',
        'Your payment for order ${order.id} was confirmed via payOS. Total: \$${order.total.toStringAsFixed(2)}',
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: AppTheme.darkSurface,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.secondaryTeal,
                  child: Icon(Icons.check, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order Confirmed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Order ID: ${order.id}\npayOS Ref: $orderCode',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close checkout
                  },
                  child: const Text('BACK TO SHOP'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = Provider.of<CartViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('C H E C K O U T'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Summary section
              const Text(
                'Shipping Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '123 Main Street, Hoan Kiem District, Hanoi',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a shipping address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Payment Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              // Card Holder Name
              TextFormField(
                controller: _holderController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'CARDHOLDER NAME',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Cardholder name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Card Number
              TextFormField(
                controller: _cardController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  CardNumberFormatter(),
                ],
                decoration: const InputDecoration(
                  hintText: '0000 0000 0000 0000',
                  prefixIcon: Icon(Icons.credit_card_outlined, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Credit card number is required';
                  }
                  if (value.replaceAll(' ', '').length != 16) {
                    return 'Please enter a valid 16-digit card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Expiry Date & CVV Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        CardExpiryFormatter(),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'MM/YY',
                        prefixIcon: Icon(Icons.date_range, color: AppTheme.textMuted),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.length != 5) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'CVV',
                        prefixIcon: Icon(Icons.security, color: AppTheme.textMuted),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.length != 3) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Order Total preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '\$${cartVm.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.secondaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitCheckout,
                child: const Text('PLACE ORDER'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Formatters for inputs
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
