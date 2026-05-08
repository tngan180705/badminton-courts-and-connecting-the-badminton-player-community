import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});
