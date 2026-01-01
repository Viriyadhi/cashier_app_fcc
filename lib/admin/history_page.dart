import 'package:flutter/material.dart';
import 'package:cashier_app/api/history_service.dart';
import 'package:cashier_app/api/transaction_service.dart' as txn_api;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isReturning = false;
  bool _isReturnMode = false;
  String? _errorText;
  List<TransactionGroup> _groups = [];
  String _searchQuery = '';
  String? _selectedGroupKey;
  final Map<int, int> _returnQuantities = {};

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
      _isReturnMode = false;
      _returnQuantities.clear();
    });

    try {
      final records =
          await TransactionService.instance.fetchTransactionHistory();
      final groups = _groupByTime(records);

      setState(() {
        _groups = groups;
        final filtered = _filterGroups(_groups, _searchQuery);
        _selectedGroupKey =
            filtered.isNotEmpty ? filtered.first.time.toIso8601String() : null;
        _isReturnMode = false;
        _returnQuantities.clear();
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

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value;
      final filtered = _filterGroups(_groups, _searchQuery);
      _selectedGroupKey =
          filtered.isNotEmpty ? filtered.first.time.toIso8601String() : null;
      _isReturnMode = false;
      _returnQuantities.clear();
    });
  }

  List<TransactionGroup> _filterGroups(
    List<TransactionGroup> groups,
    String query,
  ) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return groups;
    return groups.where((group) {
      final date = _formatDate(group.time).toLowerCase();
      return date.contains(needle);
    }).toList();
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
          final totalAmount = items.fold<int>(
            0,
            (sum, r) => sum + (r.price * r.count),
          );
          final rank = items.isNotEmpty ? items.first.rank : 0;
          return TransactionGroup(
            time: time,
            records: items,
            totalCount: totalCount,
            totalAmount: totalAmount,
            rank: rank,
          );
        }).toList();

    groups.sort((a, b) => b.time.compareTo(a.time));
    return groups;
  }

  TransactionGroup? get _selectedGroup {
    final filtered = _filterGroups(_groups, _searchQuery);
    if (filtered.isEmpty) return null;
    if (_selectedGroupKey == null) return filtered.first;
    return filtered.firstWhere(
      (group) => group.time.toIso8601String() == _selectedGroupKey,
      orElse: () => filtered.first,
    );
  }

  int _calculateReturnTotal(TransactionGroup group) {
    var total = 0;
    for (final record in group.records) {
      final qty = _returnQuantities[record.itemId] ?? 0;
      total += record.price * qty;
    }
    return total;
  }

  void _incrementReturnQty(TransactionRecord record) {
    final current = _returnQuantities[record.itemId] ?? 0;
    final maxQty = record.count.abs();
    if (current >= maxQty) {
      _showSnackBar('Cannot return more than purchased.');
      return;
    }
    setState(() {
      _returnQuantities[record.itemId] = current + 1;
    });
  }

  void _decrementReturnQty(TransactionRecord record) {
    final current = _returnQuantities[record.itemId] ?? 0;
    if (current <= 0) return;
    setState(() {
      _returnQuantities[record.itemId] = current - 1;
    });
  }

  Future<void> _handleReturnAction() async {
    final group = _selectedGroup;
    if (group == null || group.totalAmount < 0) return;

    if (!_isReturnMode) {
      setState(() {
        _isReturnMode = true;
        _returnQuantities
          ..clear()
          ..addEntries(group.records.map((r) => MapEntry(r.itemId, 0)));
      });
      return;
    }

    if (_isReturning) return;

    final itemsToReturn = <String, int>{};
    for (final record in group.records) {
      final qty = _returnQuantities[record.itemId] ?? 0;
      if (qty > 0) {
        itemsToReturn[record.itemId.toString()] = -qty;
      }
    }

    if (itemsToReturn.isEmpty) {
      _showSnackBar('No items to return.');
      return;
    }

    final returnTotal = _calculateReturnTotal(group);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm return'),
          content: Text(
            'Return ${itemsToReturn.length} item(s) for NT\$$returnTotal?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isReturning = true;
    });

    try {
      await txn_api.TransactionService.instance.createTransaction(
        itemsToReturn,
      );
      if (!mounted) return;
      await _fetchHistory();
      if (!mounted) return;
      _showSnackBar('Return saved.');
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Failed to save return.');
    } finally {
      if (mounted) {
        setState(() {
          _isReturning = false;
          _isReturnMode = false;
          _returnQuantities.clear();
        });
      }
    }
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
    final isReturnTransaction =
        selectedGroup != null && selectedGroup.totalAmount < 0;
    final displayTotal =
        _isReturnMode && selectedGroup != null
            ? _calculateReturnTotal(selectedGroup)
            : (selectedGroup?.totalAmount ?? 0);
    final contentTitle =
        isReturnTransaction || _isReturnMode ? 'Returned Content' : 'Content';

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
                              onChanged: _updateSearch,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'YYYY‑MM‑DD',
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
                              flex: 3,
                              child: Text(
                                'Date',
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
                          Text(
                            contentTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF0C6B45),
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
                                      : 'NT\$$displayTotal',
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

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            selectedGroup == null || isReturnTransaction
                                ? null
                                : _handleReturnAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isReturnMode
                                  ? const Color(0xFF27DD8E)
                                  : const Color(0xFFFF2D2D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isReturning
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _isReturnMode ? 'Save' : 'Return Item',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
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

    final filteredGroups = _filterGroups(_groups, _searchQuery);
    if (filteredGroups.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return ListView.separated(
      itemCount: filteredGroups.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        final selected = group.time.toIso8601String() == _selectedGroupKey;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedGroupKey = group.time.toIso8601String();
              _isReturnMode = false;
              _returnQuantities.clear();
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
                Expanded(flex: 3, child: Text(_formatDate(group.time))),
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
        final name =
            record.name.isNotEmpty ? record.name : 'Item #${record.itemId}';
        if (_isReturnMode) {
          final qty = _returnQuantities[record.itemId] ?? 0;
          return _ReturnRow(
            name: name,
            qty: qty,
            maxQty: record.count.abs(),
            price: record.price * qty,
            onIncrement: () => _incrementReturnQty(record),
            onDecrement: () => _decrementReturnQty(record),
          );
        }

        final price = record.price > 0 ? 'NT\$${record.price}' : '-';
        return _ContentRow(
          name: name,
          qty: record.count.toString(),
          price: price,
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class TransactionGroup {
  TransactionGroup({
    required this.time,
    required this.records,
    required this.totalCount,
    required this.totalAmount,
    required this.rank,
  });

  final DateTime time;
  final List<TransactionRecord> records;
  final int totalCount;
  final int totalAmount;
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

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({
    required this.name,
    required this.qty,
    required this.maxQty,
    required this.price,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String name;
  final int qty;
  final int maxQty;
  final int price;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final canDecrement = qty > 0;
    final canIncrement = qty < maxQty;

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  enabled: canDecrement,
                  onTap: canDecrement ? onDecrement : null,
                ),
                const SizedBox(width: 8),
                Text('$qty', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                _QtyButton(
                  icon: Icons.add,
                  enabled: canIncrement,
                  onTap: canIncrement ? onIncrement : null,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'NT\$$price',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? const Color(0xFF27DD8E) : const Color(0xFFE0E0E0);
    final fg = enabled ? Colors.white : Colors.white70;

    return InkResponse(
      onTap: onTap,
      radius: 14,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: fg),
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
