import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:absenku/services/auth_services.dart';
import 'package:flutter/foundation.dart';
import 'package:absenku/pages/admin/user_page.dart';
import 'package:absenku/pages/admin/absen.dart';
import 'package:google_fonts/google_fonts.dart';

// === IMPROVED COLOR SCHEME ===
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

// === DATA CLASSES ===
class AbsensiDashboardData {
  int totalUsers = 0;
  int totalAbsenHariIni = 0;
  int totalHadirHariIni = 0;
  int totalTerlambat = 0;
  int totalIzin = 0;
  List<Map<String, dynamic>> recentAbsensi = [];

  AbsensiDashboardData();
  
  factory AbsensiDashboardData.empty() => AbsensiDashboardData();
}

class QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class NavigationItem {
  final String label;
  final IconData icon;
  
  NavigationItem(this.label, this.icon);
}

// === MAIN DASHBOARD CLASS ===
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem('Dashboard', Icons.dashboard_rounded),
    NavigationItem('Pengguna', Icons.people_alt_rounded),
    NavigationItem('Absensi', Icons.access_time_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: _getSelectedView(),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Container(
                      //   padding: const EdgeInsets.all(8),
                      //   decoration: BoxDecoration(
                      //     color: Colors.white.withOpacity(0.2),
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Icon(
                      //     _navigationItems[_selectedIndex].icon,
                      //     color: Colors.white,
                      //     size: 24,
                      //   ),
                      // ),
                      // const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _navigationItems[_selectedIndex].label,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _getPageSubtitle(),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => AuthService().signout(context: context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPageSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Kelola sistem absensi karyawan';
      case 1:
        return 'Manajemen data pengguna';
      case 2:
        return 'Laporan kehadiran karyawan';
      default:
        return '';
    }
  }

  Widget _getSelectedView() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardView();
      case 1:
        return const UsersPage();
      case 2:
        return AttendanceView();
      default:
        return const DashboardView();
    }
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textLight,
      backgroundColor: AppColors.cardBackground,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      items: _navigationItems.map((item) {
        return BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Icon(item.icon, size: 22),
          ),
          activeIcon: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 22),
          ),
          label: item.label,
        );
      }).toList(),
    );
  }
}

// === DASHBOARD VIEW ===
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final AbsensiController _controller = AbsensiController();

  @override
  void initState() {
    super.initState();
    _controller.initializeStreams();
    if (kDebugMode) {
      _controller.debugTestWriteLocations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            StreamBuilder<AbsensiDashboardData>(
              stream: _controller.dashboardStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                
                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                }
                
                final data = snapshot.data ?? AbsensiDashboardData.empty();
                
                return Column(
                  children: [
                    _buildStatsGrid(data),
                    const SizedBox(height: 24),
                    _buildRecentActivity(data.recentAbsensi),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 100), // Bottom padding untuk nav bar
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildLoadingCard(),
        const SizedBox(height: 16),
        _buildLoadingCard(),
        const SizedBox(height: 16),
        _buildLoadingCard(),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
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
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return ModernCard(
      child: Column(
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
            'Gagal Memuat Data',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Periksa koneksi internet dan coba lagi',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _controller.initializeStreams(),
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
    );
  }

  Widget _buildWelcomeHeader() {
    return ModernCard(
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
              Icons.dashboard_rounded,
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
                  'Selamat datang, Admin!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCurrentDate(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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

  Widget _buildStatsGrid(AbsensiDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Hari Ini',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Hadir',
                value: data.totalHadirHariIni.toString(),
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Total Absen',
                value: data.totalAbsenHariIni.toString(),
                icon: Icons.access_time_rounded,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Terlambat',
                value: data.totalTerlambat.toString(),
                icon: Icons.schedule_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Total User',
                value: data.totalUsers.toString(),
                icon: Icons.people_rounded,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(List<Map<String, dynamic>> recentAbsensi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terbaru',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {}, // Navigate to full list
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentAbsensi.isEmpty)
          ModernCard(
            child: EmptyState(
              icon: Icons.inbox_rounded,
              title: 'Belum Ada Absensi',
              subtitle: 'Absensi hari ini akan muncul di sini',
            ),
          )
        else
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: recentAbsensi.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final isLast = index == recentAbsensi.length - 1;
                return AbsensiTile(data: data, isLast: isLast);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      QuickActionData(
        title: 'Ekspor Data Absensi',
        subtitle: 'Download laporan absensi dalam format CSV',
        icon: Icons.file_download_rounded,
        color: AppColors.success,
        onTap: () => _controller.showExportDialog(context),
      ),
      QuickActionData(
        title: 'Ekspor Data Pengguna',
        subtitle: 'Download daftar pengguna sistem',
        icon: Icons.people_rounded,
        color: AppColors.info,
        onTap: () => _controller.exportUsers(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map((action) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: QuickActionCard(action: action),
        )),
      ],
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    return formatter.format(now);
  }
}

// === REUSABLE WIDGETS ===
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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
      child: child,
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AbsensiTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLast;

  const AbsensiTile({super.key, required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(data['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(data['status']),
              color: _getStatusColor(data['status']),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(data),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${data['jamAbsen'] ?? 'N/A'} • ${data['jenisAbsen'] ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(data['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              data['status'] ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(data['status']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(Map<String, dynamic> data) {
    if (data['nama'] != null && data['nama'].toString().isNotEmpty) {
      return data['nama'].toString();
    }
    if (data['name'] != null && data['name'].toString().isNotEmpty) {
      return data['name'].toString();
    }
    if (data['email'] != null) {
      String email = data['email'].toString();
      return email.split('@')[0];
    }
    return 'Unknown User';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir':
        return AppColors.success;
      case 'terlambat':
        return AppColors.warning;
      case 'izin':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir':
        return Icons.check_circle_rounded;
      case 'terlambat':
        return Icons.schedule_rounded;
      case 'izin':
        return Icons.assignment_outlined;
      default:
        return Icons.access_time_rounded;
    }
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final QuickActionData action;

  const QuickActionCard({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(action.icon, color: action.color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === CONTROLLER CLASS (FIXED) ===
class AbsensiController {
  final List<StreamSubscription> _subscriptions = [];
  final StreamController<AbsensiDashboardData> _dashboardController = 
      StreamController<AbsensiDashboardData>.broadcast();

  Stream<AbsensiDashboardData> get dashboardStream => _dashboardController.stream;

  void initializeStreams() {
    final data = AbsensiDashboardData();

    try {
      _subscriptions.add(
        FirebaseFirestore.instance
            .collection('users')
            .snapshots()
            .handleError((error) {
              _dashboardController.addError(error);
            })
            .listen((snapshot) {
              data.totalUsers = snapshot.docs.length;
              _dashboardController.add(data);
            }),
      );

      _subscriptions.add(
        FirebaseFirestore.instance
            .collection('absensi')
            .orderBy('waktuAbsen', descending: true)
            .limit(100)
            .snapshots()
            .handleError((error) {
              return FirebaseFirestore.instance
                  .collection('absensi')
                  .limit(50)
                  .snapshots();
            })
            .listen((snapshot) {
              final today = DateTime.now();
              final todayDocs = snapshot.docs.where((doc) {
                final docData = doc.data() as Map<String, dynamic>;
                if (docData['waktuAbsen'] != null) {
                  final timestamp = docData['waktuAbsen'] as Timestamp;
                  final date = timestamp.toDate();
                  return date.day == today.day && 
                         date.month == today.month && 
                         date.year == today.year;
                }
                return false;
              }).toList();
              
              data.totalAbsenHariIni = todayDocs.length;
              data.totalHadirHariIni = todayDocs
                  .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'hadir')
                  .length;
              data.totalTerlambat = todayDocs
                  .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'terlambat')
                  .length;
              
              todayDocs.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['waktuAbsen'] as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['waktuAbsen'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });
              
              data.recentAbsensi = todayDocs
                  .take(5)
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();
              
              _dashboardController.add(data);
            }),
      );
    } catch (e) {
      _dashboardController.addError(e);
    }
  }

  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _dashboardController.close();
  }

  // Method untuk debug testing - sudah diperbaiki nama methodnya
  void debugTestWriteLocations() {
    if (kDebugMode) {
      print('Testing write locations for admin dashboard...');
    }
  }

  void showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Export Data Absensi',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExportOption(
              'Export Semua Absensi',
              Icons.table_chart_rounded,
              () {
                Navigator.pop(context);
                _exportAllAbsensi(context);
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              'Export Absensi Hari Ini',
              Icons.today_rounded,
              () {
                Navigator.pop(context);
                _exportTodayAbsensi(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Export methods dengan error handling yang lebih baik
  Future<void> _exportAllAbsensi(BuildContext context) async {
    if (!context.mounted) return;
    
    OverlayEntry? loadingOverlay;
    
    try {
      loadingOverlay = _showModernLoadingOverlay(context, 'Mengunduh data absensi...');
      
      if (!(await _requestStoragePermission(context))) {
        _hideLoadingOverlay(loadingOverlay);
        return;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('absensi')
          .get()
          .timeout(const Duration(seconds: 30));

      if (snapshot.docs.isEmpty) {
        _hideLoadingOverlay(loadingOverlay);
        if (context.mounted) {
          _showModernSnackBar(context, 'Tidak ada data absensi untuk diekspor', AppColors.warning);
        }
        return;
      }

      final csvData = _prepareAbsensiCsvData(snapshot.docs);
      final csvString = const ListToCsvConverter().convert(csvData);

      _hideLoadingOverlay(loadingOverlay);
      loadingOverlay = null;

      final fileName = 'absensi_all_${DateFormat('ddMMyyyy_HHmmss').format(DateTime.now())}.csv';
      
      try {
        await _saveAndDownloadFile(context, csvString, fileName);
      } catch (saveError) {
        if (context.mounted) {
          _showModernSnackBar(context, 'Error saving file: $saveError', AppColors.danger);
        }
      }

    } catch (e) {
      _hideLoadingOverlay(loadingOverlay);
      if (context.mounted) {
        _showModernSnackBar(context, 'Gagal mengunduh data absensi: $e', AppColors.danger);
      }
    }
  }

  Future<void> _exportTodayAbsensi(BuildContext context) async {
    if (!context.mounted) return;
    
    OverlayEntry? loadingOverlay;
    
    try {
      loadingOverlay = _showModernLoadingOverlay(context, 'Mengunduh data absensi hari ini...');

      if (!(await _requestStoragePermission(context))) {
        _hideLoadingOverlay(loadingOverlay);
        return;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('absensi')
          .get()
          .timeout(const Duration(seconds: 30));

      final today = DateTime.now();
      final todayDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['waktuAbsen'] != null) {
          final timestamp = data['waktuAbsen'] as Timestamp;
          final date = timestamp.toDate();
          return date.day == today.day && 
                 date.month == today.month && 
                 date.year == today.year;
        }
        return false;
      }).toList();

      if (todayDocs.isEmpty) {
        _hideLoadingOverlay(loadingOverlay);
        if (context.mounted) {
          _showModernSnackBar(context, 'Tidak ada data absensi hari ini untuk diekspor', AppColors.warning);
        }
        return;
      }

      final csvData = _prepareAbsensiCsvData(todayDocs);
      final csvString = const ListToCsvConverter().convert(csvData);

      _hideLoadingOverlay(loadingOverlay);

      if (!context.mounted) return;

      final todayString = DateFormat('ddMMyyyy').format(DateTime.now());
      final fileName = 'absensi_today_${todayString}_${DateFormat('HHmmss').format(DateTime.now())}.csv';
      await _saveAndDownloadFile(context, csvString, fileName);

    } catch (e) {
      _hideLoadingOverlay(loadingOverlay);
      if (context.mounted) {
        _showModernSnackBar(context, 'Gagal mengunduh data absensi hari ini: $e', AppColors.danger);
      }
    }
  }

  Future<void> exportUsers(BuildContext context) async {
    if (!context.mounted) return;
    
    OverlayEntry? loadingOverlay;
    
    try {
      loadingOverlay = _showModernLoadingOverlay(context, 'Mengunduh data pengguna...');

      if (!(await _requestStoragePermission(context))) {
        _hideLoadingOverlay(loadingOverlay);
        return;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 30));

      List<List<dynamic>> csvData = [];
      csvData.add(['No', 'Email', 'Nama', 'Role', 'Created At']);

      for (int i = 0; i < snapshot.docs.length; i++) {
        final data = snapshot.docs[i].data() as Map<String, dynamic>;
        csvData.add([
          i + 1,
          data['email'] ?? '',
          data['nama'] ?? data['name'] ?? '',
          data['role'] ?? '',
          data['createdAt']?.toString() ?? ''
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      _hideLoadingOverlay(loadingOverlay);

      if (!context.mounted) return;

      final fileName = 'users_export_${DateFormat('ddMMyyyy_HHmmss').format(DateTime.now())}.csv';
      await _saveAndDownloadFile(context, csvString, fileName);

    } catch (e) {
      _hideLoadingOverlay(loadingOverlay);
      if (context.mounted) {
        _showModernSnackBar(context, 'Gagal mengunduh data pengguna: $e', AppColors.danger);
      }
    }
  }

  // Modern UI methods
  OverlayEntry _showModernLoadingOverlay(BuildContext context, String message) {
    final overlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(overlay);
    return overlay;
  }

  void _hideLoadingOverlay(OverlayEntry? overlay) {
    overlay?.remove();
  }

  void _showModernSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Storage and CSV methods
  Future<bool> _requestStoragePermission(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        
        if (!status.isGranted) {
          var manageStatus = await Permission.manageExternalStorage.status;
          
          if (!manageStatus.isGranted) {
            manageStatus = await Permission.manageExternalStorage.request();
          }
          
          if (!manageStatus.isGranted) {
            if (context.mounted) {
              _showModernSnackBar(
                context, 
                'Izin penyimpanan diperlukan untuk export file. Silakan berikan izin di pengaturan aplikasi.',
                AppColors.danger,
              );
            }
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      if (context.mounted) {
        _showModernSnackBar(context, 'Error requesting permission: $e', AppColors.danger);
      }
      return false;
    }
  }

  List<List<dynamic>> _prepareAbsensiCsvData(List<QueryDocumentSnapshot> docs) {
    List<List<dynamic>> csvData = [];
    
    csvData.add([
      'No',
      'Nama',
      'Email',
      'Tanggal',
      'Jam Absen',
      'Jenis Absen',
      'Status',
      'Keterangan',
      'Waktu Absen'
    ]);

    for (int i = 0; i < docs.length; i++) {
      final data = docs[i].data() as Map<String, dynamic>;
      
      String waktuAbsen = '';
      if (data['waktuAbsen'] != null) {
        final timestamp = data['waktuAbsen'] as Timestamp;
        final dateTime = timestamp.toDate();
        waktuAbsen = DateFormat('dd-MM-yyyy HH:mm:ss').format(dateTime);
      }
      
      String displayName = '';
      if (data['nama'] != null && data['nama'].toString().isNotEmpty) {
        displayName = data['nama'].toString();
      } else if (data['name'] != null && data['name'].toString().isNotEmpty) {
        displayName = data['name'].toString();
      } else if (data['email'] != null) {
        displayName = data['email'].toString().split('@')[0];
      }
      
      csvData.add([
        i + 1,
        displayName,
        data['email'] ?? '',
        data['tanggal'] ?? '',
        data['jamAbsen'] ?? '',
        data['jenisAbsen'] ?? '',
        data['status'] ?? '',
        data['keterangan'] ?? '',
        waktuAbsen,
      ]);
    }

    return csvData;
  }

  Future<void> _saveAndDownloadFile(BuildContext context, String content, String filename) async {
    try {
      await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();
      
      final downloadDir = Directory('/storage/emulated/0/Download');
      
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      
      final file = File('${downloadDir.path}/$filename');
      await file.writeAsString(content);
      
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      
      if (!context.mounted) return;
      
      if (exists) {
        _showModernSnackBar(
          context,
          'File berhasil disimpan!\nNama: $filename\nUkuran: ${(size/1024).toStringAsFixed(1)} KB',
          AppColors.success,
        );
      } else {
        _showModernSnackBar(
          context,
          'File tidak berhasil disimpan',
          AppColors.danger,
        );
      }
      
    } catch (e) {
      if (context.mounted) {
        _showModernSnackBar(
          context,
          'Error: $e',
          AppColors.danger,
        );
      }
    }
  }

  Future<void> checkExistingFiles() async {
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final files = await downloadDir.list().where((f) => 
          f.path.contains('.csv') && 
          (f.path.contains('absensi') || f.path.contains('laporan'))
        ).toList();
        
        if (kDebugMode) {
          print('=== FILE CSV YANG DITEMUKAN ===');
          for (var file in files) {
            final stat = await file.stat();
            print('File: ${file.path}');
            print('Ukuran: ${stat.size} bytes');
            print('Modified: ${stat.modified}');
            print('---');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking files: $e');
      }
    }
  }
}

// === PLACEHOLDER VIEW ===
class PlaceholderView extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderView({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.textLight),
            const SizedBox(height: 20),
            Text(
              'Halaman $title',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sedang dalam pengembangan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}