import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_colors.dart';

/// Halaman Tentang (About) aplikasi Sadaya.
///
/// Menampilkan identitas koperasi, filosofi nama, moto, dan versi aplikasi
/// yang dibaca dinamis dari `package_info_plus` (mengikuti pubspec.yaml).
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        scrolledUnderElevation: 0,
        title: const Text('Tentang'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.brand800,
                    child: const Text(
                      'CDP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'KSU Cahaya Dhamma Phala',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sadaya — Sistem Informasi Koperasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  if (_version.isNotEmpty)
                    Text(
                      'Versi $_version'
                      '${_buildNumber.isNotEmpty ? ' ($_buildNumber)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brand700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const Divider(height: 24),
                  const SizedBox(height: 8),
                  Text(
                    'Tentang kami',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"Sadaya" berasal dari bahasa Sunda "sadayana" yang '
                    'berarti semua/bersama. Dimaknai sebagai wujud nyata dari '
                    'Dana Paramita — kesempurnaan berbagi dalam ajaran Dhamma. '
                    'Koperasi adalah tempat di mana kebajikan dipraktikkan '
                    'bersama: setiap anggota saling menopang, hasil usaha '
                    'dinikmati bersama, seperti Sangha yang tumbuh dalam '
                    'cahaya kebenaran.',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.brand100),
                    ),
                    child: Text(
                      '"Bersama dalam Cahaya, Tumbuh dalam Kebajikan"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}