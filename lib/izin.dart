import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:absenku/favorite_page.dart';

// Halaman Detail Ajukan Izin dengan implementasi foto opsional dan Firestore
class AjukanIzinDetailPage extends StatefulWidget {
  const AjukanIzinDetailPage({super.key});

  @override
  State<AjukanIzinDetailPage> createState() => _AjukanIzinDetailPageState();
}

class _AjukanIzinDetailPageState extends State<AjukanIzinDetailPage> {
  final TextEditingController _alasanController = TextEditingController();
  final TextEditingController _tanggalMulaiController = TextEditingController();
  final TextEditingController _tanggalSelesaiController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  String _jenisIzin = 'Sakit';
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  File? _selectedDocument;

  final List<String> _jenisIzinList = ['Sakit', 'Cuti', 'Keperluan Lain'];

  // Cloudinary configuration
  static const String CLOUDINARY_URL = 'https://api.cloudinary.com/v1_1/dlcj382to/image/upload';
  static const String CLOUDINARY_UPLOAD_PRESET = 'absensi_preset';

  // Warna merah yang bagus dan konsisten
  static const Color primaryRed = Color(0xFFE74C3C);     // Merah vibrant
  static const Color primaryRedDark = Color(0xFFC0392B);  // Merah gelap
  static const Color primaryRedLight = Color(0xFFFF6B6B); // Coral red terang
  static const Color lightRedBackground = Color(0xFFFEF2F2); // Red 50
  static const Color veryLightRedBackground = Color(0xFFFFFAFA);
  static const Color redAccent = Color(0xFFFCA5A5);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _tanggalMulai = picked;
          _tanggalMulaiController.text = '${picked.day}/${picked.month}/${picked.year}';
        } else {
          _tanggalSelesai = picked;
          _tanggalSelesaiController.text = '${picked.day}/${picked.month}/${picked.year}';
        }
      });
    }
  }

  // Fungsi untuk menampilkan pilihan sumber dokumen
  void _showDocumentSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Sumber Dokumen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryRed),
                title: const Text('Kamera'),
                subtitle: const Text('Foto dokumen'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoFromCamera();
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryRed),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk mengambil foto dari kamera
  Future<void> _takePhotoFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedDocument = File(image.path);
        });
      }
    } catch (e) {
      String errorMessage = 'Gagal mengambil foto dari kamera';
      
      if (e.toString().contains('no_available_camera')) {
        errorMessage = 'Kamera tidak tersedia di emulator. Coba gunakan galeri atau perangkat fisik.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Coba Galeri',
              textColor: Colors.white,
              onPressed: _pickFromGallery,
            ),
          ),
        );
      }
    }
  }

  // Fungsi untuk memilih foto dari galeri
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedDocument = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  // Fungsi untuk upload dokumen ke Cloudinary (opsional)
  Future<String?> _uploadDocumentToCloudinary(File documentFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(CLOUDINARY_URL));
      request.files.add(await http.MultipartFile.fromPath('file', documentFile.path));
      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      print('Response status: ${response.statusCode}');
      print('Response body: $responseString');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(responseString);
        return jsonResponse['secure_url'];
      } else {
        print('Upload failed: $responseString');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Fungsi untuk submit izin ke Firestore
  void _submitIzin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda harus login terlebih dahulu'),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    if (_alasanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alasan izin harus diisi!'),
          backgroundColor: primaryRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_tanggalMulai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tanggal mulai harus dipilih!'),
          backgroundColor: primaryRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload dokumen ke Cloudinary jika ada (opsional)
      String? documentUrl;
      if (_selectedDocument != null) {
        documentUrl = await _uploadDocumentToCloudinary(_selectedDocument!);
        if (documentUrl == null) {
          throw Exception('Gagal mengupload dokumen pendukung');
        }
      }

      // Simpan data izin ke Firestore - COLLECTION ABSENSI YANG SAMA
      final now = DateTime.now();
      final izinData = {
        'userId': user.uid,
        'email': user.email,
        'jenisData': 'izin',  // Field pembeda: 'izin' vs 'absensi'
        'jenisIzin': _jenisIzin,
        'alasan': _alasanController.text.trim(),
        'tanggalMulai': Timestamp.fromDate(_tanggalMulai!),
        'tanggalSelesai': _tanggalSelesai != null ? Timestamp.fromDate(_tanggalSelesai!) : null,
        'dokumenUrl': documentUrl, // Bisa null jika tidak ada dokumen
        'status': 'Disetujui',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Field tambahan untuk konsistensi dengan data absensi
        'tanggal': Timestamp.fromDate(_tanggalMulai!), // Tanggal utama untuk filter
        'jamAbsen': '', // Kosong untuk izin
        'jenisAbsen': 'izin', // Tambahan field untuk identifikasi
        'lokasi': '', // Kosong untuk izin
        'catatan': _alasanController.text.trim(), // Sama dengan alasan
        'fotoUrl': documentUrl, // Dokumen sebagai foto (opsional)
      };

      // Simpan ke collection absensi yang sama
      await FirebaseFirestore.instance
          .collection('absensi')
          .add(izinData);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pengajuan izin berhasil dikirim!'),
            backgroundColor: Colors.green[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Route ke halaman riwayat atau kembali
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceHistoryPage(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan izin: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Ajukan Izin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryRedLight,  // FF6B6B - Coral red terang
                primaryRed,       // E74C3C - Merah vibrant
                primaryRedDark,   // C0392B - Merah gelap
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header dengan warna yang konsisten
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lightRedBackground, veryLightRedBackground],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: redAccent.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: primaryRed,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ajukan Izin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryRedDark,
                    ),
                  ),
                  Text(
                    'Sakit, Cuti, Keperluan Lain',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Jenis Izin Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Jenis Izin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _jenisIzin,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        onChanged: (String? newValue) {
                          setState(() {
                            _jenisIzin = newValue!;
                          });
                        },
                        items: _jenisIzinList.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tanggal Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.date_range_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Periode Izin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tanggal Mulai
                  Text(
                    'Tanggal Mulai *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _tanggalMulaiController.text.isEmpty 
                                ? 'Pilih tanggal mulai' 
                                : _tanggalMulaiController.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: _tanggalMulaiController.text.isEmpty 
                                  ? Colors.grey[400] 
                                  : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tanggal Selesai
                  Text(
                    'Tanggal Selesai (Opsional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _tanggalSelesaiController.text.isEmpty 
                                ? 'Pilih tanggal selesai' 
                                : _tanggalSelesaiController.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: _tanggalSelesaiController.text.isEmpty 
                                  ? Colors.grey[400] 
                                  : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Dokumen Pendukung Section - Sekarang Aktif
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_file_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Dokumen Pendukung (Opsional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showDocumentSourceDialog,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _selectedDocument != null ? Colors.transparent : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDocument != null ? primaryRed : Colors.grey[300]!,
                          width: _selectedDocument != null ? 2 : 1,
                        ),
                      ),
                      child: _selectedDocument != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _selectedDocument!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _showDocumentSourceDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 36,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap untuk upload dokumen',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '(Surat dokter, dll)',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Alasan Section dengan focus border warna merah
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Alasan Izin *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _alasanController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Jelaskan alasan izin Anda...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryRed, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button dengan gradasi yang konsisten
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      primaryRed,       // E74C3C
                      primaryRedDark,   // C0392B
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitIzin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Ajukan Izin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _alasanController.dispose();
    _tanggalMulaiController.dispose();
    _tanggalSelesaiController.dispose();
    super.dispose();
  }
}