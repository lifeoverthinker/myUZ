import 'package:http/http.dart' as http;

abstract class ScraperBase {
  Future<String> fetchPage(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load page');
    }
  }

  String normalizeUrl(String url) {
    return url.startsWith('http') ? url : 'https://plan.uz.zgora.pl/$url';
  }

  String? extractIdFromUrl(String url, String param) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    return uri.queryParameters[param];
  }
}