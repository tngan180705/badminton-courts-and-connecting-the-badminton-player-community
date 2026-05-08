import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/payment_info_card.dart';
import '../widgets/qr_code_display.dart';
import '../widgets/transfer_content_box.dart';

// ─── Hằng số ngân hàng ────────────────────────────────────────────────────────
const _kBankId = 'MB';
const _kAccountNo = '0566699305';
const _kAccountName = 'Nguyen Thanh Thien Ngan';

// ─── Utility: loại bỏ dấu tiếng Việt ────────────────────────────────────────
String removeVietnameseDiacritics(String text) {
  const src =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  const dst =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
      'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
  String result = text;
  for (int i = 0; i < src.length; i++) {
    result = result.replaceAll(src[i], dst[i]);
  }
  return result.toUpperCase();
}

String buildTransferContent({
  required String fullName,
  required String paymentType,
  required String subCourtName,
  required String startTime,
  required String formattedDate,
}) {
  final name = removeVietnameseDiacritics(fullName);
  final action = paymentType == 'deposit' ? 'COC' : 'TT';
  // Lấy phần cuối tên sân (bỏ "Sân " nếu có) để nội dung gọn hơn
  final court = removeVietnameseDiacritics(subCourtName)
      .replaceAll('SAN ', '')
      .trim();
  // Ngày dạng DDMMYYYY gọn cho nội dung CK
  final dateParts = formattedDate.split('/');
  final shortDate = dateParts.length == 3
      ? '${dateParts[0]}${dateParts[1]}${dateParts[2].substring(2)}'
      : formattedDate.replaceAll('/', '');
  return '$name $action DAT SAN $court LUC ${startTime.replaceAll(':', 'h')} $shortDate';
}

// Main Screen
class VietQRPaymentScreen extends ConsumerStatefulWidget {
  final String paymentType; // 'trả hết' | 'đặt cọc'
  final double totalAmount;
  final double payAmount;
  final String courtName;
  final String subCourtName;
  final String formattedDate;
  final String startTime;
  final String endTime;
  final String fullName;
  final Future<void> Function() onPaymentConfirmed;

  const VietQRPaymentScreen({
    super.key,
    required this.paymentType,
    required this.totalAmount,
    required this.payAmount,
    required this.courtName,
    required this.subCourtName,
    required this.formattedDate,
    required this.startTime,
    required this.endTime,
    required this.fullName,
    required this.onPaymentConfirmed,
  });

  @override
  ConsumerState<VietQRPaymentScreen> createState() =>
      _VietQRPaymentScreenState();
}

class _VietQRPaymentScreenState extends ConsumerState<VietQRPaymentScreen> {
  bool _isLoading = false;
  bool _isConfirmed = false;

  late final String _transferContent;

  @override
  void initState() {
    super.initState();
    _transferContent = buildTransferContent(
      fullName: widget.fullName,
      paymentType: widget.paymentType,
      subCourtName: widget.subCourtName,
      startTime: widget.startTime,
      formattedDate: widget.formattedDate,
    );
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      await widget.onPaymentConfirmed();
      if (mounted) setState(() => _isConfirmed = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.paymentType == 'deposit'
              ? 'Đặt cọc 30%'
              : 'Thanh toán toàn bộ',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isConfirmed ? _buildSuccessState() : _buildPaymentContent(),
    );
  }

  // ── Màn hình chờ xác nhận (sau khi bấm "Tôi đã chuyển khoản") ──────────────
  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_top_rounded,
                size: 64,
                color: Colors.orange[600],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chờ Xác Nhận Thanh Toán',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D3142),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Yêu cầu đặt sân của bạn đã được ghi nhận.\n'
              'Admin sẽ xác nhận sau khi nhận được chuyển khoản.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Chi tiết đơn
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _successInfoRow('Sân',
                      '${widget.courtName} – ${widget.subCourtName}'),
                  _successInfoRow('Ngày', widget.formattedDate),
                  _successInfoRow(
                      'Giờ', '${widget.startTime} – ${widget.endTime}'),
                  _successInfoRow('Nội dung CK', _transferContent),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Pop về màn hình gốc (BookingDetailScreen đã pop trước đó)
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text(
                  'Về trang chủ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _successInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nội dung thanh toán chính 
  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Card thông tin đặt sân
          PaymentInfoCard(
            paymentType: widget.paymentType,
            courtName: widget.courtName,
            subCourtName: widget.subCourtName,
            formattedDate: widget.formattedDate,
            startTime: widget.startTime,
            endTime: widget.endTime,
            totalAmount: widget.totalAmount,
            payAmount: widget.payAmount,
          ),
          const SizedBox(height: 16),

          // 2. Nội dung chuyển khoản (copy được)
          TransferContentBox(content: _transferContent),
          const SizedBox(height: 16),

          // 3. Mã QR
          QrCodeDisplay(
            bankId: _kBankId,
            accountNo: _kAccountNo,
            accountName: _kAccountName,
            amount: widget.payAmount.toInt(),
            transferContent: _transferContent,
          ),
          const SizedBox(height: 16),

          // 4. Hướng dẫn
          _buildInstructionCard(),
          const SizedBox(height: 24),

          // 5. Nút xác nhận
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber[700]),
              const SizedBox(width: 6),
              Text(
                'Hướng dẫn chuyển khoản',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            '1. Mở app ngân hàng → Quét QR hoặc nhập STK thủ công',
            '2. Kiểm tra số tiền đúng với yêu cầu',
            '3. Nhập đúng nội dung chuyển khoản (bấm Copy để sao chép)',
            '4. Xác nhận chuyển khoản thành công',
            '5. Bấm "Tôi đã chuyển khoản" bên dưới',
          ].map(
            (step) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                step,
                style: TextStyle(fontSize: 12, color: Colors.amber[900]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Tôi đã chuyển khoản ✓',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
