import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? currentProfileData;
  final String? userId;
  
  const EditProfileScreen({Key? key, this.currentProfileData, this.userId}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Text controllers untuk form
  late TextEditingController namaController;
  late TextEditingController emailController;
  late TextEditingController jabatanController;
  late TextEditingController departemenController;
  late TextEditingController teleponController;
  late TextEditingController alamatController;
  
  String selectedStatus = 'Aktif';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers dengan data yang ada
    namaController = TextEditingController(
      text: widget.currentProfileData?['nama'] ?? ''
    );
    emailController = TextEditingController(
      text: _auth.currentUser?.email ?? widget.currentProfileData?['email'] ?? ''
    );
    jabatanController = TextEditingController(
      text: widget.currentProfileData?['jabatan'] ?? ''
    );
    departemenController = TextEditingController(
      text: widget.currentProfileData?['departemen'] ?? ''
    );
    teleponController = TextEditingController(
      text: widget.currentProfileData?['telepon'] ?? ''
    );
    alamatController = TextEditingController(
      text: widget.currentProfileData?['alamat'] ?? ''
    );
    
    selectedStatus = widget.currentProfileData?['status'] ?? 'Aktif';
  }

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    jabatanController.dispose();
    departemenController.dispose();
    teleponController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    print('=== SAVE PROFILE STARTED ===');
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        String userId = widget.userId ?? _auth.currentUser?.uid ?? '';
        print('User ID: $userId');
        
        if (userId.isEmpty) {
          throw Exception('User tidak ditemukan');
        }

        // Data yang akan diupdate
        Map<String, dynamic> updatedData = {
          'nama': namaController.text.trim(),
          'email': emailController.text.trim(),
          'jabatan': jabatanController.text.trim(),
          'departemen': departemenController.text.trim(),
          'status': selectedStatus,
          'telepon': teleponController.text.trim(),
          'alamat': alamatController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        print('Data to update: $updatedData');

        DocumentSnapshot docSnapshot = await _firestore
            .collection('profiles')
            .doc(userId)
            .get();

        if (!docSnapshot.exists) {
          print('Document tidak ada, membuat document baru...');
          // Tambahkan createdAt jika document baru
          updatedData['createdAt'] = FieldValue.serverTimestamp();
          await _firestore
              .collection('profiles')
              .doc(userId)
              .set(updatedData);
          print('Document baru berhasil dibuat');
        } else {
          print('Document ada, melakukan update...');
          await _firestore
              .collection('profiles')
              .doc(userId)
              .update(updatedData);
          print('Document berhasil diupdate');
        }

        setState(() {
          isLoading = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Profil berhasil diperbarui!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(20),
            ),
          );

          // Return updated data
          Navigator.pop(context, updatedData);
        }

      } catch (e) {
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal mengupdate profil: ${e.toString()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(20),
            ),
          );
        }

        print('Error updating profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A90E2),
                Color(0xFF7B68EE),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Card dengan Avatar
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF7B68EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Foto Profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header - Informasi Personal
                    Text(
                      'Informasi Personal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Nama Field
                    _buildInputField(
                      controller: namaController,
                      label: 'Nama Lengkap',
                      icon: Icons.person_rounded,
                      iconColor: Colors.blue[600]!,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        if (value.length < 2) {
                          return 'Nama minimal 2 karakter';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Email Field (Read Only)
                    _buildInputField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_rounded,
                      iconColor: Colors.red[600]!,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Jabatan Field
                    _buildInputField(
                      controller: jabatanController,
                      label: 'Jabatan',
                      icon: Icons.work_rounded,
                      iconColor: Colors.purple[600]!,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jabatan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Departemen Field
                    _buildInputField(
                      controller: departemenController,
                      label: 'Bidang',
                      icon: Icons.business_rounded,
                      iconColor: Colors.indigo[600]!,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Departemen tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Status Dropdown
                    _buildStatusDropdown(),

                    const SizedBox(height: 24),
                    
                    // Section Header - Informasi Kontak
                    Text(
                      'Informasi Kontak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Telepon Field
                    _buildInputField(
                      controller: teleponController,
                      label: 'No. Telepon',
                      icon: Icons.phone_rounded,
                      iconColor: Colors.green[600]!,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor telepon tidak boleh kosong';
                        }
                        if (value.length < 10) {
                          return 'Nomor telepon minimal 10 digit';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Alamat Field
                    _buildInputField(
                      controller: alamatController,
                      label: 'Alamat',
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.orange[600]!,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alamat tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child: isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Menyimpan...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk input field dengan style konsisten dengan halaman absen
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Garis kiri berwarna
          Container(
            width: 4,
            height: maxLines > 1 ? 80 : 60,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          // Input Field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (readOnly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Tidak dapat diedit',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller,
                    validator: validator,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    readOnly: readOnly,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: readOnly ? Colors.grey[600] : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Masukkan $label',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // Widget untuk status dropdown
  Widget _buildStatusDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Garis kiri berwarna
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_rounded,
              color: Colors.teal[600],
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          // Dropdown
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    items: ['Aktif', 'Tidak Aktif', 'Pending'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: value == 'Aktif' 
                                    ? Colors.green 
                                    : value == 'Pending'
                                        ? Colors.orange
                                        : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(value),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStatus = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}