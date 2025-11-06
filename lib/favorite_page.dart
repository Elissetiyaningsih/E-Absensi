import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class AttendanceHistoryPage extends StatefulWidget {
  @override
  _AttendanceHistoryPageState createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  // Warna konsisten - menggunakan tema biru-ungu yang modern
  static const Color primaryColor = Color(0xFF6366F1);     // Indigo 500
  static const Color lightBackground = Color(0xFFF0F4FF);  // Light indigo
  static const Color veryLightBackground = Color(0xFFFAFBFF);

  DateTime selectedMonth = DateTime.now();
  String selectedStatus = 'Semua';
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  // Inisialisasi locale Indonesia
  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('id_ID', null);
      setState(() {
        _localeInitialized = true;
      });
    } catch (e) {
      print('Error initializing locale: $e');
      // Fallback ke English jika gagal
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: _buildLoginPrompt(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(child: _buildAttendanceList(user.uid)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        'Riwayat Absensi',
        style: TextStyle(
          color: Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.w600
        ),
      ),
           backgroundColor: const Color(0xFF6366F1), // Indigo modern
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A90E2), // Purple
                Color(0xFF7B68EE), // Indigo
              ],
            ),
          ),
        ),
      );
        
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Silakan login untuk melihat riwayat absensi.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Riwayat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildMonthSelector(),
              const SizedBox(height: 12),
              _buildStatusFilter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return InkWell(
      onTap: () => _selectMonth(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatMonth(selectedMonth),
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: selectedStatus,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.filter_list, color: primaryColor, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: ['Semua', 'Hadir', 'Terlambat', 'Disetujui', 'Alpha'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value, 
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedStatus = newValue!;
          });
        },
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedMonth) {
      setState(() {
        selectedMonth = picked;
      });
    }
  }

  Widget _buildAttendanceList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('absensi')  // Baca dari collection 'absensi'
          .where('userId', isEqualTo: userId)  // Filter berdasarkan userId
          .orderBy('createdAt', descending: true)  // Urutkan berdasarkan createdAt
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        var attendanceRecords = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          
          // Gunakan tanggal dari field 'tanggal' atau 'createdAt'
          DateTime recordDate;
          if (data['tanggal'] != null) {
            recordDate = (data['tanggal'] as Timestamp).toDate();
          } else if (data['createdAt'] != null) {
            recordDate = (data['createdAt'] as Timestamp).toDate();
          } else {
            return false; // Skip jika tidak ada tanggal
          }
          
          // Filter by month
          bool matchesMonth = recordDate.year == selectedMonth.year && 
                             recordDate.month == selectedMonth.month;
          
          // Filter by status
          bool matchesStatus = selectedStatus == 'Semua' || 
                              data['status'] == selectedStatus;
          
          return matchesMonth && matchesStatus;
        }).toList();

        if (attendanceRecords.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: attendanceRecords.length,
          itemBuilder: (context, index) {
            var record = attendanceRecords[index];
            var data = record.data() as Map<String, dynamic>;
            
            return _buildAttendanceCard(data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: lightBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_outlined,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Belum ada riwayat absensi",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Mulai absensi untuk melihat riwayat",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> data) {
    // Gunakan field yang sesuai dengan data dari AbsenPagiDetailPage
    DateTime date;
    if (data['tanggal'] != null) {
      date = (data['tanggal'] as Timestamp).toDate();
    } else if (data['createdAt'] != null) {
      date = (data['createdAt'] as Timestamp).toDate();
    } else {
      date = DateTime.now(); // fallback
    }
    
    String status = data['status'] ?? 'Tidak Diketahui';
    String time = data['jamAbsen'] ?? data['time'] ?? ''; // Untuk izin, bisa kosong
    
    // Deteksi jika ini adalah data izin
    bool isIzin = data['jenisData'] == 'izin';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 18,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _formatDate(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isIzin ? data['jenisIzin'] ?? '' : time, // Tampilkan jenis izin atau waktu
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, 
                    vertical: 2
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (data['catatan'] != null && data['catatan'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.note_outlined,
                    size: 12,
                    color: Colors.grey[400],
                  ),
                ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
          size: 20,
        ),
        onTap: () => _showAttendanceDetail(data, date),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hadir':
        return Colors.green;
      case 'Terlambat':
        return Colors.orange;
      case 'Pulang Cepat':
        return Colors.orange;
      case 'Disetujui':
        return Colors.blue;
      case 'Alpha':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Hadir':
        return Icons.check_circle_outline;
      case 'Terlambat':
        return Icons.schedule;
      case 'Pulang Cepat':
        return Icons.schedule_outlined;
      case 'Disetujui':
        return Icons.verified;
      case 'Alpha':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  void _showAttendanceDetail(Map<String, dynamic> data, DateTime date) {
    bool isIzin = data['jenisData'] == 'izin';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIzin ? 'Detail Izin' : 'Detail Absensi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatFullDate(date),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      'Status',
                      data['status'] ?? 'Tidak Diketahui',
                      Icons.info_outline,
                      _getStatusColor(data['status'] ?? ''),
                    ),
                    
                    // Tampilkan detail berbeda untuk izin vs absensi
                    if (isIzin) ...[
                      _buildDetailItem(
                        'Jenis Izin',
                        data['jenisIzin'] ?? 'Tidak Diketahui',
                        Icons.category_outlined,
                        primaryColor,
                      ),
                      if (data['tanggalSelesai'] != null)
                        _buildDetailItem(
                          'Periode',
                          '${_formatDate((data['tanggal'] as Timestamp).toDate())} - ${_formatDate((data['tanggalSelesai'] as Timestamp).toDate())}',
                          Icons.date_range,
                          primaryColor,
                        ),
                      _buildDetailItem(
                        'Alasan',
                        data['alasan'] ?? data['catatan'] ?? 'Tidak ada keterangan',
                        Icons.edit_note_outlined,
                        primaryColor,
                      ),
                    ] else ...[
                      _buildDetailItem(
                        'Waktu',
                        data['jamAbsen'] ?? data['time'] ?? 'Tidak Diketahui',
                        Icons.access_time,
                        primaryColor,
                      ),
                      _buildDetailItem(
                        'Jenis Absen',
                        data['jenisAbsen'] ?? 'Tidak Diketahui',
                        Icons.category_outlined,
                        primaryColor,
                      ),
                      if (data['lokasi'] != null && data['lokasi'].toString().isNotEmpty)
                        _buildDetailItem(
                          'Lokasi',
                          data['lokasi'],
                          Icons.location_on_outlined,
                          primaryColor,
                        ),
                      if (data['catatan'] != null && data['catatan'].toString().isNotEmpty)
                        _buildDetailItem(
                          'Catatan',
                          data['catatan'],
                          Icons.note_outlined,
                          primaryColor,
                        ),
                    ],
                    
                    // Foto/Dokumen
                    if (data['fotoUrl'] != null || data['dokumenUrl'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            isIzin ? 'Dokumen Pendukung' : 'Foto Absensi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                data['fotoUrl'] ?? data['dokumenUrl'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey[400],
                                      size: 48,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods untuk formatting tanggal dengan fallback
  String _formatMonth(DateTime date) {
    try {
      return DateFormat('MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      // Fallback ke format manual jika locale gagal
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEE, dd MMM', 'id_ID').format(date);
    } catch (e) {
      // Fallback ke format manual
      const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      int weekday = date.weekday == 7 ? 0 : date.weekday;
      return '${days[weekday]}, ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
    }
  }

  String _formatFullDate(DateTime date) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      // Fallback ke format manual
      const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      int weekday = date.weekday == 7 ? 0 : date.weekday;
      return '${days[weekday]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}