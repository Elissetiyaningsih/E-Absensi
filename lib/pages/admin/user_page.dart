import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

// === IMPROVED COLOR SCHEME (sama dengan admin_dashboard) ===
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

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UsersController _controller = UsersController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.initializeUsersStream();
    
    // Debug: Print untuk cek inisialisasi
    if (kDebugMode) {
      print('=== USERS PAGE INITIALIZED ===');
      _controller.debugFirestoreConnection();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _getFilteredUsers(List<QueryDocumentSnapshot> users) {
    if (_searchQuery.isEmpty) return users;
    
    return users.where((user) {
      final data = user.data() as Map<String, dynamic>;
      final name = _controller.getUserName(data, user.id);
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? '').toString().toLowerCase();
      
      return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             email.contains(_searchQuery.toLowerCase()) ||
             role.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: StreamBuilder<UsersData>(
        stream: _controller.usersStream,
        builder: (context, snapshot) {
          if (kDebugMode) {
            print('=== STREAM BUILDER STATE ===');
            print('Connection State: ${snapshot.connectionState}');
            print('Has Error: ${snapshot.hasError}');
            print('Has Data: ${snapshot.hasData}');
            if (snapshot.hasData) {
              print('Users Count: ${snapshot.data!.users.length}');
            }
            if (snapshot.hasError) {
              print('Error: ${snapshot.error}');
            }
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final data = snapshot.data ?? UsersData.empty();
          final filteredUsers = _getFilteredUsers(data.users);

          if (data.users.isEmpty) {
            return _buildEmptyState();
          }

          // Gunakan Column dengan SingleChildScrollView instead of CustomScrollView
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderWidget(data.users.length, filteredUsers.length),
                const SizedBox(height: 20),
                _buildUsersListWidget(filteredUsers),
                const SizedBox(height: 100), // Bottom padding untuk nav bar
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
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
              'Memuat Data Pengguna...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
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
              'Gagal Memuat Data Pengguna',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet dan permission Firestore',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _controller.initializeUsersStream(),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            Icon(
              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Tidak Ada Pengguna' : 'Tidak Ada Hasil Pencarian',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada pengguna yang terdaftar'
                  : 'Coba sesuaikan istilah pencarian',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Hapus Pencarian',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWidget(int totalUsers, int filteredUsers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section with Modern Card Design
        Container(
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
                  Icons.people_rounded,
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
                      'Manajemen Pengguna',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalUsers pengguna terdaftar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kDebugMode)
                    IconButton(
                      onPressed: () => _controller.debugUserData(),
                      icon: Icon(Icons.bug_report, color: AppColors.textSecondary),
                      tooltip: 'Debug User Data',
                    ),
                  IconButton(
                    onPressed: () => _controller.autoFixUserProfiles(context),
                    icon: Icon(Icons.auto_fix_high, color: AppColors.textSecondary),
                    tooltip: 'Perbaiki Profil Otomatis',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Search Bar with Modern Design
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
              hintText: 'Cari nama, email, atau role...',
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
        
        // Results info
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '$filteredUsers dari $totalUsers pengguna ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUsersListWidget(List<QueryDocumentSnapshot> users) {
    return Column(
      children: users.map((user) {
        final userData = user.data() as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildUserCard(userData, user.id),
        );
      }).toList(),
    );
  }

  // Keep the old sliver methods for reference but unused
  Widget _buildHeader(int totalUsers, int filteredUsers) {
    return SliverToBoxAdapter(
      child: _buildHeaderWidget(totalUsers, filteredUsers),
    );
  }

  Widget _buildUsersList(List<QueryDocumentSnapshot> users) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            return _buildUserCard(userData, users[index].id);
          },
          childCount: users.length,
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, String docId) {
    final name = _controller.getUserName(userData, docId);
    final email = userData['email'] ?? 'No email';
    final role = userData['role'] ?? 'user';
    final createdAt = _formatDate(userData['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetails(userData, name),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                UserAvatar(name: name, role: role),
                const SizedBox(width: 16),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          RoleBadge(role: role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bergabung: $createdAt',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions
                UserActions(
                  onDelete: () => _controller.deleteUser(context, userData, name),
                  onEdit: () => _editUser(userData, name),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      if (timestamp is Timestamp) {
        return DateFormat('dd MMM yyyy').format(timestamp.toDate());
      } else if (timestamp is String) {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(timestamp));
      }
    } catch (e) {
      if (kDebugMode) print('Error formatting date: $e');
    }
    
    return timestamp.toString();
  }

  void _showUserDetails(Map<String, dynamic> userData, String userName) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(
        userData: userData,
        userName: userName,
      ),
    );
  }

  void _editUser(Map<String, dynamic> userData, String userName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Edit user functionality coming soon!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

// === DATA CLASSES ===
class UsersData {
  List<QueryDocumentSnapshot> users = [];
  Map<String, String> userNamesCache = {};

  UsersData();
  
  factory UsersData.empty() => UsersData();
}

// === CONTROLLER CLASS (DIPERBAIKI) ===
class UsersController {
  final List<StreamSubscription> _subscriptions = [];
  final StreamController<UsersData> _usersController = 
      StreamController<UsersData>.broadcast();
  final UsersData _data = UsersData();

  Stream<UsersData> get usersStream => _usersController.stream;

  void _debugPrint(String message) {
    if (kDebugMode) print(message);
  }

  Future<void> debugFirestoreConnection() async {
    try {
      _debugPrint('=== TESTING FIRESTORE CONNECTION ===');
      
      // Test basic connection
      final testDoc = await FirebaseFirestore.instance
          .collection('users')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      
      _debugPrint('Firestore Connection: SUCCESS');
      _debugPrint('Test query returned: ${testDoc.docs.length} documents');
      
      // Test full users collection
      final allUsers = await FirebaseFirestore.instance
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 15));
      
      _debugPrint('Total users in collection: ${allUsers.docs.length}');
      
      for (int i = 0; i < allUsers.docs.length && i < 3; i++) {
        final doc = allUsers.docs[i];
        final data = doc.data();
        _debugPrint('User ${i + 1}: ID=${doc.id}, Email=${data['email']}, Role=${data['role']}');
      }
      
    } catch (e) {
      _debugPrint('Firestore Connection ERROR: $e');
    }
  }

  void initializeUsersStream() {
    _debugPrint('=== INITIALIZING USERS STREAM ===');
    
    // Clear previous subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    try {
      final stream = FirebaseFirestore.instance
          .collection('users')
          .snapshots();

      _subscriptions.add(
        stream
            .handleError((error) {
              _debugPrint('Stream Error: $error');
              _usersController.addError('Error loading users: $error');
            })
            .listen(
              (snapshot) async {
                _debugPrint('Stream Update: ${snapshot.docs.length} users received');
                
                _data.users = snapshot.docs;
                await _loadUserNamesFromProfiles(snapshot.docs);
                
                _debugPrint('Emitting data to stream...');
                _usersController.add(_data);
              },
              onError: (error) {
                _debugPrint('Stream Listen Error: $error');
                _usersController.addError(error);
              },
            ),
      );
    } catch (e) {
      _debugPrint('Error initializing users stream: $e');
      _usersController.addError(e);
    }
  }

  Future<void> _loadUserNamesFromProfiles(List<QueryDocumentSnapshot> userDocs) async {
    _debugPrint('=== LOADING USER NAMES FROM PROFILES ===');
    
    for (var userDoc in userDocs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      
      List<String> possibleIds = [
        userData['uid']?.toString() ?? '',
        userDoc.id,
        userData['email']?.toString() ?? '',
      ];
      
      String userName = 'Unknown User';
      bool profileFound = false;
      
      // Check cache first
      for (String possibleId in possibleIds) {
        if (possibleId.isNotEmpty && _data.userNamesCache.containsKey(possibleId)) {
          userName = _data.userNamesCache[possibleId]!;
          profileFound = true;
          break;
        }
      }
      
      if (!profileFound) {
        // Try to load from Firestore profiles
        for (String possibleId in possibleIds) {
          if (possibleId.isEmpty) continue;
          
          try {
            final profileDoc = await FirebaseFirestore.instance
                .collection('profiles')
                .doc(possibleId)
                .get()
                .timeout(const Duration(seconds: 5));
                
            if (profileDoc.exists) {
              final profileData = profileDoc.data() as Map<String, dynamic>;
              userName = profileData['nama']?.toString() ?? 
                        profileData['name']?.toString() ?? 
                        profileData['displayName']?.toString() ?? 
                        'Unknown User';
              
              // Cache with all possible IDs
              for (String id in possibleIds) {
                if (id.isNotEmpty) {
                  _data.userNamesCache[id] = userName;
                }
              }
              profileFound = true;
              _debugPrint('Profile found for $possibleId: $userName');
              break;
            }
          } catch (e) {
            _debugPrint('Error loading profile for $possibleId: $e');
          }
        }
      }
      
      // If still not found, try query by email
      if (!profileFound) {
        final userEmail = userData['email']?.toString();
        if (userEmail != null && userEmail.isNotEmpty) {
          try {
            final profileQuery = await FirebaseFirestore.instance
                .collection('profiles')
                .where('email', isEqualTo: userEmail)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 5));
                
            if (profileQuery.docs.isNotEmpty) {
              final profileData = profileQuery.docs.first.data();
              userName = profileData['nama']?.toString() ?? 
                        profileData['name']?.toString() ?? 
                        profileData['displayName']?.toString() ?? 
                        'Unknown User';
              
              for (String id in possibleIds) {
                if (id.isNotEmpty) {
                  _data.userNamesCache[id] = userName;
                }
              }
              profileFound = true;
              _debugPrint('Profile found by email for $userEmail: $userName');
            }
          } catch (e) {
            _debugPrint('Error querying profile by email for $userEmail: $e');
          }
        }
      }
      
      // Fallback to email username
      if (!profileFound) {
        final email = userData['email']?.toString() ?? '';
        if (email.contains('@')) {
          userName = email.split('@')[0]
              .replaceAll('.', ' ')
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) => word.isNotEmpty ? 
                  word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
              .join(' ');
        }
        
        for (String id in possibleIds) {
          if (id.isNotEmpty) {
            _data.userNamesCache[id] = userName;
          }
        }
        _debugPrint('Fallback name for ${userDoc.id}: $userName');
      }
    }
  }

  String getUserName(Map<String, dynamic> userData, String docId) {
    List<String> possibleIds = [
      userData['uid']?.toString() ?? '',
      docId,
      userData['email']?.toString() ?? '',
    ];
    
    for (String id in possibleIds) {
      if (id.isNotEmpty && _data.userNamesCache.containsKey(id)) {
        return _data.userNamesCache[id]!;
      }
    }
    
    // Fallback
    final email = userData['email']?.toString() ?? '';
    if (email.contains('@')) {
      return email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
    }
    
    return 'Unknown User';
  }

  Future<void> debugUserData() async {
    _debugPrint('=== DEBUG USER DATA ===');
    
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      _debugPrint('Total users: ${usersSnapshot.docs.length}');
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        _debugPrint('User: ${userDoc.id}, Email: ${userData['email']}, UID: ${userData['uid']}');
      }
      
      final profilesSnapshot = await FirebaseFirestore.instance.collection('profiles').get();
      _debugPrint('Total profiles: ${profilesSnapshot.docs.length}');
      
      for (var profileDoc in profilesSnapshot.docs) {
        final profileData = profileDoc.data();
        _debugPrint('Profile: ${profileDoc.id}, Name: ${profileData['nama'] ?? profileData['name']}');
      }
    } catch (e) {
      _debugPrint('Error in debug: $e');
    }
  }

  Future<void> autoFixUserProfiles(BuildContext context) async {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Memperbaiki Profil...',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Sedang memperbaiki profil pengguna...',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
      ),
    );
    
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      int fixedCount = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userEmail = userData['email']?.toString();
        
        if (userEmail == null) continue;
        
        final profileQuery = await FirebaseFirestore.instance
            .collection('profiles')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();
        
        if (profileQuery.docs.isNotEmpty) {
          final profileDoc = profileQuery.docs.first;
          final profileData = profileDoc.data();
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .update({
                'profileId': profileDoc.id,
                'displayName': profileData['nama'] ?? profileData['name'] ?? 'Unknown',
              });
          
          fixedCount++;
        }
      }
      
      if (!context.mounted) return;
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fixed $fixedCount user profiles successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Clear cache and refresh
      _data.userNamesCache.clear();
      initializeUsersStream();
      
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fixing profiles: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> deleteUser(BuildContext context, Map<String, dynamic> userData, String userName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Pengguna',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus $userName? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement actual delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pengguna dihapus: $userName',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _usersController.close();
  }
}

// === REUSABLE WIDGETS (UPDATED WITH MODERN DESIGN) ===
class UserAvatar extends StatelessWidget {
  final String name;
  final String role;

  const UserAvatar({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRoleColor(role),
            _getRoleColor(role).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.danger;
      case 'manager':
        return AppColors.info;
      case 'user':
      default:
        return AppColors.success;
    }
  }
}

class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRoleIcon(role), size: 12, color: _getRoleColor(role)),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getRoleColor(role),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.danger;
      case 'manager':
        return AppColors.info;
      case 'user':
      default:
        return AppColors.success;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'manager':
        return Icons.manage_accounts_rounded;
      case 'user':
      default:
        return Icons.person_rounded;
    }
  }
}

class UserActions extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const UserActions({super.key, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: AppColors.textLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: onEdit,
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: AppColors.info),
              const SizedBox(width: 12),
              Text(
                'Edit Pengguna',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onDelete,
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: AppColors.danger),
              const SizedBox(width: 12),
              Text(
                'Hapus Pengguna',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UserDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userName;

  const UserDetailsDialog({
    super.key,
    required this.userData,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          minWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Detail Pengguna',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Nama', userName),
              _buildDetailRow('Email', userData['email'] ?? 'N/A'),
              _buildDetailRow('Role', userData['role'] ?? 'N/A'),
              _buildDetailRow('UID', userData['uid'] ?? 'N/A'),
              _buildDetailRow('Profile ID', userData['profileId'] ?? 'N/A'),
              _buildDetailRow('Display Name', userData['displayName'] ?? 'N/A'),
              _buildDetailRow('Created At', _formatTimestamp(userData['createdAt'])),
              if (userData['updatedAt'] != null)
                _buildDetailRow('Updated At', _formatTimestamp(userData['updatedAt'])),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      if (timestamp is Timestamp) {
        return DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate());
      } else if (timestamp is String) {
        return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(timestamp));
      }
    } catch (e) {
      if (kDebugMode) print('Error formatting timestamp: $e');
    }
    
    return timestamp.toString();
  }
}