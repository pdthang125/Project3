import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/expense_transaction.dart';
import '../../../presentation/providers/expense_providers.dart';
import '../../../presentation/widgets/charts/donut_chart.dart';
import '../../../presentation/widgets/charts/bar_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Khi số transaction thay đổi (thêm/xóa) → cuộn về đầu trang
    ref.listen<AsyncValue<List<ExpenseTransaction>>>(
      transactionsProvider,
          (prev, next) {
        final prevLen = prev?.valueOrNull?.length;
        final nextLen = next.valueOrNull?.length;
        if (nextLen != null && prevLen != nextLen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          });
        }
      },
    );

    final transactionsAsync = ref.watch(transactionsProvider);
    final categoryTotalsAsync = ref.watch(categoryTotalsProvider);
    final weeklyAsync = ref.watch(weeklySpendingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── App Bar ───────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.backgroundDark,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Dashboard',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.backgroundDark, AppColors.backgroundCard],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: () {
                  ref.invalidate(transactionsProvider);
                  ref.invalidate(categoryTotalsProvider);
                  ref.invalidate(weeklySpendingProvider);
                },
              ),
            ],
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ─── Total Summary Card ────────────────────────────────────────
          SliverToBoxAdapter(
            child: transactionsAsync.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (txns) => _TotalSummaryCard(
                totalAmount: txns.fold(0.0, (s, t) => s + t.totalAmount),
                transactionCount: txns.length,
              ),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ─── Donut Chart Card ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: categoryTotalsAsync.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (data) => data.isEmpty
                  ? const _EmptyCard(message: 'No category data yet')
                  : _DonutChartCard(categoryTotals: data),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ─── Bar Chart Card ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: weeklyAsync.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (data) => _BarChartCard(weeklyData: data),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _TotalSummaryCard extends StatelessWidget {
  final double totalAmount;
  final int transactionCount;

  const _TotalSummaryCard({
    required this.totalAmount,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    // Dùng dạng rút gọn khi số tiền quá lớn tránh chữ bị co quá nhỏ
    final amountText = totalAmount >= 1e10
        ? CurrencyFormatter.formatVNDShort(totalAmount)
        : CurrencyFormatter.formatVND(totalAmount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(80),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total Spending',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Gap(8),
              // FittedBox trong SizedBox infinite-width để co chữ thay vì tràn
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amountText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  const Icon(Icons.receipt, color: Colors.white70, size: 16),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      '$transactionCount receipts scanned',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chart Cards ─────────────────────────────────────────────────────────────

class _DonutChartCard extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const _DonutChartCard({required this.categoryTotals});

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals.values.fold(0.0, (s, v) => s + v);

    return _DashCard(
      title: 'Spending by Category',
      icon: Icons.pie_chart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          AnimatedDonutChart(
            data: categoryTotals,
            size: 200,
            strokeWidth: 32,
            centerLabel: 'Total',
            centerValue: total,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChartLegend(data: categoryTotals),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<double> weeklyData;

  const _BarChartCard({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final labels = List.generate(
      weeklyData.length,
          (i) => 'W${i + 1}',
    );

    final hasData = weeklyData.any((v) => v > 0);

    return _DashCard(
      title: 'Weekly Spending',
      icon: Icons.bar_chart,
      child: hasData
          ? Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AnimatedBarChart(
          values: weeklyData,
          labels: labels,
          height: 160,
        ),
      )
          : const SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, color: AppColors.textMuted, size: 48),
              SizedBox(height: 12),
              Text(
                'Chưa có dữ liệu chi tiêu tuần',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Card Wrapper ──────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const Gap(8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Gap(20),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── State Widgets ────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    // Chiều cao cố định để layout không nhảy khi reload
    return const SizedBox(
      height: 180,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const Gap(10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined,
                color: AppColors.textMuted, size: 48),
            const Gap(12),
            Text(
              message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}