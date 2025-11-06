import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

// === IMPROVED COLOR SCHEME (sama dengan yang lain) ===
class AppColors {
  static const primary = Color(0xFF1354E0);
  static const primaryLight = Color(0xFF4A90E2);
  static const secondary = Color(0xFF6366F1);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  
  // Background colors
  static const background = Color(0xFFF8FAFC);
  static const cardBackground = Colors.white;
  static const divider = Color(0xFFE5E7EB);
  
  // Text colors
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
}

class AttendanceView extends StatefulWidget {
  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  StreamSubscription<QuerySnapshot>? _attendanceSubscription;
  List<QueryDocumentSnapshot> _attendances = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  String _selectedStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  Map<String, String> _userNames = {};
  Set<String> _availableDates = {};
  List<String> _filterOptions = ['Semua'];
  final List<String> _statusOptions = ['Semua', 'Hadir', 'Terlambat', 'Izin', 'Pulang Cepat'];

  @override
  void initState() {
    super.initState();
    _checkAuthAndInitialize();
  }

  void _checkAuthAndInitialize() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _initializeAttendanceStream();
      _loadUserNames();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'User not authenticated. Please login first.';
      });
    }
  }

  void _loadUserNames() async {
    try {
      print('=== LOADING USER NAMES FOR ATTENDANCE ===');
      
      final profilesSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .get()
          .timeout(const Duration(seconds: 10));
      
      Map<String, String> names = {};
      for (var doc in profilesSnapshot.docs) {
        final data = doc.data();
        final name = data['nama']?.toString() ?? 
                    data['name']?.toString() ?? 
                    data['displayName']?.toString() ?? 
                    'Unknown User';
        names[doc.id] = name;
        print('Profile loaded: ${doc.id} -> $name');
      }
      
      print('Total profiles loaded: ${names.length}');
      
      if (mounted) {
        setState(() {
          _userNames = names;
        });
      }
    } catch (e) {
      print('Error loading user names: $e');
      if (e.toString().contains('permission-denied')) {
        print('Permission denied when loading user profiles');
      }
    }
  }

  void _initializeAttendanceStream() {
    print('=== INITIALIZING ATTENDANCE STREAM ===');
    
    _attendanceSubscription = FirebaseFirestore.instance
        .collection('absensi')
        .snapshots()
        .listen(
          (snapshot) {
            print('Attendance stream update: ${snapshot.docs.length} documents');
            
            if (mounted) {
              // Extract unique dates for filter
              Set<String> dates = {};
              for (var doc in snapshot.docs) {
                final data = doc.data() as Map<String, dynamic>;
                
                String? dateString;
                
                // Check for string date field
                if (data['tanggal'] != null && data['tanggal'] is String) {
                  dateString = data['tanggal'].toString();
                } else if (data['Tanggal'] != null && data['Tanggal'] is String) {
                  dateString = data['Tanggal'].toString();
                }
                // Check for Timestamp date field
                else if (data['tanggal'] != null && data['tanggal'] is Timestamp) {
                  final timestamp = data['tanggal'] as Timestamp;
                  final date = timestamp.toDate();
                  dateString = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                } else if (data['Tanggal'] != null && data['Tanggal'] is Timestamp) {
                  final timestamp = data['Tanggal'] as Timestamp;
                  final date = timestamp.toDate();
                  dateString = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                }
                // Check for waktuAbsen as fallback
                else if (data['waktuAbsen'] != null && data['waktuAbsen'] is Timestamp) {
                  final timestamp = data['waktuAbsen'] as Timestamp;
                  final date = timestamp.toDate();
                  dateString = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                }
                
                if (dateString != null && dateString.isNotEmpty) {
                  dates.add(dateString);
                }
              }
              
              // Sort dates
              List<String> sortedDates = dates.toList();
              sortedDates.sort((a, b) {
                try {
                  List<String> partsA = a.split('-');
                  List<String> partsB = b.split('-');
                  
                  DateTime dateA = DateTime(
                    int.parse(partsA[2]), // year
                    int.parse(partsA[1]), // month
                    int.parse(partsA[0])  // day
                  );
                  DateTime dateB = DateTime(
                    int.parse(partsB[2]), // year
                    int.parse(partsB[1]), // month
                    int.parse(partsB[0])  // day
                  );
                  
                  return dateB.compareTo(dateA); // Sort descending (newest first)
                } catch (e) {
                  return b.compareTo(a); // Fallback to string comparison
                }
              });
              
              setState(() {
                _attendances = snapshot.docs;
                _availableDates = dates;
                _filterOptions = ['Semua', ...sortedDates];
                _isLoading = false;
                _error = null;
              });
              
              print('Total attendances loaded: ${_attendances.length}');
              print('Available dates: ${sortedDates.take(5).toList()}');
            }
          },
          onError: (error) {
            print('Error in attendance stream: $error');
            if (mounted) {
              setState(() {
                _isLoading = false;
                if (error.toString().contains('permission-denied')) {
                  _error = 'Permission denied. Please check your Firebase rules or ensure you are logged in.';
                } else {
                  _error = error.toString();
                }
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> get _filteredAttendances {
    List<QueryDocumentSnapshot> filtered = _attendances;

    // Filter by date
    if (_selectedFilter != 'Semua') {
      filtered = filtered.where((attendance) {
        final data = attendance.data() as Map<String, dynamic>;
        
        String dateString = '';
        
        if (data['tanggal'] != null && data['tanggal'] is String) {
          dateString = data['tanggal'].toString();
        } else if (data['Tanggal'] != null && data['Tanggal'] is String) {
          dateString = data['Tanggal'].toString();
        }
        else if (data['tanggal'] != null && data['tanggal'] is Timestamp) {
          final timestamp = data['tanggal'] as Timestamp;
          final date = timestamp.toDate();
          dateString = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
        } else if (data['Tanggal'] != null && data['Tanggal'] is Timestamp) {
          final timestamp = data['Tanggal'] as Timestamp;
          final date = timestamp.toDate();
          dateString = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
        }
        else if (data['waktuAbsen'] != null && data['waktuAbsen'] is Timestamp) {
          final timestamp = data['waktuAbsen'] as Timestamp;
          final date = timestamp.toDate();
          dateString = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
        }
        
        return dateString == _selectedFilter;
      }).toList();
    }

    // Filter by status
    if (_selectedStatus != 'Semua') {
      filtered = filtered.where((attendance) {
        final data = attendance.data() as Map<String, dynamic>;
        final status = (data['status'] ?? data['Status'] ?? '').toString().toLowerCase();
        final jenis = (data['jenis'] ?? data['Jenis'] ?? data['jenisAbsen'] ?? '').toString().toLowerCase();
        
        switch (_selectedStatus.toLowerCase()) {
          case 'hadir':
            return status.contains('hadir') || status.contains('present');
          case 'terlambat':
            return status.contains('terlambat') || status.contains('late');
          case 'izin':
            return status.contains('izin') || jenis.contains('izin') || status.contains('disetujui');
          case 'pulang cepat':
            return status.contains('pulang cepat') || status.contains('early leave') || jenis.contains('pulang cepat');
          default:
            return false;
        }
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((attendance) {
        final data = attendance.data() as Map<String, dynamic>;
        
        String tanggalString = '';
        if (data['tanggal'] != null) {
          if (data['tanggal'] is String) {
            tanggalString = data['tanggal'].toString();
          } else if (data['tanggal'] is Timestamp) {
            final timestamp = data['tanggal'] as Timestamp;
            final date = timestamp.toDate();
            tanggalString = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
          }
        } else if (data['Tanggal'] != null) {
          if (data['Tanggal'] is String) {
            tanggalString = data['Tanggal'].toString();
          } else if (data['Tanggal'] is Timestamp) {
            final timestamp = data['Tanggal'] as Timestamp;
            final date = timestamp.toDate();
            tanggalString = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
          }
        }
        
        final tanggal = tanggalString.toLowerCase();
        final waktu = (data['waktu'] ?? data['Waktu'] ?? data['jamAbsen'] ?? '').toString().toLowerCase();
        final lokasi = (data['lokasi'] ?? data['Lokasi'] ?? '').toString().toLowerCase();
        final jenis = (data['jenis'] ?? data['Jenis'] ?? data['jenisAbsen'] ?? '').toString().toLowerCase();
        final keterangan = (data['keterangan'] ?? data['Keterangan'] ?? '').toString().toLowerCase();
        final status = (data['status'] ?? data['Status'] ?? '').toString().toLowerCase();
        
        final searchLower = _searchQuery.toLowerCase();
        final userIdField = data['userId'] ?? data['uid'] ?? '';
        final userName = _userNames[userIdField] ?? '';
        final nama = userName.toLowerCase();
        
        return tanggal.contains(searchLower) ||
               waktu.contains(searchLower) ||
               lokasi.contains(searchLower) ||
               jenis.contains(searchLower) ||
               keterangan.contains(searchLower) ||
               status.contains(searchLower) ||
               nama.contains(searchLower);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    // FIXED: Gunakan SingleChildScrollView + Column instead of CustomScrollView
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderWidget(),
            const SizedBox(height: 20),
            _buildFiltersWidget(),
            const SizedBox(height: 20),
            if (_attendances.isNotEmpty) _buildCountInfo(),
            if (_attendances.isNotEmpty) const SizedBox(height: 16),
            _buildAttendancesList(),
            const SizedBox(height: 100), // Bottom padding for nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Memuat Data Absensi...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal Memuat Data Absensi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initializeAttendanceStream();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Absensi',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Laporan kehadiran karyawan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersWidget() {
    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Cari data absensi...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textLight,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.textLight),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textLight),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Date and Status Filters
        Row(
          children: [
            // Date Filter
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today, 
                        color: AppColors.primary, 
                        size: 18
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFilter == 'Semua' ? 'Semua Tanggal' : _selectedFilter,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _selectedFilter == 'Semua' 
                                ? AppColors.textSecondary 
                                : AppColors.textPrimary,
                            fontWeight: _selectedFilter == 'Semua' 
                                ? FontWeight.normal 
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Status Filter
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.filter_list, 
                      color: AppColors.primary, 
                      size: 18
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, 
                      vertical: 16
                    ),
                  ),
                  items: _statusOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: value == 'Semua' 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue ?? 'Semua';
                    });
                  },
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                  isExpanded: true,
                  dropdownColor: AppColors.cardBackground,
                  elevation: 8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${_filteredAttendances.length} data absensi ditemukan',
        style: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAttendancesList() {
    final filteredAttendances = _filteredAttendances;
    
    if (filteredAttendances.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: filteredAttendances.map((attendance) {
        final attendanceData = attendance.data() as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAttendanceCard(attendanceData),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchQuery.isNotEmpty || _selectedFilter != 'Semua' 
                ? Icons.search_off 
                : Icons.access_time_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'Semua' || _selectedStatus != 'Semua'
                ? 'Tidak Ada Data Absensi Ditemukan'
                : 'Tidak Ada Data Absensi Tersedia',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'Semua' || _selectedStatus != 'Semua'
                ? 'Coba sesuaikan pencarian atau filter Anda.'
                : 'Data absensi akan muncul di sini saat pengguna melakukan absensi.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _selectedFilter != 'Semua' || _selectedStatus != 'Semua') ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'Semua';
                  _selectedStatus = 'Semua';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Reset Filter',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> attendanceData) {
    final tanggal = attendanceData['tanggal'] ?? attendanceData['Tanggal'] ?? 'No Date';
    final waktu = attendanceData['jamAbsen'] ?? attendanceData['waktu'] ?? attendanceData['Waktu'] ?? 'No Time';
    final jenis = attendanceData['jenisAbsen'] ?? attendanceData['jenis'] ?? attendanceData['Jenis'] ?? 'Unknown';
    final lokasi = attendanceData['lokasi'] ?? attendanceData['Lokasi'] ?? 'No Location';
    final keterangan = attendanceData['keterangan'] ?? attendanceData['Keterangan'] ?? '';
    final status = attendanceData['status'] ?? attendanceData['Status'] ?? 'Present';
    final userIdField = attendanceData['userId'] ?? attendanceData['uid'] ?? '';
    final namaProfile = _userNames[userIdField] ?? 'Loading...';
    // Format tanggal jika berupa Timestamp
    String displayTanggal = tanggal.toString();
    String displayWaktu = waktu.toString();
    
    if (tanggal is Timestamp) {
      final date = tanggal.toDate();
      displayTanggal = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    }
    
    if (waktu is Timestamp) {
      final time = waktu.toDate();
      displayWaktu = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    // Get status color based on attendance status
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'hadir':
        case 'present':
          return const Color(0xFF4CAF50); // Hijau
        case 'terlambat':
        case 'late':
          return const Color(0xFFFFA726); // Kuning/Orange
        case 'pulang cepat':
        case 'early leave':
          return const Color(0xFFFFA726); // Kuning/Orange
        case 'izin':
        case 'disetujui':
        case 'approved':
          return const Color(0xFF2196F3); // Biru
        default:
          return const Color(0xFF9E9E9E); // Abu-abu
      }
    }

    IconData getStatusIcon(String status) {
      switch (status.toLowerCase()) {
        case 'hadir':
        case 'present':
          return Icons.check_circle_outline;
        case 'terlambat':
        case 'late':
          return Icons.schedule_rounded;
        case 'pulang cepat':
        case 'early leave':
          return Icons.logout_rounded;
        case 'izin':
        case 'disetujui':
        case 'approved':
          return Icons.info_outline_rounded;
        default:
          return Icons.access_time_rounded;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAttendanceDetails(attendanceData),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row - Fixed for overflow issues
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getStatusIcon(status),
                        color: getStatusColor(status),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2, // Give more space to the main content
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jenis.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$displayTanggal • $displayWaktu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge - Fixed size and constrained
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 80, // Limit badge width
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: getStatusColor(status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: getStatusColor(status),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Details Container - Better overflow handling
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Lokasi', lokasi, Icons.location_on_rounded),
                      if (keterangan.isNotEmpty) ...[
                        const Divider(height: 16, thickness: 0.5),
                        _buildDetailRow('Keterangan', keterangan, Icons.notes_rounded),
                      ],
                      const Divider(height: 16, thickness: 0.5),
                      _buildDetailRow('Nama', namaProfile, Icons.person_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, IconData icon, {bool isCompact = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isCompact ? 14 : 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: isCompact ? 6 : 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                color: const Color(0xFF2D3748),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetails(Map<String, dynamic> attendanceData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 0, 77, 150),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Detail Absensi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection('Tanggal', attendanceData['tanggal'] ?? attendanceData['Tanggal']),
                        _buildDetailSection('Waktu', attendanceData['jamAbsen'] ?? attendanceData['waktu'] ?? attendanceData['Waktu']),
                        _buildDetailSection('Jenis', attendanceData['jenisAbsen'] ?? attendanceData['jenis'] ?? attendanceData['Jenis']),
                        _buildDetailSection('Status', attendanceData['status'] ?? attendanceData['Status']),
                        _buildDetailSection('Lokasi', attendanceData['lokasi'] ?? attendanceData['Lokasi']),
                        if ((attendanceData['keterangan'] ?? attendanceData['Keterangan'] ?? '').toString().isNotEmpty)
                          _buildDetailSection('Keterangan', attendanceData['keterangan'] ?? attendanceData['Keterangan']),
                        _buildDetailSection('User', _getUserName(attendanceData)),
                        _buildDetailSection('User ID', _getUserId(attendanceData)),
                        if (attendanceData['foto'] != null)
                          _buildDetailSection('Foto', 'Ada foto tersimpan'),
                      ],
                    ),
                  ),
                ),
                
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tutup'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _exportSingleAttendance(attendanceData);
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Ekspor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 77, 150),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String label, dynamic value) {
    // Convert timestamp to readable format if needed
    String displayValue;
    if (value is Timestamp) {
      final date = value.toDate();
      displayValue = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      displayValue = value?.toString() ?? 'N/A';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Text(
              displayValue,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportSingleAttendance(Map<String, dynamic> attendanceData) {
    final jenis = attendanceData['jenis'] ?? attendanceData['Jenis'] ?? 'Unknown';
    final tanggal = attendanceData['tanggal'] ?? attendanceData['Tanggal'] ?? 'No Date';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ekspor data absensi: $jenis - $tanggal'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Colors.white,
          onPressed: () {
            // Open exported file location
          },
        ),
      ),
    );
  }

  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    // Show available dates as options
    if (_filterOptions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data tanggal tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Tanggal'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final date = _filterOptions[index];
                final isSelected = _selectedFilter == date;
                
                return ListTile(
                  title: Text(
                    date,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? const Color.fromARGB(255, 0, 77, 150) : null,
                    ),
                  ),
                  leading: Icon(
                    date == 'Semua' ? Icons.list : Icons.calendar_today,
                    color: isSelected ? const Color.fromARGB(255, 0, 77, 150) : Colors.grey,
                    size: 20,
                  ),
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedFilter = date;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  String _getUserName(Map<String, dynamic> attendanceData) {
    final userId = attendanceData['userId']?.toString();
    final uid = attendanceData['uid']?.toString();
    final userIdField = userId ?? uid;
    
    if (userIdField != null) {
      return _userNames[userIdField] ?? 'Unknown User';
    }
    return 'Unknown User';
  }

  String _getUserId(Map<String, dynamic> attendanceData) {
    final userId = attendanceData['userId']?.toString();
    final uid = attendanceData['uid']?.toString();
    return userId ?? uid ?? 'N/A';
  }
}