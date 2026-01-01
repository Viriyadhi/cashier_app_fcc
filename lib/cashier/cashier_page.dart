import 'dart:convert';
import 'dart:typed_data';

import 'package:cashier_app/api/auth_service.dart';
import 'package:cashier_app/api/stock_service.dart';
import 'package:cashier_app/api/transaction_service.dart';
import 'package:cashier_app/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isLoggingOut = false;
  String? _errorText;
  List<StockItem> _items = [];
  final Map<int, _CartEntry> _cart = {};
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;
  bool _isSubmitting = false;

  Future<void> onLogoutTap() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService.instance.logout();
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Logout failed. Please try again.');
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

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
        _syncCartWithItems(items);
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitTransaction() async {
    if (_cart.isEmpty) {
      _showSnackBar('Cart is empty.');
      return;
    }
    if (_isSubmitting) return;

    final payload = <String, int>{
      for (final entry in _cart.values) entry.item.id.toString(): entry.qty,
    };

    setState(() {
      _isSubmitting = true;
    });

    try {
      await TransactionService.instance.createTransaction(payload);
      if (!mounted) return;
      setState(() {
        _cart.clear();
      });
      await _fetchItems();
      if (!mounted) return;
      _showSnackBar('Payment successful.');
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Payment failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _syncCartWithItems(List<StockItem> items) {
    if (_cart.isEmpty) return;
    final byId = {for (final item in items) item.id: item};
    for (final id in _cart.keys.toList()) {
      final item = byId[id];
      if (item == null) {
        _cart.remove(id);
      } else {
        final available = item.currentStock < 0 ? 0 : item.currentStock;
        if (available == 0) {
          _cart.remove(id);
          continue;
        }
        final currentQty = _cart[id]!.qty;
        final nextQty = currentQty > available ? available : currentQty;
        _cart[id] = _CartEntry(item: item, qty: nextQty);
      }
    }
  }

  void _addToCart(StockItem item) {
    final available = item.currentStock < 0 ? 0 : item.currentStock;
    if (available == 0) {
      _showSnackBar('Out of stock.');
      return;
    }
    final entry = _cart[item.id];
    if (entry != null && entry.qty >= available) {
      _showSnackBar('No more stock available.');
      return;
    }
    setState(() {
      if (entry == null) {
        _cart[item.id] = _CartEntry(item: item, qty: 1);
      } else {
        _cart[item.id] = entry.copyWith(qty: entry.qty + 1);
      }
    });
  }

  void _incrementCartItem(int itemId) {
    final entry = _cart[itemId];
    if (entry == null) return;
    final available =
        entry.item.currentStock < 0 ? 0 : entry.item.currentStock;
    if (entry.qty >= available) {
      _showSnackBar('No more stock available.');
      return;
    }
    setState(() {
      _cart[itemId] = entry.copyWith(qty: entry.qty + 1);
    });
  }

  void _decrementCartItem(int itemId) {
    final entry = _cart[itemId];
    if (entry == null) return;
    setState(() {
      if (entry.qty <= 1) {
        _cart.remove(itemId);
      } else {
        _cart[itemId] = entry.copyWith(qty: entry.qty - 1);
      }
    });
  }

  void _removeCartItem(int itemId) {
    setState(() {
      _cart.remove(itemId);
    });
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
  }

  List<StockItem> get _filteredItems {
    final query = _searchQuery.toLowerCase().trim();
    final selected = _categoryOptions[_selectedCategoryIndex];
    final knownTypes =
        _categoryOptions
            .where((category) => !category.isAll && !category.isOthers)
            .expand((category) => category.matchTypes)
            .toSet();

    final filtered =
        _items.where((item) {
          final name = item.name.toLowerCase();
          final matchesSearch = query.isEmpty || name.contains(query);
          if (!matchesSearch) return false;

          final type = item.type?.toLowerCase().trim() ?? '';
          if (selected.isAll) return true;
          if (selected.isOthers) {
            return type.isEmpty || !knownTypes.contains(type);
          }
          return selected.matchTypes.contains(type);
        }).toList();

    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final catalogItems = _filteredItems;
    final checkoutItems = _cart.values.toList();
    final cartQuantities = {
      for (final entry in _cart.entries) entry.key: entry.value.qty,
    };
    final total = _cart.values.fold<int>(
      0,
      (sum, entry) => sum + (entry.item.price * entry.qty),
    );

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
                            categories: _categoryOptions,
                            selectedCategoryIndex: _selectedCategoryIndex,
                            onCategorySelected: _selectCategory,
                            cartQuantities: cartQuantities,
                            onItemTap: _addToCart,
                          ),
                          const SizedBox(height: 16),
                          CheckoutPanel(
                            isNarrow: isNarrow,
                            items: checkoutItems,
                            total: total,
                            onIncrement: _incrementCartItem,
                            onDecrement: _decrementCartItem,
                            onRemove: _removeCartItem,
                            onPay: _submitTransaction,
                            isPaying: _isSubmitting,
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
                            categories: _categoryOptions,
                            selectedCategoryIndex: _selectedCategoryIndex,
                            onCategorySelected: _selectCategory,
                            cartQuantities: cartQuantities,
                            onItemTap: _addToCart,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 300,
                          child: CheckoutPanel(
                            isNarrow: isNarrow,
                            items: checkoutItems,
                            total: total,
                            onIncrement: _incrementCartItem,
                            onDecrement: _decrementCartItem,
                            onRemove: _removeCartItem,
                            onPay: _submitTransaction,
                            isPaying: _isSubmitting,
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
                  children: [
                    SvgPicture.asset(
                      'assets/Logo.svg',
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFFFC107),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "ASEP'S POS",
                      style: GoogleFonts.aclonica(
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
    required this.categories,
    required this.selectedCategoryIndex,
    required this.onCategorySelected,
    required this.cartQuantities,
    required this.onItemTap,
  });

  final bool isNarrow;
  final List<StockItem> items;
  final bool isLoading;
  final String? errorText;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<_CategoryOption> categories;
  final int selectedCategoryIndex;
  final ValueChanged<int> onCategorySelected;
  final Map<int, int> cartQuantities;
  final ValueChanged<StockItem> onItemTap;

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
      itemBuilder: (context, index) {
        final item = items[index];
        final inCart = cartQuantities[item.id] ?? 0;
        final available = item.currentStock < 0 ? 0 : item.currentStock;
        final remaining = available - inCart;
        final displayStock = remaining < 0 ? 0 : remaining;
        return CatalogItemCard(
          item: item,
          remainingStock: displayStock,
          onTap: () => onItemTap(item),
        );
      },
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
        CategoryBar(
          categories: categories,
          selectedIndex: selectedCategoryIndex,
          onCategorySelected: onCategorySelected,
        ),
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

const List<_CategoryOption> _categoryOptions = [
  _CategoryOption(label: 'All', icon: Icons.apps, isAll: true),
  _CategoryOption(
    label: 'Food',
    icon: Icons.fastfood,
    matchTypes: ['food', 'foods'],
  ),
  _CategoryOption(
    label: 'Beverage',
    icon: Icons.local_cafe,
    matchTypes: ['drnk', 'drink', 'drinks', 'beverage', 'beverages'],
  ),
  _CategoryOption(
    label: 'Snacks',
    icon: Icons.local_pizza,
    matchTypes: ['snack', 'snacks'],
  ),
  _CategoryOption(label: 'Others', icon: Icons.category, isOthers: true),
];

class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  final List<_CategoryOption> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < categories.length; index++) ...[
          Expanded(
            child: CategoryChip(
              data: categories[index],
              isSelected: index == selectedIndex,
              onTap: () => onCategorySelected(index),
            ),
          ),
          if (index != categories.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _CategoryOption data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? const Color(0xFFE7FFF4) : Colors.white;
    final border =
        isSelected ? const Color(0xFF27DD8E) : const Color(0xFFD6E9DD);
    final contentColor =
        isSelected ? const Color(0xFF27DD8E) : const Color(0xFF7D8C86);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
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
        ),
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
  const CatalogItemCard({
    super.key,
    required this.item,
    required this.remainingStock,
    required this.onTap,
  });

  final StockItem item;
  final int remainingStock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeBase64Image(item.imageBase64);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
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
              const SizedBox(height: 2),
              Text(
                'Stock: $remainingStock',
                style: const TextStyle(
                  color: Color(0xFF8A9691),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutPanel extends StatelessWidget {
  const CheckoutPanel({
    super.key,
    required this.isNarrow,
    required this.items,
    required this.total,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onPay,
    required this.isPaying,
  });

  final bool isNarrow;
  final List<_CartEntry> items;
  final int total;
  final ValueChanged<int> onIncrement;
  final ValueChanged<int> onDecrement;
  final ValueChanged<int> onRemove;
  final VoidCallback onPay;
  final bool isPaying;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE2E9E5);
    const mutedText = Color(0xFF8A9691);
    const titleColor = Color(0xFF137048);

    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ FIX: responsive widths + scaleDown to prevent overflow
        final maxW = constraints.maxWidth;
        final isCompact = maxW < 360;

        final qtyWidth = (maxW * 0.34).clamp(84.0, 120.0);
        final priceWidth = (maxW * 0.22).clamp(64.0, 92.0);

        final layout = _CheckoutLayout(
          leadingWidth: isCompact ? 20 : 24,
          iconSize: isCompact ? 14 : 16,
          gapWidth: isCompact ? 4 : 6,
          qtyWidth: qtyWidth,
          priceWidth: priceWidth,
          qtyPadding: isCompact ? 4 : 6,
          qtySpacing: isCompact ? 3 : 4,
          qtyIconSize: isCompact ? 18 : 22,
          qtyIconInnerSize: isCompact ? 12 : 14,
        );

        final list = ListView.separated(
          itemCount: items.length,
          shrinkWrap: isNarrow,
          physics: isNarrow ? const NeverScrollableScrollPhysics() : null,
          padding: EdgeInsets.zero,
          separatorBuilder:
              (_, __) => const Divider(height: 16, color: borderColor),
          itemBuilder: (context, index) {
            final item = items[index];
            final available =
                item.item.currentStock < 0 ? 0 : item.item.currentStock;
            final canIncrement = available > item.qty;
            return CheckoutItemRow(
              item: item,
              onIncrement: () => onIncrement(item.item.id),
              onDecrement: () => onDecrement(item.item.id),
              onRemove: () => onRemove(item.item.id),
              layout: layout,
              canIncrement: canIncrement,
            );
          },
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
                  SizedBox(width: layout.leadingWidth),
                  Expanded(
                    child: Text(
                      'Name',
                      style: const TextStyle(
                        color: mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: layout.qtyWidth,
                    child: Text(
                      'QTY',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: layout.priceWidth,
                    child: Text(
                      'Price',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
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
              _SummaryRow(
                label: 'Total',
                value: 'NT\$$total',
                isEmphasis: true,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: total == 0 || isPaying ? null : onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27DD8E),
                    foregroundColor: const Color(0xFF0D5A39),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isPaying ? 'Processing...' : 'Pay (NT\$$total)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CheckoutItemRow extends StatelessWidget {
  const CheckoutItemRow({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.layout,
    required this.canIncrement,
  });

  final _CartEntry item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final _CheckoutLayout layout;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    const mutedText = Color(0xFF8A9691);
    const qtyBorder = Color(0xFFBFEBD7);

    return Row(
      children: [
        SizedBox(
          width: layout.leadingWidth - layout.gapWidth,
          child: InkResponse(
            onTap: onRemove,
            radius: 14,
            child: Icon(
              Icons.delete_outline,
              size: layout.iconSize,
              color: mutedText,
            ),
          ),
        ),
        SizedBox(width: layout.gapWidth),
        Expanded(
          child: Text(
            item.item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),

        SizedBox(
          width: layout.qtyWidth,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.qtyPadding,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: qtyBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyIcon(
                      icon: Icons.remove,
                      onTap: onDecrement,
                      size: layout.qtyIconSize,
                      iconSize: layout.qtyIconInnerSize,
                    ),
                    SizedBox(width: layout.qtySpacing),
                    Text(
                      item.qty.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF2F6E54),
                      ),
                    ),
                    SizedBox(width: layout.qtySpacing),
                    _QtyIcon(
                      icon: Icons.add,
                      onTap: onIncrement,
                      size: layout.qtyIconSize,
                      iconSize: layout.qtyIconInnerSize,
                      enabled: canIncrement,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SizedBox(
          width: layout.priceWidth,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                'NT\$${item.item.price * item.qty}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyIcon extends StatelessWidget {
  const _QtyIcon({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.iconSize,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF27DD8E);
    const disabled = Color(0xFFBFD8CB);
    final color = enabled ? accent : disabled;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}

class _CheckoutLayout {
  const _CheckoutLayout({
    required this.leadingWidth,
    required this.iconSize,
    required this.gapWidth,
    required this.qtyWidth,
    required this.priceWidth,
    required this.qtyPadding,
    required this.qtySpacing,
    required this.qtyIconSize,
    required this.qtyIconInnerSize,
  });

  final double leadingWidth;
  final double iconSize;
  final double gapWidth;
  final double qtyWidth;
  final double priceWidth;
  final double qtyPadding;
  final double qtySpacing;
  final double qtyIconSize;
  final double qtyIconInnerSize;
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

class _CartEntry {
  const _CartEntry({required this.item, required this.qty});

  final StockItem item;
  final int qty;

  _CartEntry copyWith({StockItem? item, int? qty}) {
    return _CartEntry(item: item ?? this.item, qty: qty ?? this.qty);
  }
}

class _CategoryOption {
  const _CategoryOption({
    required this.label,
    required this.icon,
    this.matchTypes = const [],
    this.isAll = false,
    this.isOthers = false,
  });

  final String label;
  final IconData icon;
  final List<String> matchTypes;
  final bool isAll;
  final bool isOthers;
}
