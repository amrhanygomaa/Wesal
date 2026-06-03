import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';

class AuthenticatedNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error, StackTrace? stack)?
      errorBuilder;

  const AuthenticatedNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (!_needsAuthHeader(url)) {
      return _image(url);
    }

    return FutureBuilder<String?>(
      future: ApiClient.instance.getToken(),
      builder: (context, snapshot) {
        final token = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return loadingBuilder?.call(context) ?? const SizedBox.shrink();
        }
        return _image(
          url,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        );
      },
    );
  }

  Widget _image(String src, {Map<String, String>? headers}) {
    return Image.network(
      src,
      fit: fit,
      headers: headers,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return loadingBuilder?.call(context) ?? child;
      },
      errorBuilder: errorBuilder,
    );
  }

  bool _needsAuthHeader(String src) {
    final uri = Uri.tryParse(src);
    final apiUri = Uri.tryParse(ApiConfig.baseUrl);
    if (uri == null || apiUri == null) return false;
    return uri.host == apiUri.host && uri.scheme == apiUri.scheme;
  }
}
