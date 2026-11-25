import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// 一次定位结果（当前一期为 IP 城市级）。
class GeoPlace {
  const GeoPlace({
    required this.country,
    required this.city,
    this.province,
    this.lat,
    this.lng,
    this.source = 'ip',
  });

  /// 国家（已尽量转成中文，如「中国」）。
  final String country;

  /// 省 / 州。
  final String? province;

  /// 城市（如「深圳」）。
  final String city;

  /// 粗略坐标（IP 级，仅作参考）。
  final double? lat;
  final double? lng;

  /// 来源：ip / gps / manual。
  final String source;

  /// 展示文案：「中国-深圳」。
  String get label {
    final parts = [country, city]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.join('-');
  }
}

/// 位置服务：通过免 Key 的 IP 定位接口获取城市。
///
/// 主通道 ipwho.is，失败自动切 ipapi.co；两者都失败返回 null，
/// 由调用方退回手动输入。结果在内存缓存 10 分钟，避免频繁进出记账页时
/// 反复暴露 IP。
class LocationService {
  LocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 6);
  static const Duration _cacheTtl = Duration(minutes: 10);

  static GeoPlace? _cache;
  static DateTime? _cacheAt;

  static const _labelMap = <String, String>{
    'China': '中国',
    'Hong Kong': '中国香港',
    'Macao': '中国澳门',
    'Macau': '中国澳门',
    'Taiwan': '中国台湾',
  };

  /// 获取当前城市。[force] 为 true 时忽略缓存重新请求。
  Future<GeoPlace?> currentCity({bool force = false}) async {
    if (!force && _cache != null && _cacheAt != null) {
      if (DateTime.now().difference(_cacheAt!) < _cacheTtl) return _cache;
    }
    final place = await _fromIpWho() ?? await _fromIpApiCo();
    if (place != null) {
      _cache = place;
      _cacheAt = DateTime.now();
    }
    return place;
  }

  Future<GeoPlace?> _fromIpWho() async {
    try {
      final resp = await _client
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final map = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (map['success'] != true) return null;
      final city = (map['city'] as String? ?? '').trim();
      if (city.isEmpty) return null;
      return GeoPlace(
        country: _cn(map['country'] as String?),
        city: city,
        province: (map['region'] as String?)?.trim(),
        lat: (map['latitude'] as num?)?.toDouble(),
        lng: (map['longitude'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<GeoPlace?> _fromIpApiCo() async {
    try {
      final resp = await _client
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final map = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (map['error'] == true) return null;
      final city = (map['city'] as String? ?? '').trim();
      if (city.isEmpty) return null;
      return GeoPlace(
        country: _cn(map['country_name'] as String?),
        city: city,
        province: (map['region'] as String?)?.trim(),
        lat: (map['latitude'] as num?)?.toDouble(),
        lng: (map['longitude'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  String _cn(String? country) {
    final name = (country ?? '').trim();
    if (name.isEmpty) return '';
    return _labelMap[name] ?? name;
  }
}

/// 位置服务 provider。
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
