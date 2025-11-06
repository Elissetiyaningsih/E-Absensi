import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:absenku/favorite_page.dart';
import 'package:absenku/drama_screen.dart';
import 'package:absenku/pages/edit/edit_profile.dart';
// Import halaman edit profil - sesuaikan dengan path yang benar
// import 'package:absenku/edit_profile_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    DramaPage(),   // Halaman Drama
    AttendanceHistoryPage(), // Halaman Favorit
    ProfilePage(), // Halaman Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Absen'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProfileScreen();
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? profileData;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? currentUserId;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('User tidak login');
        return;
      }

      currentUserId = currentUser.uid;
      userEmail = currentUser.email;
      print('Loading data untuk user: $currentUserId');
      print('User email: $userEmail');

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      DocumentSnapshot profileDoc = await _firestore
          .collection('profiles')
          .doc(currentUserId)
          .get();

      setState(() {
        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>?;
          print('User data: $userData');
        }
        
        if (profileDoc.exists) {
          profileData = profileDoc.data() as Map<String, dynamic>?;
          print('Profile data: $profileData');
        } else {
          print('Profile data tidak ditemukan');
          profileData = {
            'nama': '',
            'email': userEmail ?? '',
            'jabatan': '',
            'departemen': '',
            'status': 'Aktif',
            'telepon': '',
            'alamat': '',
          };
        }
        
        if (profileData != null) {
          profileData!['email'] = userEmail ?? '';
        }
        
        isLoading = false;
      });

    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    // Debug: cek apakah fungsi dipanggil
    print('=== NAVIGATE TO EDIT PROFILE ===');
    print('profileData: $profileData');
    print('currentUserId: $currentUserId');

    // Pastikan ada data untuk dikirim ke EditProfile
    Map<String, dynamic> dataToSend = profileData ?? {
      'nama': '',
      'email': userEmail ?? '',
      'jabatan': '',
      'departemen': '',
      'status': 'Aktif',
      'telepon': '',
      'alamat': '',
    };

    print('Data yang akan dikirim: $dataToSend');

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(
            currentProfileData: dataToSend,
            userId: currentUserId,
          ),
        ),
      );

      print('Result dari EditProfile: $result');

      if (result != null) {
        // Refresh data profil setelah edit
        await _loadUserData();
        
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
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      print('Error navigating to EditProfile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '15 Januari 2020';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else {
        return timestamp.toString();
      }
      
      List<String> months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return '15 Januari 2020';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // Background abu-abu muda
        appBar: AppBar(
          backgroundColor: const Color(0xFF6366F1),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Profil Saya',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1354E0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF1354E0),
                  ),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Memuat profil...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Background abu-abu muda seperti halaman absen
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: const Color(0xFF1354E0),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card - mirip dengan card di halaman absen
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF7B68EE)], // Gradient sama dengan DramaPage
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Profile Avatar
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
                      
                      const SizedBox(height: 16),
                      
                      // Name
                      Text(
                        profileData?['nama']?.isNotEmpty == true 
                            ? profileData!['nama'] 
                            : 'Nama belum diatur',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Position Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          profileData?['jabatan']?.isNotEmpty == true
                              ? profileData!['jabatan']
                              : 'Jabatan belum diatur',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Email
                      Text(
                        userEmail ?? 'Email tidak tersedia',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Section Header - sama seperti di halaman absen
                Text(
                  'Informasi Profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Profile Detail Cards - mengikuti style halaman absen
                _buildProfileInfoCard(
                  icon: Icons.business_rounded,
                  iconColor: Colors.purple[600]!,
                  title: 'Bidang',
                  value: profileData?['departemen'] ?? 'Belum diatur',
                  borderColor: Colors.purple[100]!,
                ),
                
                const SizedBox(height: 12),
                
                _buildProfileInfoCard(
                  icon: Icons.phone_rounded,
                  iconColor: Colors.green[600]!,
                  title: 'No. Telepon',
                  value: profileData?['telepon'] ?? 'Belum diatur',
                  borderColor: Colors.green[100]!,
                ),
                
                const SizedBox(height: 12),
                
                _buildProfileInfoCard(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.orange[600]!,
                  title: 'Alamat',
                  value: profileData?['alamat'] ?? 'Belum diatur',
                  borderColor: Colors.orange[100]!,
                ),
                
                const SizedBox(height: 12),
                
                // Status Card
                _buildStatusCard(),
                
                const SizedBox(height: 12),
                
                _buildProfileInfoCard(
                  icon: Icons.calendar_today_rounded,
                  iconColor: Colors.blue[600]!,
                  title: 'Bergabung',
                  value: _formatDate(userData?['createdAt']),
                  borderColor: Colors.blue[100]!,
                ),
                
                const SizedBox(height: 32),
                
                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToEditProfile,
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    label: const Text(
                      'Edit Profil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1), // Warna sama dengan DramaPage
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[600]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk card informasi profil - mengikuti style halaman absen
  Widget _buildProfileInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = profileData?['status'] ?? 'Aktif';
    final isActive = status == 'Aktif';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isActive ? Colors.green[100]! : Colors.red[100]!,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isActive ? Colors.green[600] : Colors.red[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[600] : Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan icon dan title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Konfirmasi Keluar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Content text
                const Text(
                  'Apakah Anda yakin ingin keluar dari aplikasi?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, "/login");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:  const Color(0xFF6366F1),// Warna biru seperti halaman absen
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}