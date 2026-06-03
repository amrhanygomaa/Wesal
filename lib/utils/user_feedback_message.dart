String friendlyApiErrorMessage(
  int statusCode,
  String rawMessage, {
  Object? body,
}) {
  final raw = _cleanRawMessage(rawMessage);
  final rawLower = raw.toLowerCase();
  final bodyLower = body?.toString().toLowerCase() ?? '';
  final combined = '$rawLower $bodyLower';

  if (_looksLikeConnectionIssue(combined)) {
    return 'تعذر الاتصال بالخدمة. تحقق من الإنترنت ثم حاول مرة أخرى.';
  }
  if (combined.contains('managed user') && combined.contains('not found')) {
    return 'الحساب غير موجود أو تم حذفه من قبل، لذلك لا يمكن تنفيذ الإجراء عليه.';
  }
  if (combined.contains('internal server error')) {
    return 'تعذر تنفيذ العملية لأن الخدمة مشغولة حالياً. حاول مرة أخرى بعد قليل.';
  }
  if (combined.contains('should not exist') ||
      combined.contains('property ') ||
      combined.contains('invalid profile image') ||
      combined.contains('invalid family media')) {
    return 'بعض البيانات المرسلة غير مناسبة لهذا الإجراء. راجع البيانات ثم حاول مرة أخرى.';
  }
  if (combined.contains('already') ||
      combined.contains('exists') ||
      combined.contains('duplicate')) {
    return 'هذه البيانات مستخدمة من قبل. جرّب بيانات مختلفة ثم أعد المحاولة.';
  }
  if (combined.contains('not found')) {
    return 'العنصر المطلوب غير موجود أو تم حذفه من قبل.';
  }

  return switch (statusCode) {
    0 => raw.isNotEmpty
        ? _friendlyNonTechnical(raw)
        : 'تعذر الاتصال بالخدمة. تحقق من الإنترنت ثم حاول مرة أخرى.',
    400 =>
      'البيانات غير مكتملة أو غير مناسبة لهذا الإجراء. راجع الحقول ثم حاول مرة أخرى.',
    401 => 'انتهت صلاحية الجلسة. سجّل الدخول مرة أخرى ثم حاول.',
    403 => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
    404 => 'العنصر المطلوب غير موجود أو تم حذفه من قبل.',
    409 =>
      'يوجد تعارض في البيانات. ربما تم استخدام نفس البريد أو الرقم من قبل.',
    413 => 'الملف كبير جداً. اختر ملفاً أصغر ثم حاول مرة أخرى.',
    422 => 'بعض البيانات غير مقبولة. راجع الحقول المطلوبة ثم حاول مرة أخرى.',
    429 => 'تم إرسال طلبات كثيرة في وقت قصير. انتظر قليلاً ثم حاول مرة أخرى.',
    >= 500 && <= 599 =>
      'تعذر تنفيذ العملية لأن الخدمة مشغولة حالياً. حاول مرة أخرى بعد قليل.',
    _ => raw.isEmpty
        ? 'تعذر تنفيذ العملية حالياً. حاول مرة أخرى.'
        : _looksLikeTechnicalMessage(rawLower)
            ? 'تعذر تنفيذ العملية حالياً. راجع البيانات ثم حاول مرة أخرى.'
            : raw,
  };
}

String friendlyFeedbackMessage(String message) {
  final raw = _cleanRawMessage(message);
  if (raw.isEmpty) return 'تعذر تنفيذ العملية حالياً. حاول مرة أخرى.';

  final lower = raw.toLowerCase();
  final contextualMessage = _friendlyContextualMessage(raw);
  if (contextualMessage != null) return contextualMessage;

  final statusCode = _statusCodeFromText(lower);
  if (statusCode != null) {
    return friendlyApiErrorMessage(statusCode, raw);
  }
  if (_looksLikeTechnicalMessage(lower)) {
    return friendlyApiErrorMessage(-1, raw);
  }
  return raw;
}

String? _friendlyContextualMessage(String raw) {
  final match = RegExp(r'^(.{3,80}?)[\:：]\s*(.+)$').firstMatch(raw);
  if (match == null) return null;

  final prefix = (match.group(1) ?? '').trim();
  final detail = (match.group(2) ?? '').trim();
  if (prefix.isEmpty || detail.isEmpty || prefix == 'خطأ' || prefix == 'فشل') {
    return null;
  }

  final detailLower = detail.toLowerCase();
  if (!_looksLikeTechnicalMessage(detailLower)) return null;

  final reason = friendlyApiErrorMessage(
    _statusCodeFromText(detailLower) ?? -1,
    detail,
  );
  return '$prefix. السبب: $reason';
}

String _cleanRawMessage(String value) {
  var text = value.trim();
  text = text.replaceFirst(RegExp(r'^ApiException\(\d+\):\s*'), '');
  text = text.replaceFirst(RegExp(r'^خطأ\s*:\s*'), '');
  text = text.replaceFirst(RegExp(r'^فشل\s*:\s*'), '');
  return text.trim();
}

String _friendlyNonTechnical(String raw) {
  final lower = raw.toLowerCase();
  if (_looksLikeTechnicalMessage(lower)) {
    return 'تعذر تنفيذ العملية حالياً. راجع البيانات ثم حاول مرة أخرى.';
  }
  return raw;
}

bool _looksLikeConnectionIssue(String value) {
  return value.contains('socket') ||
      value.contains('timeout') ||
      value.contains('timed out') ||
      value.contains('network') ||
      value.contains('connection') ||
      value.contains('internet') ||
      value.contains('لا يوجد اتصال') ||
      value.contains('مهلة الاتصال');
}

bool _looksLikeTechnicalMessage(String value) {
  return value.contains('internal server error') ||
      value.contains('apiresponse') ||
      value.contains('apiexception') ||
      value.contains('http ') ||
      value.contains('الباك اند') ||
      value.contains('property ') ||
      value.contains('should not exist') ||
      value.contains('cognito') ||
      value.contains('s3') ||
      value.contains('json') ||
      value.contains('backend') ||
      value.contains('server') ||
      value.contains('exception') ||
      value.contains('null') ||
      value.contains('undefined') ||
      value.contains('not found');
}

int? _statusCodeFromText(String value) {
  final apiMatch = RegExp(r'apiexception\((\d+)\)').firstMatch(value);
  if (apiMatch != null) return int.tryParse(apiMatch.group(1) ?? '');

  final httpMatch = RegExp(r'http\s*(\d+)').firstMatch(value);
  if (httpMatch != null) return int.tryParse(httpMatch.group(1) ?? '');

  if (value.contains('internal server error')) return 500;
  return null;
}
