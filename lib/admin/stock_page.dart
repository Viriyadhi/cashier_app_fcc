import 'package:flutter/material.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final Color _accent = const Color(0xFF00D084);
  final Color _mintBg = const Color(0xFFE8FFF6);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  int _selectedIndex = 0;
  int _stockValue = 10;
  String _imageLabel = 'No image selected';

  final List<Map<String, dynamic>> _items = [
    {
      "name": "Bertrand Onlyfans",
      "price": "NT\$1000",
      "stock": 10,
      "imageUrl": "https://picsum.photos/seed/a/300/300",
    },

    {
      "name": "Bertrand Onlyfans",
      "price": "NT\$1000",
      "stock": 10,
      "imageUrl": "https://picsum.photos/seed/b/300/300",
    },
    {
      "name": "Bertrand Onlyfans",
      "price": "NT\$1000",
      "stock": 10,
      "imageUrl": "https://picsum.photos/seed/c/300/300",
    },
    {
      "name": "Bertrand Onlyfans",
      "price": "NT\$1000",
      "stock": 10,
      "imageUrl": "https://picsum.photos/seed/d/300/300",
    },
    {
      "name": "Bertrand Onlyfans",
      "price": "NT\$1000",
      "stock": 10,
      "imageUrl": "https://picsum.photos/seed/e/300/300",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedItem(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _loadSelectedItem(int index) {
    final item = _items[index];
    _nameController.text = item["name"] as String;
    _priceController.text = item["price"] as String;
    _stockValue = (item["stock"] as int?) ?? 0;
    _imageLabel = (item["imageUrl"] as String?) ?? 'No image selected';
  }

  void _selectItem(int index) {
    setState(() {
      _selectedIndex = index;
      _loadSelectedItem(index);
    });
  }

  void _addNewItem() {
    setState(() {
      _selectedIndex = -1;
      _nameController.clear();
      _priceController.clear();
      _stockValue = 0;
      _imageLabel = 'No image selected';
    });
  }

  int _calcCrossAxisCount(double width) {
    if (width >= 1100) return 5;
    if (width >= 900) return 4;
    if (width >= 650) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mintBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // LEFT PANEL
              Expanded(
                flex: 3,
                child: _panel(
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _addNewItem,
                            icon: Icon(Icons.add, color: _accent),
                            label: Text(
                              'ADD NEW ITEM',
                              style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 320,
                            height: 42,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: 'search items here',
                                filled: true,
                                fillColor: const Color(0xFFF0F0F0),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Grid
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final count = _calcCrossAxisCount(c.maxWidth);
                            return GridView.builder(
                              padding: const EdgeInsets.only(bottom: 8),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: count,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.78,
                                  ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                final selected = index == _selectedIndex;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _selectItem(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            selected
                                                ? _accent
                                                : Colors.transparent,
                                        width: selected ? 2 : 1,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                          offset: Offset(0, 3),
                                          color: Color(0x14000000),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: AspectRatio(
                                              aspectRatio: 1,
                                              child: Image.network(
                                                item["imageUrl"] as String,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) => Container(
                                                      color: const Color(
                                                        0xFFEDEDED,
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        size: 36,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          item["name"] as String,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item["price"] as String,
                                          style: TextStyle(
                                            color: _accent,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Stock : ${(item["stock"] as int)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // RIGHT PANEL
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _panel(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Description',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            _label('Name'),
                            _field(_nameController, hint: 'Item name'),
                            const SizedBox(height: 12),

                            _label('Price'),
                            _field(_priceController, hint: 'NT\$0'),
                            const SizedBox(height: 12),

                            _label('Stock'),
                            Row(
                              children: [
                                _stepButton(
                                  icon: Icons.remove,
                                  onTap:
                                      () => setState(() {
                                        if (_stockValue > 0) _stockValue--;
                                      }),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 48,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F3F3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  child: Text(
                                    '$_stockValue',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _stepButton(
                                  icon: Icons.add,
                                  onTap:
                                      () => setState(() {
                                        _stockValue++;
                                      }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _label('Image'),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _imageLabel = 'sample_image.jpg';
                                    });
                                  },
                                  child: const Text('Upload Image'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _imageLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _panel({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
    );
  }

  Widget _field(TextEditingController controller, {required String hint}) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF3F3F3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _stepButton({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
