import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cashier_app/api/summary_service.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _isLoading = false;
  String? _errorText;
  SummaryViewData _view = SummaryViewData.empty();

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final records = await SummaryService.instance.fetchSummary();
      setState(() {
        _view = SummaryViewData.fromRecords(records);
      });
    } catch (_) {
      setState(() {
        _errorText = 'Failed to load summary.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const mintBg = Color(0xFFE8FFF6);
    const panelShadow = [
      BoxShadow(blurRadius: 14, offset: Offset(0, 5), color: Color(0x14000000)),
    ];

    return Scaffold(
      backgroundColor: mintBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, c) {
              final isNarrow = c.maxWidth < 980;
              final stats = _buildStatCards(_view);

              return Column(
                children: [
                  stats,
                  const SizedBox(height: 16),
                  Expanded(child: _buildMainGrid(isNarrow, panelShadow)),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorText!),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _fetchSummary,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(SummaryViewData view) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Revenue',
            value: view.totalRevenueLabel,
            accent: const Color(0xFF29D38D),
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Total Orders',
            value: view.totalOrdersLabel,
            accent: const Color(0xFF77E880),
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Total Items',
            value: view.totalItemsLabel,
            accent: const Color(0xFFD5E74E),
            icon: Icons.people_alt_outlined,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Total Sale',
            value: view.totalSalesLabel,
            accent: const Color(0xFFFFE15B),
            icon: Icons.bar_chart_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMainGrid(bool isNarrow, List<BoxShadow> panelShadow) {
    return isNarrow
        ? Column(
          children: [
            Expanded(
              child: _panel(
                panelShadow,
                child: _SalesRevenueCard(
                  revenue: _view.monthlyRevenue,
                  sales: _view.monthlySales,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _panel(
                panelShadow,
                child: _BestSellingCard(segments: _view.bestSellingSegments),
              ),
            ),
          ],
        )
        : Row(
          children: [
            Expanded(
              flex: 3,
              child: _panel(
                panelShadow,
                child: _SalesRevenueCard(
                  revenue: _view.monthlyRevenue,
                  sales: _view.monthlySales,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _panel(
                panelShadow,
                child: _BestSellingCard(segments: _view.bestSellingSegments),
              ),
            ),
          ],
        );
  }

  Widget _panel(List<BoxShadow> panelShadow, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: panelShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class SummaryViewData {
  SummaryViewData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalItems,
    required this.totalSales,
    required this.monthlyRevenue,
    required this.monthlySales,
    required this.bestSellingSegments,
  });

  final int totalRevenue;
  final int totalOrders;
  final int totalItems;
  final int totalSales;
  final List<int> monthlyRevenue;
  final List<int> monthlySales;
  final List<_DonutSegment> bestSellingSegments;

  static SummaryViewData empty() {
    return SummaryViewData(
      totalRevenue: 0,
      totalOrders: 0,
      totalItems: 0,
      totalSales: 0,
      monthlyRevenue: List.filled(12, 0),
      monthlySales: List.filled(12, 0),
      bestSellingSegments: const [
        _DonutSegment('No data', 100, Color(0xFFE0E0E0)),
      ],
    );
  }

  static SummaryViewData fromRecords(List<SummaryRecord> records) {
    if (records.isEmpty) return empty();

    final revenueByMonth = List<int>.filled(12, 0);
    final salesByMonth = List<int>.filled(12, 0);
    final itemTotals = <int, _ItemAgg>{};
    final transactionTimes = <String>{};

    int totalRevenue = 0;
    int totalSales = 0;

    for (final r in records) {
      totalRevenue += r.count * r.price;
      totalSales += r.count;

      final monthIndex = r.time.month - 1;
      if (monthIndex >= 0 && monthIndex < 12) {
        revenueByMonth[monthIndex] += r.count * r.price;
        salesByMonth[monthIndex] += r.count;
      }

      final name = r.name.isEmpty ? 'Item #${r.itemId}' : r.name;
      final existing = itemTotals[r.itemId];
      if (existing == null) {
        itemTotals[r.itemId] = _ItemAgg(r.count, name);
      } else {
        existing.count += r.count;
      }

      transactionTimes.add(r.time.toIso8601String());
    }

    final segments = _buildSegments(itemTotals);

    return SummaryViewData(
      totalRevenue: totalRevenue,
      totalOrders: transactionTimes.length,
      totalItems: itemTotals.length,
      totalSales: totalSales,
      monthlyRevenue: revenueByMonth,
      monthlySales: salesByMonth,
      bestSellingSegments: segments,
    );
  }

  String get totalRevenueLabel => '\$${_formatNumber(totalRevenue)}';
  String get totalOrdersLabel => _formatNumber(totalOrders);
  String get totalItemsLabel => _formatNumber(totalItems);
  String get totalSalesLabel => _formatNumber(totalSales);

  static String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final indexFromEnd = str.length - i;
      buffer.write(str[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  static List<_DonutSegment> _buildSegments(Map<int, _ItemAgg> itemTotals) {
    if (itemTotals.isEmpty) {
      return const [_DonutSegment('No data', 100, Color(0xFFE0E0E0))];
    }

    final sorted =
        itemTotals.entries.toList()
          ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final total = itemTotals.values.fold<int>(0, (sum, v) => sum + v.count);
    final colors = [
      const Color(0xFF0B7A4B),
      const Color(0xFF1AC978),
      const Color(0xFF37E09B),
      const Color(0xFF8FF0BF),
      const Color(0xFFA6F5D3),
    ];

    return sorted.take(4).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value.value;
      final value = (item.count / total) * 100;
      return _DonutSegment(item.name, value, colors[index % colors.length]);
    }).toList();
  }
}

class _ItemAgg {
  _ItemAgg(this.count, this.name);

  int count;
  final String name;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 5),
            color: Color(0x14000000),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesRevenueCard extends StatelessWidget {
  const _SalesRevenueCard({required this.revenue, required this.sales});

  final List<int> revenue;
  final List<int> sales;

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final maxValue = revenue.fold<int>(0, math.max).toDouble();
    final interval = maxValue == 0 ? 1.0 : maxValue / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [_LegendDot(color: Color(0xFF1AC978), label: 'Revenue')],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxValue == 0 ? 1 : maxValue,
              barTouchData: BarTouchData(enabled: false),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 6,
                        child: Text(
                          _formatCompact(value),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= months.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          months[index],
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(months.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: revenue[index].toDouble(),
                      color: const Color(0xFF1AC978),
                      width: 7,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000) {
      final text = (value / 1000).toStringAsFixed(1).replaceAll('.', ',');
      return '${text}k';
    }
    return value.toInt().toString();
  }
}

class _BestSellingCard extends StatelessWidget {
  const _BestSellingCard({required this.segments});

  final List<_DonutSegment> segments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Best Selling Food',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 46,
                sections:
                    segments
                        .map(
                          (s) => PieChartSectionData(
                            value: s.value,
                            color: s.color,
                            radius: 22,
                            showTitle: false,
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _DonutLegend(segments: segments),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _DonutSegment {
  const _DonutSegment(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _DonutLegend extends StatelessWidget {
  const _DonutLegend({required this.segments});

  final List<_DonutSegment> segments;

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          segments
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${s.label}  ${s.value.toStringAsFixed(0)}%',
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}
