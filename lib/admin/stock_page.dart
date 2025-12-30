import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cashier_app/api/stock_service.dart';

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

  int _selectedIndex = -1;
  int _stockValue = 0;
  String _imageLabel = 'No image selected';

  bool _isLoading = false;
  String? _errorText;
  List<StockItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final items = await StockService.instance.fetchItemList();
      setState(() {
        _items = items;
        if (_items.isNotEmpty) {
          _selectedIndex = 0;
          _loadSelectedItem(0);
        } else {
          _selectedIndex = -1;
          _nameController.clear();
          _priceController.clear();
          _stockValue = 0;
          _imageLabel = 'No image selected';
        }
      });
    } catch (error) {
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

  void _loadSelectedItem(int index) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    _nameController.text = item.name;
    _priceController.text = item.price.toString();
    _stockValue = item.currentStock;
    _imageLabel = item.imageBase64.isNotEmpty
        ? 'image_${item.id}.png'
        : 'No image selected';
  }

  void _selectItem(int index) {
    setState(() {
      _selectedIndex = index;
      _loadSelectedItem(index);
    });
  }

  void _resetSelection() {
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

  Uint8List? _decodeImage(String base64Image) {
    if (base64Image.isEmpty) return null;
    try {
      return base64Decode(base64Image);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openAddItemDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    XFile? selectedImage;
    bool isSaving = false;
    String? dialogError;

    final picker = ImagePicker();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final file = await picker.pickImage(source: ImageSource.gallery);
              if (file != null) {
                setDialogState(() {
                  selectedImage = file;
                });
              }
            }

            Future<void> saveItem() async {
              final name = nameController.text.trim();
              final price = int.tryParse(priceController.text.trim());
              final stock = int.tryParse(stockController.text.trim());

              if (name.isEmpty || price == null || stock == null) {
                setDialogState(() {
                  dialogError = 'Please enter valid name, price, and stock.';
                });
                return;
              }

              setDialogState(() {
                isSaving = true;
                dialogError = null;
              });

              try {
                await StockService.instance.createItem(
                  name: name,
                  stock: stock,
                  price: price,
                  imagePath: selectedImage?.path,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _resetSelection();
                _fetchItems();
              } catch (error) {
                setDialogState(() {
                  dialogError = 'Failed to save item.';
                  isSaving = false;
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 720,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Add New Item',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0C6B45),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: pickImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C6B45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: selectedImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          color: Colors.white,
                                          size: 42,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Add Image',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(selectedImage!.path),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) {
                                          return const Center(
                                            child: Icon(
                                              Icons.image,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                _dialogField(
                                  controller: nameController,
                                  hintText: 'Item Name',
                                ),
                                const SizedBox(height: 12),
                                _dialogField(
                                  controller: priceController,
                                  hintText: 'Price',
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 12),
                                _dialogField(
                                  controller: stockController,
                                  hintText: 'Stock',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (dialogError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            dialogError!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0C6B45),
                              side: const BorderSide(color: Color(0xFF0C6B45)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text('Discard'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isSaving ? null : saveItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C6B45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF3F8F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
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
              onPressed: _fetchItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text('No items found.'));
    }

    return LayoutBuilder(
      builder: (context, c) {
        final count = _calcCrossAxisCount(c.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final selected = index == _selectedIndex;
            final imageBytes = _decodeImage(item.imageBase64);

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectItem(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? _accent : Colors.transparent,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: imageBytes != null
                              ? Image.memory(imageBytes, fit: BoxFit.cover)
                              : Container(
                                  color: const Color(0xFFEDEDED),
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 36,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'NT\$${item.price}',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock : ${item.currentStock}',
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
    );
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
                            onPressed: _openAddItemDialog,
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
                      Expanded(child: _buildGrid(context)),
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
                                  onTap: () => setState(() {
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
                                  onTap: () => setState(() {
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
