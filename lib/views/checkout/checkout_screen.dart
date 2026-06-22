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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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
        totalVnd: cartVm.total,
        itemName: 'Đơn hàng Luxura',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading indicator
      }

      if (paymentData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể kết nối tới cổng thanh toán payOS. Vui lòng thử lại.'),
              backgroundColor: AppTheme.accentRose,
            ),
          );
        }
        return;
      }

      final checkoutUrl = paymentData['checkoutUrl'] as String;
      final amountVnd = paymentData['amount'] as int;
      final qrCodeText = paymentData['qrCode'] as String? ?? '';
      final accountNumber = paymentData['accountNumber'] as String? ?? '';
      final accountName = paymentData['accountName'] as String? ?? '';
      final bin = paymentData['bin'] as String? ?? '';
      final description = paymentData['description'] as String? ?? '';

      // Tên ngân hàng dựa trên mã BIN của Việt Nam
      String getBankName(String binCode) {
        final binMap = {
          '970415': 'VietinBank',
          '970436': 'Vietcombank',
          '970418': 'BIDV',
          '970405': 'Agribank',
          '970422': 'MBBank',
          '970407': 'Techcombank',
          '970416': 'ACB',
          '970432': 'VPBank',
          '970423': 'TPBank',
          '970403': 'Sacombank',
          '970437': 'HDBank',
          '970441': 'VIB',
          '970443': 'SHB',
          '970448': 'OCB',
          '970449': 'LPBank',
        };
        return binMap[binCode] ?? 'Ngân hàng thụ hưởng (BIN: $binCode)';
      }

      final bankName = getBankName(bin);

      // 3. Show the payment status polling dialog (In-App QR Dialog)
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
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); // Close this polling dialog
                }
                if (mounted) {
                  _completeOrder(cartVm, notifVm, orderCode);
                }
              }
            });

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryNeon, AppTheme.primaryNeon.withOpacity(0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thanh toán Đơn hàng',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Quét mã QR qua ứng dụng Ngân hàng',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // QR Image Container (White background is mandatory for QR readers)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: qrCodeText.isNotEmpty
                                    ? Image.network(
                                        'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(qrCodeText)}',
                                        width: 180,
                                        height: 180,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const SizedBox(
                                            width: 180,
                                            height: 180,
                                            child: Center(
                                              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const SizedBox(
                                            width: 180,
                                            height: 180,
                                            child: Center(
                                              child: Icon(Icons.broken_image_outlined, color: AppTheme.accentRose, size: 48),
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox(
                                        width: 180,
                                        height: 180,
                                        child: Center(
                                          child: Text('Không tìm thấy mã QR', style: TextStyle(color: Colors.black)),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 18),

                              // Amount display
                              Text(
                                AppTheme.formatVnd(amountVnd.toDouble()),
                                style: const TextStyle(
                                  color: AppTheme.secondaryTeal,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Detail Card with copy buttons
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Column(
                                  children: [
                                    _buildTransferDetailRow(
                                      label: 'Ngân hàng',
                                      value: bankName,
                                      showCopy: false,
                                    ),
                                    const Divider(color: Colors.white10, height: 16),
                                    _buildTransferDetailRow(
                                      label: 'Số tài khoản',
                                      value: accountNumber,
                                      showCopy: true,
                                    ),
                                    const Divider(color: Colors.white10, height: 16),
                                    _buildTransferDetailRow(
                                      label: 'Chủ tài khoản',
                                      value: accountName,
                                      showCopy: false,
                                    ),
                                    const Divider(color: Colors.white10, height: 16),
                                    _buildTransferDetailRow(
                                      label: 'Nội dung CK',
                                      value: description,
                                      showCopy: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Status Loader
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.secondaryTeal,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Đang tự động kiểm tra trạng thái thanh toán...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Actions row
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppTheme.accentRose),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        pollingTimer?.cancel();
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Đã hủy giao dịch thanh toán.'),
                                            backgroundColor: AppTheme.accentRose,
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'HỦY GIAO DỊCH',
                                        style: TextStyle(
                                          color: AppTheme.accentRose,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.secondaryTeal,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final status = await _payosService.getPaymentStatus(orderCode);
                                        if (!dialogContext.mounted) return;
                                        if (status == 'PAID') {
                                          pollingTimer?.cancel();
                                          Navigator.pop(dialogContext);
                                          if (mounted) {
                                            _completeOrder(cartVm, notifVm, orderCode);
                                          }
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Thanh toán đang chờ xử lý...'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text(
                                        'KIỂM TRA LẠI',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Alternative link
                              TextButton(
                                onPressed: () async {
                                  final uri = Uri.parse(checkoutUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Không thể mở liên kết trình duyệt.'),
                                          backgroundColor: AppTheme.accentRose,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  'Mở trang thanh toán trên trình duyệt web',
                                  style: TextStyle(
                                    color: AppTheme.primaryNeon.withOpacity(0.9),
                                    fontSize: 11,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
      cardHolder: _nameController.text.trim(),
      cardNumber: 'SĐT: ${_phoneController.text.trim()} (payOS-$orderCode)',
    );

    if (order != null) {
      await notifVm.addNotification(
        'Đơn hàng đã đặt qua payOS!',
        'Đơn hàng ${order.id} đã được xác nhận thanh toán thành công qua payOS. Tổng tiền: ${AppTheme.formatVnd(order.total)}',
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
                  'Đơn hàng đã xác nhận!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mã đơn hàng: ${order.id}\nMã giao dịch payOS: $orderCode',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Quay thẳng về màn hình gốc (Dashboard chính chứa tab Cửa hàng)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('QUAY LẠI CỬA HÀNG'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Widget _buildTransferDetailRow({
    required String label,
    required String value,
    required bool showCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textMain,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            softWrap: true,
          ),
        ),
        if (showCopy) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép $label!'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppTheme.secondaryTeal,
                ),
              );
            },
            child: const Icon(
              Icons.copy,
              size: 16,
              color: AppTheme.secondaryTeal,
            ),
          ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = Provider.of<CartViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('T H A N H  T O Á N'),
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
                'Địa chỉ giao hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Số 150 Đường Bạch Đằng, Quận Hải Châu, Đà Nẵng',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ giao hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Thông tin nhận hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              const SizedBox(height: 12),

              // Recipient Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Họ và tên người nhận',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên người nhận';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Recipient Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(
                  hintText: 'Số điện thoại nhận hàng',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại nhận hàng';
                  }
                  if (value.trim().length < 9) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

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
                    const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      AppTheme.formatVnd(cartVm.total),
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
                child: const Text('ĐẶT HÀNG'),
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
