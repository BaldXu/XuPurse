import 'package:flutter/material.dart';

/// 弹出 PS 风格取色器（色相条 + 饱和度/明度二维面板）。
/// 确认返回所选颜色；取消返回 null。
Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required Color initial,
  String? title,
}) {
  return showDialog<Color>(
    context: context,
    builder: (_) => _ColorPickerDialog(initial: initial, title: title),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, this.title});

  final Color initial;
  final String? title;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _hue;

  /// 面板内位置：(dx = 饱和度 0~1, dy = 明度 0~1)
  late Offset _sv;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initial);
    _hue = hsv.hue;
    // 面板布局:顶=最亮(v=1) 底=黑(v=0),故 dy 存储时翻转
    _sv = Offset(hsv.saturation, 1 - hsv.value);
  }

  /// dy 在面板中「上=0 下=1」,而 HSV 明度「v=1 亮 / v=0 黑」,需 1-dy 还原
  Color get _color =>
      HSVColor.fromAHSV(1, _hue, _sv.dx, 1 - _sv.dy).toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? '选择颜色'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SVPanel(
            hue: _hue,
            pos: _sv,
            onChanged: (o) => setState(() => _sv = o),
          ),
          const SizedBox(height: 12),
          _HueBar(hue: _hue, onChanged: (h) => setState(() => _hue = h)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                key: const ValueKey('color_picker_preview'),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '#${_hex(_color)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('确认'),
        ),
      ],
    );
  }

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

/// 饱和度/明度二维取色面板（横向 = 饱和度，纵向 = 明度）。
class _SVPanel extends StatelessWidget {
  const _SVPanel({
    required this.hue,
    required this.pos,
    required this.onChanged,
  });

  final double hue;
  final Offset pos;
  final ValueChanged<Offset> onChanged;

  static const _width = 280.0;
  static const _height = 200.0;

  @override
  Widget build(BuildContext context) {
    Offset clamp(Offset d) => Offset(
      (d.dx / _width).clamp(0.0, 1.0),
      (d.dy / _height).clamp(0.0, 1.0),
    );
    return GestureDetector(
      key: const ValueKey('color_picker_sv_panel'),
      onPanDown: (d) => onChanged(clamp(d.localPosition)),
      onPanUpdate: (d) => onChanged(clamp(d.localPosition)),
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          children: [
            // 横向：白 → 当前色相全饱和；纵向叠加：透明 → 黑（明度）
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // 指示器
            Positioned(
              left: pos.dx * _width - 10,
              top: pos.dy * _height - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 色相条（彩虹渐变，拖动选择色相 0~360）。
class _HueBar extends StatelessWidget {
  const _HueBar({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  static const _width = 280.0;

  static const _colors = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('color_picker_hue_bar'),
      onPanDown: (d) =>
          onChanged((d.localPosition.dx / _width).clamp(0.0, 1.0) * 360),
      onPanUpdate: (d) =>
          onChanged((d.localPosition.dx / _width).clamp(0.0, 1.0) * 360),
      child: SizedBox(
        width: _width,
        height: 24,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: _colors),
              ),
            ),
            Positioned(
              left: (hue / 360 * _width) - 7,
              child: Container(
                width: 14,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
