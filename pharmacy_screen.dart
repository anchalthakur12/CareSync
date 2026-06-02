import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';

class PharmacyScreen extends StatefulWidget {
  final String? prefilterMedicine;
  const PharmacyScreen({super.key, this.prefilterMedicine});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _Pharmacy {
  final String name;
  final double lat;
  final double lon;
  final double distanceMeters;
  final String? phone;
  final String? address;
  final String openStatus;
  _Pharmacy({
    required this.name,
    required this.lat,
    required this.lon,
    required this.distanceMeters,
    required this.openStatus,
    this.phone,
    this.address,
  });

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m away';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km away';
  }
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  bool _loading = true;
  String? _error;
  List<_Pharmacy> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _findNearby();
  }

  Future<Position?> _getLocation() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) throw 'Please enable location services on your device.';
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw 'Location permission is required to find nearby pharmacies.';
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _findNearby() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pos = await _getLocation();
      if (pos == null) throw 'Could not get your location.';

      const radius = 3000;
      final query = '''
[out:json][timeout:15];
(
  node["amenity"="pharmacy"](around:$radius,${pos.latitude},${pos.longitude});
  way["amenity"="pharmacy"](around:$radius,${pos.latitude},${pos.longitude});
);
out center 25;
''';

    final res = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "CareSyncApp/1.0",
        },
        body: "data=$query",
        ).timeout(const Duration(seconds: 20));

    //if (res.statusCode != 200) throw 'Pharmacy lookup failed (${res.statusCode}).';
    if (res.statusCode != 200) {
        print("ERROR BODY: ${res.body}");
        throw 'Pharmacy service temporarily unavailable. Please try again.';
        }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List?) ?? [];
      final list = <_Pharmacy>[];
      for (final el in elements) {
        final tags = (el['tags'] as Map?) ?? {};
        final lat = (el['lat'] ?? el['center']?['lat']) as num?;
        final lon = (el['lon'] ?? el['center']?['lon']) as num?;
        if (lat == null || lon == null) continue;
        final dist = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, lat.toDouble(), lon.toDouble(),
        );
        list.add(_Pharmacy(
          name: (tags['name'] as String?) ?? 'Pharmacy',
          lat: lat.toDouble(),
          lon: lon.toDouble(),
          distanceMeters: dist,
          openStatus: _formatOpenStatus(tags['opening_hours'] as String?),
          phone: (tags['phone'] ?? tags['contact:phone']) as String?,
          address: _formatAddress(tags),
        ));
      }
      list.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      if (mounted) {
        setState(() {
          _pharmacies = list.take(20).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatOpenStatus(String? raw) {
    if (raw == null || raw.isEmpty) return 'Hours unknown';
    if (raw.toLowerCase().contains('24/7')) return 'Open 24/7';
    return 'Hours: $raw';
  }

  String? _formatAddress(Map tags) {
    final parts = <String>[
      (tags['addr:housenumber'] as String?) ?? '',
      (tags['addr:street'] as String?) ?? '',
      (tags['addr:city'] as String?) ?? '',
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  Future<void> _openInMaps(_Pharmacy p) async {
    final label = Uri.encodeComponent(p.name);
    final googleApp = Uri.parse('google.navigation:q=${p.lat},${p.lon}');
    final googleWeb = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lon}($label)',
    );
    if (await canLaunchUrl(googleApp)) {
      await launchUrl(googleApp, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(googleWeb, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s+'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: Text('Nearby Pharmacies',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navy)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _findNearby),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_off, color: AppColors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _findNearby,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal, foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
    }
    if (_pharmacies.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_pharmacy_outlined, size: 56, color: AppColors.border),
        const SizedBox(height: 12),
        Text('No pharmacies found within 3 km.',
            style: GoogleFonts.poppins(color: AppColors.textMuted)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pharmacies.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildHeader();
        return _buildCard(_pharmacies[i - 1]);
      },
    );
  }

  Widget _buildHeader() {
    final med = widget.prefilterMedicine;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: AppColors.tealGradient, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.location_on, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(med != null ? 'Refill: $med' : 'Pharmacies near you',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text('${_pharmacies.length} found within 3 km',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCard(_Pharmacy p) {
    final isOpen24 = p.openStatus.toLowerCase().contains('24/7');
    final unknown = p.openStatus == 'Hours unknown';
    final statusColor = unknown ? AppColors.textMuted : (isOpen24 ? AppColors.green : AppColors.blue);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_pharmacy, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.directions_walk, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(p.distanceLabel, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text(unknown ? 'Hours N/A' : (isOpen24 ? 'Open 24/7' : 'Check hours'),
                      style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ]),
              if (p.address != null) ...[
                const SizedBox(height: 4),
                Text(p.address!, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openInMaps(p),
              icon: const Icon(Icons.directions, size: 16),
              label: Text('Navigate', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (p.phone != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _call(p.phone!),
                icon: const Icon(Icons.call, size: 16, color: AppColors.teal),
                label: Text('Call', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}