/// Konstanta breakpoint dan batas lebar responsif aplikasi.
///
/// Basis: mobile < 600, tablet 600..1023, desktop >= 1024.
abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;

  /// Batas maksimal lebar konten [MaxWidthBox] pada layar lebar.
  /// Mirip pola login (400) namun untuk halaman konten umum.
  static const double contentMaxWidth = 1200;

  /// Lebar maksimal form/sheet vertikal.
  static const double formMaxWidth = 480;
}
