import 'package:flutter/material.dart';
import 'package:cashier_app/api/history_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;
  List<TransactionGroup> _groups = [];
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final records =
          await TransactionService.instance.fetchTransactionHistory();
      final groups = _groupByTime(records);

      setState(() {
        _groups = groups;
        _selectedIndex = _groups.isNotEmpty ? 0 : -1;
      });
    } catch (error) {
      setState(() {
        _errorText = 'Failed to load history.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<TransactionGroup> _groupByTime(List<TransactionRecord> records) {
    final Map<String, List<TransactionRecord>> grouped = {};
    for (final record in records) {
      final key = record.time.toIso8601String();
      grouped.putIfAbsent(key, () => []).add(record);
    }

    final groups =
        grouped.entries.map((entry) {
          final time = DateTime.parse(entry.key);
          final items = entry.value;
          final totalCount = items.fold<int>(0, (sum, r) => sum + r.count);
          final rank = items.isNotEmpty ? items.first.rank : 0;
          return TransactionGroup(
            time: time,
            records: items,
            totalCount: totalCount,
            rank: rank,
          );
        }).toList();

    groups.sort((a, b) => b.time.compareTo(a.time));
    return groups;
  }

  TransactionGroup? get _selectedGroup {
    if (_selectedIndex < 0 || _selectedIndex >= _groups.length) return null;
    return _groups[_selectedIndex];
  }

  String _formatDate(DateTime time) {
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    const mintBg = Color(0xFFE8FFF6);
    const panelShadow = [
      BoxShadow(blurRadius: 14, offset: Offset(0, 5), color: Color(0x14000000)),
    ];

    final selectedGroup = _selectedGroup;

    return Scaffold(
      backgroundColor: mintBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // LEFT: HISTORY TABLE PANEL
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: panelShadow,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Top row: date + search
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.chevron_left,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                selectedGroup == null
                                    ? 'Recent'
                                    : _formatDate(selectedGroup.time),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 320,
                            height: 42,
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'search items here',
                                filled: true,
                                fillColor: Color(0xFFF0F0F0),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(24),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Table header
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'ID',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Time',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rows
                      Expanded(child: _buildRows()),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // RIGHT: CONTENT + BUTTON
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Content panel
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: panelShadow,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 14),
                          const Text(
                            'Content',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),

                          // header row for mini table
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            color: const Color(0xFFF2F2F2),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'Name',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'QTY',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Price',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // items list
                          SizedBox(
                            height: 220,
                            child: _buildContentList(selectedGroup),
                          ),

                          const Divider(height: 1),

                          // Summary section
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _SummaryRow(
                                  label: 'Rank',
                                  value:
                                      selectedGroup == null
                                          ? '-'
                                          : '#${selectedGroup.rank}',
                                ),
                                const SizedBox(height: 10),
                                _SummaryRow(
                                  label: 'Items',
                                  value:
                                      selectedGroup == null
                                          ? '-'
                                          : '${selectedGroup.totalCount}',
                                ),
                                const SizedBox(height: 10),
                                _SummaryRow(
                                  label: 'Lines',
                                  value:
                                      selectedGroup == null
                                          ? '-'
                                          : '${selectedGroup.records.length}',
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1),

                          // Total
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  selectedGroup == null
                                      ? '-'
                                      : '${selectedGroup.totalCount} items',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Return Item button (UI only)
                    Container(
                      width: double.infinity,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2D2D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Return Item',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildRows() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorText!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _fetchHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return ListView.separated(
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final group = _groups[index];
        final selected = index == _selectedIndex;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE9E9E9) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('TXN ${index + 1}')),
                Expanded(flex: 2, child: Text(_formatTime(group.time))),
                Expanded(flex: 2, child: Text('${group.totalCount}')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentList(TransactionGroup? group) {
    if (group == null) {
      return const Center(child: Text('Select a transaction'));
    }

    if (group.records.isEmpty) {
      return const Center(child: Text('No items.'));
    }

    return ListView.separated(
      itemCount: group.records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = group.records[index];
        return _ContentRow(
          name: 'Item #${record.itemId}',
          qty: record.count.toString(),
          price: '-',
        );
      },
    );
  }
}

class TransactionGroup {
  TransactionGroup({
    required this.time,
    required this.records,
    required this.totalCount,
    required this.rank,
  });

  final DateTime time;
  final List<TransactionRecord> records;
  final int totalCount;
  final int rank;
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({
    required this.name,
    required this.qty,
    required this.price,
  });

  final String name;
  final String qty;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              price,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
