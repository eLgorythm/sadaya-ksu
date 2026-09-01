import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';

/// Halaman Tentang (About) aplikasi Sadaya.
///
/// Menampilkan identitas koperasi (logo, nama, tagline, versi, filosofi,
/// moto, dan informasi aplikasi). Data identitas dibaca dari tabel
/// `app_settings` (dapat diubah pengurus tanpa release) dengan fallback ke
/// nilai bawaan bila belum tersedia/offline. Versi dibaca dinamis dari
/// `package_info_plus`.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const _defaultName = 'KSU Cahaya Dhamma Phala';
  static const _defaultTagline = 'Sadaya — Sistem Informasi Koperasi';
  static const _defaultAppName = 'Sadaya';
  static const _defaultMotto = '"Bersama dalam Cahaya, Tumbuh dalam Kebajikan"';
  static const _defaultDeveloper = 'Elfan Dwi Saputra';
  static const _defaultDescription =
      '"Sadaya" berasal dari bahasa Sunda "sadayana" yang berarti '
      'semua/bersama. Dimaknai sebagai wujud nyata dari Dana Paramita — '
      'kesempurnaan berbagi dalam ajaran Dhamma. Koperasi adalah tempat di '
      'mana kebajikan dipraktikkan bersama: setiap anggota saling menopang, '
      'hasil usaha dinikmati bersama, seperti Sangha yang tumbuh dalam '
      'cahaya kebenaran.';

  final int _year = DateTime.now().year;

  String _name = _defaultName;
  String _tagline = _defaultTagline;
  String _appName = _defaultAppName;
  String _motto = _defaultMotto;
  String _developer = _defaultDeveloper;
  String _description = _defaultDescription;
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadSettings();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _loadSettings() async {
    try {
      final rows = await Supabase.instance.client
          .from('app_settings')
          .select('key, value')
          .inFilter('key', const [
            'koperasi_name',
            'app_tagline',
            'app_name',
            'app_motto',
            'app_developer',
            'app_description',
          ]);
      if (!mounted) return;
      final map = <String, String>{
        for (final r in rows) r['key'] as String: (r['value'] as String? ?? ''),
      };
      setState(() {
        _name = _valueOr(map, 'koperasi_name', _name);
        _tagline = _valueOr(map, 'app_tagline', _tagline);
        _appName = _valueOr(map, 'app_name', _appName);
        _motto = _valueOr(map, 'app_motto', _motto);
        _developer = _valueOr(map, 'app_developer', _developer);
        _description = _valueOr(map, 'app_description', _description);
      });
    } catch (_) {
      // Tetap pakai nilai bawaan bila gagal/offline.
    }
  }

  String _valueOr(
      Map<String, String> map, String key, String fallback) {
    final v = map[key];
    return (v != null && v.isNotEmpty) ? v : fallback;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo, nama, tagline, chip versi
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
              _name,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _tagline,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (versionNumber.isNotEmpty)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.brand100),
                  ),
                  child: Text(
                    versionNumber.isEmpty
                        ? 'v—'
                        : 'v$versionNumber • '
                            '${_buildNumber.isEmpty ? '?' : _buildNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand700,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Kartu filosofi
            _SectionCard(
              title: 'Tentang Sadaya',
              child: Text(
                _description,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Kartu motto
            _SectionCard(
              child: Text(
                _motto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand800,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Informasi Aplikasi
            Text(
              'Informasi Aplikasi',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _InfoCard(
              items: [
                _InfoItem(label: 'Nama Aplikasi', value: _appName),
                _InfoItem(
                  label: 'Versi',
                  value: versionNumber.isEmpty
                      ? '—'
                      : '$versionNumber (${_buildNumber.isEmpty ? '?' : _buildNumber})',
                ),
                _InfoItem(label: 'Pengembang', value: _developer),
                _InfoItem(label: 'Tahun', value: '$_year'),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Dibuat untuk Koperasi Cahaya Dhamma Phala',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),

            Text(
              '0xfndLabs © $_year',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  String get versionNumber =>
      _version.isNotEmpty ? _version : '';
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    items[i].label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  Text(
                    items[i].value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}