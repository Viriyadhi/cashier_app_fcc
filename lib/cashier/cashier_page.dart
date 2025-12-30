import 'dart:convert';
import 'dart:typed_data';

import 'package:cashier_app/api/stock_service.dart';
import 'package:flutter/material.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  List<StockItem> _items = [];
  String _searchQuery = '';

  void onLogoutTap() {}

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final items = await StockService.instance.fetchItemList();
      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Failed to load items.';
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
    });
  }

  List<StockItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final query = _searchQuery.toLowerCase();
    return _items
        .where((item) => item.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final catalogItems = _filteredItems;
    const checkoutItems = [
      _CheckoutItem(name: 'Bertrand Onlyfans', qty: 3, price: 'NT\$3000'),
      _CheckoutItem(name: 'Pacar Cina', qty: 2, price: 'NT\$300'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F0),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            CashierTopBar(onLogoutTap: onLogoutTap),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;

                  if (isNarrow) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CatalogPanel(
                            isNarrow: isNarrow,
                            items: catalogItems,
                            isLoading: _isLoading,
                            errorText: _errorText,
                            searchController: _searchController,
                            onSearchChanged: _updateSearch,
                          ),
                          const SizedBox(height: 16),
                          CheckoutPanel(
                            isNarrow: isNarrow,
                            items: checkoutItems,
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CatalogPanel(
                            isNarrow: isNarrow,
                            items: catalogItems,
                            isLoading: _isLoading,
                            errorText: _errorText,
                            searchController: _searchController,
                            onSearchChanged: _updateSearch,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 300,
                          child: CheckoutPanel(
                            isNarrow: isNarrow,
                            items: checkoutItems,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CashierTopBar extends StatelessWidget {
  const CashierTopBar({super.key, required this.onLogoutTap});

  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF137048);

    return Material(
      color: bg,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Row(
                  children: const [
                    Icon(Icons.storefront, color: Color(0xFF27DD8E), size: 26),
                    SizedBox(width: 10),
                    Text(
                      "ASEP'S POS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onLogoutTap,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFCFF5E4),
                    foregroundColor: bg,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CatalogPanel extends StatelessWidget {
  const CatalogPanel({
    super.key,
    required this.isNarrow,
    required this.items,
    required this.isLoading,
    required this.errorText,
    required this.searchController,
    required this.onSearchChanged,
  });

  final bool isNarrow;
  final List<StockItem> items;
  final bool isLoading;
  final String? errorText;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
      itemCount: items.length,
      padding: EdgeInsets.zero,
      shrinkWrap: isNarrow,
      physics: isNarrow ? const NeverScrollableScrollPhysics() : null,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isNarrow ? 2 : 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) => CatalogItemCard(item: items[index]),
    );

    final gridBody =
        items.isEmpty
            ? _CatalogPlaceholder(
              message:
                  isLoading
                      ? 'Loading items...'
                      : (errorText ?? 'No items found.'),
            )
            : grid;

    final gridContent = Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: isNarrow ? 240 : 260,
            child: SearchBarField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isNarrow) gridBody else Expanded(child: gridBody),
      ],
    );

    final gridContainer = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E9DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: gridContent,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isNarrow) gridContainer else Expanded(child: gridContainer),
        const SizedBox(height: 12),
        const CategoryBar(),
      ],
    );
  }
}

class _CatalogPlaceholder extends StatelessWidget {
  const _CatalogPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF8A9691),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SearchBarField extends StatelessWidget {
  const SearchBarField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'search items here',
        hintStyle: const TextStyle(color: Color(0xFF7D8C86)),
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: Color(0xFF7D8C86),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class CategoryBar extends StatelessWidget {
  const CategoryBar({super.key});

  static const categories = [
    _CategoryData(label: 'All', icon: Icons.apps, isSelected: true),
    _CategoryData(label: 'Food', icon: Icons.fastfood),
    _CategoryData(label: 'Beverage', icon: Icons.local_cafe),
    _CategoryData(label: 'Snacks', icon: Icons.local_pizza),
    _CategoryData(label: 'Others', icon: Icons.category),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < categories.length; index++) ...[
          Expanded(child: CategoryChip(data: categories[index])),
          if (index != categories.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.data});

  final _CategoryData data;

  @override
  Widget build(BuildContext context) {
    final bg = data.isSelected ? const Color(0xFFE7FFF4) : Colors.white;
    final border =
        data.isSelected ? const Color(0xFF27DD8E) : const Color(0xFFD6E9DD);
    final contentColor =
        data.isSelected ? const Color(0xFF27DD8E) : const Color(0xFF7D8C86);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(data.icon, color: contentColor, size: 22),
          const SizedBox(height: 6),
          Text(
            data.label,
            style: TextStyle(
              color: contentColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Uint8List? _decodeBase64Image(String base64Image) {
  if (base64Image.isEmpty) return null;
  try {
    return base64Decode(base64Image);
  } catch (_) {
    return null;
  }
}

class CatalogItemCard extends StatelessWidget {
  const CatalogItemCard({super.key, required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeBase64Image(item.imageBase64);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFECECEC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child:
                    imageBytes == null
                        ? const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF9E9E9E),
                          size: 32,
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'NT\$${item.price}',
            style: const TextStyle(
              color: Color(0xFF27DD8E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutPanel extends StatelessWidget {
  const CheckoutPanel({super.key, required this.isNarrow, required this.items});

  final bool isNarrow;
  final List<_CheckoutItem> items;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE2E9E5);
    const mutedText = Color(0xFF8A9691);
    const titleColor = Color(0xFF137048);

    final list = ListView.separated(
      itemCount: items.length,
      shrinkWrap: isNarrow,
      physics: isNarrow ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      separatorBuilder:
          (_, __) => const Divider(height: 16, color: borderColor),
      itemBuilder: (context, index) => CheckoutItemRow(item: items[index]),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Checkout',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 24),
              const Expanded(
                child: Text(
                  'Name',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 76,
                child: Text(
                  'QTY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  'Price',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 8),
          if (isNarrow) list else Expanded(child: list),
          const SizedBox(height: 8),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 6),
          const _SummaryRow(
            label: 'Total',
            value: 'NT\$3292',
            isEmphasis: true,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27DD8E),
                foregroundColor: const Color(0xFF0D5A39),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Pay (NT\$3292)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutItemRow extends StatelessWidget {
  const CheckoutItemRow({super.key, required this.item});

  final _CheckoutItem item;

  @override
  Widget build(BuildContext context) {
    const mutedText = Color(0xFF8A9691);
    const qtyBorder = Color(0xFFBFEBD7);

    return Row(
      children: [
        const SizedBox(
          width: 18,
          child: Icon(Icons.delete_outline, size: 16, color: mutedText),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        SizedBox(
          width: 76,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: qtyBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _QtyIcon(icon: Icons.remove),
                  const SizedBox(width: 6),
                  Text(
                    item.qty.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF2F6E54),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const _QtyIcon(icon: Icons.add),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.price,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyIcon extends StatelessWidget {
  const _QtyIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF27DD8E);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent),
      ),
      child: Icon(icon, size: 12, color: accent),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w500,
      fontSize: isEmphasis ? 13 : 12,
      color: isEmphasis ? Colors.black : const Color(0xFF8A9691),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}

class _CheckoutItem {
  const _CheckoutItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  final String name;
  final int qty;
  final String price;
}

class _CategoryData {
  const _CategoryData({
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
}
