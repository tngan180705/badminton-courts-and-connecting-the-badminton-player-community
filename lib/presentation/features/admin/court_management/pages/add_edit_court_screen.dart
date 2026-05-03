import 'package:badminton_app/data/models/court_model.dart';
import 'package:badminton_app/presentation/features/admin/court_management/providers/admin_court_provider.dart';
import 'package:badminton_app/presentation/features/admin/court_management/widgets/asset_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddEditCourtScreen extends ConsumerStatefulWidget {
  final CourtModel? court;
  const AddEditCourtScreen({super.key, this.court});

  @override
  ConsumerState<AddEditCourtScreen> createState() => _AddEditCourtScreenState();
}

class _AddEditCourtScreenState extends ConsumerState<AddEditCourtScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;
  String _selectedImagePath = ''; // Lưu đường dẫn ảnh asset

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.court?.name ?? '');
    _addressController =
        TextEditingController(text: widget.court?.address ?? '');
    _priceController = TextEditingController(
        text: widget.court?.pricePerHour.toString() ?? '');
    _openTimeController =
        TextEditingController(text: widget.court?.openTime ?? '05:00');
    _closeTimeController =
        TextEditingController(text: widget.court?.closeTime ?? '22:00');
    // Ưu tiên lấy ảnh cũ, nếu không có thì mặc định san1
    _selectedImagePath = widget.court?.imageUrl ?? 'assets/images/san1.jpg';
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final newCourt = CourtModel(
        courtId: widget.court?.courtId ?? '',
        ownerId: widget.court?.ownerId ?? 'ADMIN_ID',
        name: _nameController.text,
        address: _addressController.text,
        latitude: 0.0,
        longitude: 0.0,
        pricePerHour: double.parse(_priceController.text),
        openTime: _openTimeController.text,
        closeTime: _closeTimeController.text,
        createdAt: widget.court?.createdAt ?? DateTime.now(),
        imageUrl: _selectedImagePath, // Sử dụng ảnh đã chọn từ Asset
      );

      final notifier = ref.read(adminCourtActionProvider.notifier);

      if (widget.court == null) {
        await notifier.addNewCourt(newCourt);
      } else {
        await notifier.editCourt(newCourt);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.court == null ? 'Thêm sân mới' : 'Sửa thông tin'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Widget chọn ảnh từ Assets đã viết ở bước trước
            AssetImagePicker(
              initialValue: _selectedImagePath,
              onImageSelected: (path) {
                setState(() => _selectedImagePath = path);
              },
            ),
            const SizedBox(height: 20),

            // 2. Các ô nhập liệu
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Tên sân', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                  labelText: 'Địa chỉ', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                  labelText: 'Giá mỗi giờ',
                  border: OutlineInputBorder(),
                  suffixText: 'đ'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập giá' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _openTimeController,
                    decoration: const InputDecoration(
                        labelText: 'Mở cửa',
                        border: OutlineInputBorder(),
                        hintText: '05:00'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _closeTimeController,
                    decoration: const InputDecoration(
                        labelText: 'Đóng cửa',
                        border: OutlineInputBorder(),
                        hintText: '22:00'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 3. Nút Lưu
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
                onPressed: _saveForm,
                child: const Text('LƯU THÔNG TIN SÂN',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
