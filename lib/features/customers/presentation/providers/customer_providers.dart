import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database_provider.dart';
import '../../data/customer_repository.dart';
import '../../domain/customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepository(ref.watch(databaseProvider)),
);

final customersProvider = FutureProvider.autoDispose<List<Customer>>(
  (ref) => ref.watch(customerRepositoryProvider).getAll(),
);
