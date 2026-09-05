import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Pembatas sentral lebar konten pada layar lebar.
///
/// Membungkus [child] dalam [Align] + [ConstrainedBox] ber-[maxWidth] sehingga
/// isi tidak terentang penuh di Windows/desktop — dipakai seragam di semua
/// halaman (dulu hanya login yang membatasi lebar).
///
/// Tidak menambah padding sendiri: padding tetap dipegang konten (ListView dsb.)
/// agar tidak menumpuk; berperilaku netral di layar mobile (lebar < [maxWidth]).
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Grid kartu yang menyesuaikan jumlah kolom terhadap lebar tersedia.
///
/// Mengganti `GridView.count(crossAxisCount: 3)` dan `MediaQuery.width / 2`
/// yang kaku: jumlah kolom dihitung dari [maxCrossAxisExtent] sehingga di layar
/// lebar muncul lebih banyak kolom, di layar sempit jatuh ke 1-2 kolom.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.maxCrossAxisExtent = 260,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double maxCrossAxisExtent;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _columnCount(constraints.maxWidth);
        return Column(
          children: [
            for (var i = 0; i < children.length; i += cols) ...[
              if (i > 0) SizedBox(height: spacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < cols && i + j < children.length; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(child: children[i + j]),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  int _columnCount(double width) {
    final n = (width / (maxCrossAxisExtent + spacing)).ceil();
    return n.clamp(1, 4);
  }
}
