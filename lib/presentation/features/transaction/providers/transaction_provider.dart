import 'package:badminton_app/data/models/transaction_model.dart';
import 'package:badminton_app/data/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final allTransactionsProvider =
    StreamProvider<List<TransactionModel>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);

  return repo.getAllTransactions();
});