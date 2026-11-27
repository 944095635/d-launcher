import 'dart:convert';
import 'dart:io';

/// 天气信息：地区、天气、最高温度、空气质量指数。
class WeatherInfo {
  final String location;
  final String weather;
  final String maxTemp;
  final String aqi;

  const WeatherInfo({
    required this.location,
    required this.weather,
    required this.maxTemp,
    required this.aqi,
  });

  /// 桌面单行展示文本。
  @override
  String toString() => '$location $weather $maxTemp° $aqi';
}

/// 天气服务：组合免费接口拿全所需字段，只在启动时拉取一次。
class WeatherService {
  static const _uapisUrl = 'https://uapis.cn/api/v1/misc/weather?extended=true';
  static const _geoUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _forecastUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _timeout = Duration(seconds: 8);

  /// 拉取天气：uapis 按 IP 定位给地区/天气/AQI，Open-Meteo 补当日最高温。
  /// 核心字段拿不到返回 null；最高温拿不到则留空，不影响其余展示。
  static Future<WeatherInfo?> fetch() async {
    final client = HttpClient();
    client.connectionTimeout = _timeout;
    try {
      // 1. 实况：按请求方公网 IP 自动定位，拿地区、天气、AQI
      final live = await _getJson(client, Uri.parse(_uapisUrl));
      if (live == null) return null;
      final city = live['city'] as String? ?? '';
      final weather = live['weather'] as String? ?? '';
      final aqi = live['aqi']?.toString() ?? '';
      if (city.isEmpty) return null;

      // 2. 经纬度：uapis 的 city 带「市」后缀，geocoding 只认纯城市名
      final query = city.endsWith('市')
          ? city.substring(0, city.length - 1)
          : city;
      final geo = await _getJson(
        client,
        Uri.parse(_geoUrl).replace(
          queryParameters: {
            'name': query,
            'count': '1',
            'language': 'zh',
          },
        ),
      );
      final results = geo?['results'] as List<dynamic>?;

      // 3. 预报：当日最高温；geocoding/预报失败只让最高温留空
      var maxTemp = '';
      if (results != null && results.isNotEmpty) {
        final point = results.first as Map<String, dynamic>;
        final forecast = await _getJson(
          client,
          Uri.parse(_forecastUrl).replace(
            queryParameters: {
              'latitude': '${point['latitude']}',
              'longitude': '${point['longitude']}',
              'daily': 'temperature_2m_max',
              'timezone': 'Asia/Shanghai',
              'forecast_days': '1',
            },
          ),
        );
        final temps =
            forecast?['daily']?['temperature_2m_max'] as List<dynamic>?;
        if (temps != null && temps.isNotEmpty) {
          maxTemp = (temps.first as num).round().toString();
        }
      }

      return WeatherInfo(
        location: query,
        weather: weather,
        maxTemp: maxTemp,
        aqi: aqi,
      );
    } finally {
      client.close();
    }
  }

  /// GET 并解析 JSON；网络或解析异常统一返回 null，不让启动流程崩溃。
  static Future<Map<String, dynamic>?> _getJson(
    HttpClient client,
    Uri uri,
  ) async {
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
