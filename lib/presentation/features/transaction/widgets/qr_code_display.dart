import 'package:flutter/material.dart';

/// Widget hiển thị ảnh QR từ VietQR API
class QrCodeDisplay extends StatelessWidget {
  final String bankId;
  final String accountNo;
  final String accountName;
  final int amount;
  final String transferContent;

  const QrCodeDisplay({
    super.key,
    required this.bankId,
    required this.accountNo,
    required this.accountName,
    required this.amount,
    required this.transferContent,
  });

  String get _qrUrl {
    final encodedContent = Uri.encodeComponent(transferContent);
    final encodedName = Uri.encodeComponent(accountName);
    return 'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png'
        '?amount=$amount'
        '&addInfo=$encodedContent'
        '&accountName=$encodedName';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bank info row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bankId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '$accountNo · $accountName',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // QR Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _qrUrl,
              width: 240,
              height: 300,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: 240,
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 12),
                        const Text('Đang tải mã QR...',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return SizedBox(
                  width: 240,
                  height: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'Không tải được QR.\nVui lòng kiểm tra kết nối.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          Text(
            'Quét mã bằng app ngân hàng bất kỳ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
