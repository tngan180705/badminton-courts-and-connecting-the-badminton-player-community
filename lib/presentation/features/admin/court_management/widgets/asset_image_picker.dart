import 'package:flutter/material.dart';

class AssetImagePicker extends StatefulWidget {
  final Function(String) onImageSelected;
  final String? initialValue;

  const AssetImagePicker({
    super.key, 
    required this.onImageSelected, 
    this.initialValue,
  });

  @override
  State<AssetImagePicker> createState() => _AssetImagePickerState();
}

class _AssetImagePickerState extends State<AssetImagePicker> {
  // Danh sách khớp hoàn toàn với cây thư mục tree -a của bạn
  final List<String> _availableImages = [
    'assets/images/san1.jpg',
    'assets/images/san2.jpg',
    'assets/images/san3.jpg',
  ];

  String? _selectedAsset;

  @override
  void initState() {
    super.initState();
    // Nếu có giá trị ban đầu thì dùng, không thì mặc định lấy ảnh đầu tiên
    _selectedAsset = widget.initialValue ?? _availableImages.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Chọn ảnh minh họa sân:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableImages.length,
            itemBuilder: (context, index) {
              final imgPath = _availableImages[index];
              final isSelected = _selectedAsset == imgPath;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedAsset = imgPath);
                  widget.onImageSelected(imgPath);
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey[300]!,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      imgPath, 
                      fit: BoxFit.cover,
                      // Thêm errorBuilder để tránh crash app nếu sai đường dẫn
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}