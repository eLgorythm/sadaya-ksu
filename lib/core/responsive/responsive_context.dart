import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Ekstensi responsif [BuildContext] untuk menentukan rentang layar.
extension ResponsiveContext on BuildContext {
  /// Lebar viewport aktif (bukan lebar layar fisik).
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// True bila lebar < [AppBreakpoints.mobile] (klasik handphone).
  bool get isMobile => screenWidth < AppBreakpoints.mobile;

  /// True bila lebar di [600..1024) (tablet / jendela desktop kecil).
  bool get isTablet =>
      screenWidth >= AppBreakpoints.mobile &&
      screenWidth < AppBreakpoints.tablet;

  /// True bila lebar >= [AppBreakpoints.tablet] (Windows / desktop).
  bool get isDesktop => screenWidth >= AppBreakpoints.tablet;

  /// Jumlah kolom yang wajar untuk kartu berseri terhadap lebar saat ini.
  /// Dipakai [ResponsiveGrid] sebagai palang minimal; tetap dikenakan
  /// [AppBreakpoints.contentMaxWidth] agar tidak terlalu rapat di layar besar.
  int get responsiveColumns {
    if (isMobile) return 1;
    if (isTablet) return 2;
    return 3;
  }
}
