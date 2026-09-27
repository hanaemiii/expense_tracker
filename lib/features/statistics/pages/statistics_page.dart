import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/expense.dart';
import '../bloc/statistics_cubit.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => StatisticsCubit(context.read<AppDependencies>()),
    child: const _StatisticsView(),
  );
}

const _chartColors = [
  Color(0xFF2755FF),
  Color(0xFF34BFA3),
  Color(0xFFFFB264),
  Color(0xFFAB82EA),
  Color(0xFFFD7183),
  Color(0xFF61A9ED),
  Color(0xFF455277),
];

class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<StatisticsCubit, StatisticsState>(
    builder: (context, state) {
      final summary = state.summary;
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: state.error != null
            ? ErrorState(onRetry: context.read<StatisticsCubit>().reload)
            : state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 116),
                children: [
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF597BFF)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.donut_large_rounded,
                          color: Colors.white70,
                          size: 28,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'TOTAL SPENDING',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          money(summary.total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${summary.count} ${summary.count == 1 ? 'expense' : 'expenses'} · ${summary.breakdown.length} ${summary.breakdown.length == 1 ? 'category' : 'categories'} in this view',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All expenses',
                          value: null,
                          active: state.status,
                        ),
                        for (final status in ExpenseStatus.values)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                              label: statusLabel(status),
                              value: status,
                              active: state.status,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (summary.total <= 0)
                    const AppCard(
                      child: EmptyState(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'No statistics available yet.',
                        subtitle: 'Add expenses to see your spending.',
                      ),
                    )
                  else ...[
                    AppCard(
                      child: Column(
                        children: [
                          Text(
                            'By category',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 225,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    centerSpaceRadius: 69,
                                    sectionsSpace: 3,
                                    startDegreeOffset: -90,
                                    pieTouchData: PieTouchData(enabled: true),
                                    sections: [
                                      for (
                                        var i = 0;
                                        i < summary.breakdown.length;
                                        i++
                                      )
                                        PieChartSectionData(
                                          value: summary.breakdown[i].amount,
                                          title: '',
                                          color:
                                              _chartColors[i %
                                                  _chartColors.length],
                                          radius: 30,
                                        ),
                                    ],
                                  ),
                                ),
                                IgnorePointer(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'TOTAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1.4,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        money(summary.total),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Breakdown',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const Text(
                          'SHARE',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < summary.breakdown.length; i++) ...[
                      _BreakdownRow(
                        total: summary.breakdown[i],
                        category:
                            state
                                .categoryFor(summary.breakdown[i].categoryId)
                                ?.name ??
                            'Uncategorized',
                        color: _chartColors[i % _chartColors.length],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
      );
    },
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.active,
  });
  final String label;
  final ExpenseStatus? value;
  final ExpenseStatus? active;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: value == active,
    onSelected: (_) => context.read<StatisticsCubit>().setStatus(value),
    selectedColor: const Color(0xFFDFE7FF),
    side: const BorderSide(color: AppColors.border),
    labelStyle: TextStyle(
      fontWeight: FontWeight.w700,
      color: value == active ? AppColors.primary : AppColors.ink,
    ),
  );
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.total,
    required this.category,
    required this.color,
  });
  final CategoryTotal total;
  final String category;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(17),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${total.percent.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Text(
              '${total.count} ${total.count == 1 ? 'expense' : 'expenses'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const Spacer(),
            Text(
              money(total.amount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    ),
  );
}
