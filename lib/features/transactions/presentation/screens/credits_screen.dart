import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/transaction_type_badge.dart';
import '../../domain/finance_transaction.dart';
import '../providers/transaction_providers.dart';
import 'credit_payment_screen.dart';

class CreditsScreen extends ConsumerStatefulWidget {
  const CreditsScreen({super.key});

  @override
  ConsumerState<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends ConsumerState<CreditsScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'all';
  _CreditSortOrder _sortOrder = _CreditSortOrder.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(creditsProvider);

    return creditsAsync.when(
      loading: () => const AppLoadingState(message: 'Memuat daftar kredit…'),
      error: (error, stackTrace) => ErrorState(
        message: 'Daftar kredit belum dapat dibuka.',
        onRetry: () => ref.invalidate(creditsProvider),
      ),
      data: (credits) => _buildContent(context, credits),
    );
  }

  Widget _buildContent(BuildContext context, List<FinanceTransaction> credits) {
    final filtered = _filterCredits(credits);
    final total = credits.fold<int>(0, (sum, item) => sum + item.amount);
    final paid = credits.fold<int>(
      0,
      (sum, item) => sum + item.creditPaidAmount,
    );
    final remaining = credits.fold<int>(
      0,
      (sum, item) => sum + item.creditRemainingAmount,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(child: AppPageHeader(title: 'Kredit')),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 760
                            ? 3
                            : constraints.maxWidth >= 480
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - ((columns - 1) * 12)) /
                            columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: width,
                              child: _CreditSummaryCard(
                                label: 'Total kredit',
                                amount: total,
                                icon: Icons.receipt_long_outlined,
                                tone: _CreditSummaryTone.info,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _CreditSummaryCard(
                                label: 'Sudah dibayar',
                                amount: paid,
                                icon: Icons.check_circle_outline_rounded,
                                tone: _CreditSummaryTone.paid,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _CreditSummaryCard(
                                label: 'Sisa tagihan',
                                amount: remaining,
                                icon: Icons.pending_actions_outlined,
                                tone: _CreditSummaryTone.remaining,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    ..._dueReminderWidgets(context, credits),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Daftar kredit',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${filtered.length} transaksi',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final search = TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Cari nama pelanggan',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Hapus pencarian',
                                    onPressed: () => setState(
                                      _searchController.clear,
                                    ),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        );
                        final sort = DropdownButtonFormField<_CreditSortOrder>(
                          initialValue: _sortOrder,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Urutkan',
                            prefixIcon: Icon(Icons.sort_rounded),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: _CreditSortOrder.newest,
                              child: Text('Terbaru'),
                            ),
                            DropdownMenuItem(
                              value: _CreditSortOrder.dueSoonest,
                              child: Text(
                                'Jatuh tempo terdekat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: _CreditSortOrder.highestRemaining,
                              child: Text('Sisa terbesar'),
                            ),
                            DropdownMenuItem(
                              value: _CreditSortOrder.lowestRemaining,
                              child: Text('Sisa terkecil'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sortOrder = value);
                            }
                          },
                        );
                        if (constraints.maxWidth < 520) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              search,
                              const SizedBox(height: 10),
                              sort,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: search),
                            const SizedBox(width: 12),
                            SizedBox(width: 240, child: sort),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('Semua', 'all'),
                        _buildFilterChip(
                          'Belum dibayar',
                          'pending',
                        ),
                        _buildFilterChip(
                          'Sebagian',
                          'partial',
                        ),
                        _buildFilterChip('Lunas', 'paid'),
                        _buildFilterChip(
                          'Jatuh tempo ≤7 hari',
                          'dueSoon',
                        ),
                        _buildFilterChip('Terlambat', 'overdue'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      EmptyState(
                        icon: Icons.credit_card_off_outlined,
                        title: credits.isEmpty
                            ? 'Belum ada transaksi kredit'
                            : 'Kredit tidak ditemukan',
                        message: credits.isEmpty
                            ? 'Transaksi pemasukan dengan metode kredit akan muncul di sini.'
                            : 'Coba ubah kata kunci atau filter yang dipilih.',
                        primaryAction: credits.isEmpty
                            ? FilledButton.icon(
                                onPressed: () => context.go(
                                  '/transactions/new?type=income',
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Catat pemasukan'),
                              )
                            : null,
                      )
                    else
                      ...filtered.map(
                        (credit) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildCreditCard(context, credit),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _dueReminderWidgets(
    BuildContext context,
    List<FinanceTransaction> credits,
  ) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final limit = start.add(const Duration(days: 7));
    final active = credits.where(
      (c) => c.creditRemainingAmount > 0 && c.creditDueDate != null,
    );
    final overdue = active
        .where((c) => c.creditDueDate!.isBefore(start))
        .toList();
    final dueSoon = active
        .where(
          (c) =>
              !c.creditDueDate!.isBefore(start) &&
              c.creditDueDate!.isBefore(limit.add(const Duration(days: 1))),
        )
        .toList();
    if (overdue.isEmpty && dueSoon.isEmpty) return const [];
    final overdueColor = context.appColors.expense;
    final dueSoonColor = context.appColors.creditPending;
    return [
      const SizedBox(height: 14),
      Card(
        color: (overdue.isNotEmpty ? overdueColor : dueSoonColor).withValues(
          alpha: .08,
        ),
        child: ExpansionTile(
          leading: Icon(
            Icons.notifications_active_outlined,
            color: overdue.isNotEmpty ? overdueColor : dueSoonColor,
          ),
          title: Text(
            '${overdue.length} terlambat · ${dueSoon.length} jatuh tempo 7 hari ini',
          ),
          subtitle: const Text('Pengingat tagihan yang masih memiliki sisa'),
          children: [
            for (final item in [...overdue, ...dueSoon])
              ListTile(
                title: Text(item.creditCustomerName ?? item.name),
                subtitle: Text(
                  '${item.name} · ${item.creditDueDate == null ? '' : AppDateFormatter.long(item.creditDueDate!)}',
                ),
                trailing: Text(
                  CurrencyFormatter.format(item.creditRemainingAmount),
                  style: TextStyle(
                    color: overdue.contains(item) ? overdueColor : dueSoonColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _buildFilterChip(String label, String status) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterStatus == status,
      onSelected: (_) => setState(() => _filterStatus = status),
    );
  }

  List<FinanceTransaction> _filterCredits(
    List<FinanceTransaction> credits,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueSoonLimit = today.add(const Duration(days: 7));
    final filtered = credits.where((credit) {
      if (query.isNotEmpty &&
          !(credit.creditCustomerName ?? '').toLowerCase().contains(query) &&
          !credit.name.toLowerCase().contains(query)) {
        return false;
      }
      return switch (_filterStatus) {
        'all' => true,
        'pending' => credit.creditStatus == CreditStatus.pending,
        'partial' => credit.creditStatus == CreditStatus.partial,
        'paid' => credit.creditStatus == CreditStatus.paid,
        'overdue' => _isOverdue(credit, today),
        'dueSoon' => _isDueSoon(credit, today, dueSoonLimit),
        _ => true,
      };
    }).toList();

    filtered.sort((left, right) {
      final comparison = switch (_sortOrder) {
        _CreditSortOrder.newest =>
          right.transactionDate.compareTo(left.transactionDate),
        _CreditSortOrder.dueSoonest => _compareDueDates(left, right),
        _CreditSortOrder.highestRemaining =>
          right.creditRemainingAmount.compareTo(left.creditRemainingAmount),
        _CreditSortOrder.lowestRemaining =>
          left.creditRemainingAmount.compareTo(right.creditRemainingAmount),
      };
      return comparison != 0
          ? comparison
          : right.createdAt.compareTo(left.createdAt);
    });
    return filtered;
  }

  bool _isOverdue(FinanceTransaction credit, DateTime today) {
    final due = credit.creditDueDate;
    if (credit.creditRemainingAmount <= 0 || due == null) return false;
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay.isBefore(today);
  }

  bool _isDueSoon(
    FinanceTransaction credit,
    DateTime today,
    DateTime limit,
  ) {
    final due = credit.creditDueDate;
    if (credit.creditRemainingAmount <= 0 || due == null) return false;
    final dueDay = DateTime(due.year, due.month, due.day);
    return !dueDay.isBefore(today) && !dueDay.isAfter(limit);
  }

  int _compareDueDates(
    FinanceTransaction left,
    FinanceTransaction right,
  ) {
    final leftOpen = left.creditRemainingAmount > 0;
    final rightOpen = right.creditRemainingAmount > 0;
    if (leftOpen != rightOpen) return leftOpen ? -1 : 1;
    final leftDue = left.creditDueDate;
    final rightDue = right.creditDueDate;
    if (leftDue == null && rightDue != null) return 1;
    if (leftDue != null && rightDue == null) return -1;
    if (leftDue == null || rightDue == null) return 0;
    final leftDay = DateTime(leftDue.year, leftDue.month, leftDue.day);
    final rightDay = DateTime(rightDue.year, rightDue.month, rightDue.day);
    return leftDay.compareTo(rightDay);
  }

  Widget _buildCreditCard(BuildContext context, FinanceTransaction credit) {
    final remaining = credit.creditRemainingAmount;
    final isPaid = credit.creditStatus == CreditStatus.paid;
    final due = credit.creditDueDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue =
        !isPaid &&
        due != null &&
        DateTime(due.year, due.month, due.day).isBefore(today);
    final color = isOverdue
        ? context.appColors.expense
        : _getStatusColor(context, credit.creditStatus);
    final paidProgress = credit.amount <= 0
        ? 0.0
        : (credit.creditPaidAmount / credit.amount).clamp(0.0, 1.0).toDouble();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          foregroundColor: color,
          child: const Icon(Icons.person_outline_rounded),
        ),
        title: Text(
          credit.creditCustomerName ?? 'Pelanggan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                credit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CreditStatusBadge(
                    status: credit.creditStatus,
                    isOverdue: isOverdue,
                  ),
                  Text(
                    'Sisa ${CurrencyFormatter.format(remaining)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: remaining == 0
                          ? context.appColors.income
                          : context.appColors.creditPending,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.centerLeft,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              final stats = [
                _CreditAmount(label: 'Total kredit', amount: credit.amount),
                _CreditAmount(
                  label: 'Sudah dibayar',
                  amount: credit.creditPaidAmount,
                ),
                _CreditAmount(
                  label: 'Sisa tagihan',
                  amount: remaining,
                  emphasized: true,
                ),
              ];
              if (compact) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: stats[0]),
                        Expanded(child: stats[1]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: stats[2])]),
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: stats[i]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: paidProgress,
              minHeight: 6,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Jatuh tempo ${AppDateFormatter.short(credit.creditDueDate ?? credit.transactionDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/transactions/${credit.id}'),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Detail transaksi'),
              ),
              if (!isPaid)
                FilledButton.icon(
                  onPressed: () => _showPaymentDialog(context, credit),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Catat pembayaran'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, CreditStatus status) {
    return switch (status) {
      CreditStatus.pending ||
      CreditStatus.partial => context.appColors.creditPending,
      CreditStatus.paid => context.appColors.income,
    };
  }

  void _showPaymentDialog(BuildContext context, FinanceTransaction credit) {
    showDialog<void>(
      context: context,
      builder: (context) => CreditPaymentDialog(transaction: credit),
    );
  }
}

enum _CreditSortOrder { newest, dueSoonest, highestRemaining, lowestRemaining }

class _CreditSummaryCard extends StatelessWidget {
  const _CreditSummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.tone,
  });

  final String label;
  final int amount;
  final IconData icon;
  final _CreditSummaryTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (background, foreground) = switch (tone) {
      _CreditSummaryTone.info => (colors.infoSurface, colors.info),
      _CreditSummaryTone.paid => (colors.incomeSurface, colors.income),
      _CreditSummaryTone.remaining => (
        colors.creditPendingSurface,
        colors.creditPending,
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color.lerp(colors.card, background, .72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foreground.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: foreground),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CreditSummaryTone { info, paid, remaining }

class _CreditAmount extends StatelessWidget {
  const _CreditAmount({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  final String label;
  final int amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 3),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            CurrencyFormatter.format(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: emphasized ? colors.creditPending : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
