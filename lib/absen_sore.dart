import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:absenku/favorite_page.dart';

// Model class untuk konfigurasi geofence
class GeofenceConfig {
  final double latitude;
  final double longitude;
  final double radius;
  final String name;

  const GeofenceConfig({
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.name,
  });
}

// Service class untuk mengelola geofencing
class GeofenceService {
  static const List<GeofenceConfig> _allowedLocations = [
    GeofenceConfig(
      latitude: -3.698005,
      longitude: 128.174176,
      radius: 120.0,
      name: "Dinas Ketahanan Pangan Promal",
    ),
  ];

  // Cek apakah lokasi user berada dalam salah satu geofence
  static bool isWithinAnyGeofence(double userLat, double userLon) {
    for (var location in _allowedLocations) {
      double distance = _calculateDistance(
        userLat, userLon, 
        location.latitude, location.longitude
      );
      if (distance <= location.radius) {
        return true;
      }
    }
    return false;
  }

  // Mendapatkan lokasi terdekat dan jaraknya
  static Map<String, dynamic> getNearestLocation(double userLat, double userLon) {
    double minDistance = double.infinity;
    GeofenceConfig? nearestLocation;
    
    for (var location in _allowedLocations) {
      double distance = _calculateDistance(
        userLat, userLon,
        location.latitude, location.longitude
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestLocation = location;
      }
    }

    return {
      'location': nearestLocation,
      'distance': minDistance,
      'isWithinGeofence': minDistance <= (nearestLocation?.radius ?? 0),
    };
  }

  // Fungsi helper untuk menghitung jarak
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Radius bumi dalam meter
    
    double dLat = (lat2 - lat1) * math.pi / 180;
    double dLon = (lon2 - lon1) * math.pi / 180;
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
}

// Halaman Detail Absen Sore dengan implementasi kamera, Cloudinary, dan Geofencing
class AbsenSoreDetailPage extends StatefulWidget {
  const AbsenSoreDetailPage({super.key});

  @override
  State<AbsenSoreDetailPage> createState() => _AbsenSoreDetailPageState();
}

class _AbsenSoreDetailPageState extends State<AbsenSoreDetailPage> {
  final TextEditingController _catatanController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final loc.Location _location = loc.Location();
  
  bool _isLoading = false;
  bool _isLocationLoading = true;
  bool _isCheckingAttendance = true;
  bool _hasAttendedToday = false;
  
  // GEOFENCING VARIABLES
  bool _isWithinGeofence = false;
  double _distanceFromOffice = 0.0;
  String _geofenceStatus = 'Memeriksa lokasi...';
  GeofenceConfig? _nearestOffice;
  
  String _attendanceTime = '';
  String _attendanceStatus = '';
  String _currentTime = '';
  String _currentLocation = 'Memuat lokasi...';
  File? _selectedImage;
  loc.LocationData? _locationData;

  // Cloudinary configuration
  static const String CLOUDINARY_URL = 'https://api.cloudinary.com/v1_1/dlcj382to/image/upload';
  static const String CLOUDINARY_UPLOAD_PRESET = 'absensi_preset';

  // Tema warna untuk absen sore - menggunakan blue/indigo yang konsisten
  final Color primaryColor = const Color(0xFF6366F1); // Indigo 500
  final Color primaryDark = const Color(0xFF4F46E5); // Indigo 600
  final Color primaryLight = const Color(0xFF818CF8); // Indigo 400
  final Color lightBackground = const Color(0xFFF0F4FF); // Light indigo background
  final Color veryLightBackground = const Color(0xFFFAFBFF); // Very light indigo

  @override
  void initState() {
    super.initState();
    _getCurrentTime();
    _getCurrentLocation();
    _checkTodayAttendance();
  }

  void _getCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  // Fungsi untuk cek apakah sudah absen hari ini
  Future<void> _checkTodayAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isCheckingAttendance = false;
      });
      return;
    }

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      print('=== CHECKING AFTERNOON ATTENDANCE ===');
      print('User ID: ${user.uid}');
      print('Start of day: $startOfDay');
      print('End of day: $endOfDay');

      final query = await FirebaseFirestore.instance
          .collection('absensi')
          .where('userId', isEqualTo: user.uid)
          .where('jenisAbsen', isEqualTo: 'sore')
          .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      print('Query results: ${query.docs.length}');

      if (query.docs.isNotEmpty) {
        final todayData = query.docs.first.data();
        print('✓ Found today\'s afternoon attendance record!');
        setState(() {
          _hasAttendedToday = true;
          _attendanceTime = todayData['jamAbsen'] ?? '';
          _attendanceStatus = todayData['status'] ?? '';
          _isCheckingAttendance = false;
        });
      } else {
        print('No afternoon attendance record found for today');
        setState(() {
          _hasAttendedToday = false;
          _isCheckingAttendance = false;
        });
      }
    } catch (e) {
      print('Error checking attendance: $e');
      await _fallbackCheckAttendance();
    }
  }

  // Fallback method jika composite query gagal
  Future<void> _fallbackCheckAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final query = await FirebaseFirestore.instance
          .collection('absensi')
          .where('userId', isEqualTo: user.uid)
          .where('jenisAbsen', isEqualTo: 'sore')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      bool foundTodayRecord = false;
      Map<String, dynamic>? todayData;

      for (var doc in query.docs) {
        final data = doc.data();
        final tanggalField = data['tanggal'];
        
        if (tanggalField is Timestamp) {
          final recordDate = tanggalField.toDate();
          final recordDateString = '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
          
          if (recordDateString == todayString) {
            foundTodayRecord = true;
            todayData = data;
            break;
          }
        }
      }

      setState(() {
        _hasAttendedToday = foundTodayRecord;
        if (foundTodayRecord && todayData != null) {
          _attendanceTime = todayData['jamAbsen'] ?? '';
          _attendanceStatus = todayData['status'] ?? '';
        }
        _isCheckingAttendance = false;
      });
    } catch (e) {
      debugPrint('Fallback check also failed: $e');
      setState(() {
        _hasAttendedToday = false;
        _isCheckingAttendance = false;
      });
    }
  }

  // Fungsi refresh manual untuk update status
  Future<void> _refreshAttendanceStatus() async {
    setState(() {
      _isCheckingAttendance = true;
      _hasAttendedToday = false;
      _isLocationLoading = true;
      _geofenceStatus = 'Memeriksa lokasi...';
    });
    await _checkTodayAttendance();
    _getCurrentLocation();
    _getCurrentTime();
  }

  // FUNGSI MENDAPATKAN LOKASI DENGAN GEOFENCING
  void _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      loc.PermissionStatus permissionGranted;

      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _currentLocation = 'Layanan lokasi tidak aktif';
            _geofenceStatus = 'Tidak dapat memverifikasi lokasi kantor';
            _isWithinGeofence = false;
            _isLocationLoading = false;
          });
          return;
        }
      }

      permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          setState(() {
            _currentLocation = 'Izin lokasi ditolak';
            _geofenceStatus = 'Tidak dapat memverifikasi lokasi kantor';
            _isWithinGeofence = false;
            _isLocationLoading = false;
          });
          return;
        }
      }

      _locationData = await _location.getLocation();
      
      print('=== GEOFENCING CHECK (AFTERNOON) ===');
      print('User location: ${_locationData!.latitude}, ${_locationData!.longitude}');
      
      // VALIDASI GEOFENCE MENGGUNAKAN SERVICE
      Map<String, dynamic> geofenceResult = GeofenceService.getNearestLocation(
        _locationData!.latitude!,
        _locationData!.longitude!,
      );
      
      setState(() {
        _isWithinGeofence = geofenceResult['isWithinGeofence'];
        _distanceFromOffice = geofenceResult['distance'];
        _nearestOffice = geofenceResult['location'];
        
        if (_isWithinGeofence) {
          _geofenceStatus = 'Dalam area ${_nearestOffice?.name}';
        } else {
          _geofenceStatus = 'Di luar area kantor (${_distanceFromOffice.toStringAsFixed(0)}m dari ${_nearestOffice?.name})';
        }
      });
      
      print('Distance from office: $_distanceFromOffice meters');
      print('Is within geofence: $_isWithinGeofence');
      print('Geofence status: $_geofenceStatus');
      
      // Convert koordinat ke alamat
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _locationData!.latitude!,
        _locationData!.longitude!,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocation = '${place.street}, ${place.subLocality}, ${place.locality}';
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _currentLocation = 'Gagal mendapatkan lokasi';
        _geofenceStatus = 'Error memverifikasi lokasi kantor';
        _isWithinGeofence = false;
        _isLocationLoading = false;
      });
    }
  }

  // FUNGSI DIALOG FOTO DENGAN VALIDASI GEOFENCE
  void _showImageSourceDialog() {
    if (_hasAttendedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda sudah absen sore hari ini!'),
          backgroundColor: Colors.orange[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // VALIDASI GEOFENCE SEBELUM AMBIL FOTO
    if (!_isWithinGeofence) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: Icon(Icons.location_off, color: Colors.red[600], size: 48),
            title: const Text('Di Luar Area Kantor'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Anda harus berada dalam area kantor untuk melakukan absen.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Jarak dari ${_nearestOffice?.name ?? "kantor"}:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_distanceFromOffice.toStringAsFixed(0)} meter',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Maksimal: ${(_nearestOffice?.radius ?? 200.0).toStringAsFixed(0)} meter',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mengerti'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshAttendanceStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Refresh Lokasi'),
              ),
            ],
          );
        },
      );
      return;
    }

    // JIKA DALAM GEOFENCE, TAMPILKAN PILIHAN FOTO
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Sumber Foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryColor),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto baru'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoFromCamera();
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryColor),
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
          _selectedImage = File(image.path);
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
          _selectedImage = File(image.path);
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

  // Fungsi untuk upload foto ke Cloudinary
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      var request = http.MultipartRequest('POST', Uri.parse(CLOUDINARY_URL));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $responseString');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(responseString);
        return jsonResponse['secure_url'];
      } else {
        debugPrint('Upload failed: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Fungsi untuk menentukan status berdasarkan jam
  String _getAttendanceStatus(String currentTime) {
    List<String> timeParts = currentTime.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    
    // Jam kerja sore: 13:00 - 17:00
    // Pulang cepat jika sebelum 16:45
    if (hour < 16 || (hour == 16 && minute < 45)) {
      return 'Pulang Cepat';
    }
    return 'Hadir';
  }

  // FUNGSI SUBMIT ABSEN DENGAN VALIDASI GEOFENCE
  void _submitAbsen() async {
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

    print('=== SUBMIT AFTERNOON ABSEN VALIDATION ===');
    print('Is within geofence: $_isWithinGeofence');
    print('Distance from office: $_distanceFromOffice meters');
    print('Nearest office: ${_nearestOffice?.name}');

    // VALIDASI GEOFENCE SEBELUM SUBMIT
    if (!_isWithinGeofence) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tidak bisa absen dari lokasi ini!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Jarak dari kantor: ${_distanceFromOffice.toStringAsFixed(0)}m'),
            ],
          ),
          backgroundColor: Colors.red[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Refresh',
            textColor: Colors.white,
            onPressed: _refreshAttendanceStatus,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Cek sekali lagi apakah sudah absen
    await _checkTodayAttendance();
    
    if (_hasAttendedToday) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda sudah absen sore hari ini!'),
          backgroundColor: Colors.orange[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Foto absen wajib diambil'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    try {
      // Upload foto ke Cloudinary
      String? imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      
      if (imageUrl == null) {
        throw Exception('Gagal mengupload foto');
      }

      // Tentukan status berdasarkan jam
      String attendanceStatus = _getAttendanceStatus(_currentTime);

      // Simpan data absen ke Firestore dengan info geofence
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      
      final absenData = {
        'userId': user.uid,
        'email': user.email,
        'tanggal': Timestamp.fromDate(todayDate),
        'waktuAbsen': Timestamp.fromDate(now),
        'jamAbsen': _currentTime,
        'jenisAbsen': 'sore',
        'lokasi': _currentLocation,
        'koordinat': _locationData != null ? {
          'latitude': _locationData!.latitude,
          'longitude': _locationData!.longitude,
        } : null,
        'fotoUrl': imageUrl,
        'catatan': _catatanController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': attendanceStatus,
        // DATA GEOFENCE
        'geofence': {
          'isWithinGeofence': _isWithinGeofence,
          'distanceFromOffice': _distanceFromOffice,
          'officeName': _nearestOffice?.name ?? '',
          'geofenceRadius': _nearestOffice?.radius ?? 0,
          'officeCoordinates': {
            'latitude': _nearestOffice?.latitude ?? 0,
            'longitude': _nearestOffice?.longitude ?? 0,
          },
          'validationTime': FieldValue.serverTimestamp(),
        }
      };

      debugPrint('Saving afternoon attendance data: ${absenData.toString()}');

      // Gunakan transaction untuk memastikan tidak ada duplicate
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final checkQuery = await FirebaseFirestore.instance
            .collection('absensi')
            .where('userId', isEqualTo: user.uid)
            .where('jenisAbsen', isEqualTo: 'sore')
            .where('tanggal', isEqualTo: Timestamp.fromDate(todayDate))
            .limit(1)
            .get();

        if (checkQuery.docs.isNotEmpty) {
          throw Exception('Anda sudah absen sore hari ini!');
        }

        transaction.set(
          FirebaseFirestore.instance.collection('absensi').doc(),
          absenData,
        );
      });

      // Update status lokal setelah berhasil save
      setState(() {
        _hasAttendedToday = true;
        _attendanceTime = _currentTime;
        _attendanceStatus = attendanceStatus;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Absen sore berhasil dicatat!'),
            backgroundColor: Colors.green[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

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

      String errorMessage = e.toString();
      if (errorMessage.contains('sudah absen')) {
        await _checkTodayAttendance();
        errorMessage = 'Anda sudah absen sore hari ini!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage.replaceAll('Exception: ', '')),
          backgroundColor: Colors.red[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
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
          'Absen Sore',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryLight, primaryDark],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshAttendanceStatus,
            icon: _isCheckingAttendance || _isLocationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAttendanceStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GEOFENCE STATUS WIDGET
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isWithinGeofence ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isWithinGeofence ? Colors.green[200]! : Colors.red[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isWithinGeofence ? Icons.location_on : Icons.location_off,
                          color: _isWithinGeofence ? Colors.green[600] : Colors.red[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isWithinGeofence ? 'Dalam Area Kantor' : 'Di Luar Area Kantor',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isWithinGeofence ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                              Text(
                                _geofenceStatus,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isWithinGeofence ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!_isWithinGeofence && _distanceFromOffice > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Anda harus mendekati area kantor untuk dapat melakukan absen. Jarak maksimal: ${_nearestOffice?.radius?.toStringAsFixed(0) ?? "200"}m',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status Absen Hari Ini
              if (_isCheckingAttendance)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Memeriksa status absen hari ini...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_hasAttendedToday)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sudah Absen Sore Hari Ini',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Waktu: $_attendanceTime',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                  ),
                                ),
                                Text(
                                  'Status: $_attendanceStatus',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          'Anda telah melakukan absen sore untuk hari ini. Terima kasih dan selamat beristirahat!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[700],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_hasAttendedToday) const SizedBox(height: 24),

              // Jika belum absen, tampilkan form lengkap
              if (!_hasAttendedToday && !_isCheckingAttendance) ...[
                // Time & Date Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lightBackground, veryLightBackground],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryLight.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.nightlight_round_outlined,
                        size: 48,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentTime,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryDark,
                        ),
                      ),
                      Text(
                        'Waktu Absen Sekarang',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Jam Kerja: 13 - 17 WIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Photo Section
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
                          Icon(Icons.camera_alt_outlined, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Foto Absen *',
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
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _selectedImage != null ? Colors.transparent : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedImage != null ? primaryColor : Colors.grey[300]!,
                              width: _selectedImage != null ? 2 : 1,
                            ),
                          ),
                          child: _selectedImage != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _selectedImage!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: _showImageSourceDialog,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
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
                                      Icons.add_a_photo_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tap untuk mengambil foto',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Wajib diisi',
                                      style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 12,
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

                // Location Section
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
                          Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Lokasi Absen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryLight.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            if (_isLocationLoading)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              )
                            else
                              Icon(Icons.my_location, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentLocation,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Notes Section
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
                            'Catatan (Opsional)',
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
                        controller: _catatanController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Tambahkan catatan untuk absen sore...',
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
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isWithinGeofence) ? null : _submitAbsen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isWithinGeofence ? primaryColor : Colors.grey[400],
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
                        : Text(
                            _isWithinGeofence 
                                ? 'Submit Absen Sore'
                                : 'Tidak Dalam Area Kantor',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],

              // Info untuk user yang sudah absen
              if (_hasAttendedToday && !_isCheckingAttendance)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
                          const SizedBox(height: 8),
                          Text(
                            'Selamat Beristirahat!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Anda telah menyelesaikan absen sore hari ini. Terima kasih atas kerja keras Anda!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }
}