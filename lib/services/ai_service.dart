import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/app_models.dart';

class AiChatResponse {
  final String reply;
  final String sentiment;
  final String mode;
  final bool bedrockEnabled;
  final String disclaimer;

  AiChatResponse({
    required this.reply,
    required this.sentiment,
    required this.mode,
    required this.bedrockEnabled,
    required this.disclaimer,
  });

  bool get isFromBedrock => mode == 'bedrock';

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      reply: (json['reply'] ?? '').toString(),
      sentiment: (json['sentiment'] ?? 'neutral').toString(),
      mode: (json['mode'] ?? 'backend').toString(),
      bedrockEnabled: json['bedrockEnabled'] == true,
      disclaimer: (json['disclaimer'] ?? '').toString(),
    );
  }
}

class AiRecommendation {
  final String residentId;
  final String summary;
  final String rationale;
  final String generatedAt;
  final String flag;
  final String disclaimer;

  AiRecommendation({
    required this.residentId,
    required this.summary,
    required this.rationale,
    required this.generatedAt,
    required this.flag,
    required this.disclaimer,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      residentId: (json['residentId'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      rationale: (json['rationale'] ?? '').toString(),
      generatedAt: (json['generatedAt'] ?? '').toString(),
      flag: (json['flag'] ?? '').toString(),
      disclaimer: (json['disclaimer'] ?? '').toString(),
    );
  }
}

class AiSpeechResponse {
  final String provider;
  final String voiceId;
  final String engine;
  final String contentType;
  final String audioBase64;

  AiSpeechResponse({
    required this.provider,
    required this.voiceId,
    required this.engine,
    required this.contentType,
    required this.audioBase64,
  });

  factory AiSpeechResponse.fromJson(Map<String, dynamic> json) {
    return AiSpeechResponse(
      provider: (json['provider'] ?? 'aws-polly').toString(),
      voiceId: (json['voiceId'] ?? '').toString(),
      engine: (json['engine'] ?? '').toString(),
      contentType: (json['contentType'] ?? 'audio/mpeg').toString(),
      audioBase64: (json['audioBase64'] ?? '').toString(),
    );
  }
}

// خدمة الذكاء الاصطناعي عبر AWS Bedrock (Claude Haiku 4.5)
// متصلة فعلياً بالباك اند الإنتاجي على EC2.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  // إرسال رسالة للرفيق الذكي
  Future<AiChatResponse> sendChat({
    required String message,
    String residentName = 'صديقنا',
    String? residentId,
    String language = 'ar-eg',
    List<Map<String, String>>? conversationHistory,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'residentName': residentName,
      'language': language,
    };
    if (residentId != null) body['residentId'] = residentId;
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      body['conversationHistory'] = conversationHistory;
    }

    final res = await ApiClient.instance.post(
      '/ai/chat',
      body: body,
      auth: false, // endpoint عام في الباك اند
    );

    if (kDebugMode) {
      debugPrint('[AI] chat mode=${res['mode']} sentiment=${res['sentiment']}');
    }

    return AiChatResponse.fromJson(res as Map<String, dynamic>);
  }

  Future<AiSpeechResponse> synthesizeSpeech({
    required String text,
    String voiceId = 'Zayd',
    String engine = 'neural',
    String? provider,
    String? openAiVoice,
    String? openAiVoiceId,
    String? voiceInstructions,
  }) async {
    final body = <String, dynamic>{
      'text': text,
      'voiceId': voiceId,
      'engine': engine,
    };
    if (provider != null) body['provider'] = provider;
    if (openAiVoice != null) body['openAiVoice'] = openAiVoice;
    if (openAiVoiceId != null) body['openAiVoiceId'] = openAiVoiceId;
    if (voiceInstructions != null) {
      body['voiceInstructions'] = voiceInstructions;
    }

    final res = await ApiClient.instance.post(
      '/ai/speech',
      body: body,
      auth: false,
    );
    return AiSpeechResponse.fromJson(res as Map<String, dynamic>);
  }

  // جلب توصيات الذكاء الاصطناعي لمقيم
  Future<AiRecommendation> getRecommendations(String residentId) async {
    final res = await ApiClient.instance.get(
      '/ai/recommendations/$residentId',
      auth: false,
    );
    return AiRecommendation.fromJson(res as Map<String, dynamic>);
  }

  // حفظ ذاكرة المقيم في السيرفر (مفيد للسياق)
  Future<void> saveMemory(String residentId, List<String> facts) async {
    if (facts.isEmpty) return;
    await ApiClient.instance.post(
      '/ai/memory/$residentId',
      body: {'memory': facts},
      auth: false,
    );
  }

  // جلب الذاكرة المحفوظة للمقيم
  Future<List<String>> getMemory(String residentId) async {
    try {
      final res = await ApiClient.instance.get(
        '/ai/memory/$residentId',
        auth: false,
      );
      final memory = res['memory'];
      if (memory is List) return memory.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }

  // 1. تلخيص الشيفت
  Future<String> summarizeShiftHandoff(List<NursingNote> notes, List<CareTask> tasks) async {
    try {
      final res = await ApiClient.instance.post(
        '/ai/summarize-shift',
        body: {
          'notes': notes.map((e) => e.content).toList(),
          'tasks': tasks.map((e) => e.title).toList(),
        },
        auth: true,
      );
      final summary = res['summary']?.toString();
      if (summary != null && summary.isNotEmpty) return summary;
    } catch (_) {
      // fallback to local summary below
    }
    return _buildLocalShiftSummary(notes, tasks);
  }

  String _buildLocalShiftSummary(List<NursingNote> notes, List<CareTask> tasks) {
    final buffer = StringBuffer();

    if (notes.isEmpty && tasks.isEmpty) {
      return 'لا توجد ملاحظات أو مهام مسجلة في هذه الوردية.';
    }

    if (notes.isNotEmpty) {
      buffer.writeln('سُجِّلت ${notes.length} ملاحظة تمريضية خلال الوردية.');
      final residents = notes.map((n) => n.residentName).toSet();
      if (residents.isNotEmpty) {
        buffer.writeln('المقيمون الذين تمت متابعتهم: ${residents.join('، ')}.');
      }
    }

    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    if (total > 0) {
      buffer.writeln('مهام الرعاية: $completed/$total مهمة مكتملة.');
      final pending = tasks.where((t) => !t.isCompleted).take(3).map((t) => t.title).toList();
      if (pending.isNotEmpty) {
        buffer.writeln('المهام المعلقة: ${pending.join('، ')}.');
      }
    }

    buffer.write('يُرجى مراجعة الحالات المسجلة وضمان استمرارية الرعاية.');
    return buffer.toString().trim();
  }

  // 2. الخطة الغذائية الذكية
  Future<MealPlan> generateSmartDiet(ResidentMedicalInfo info) async {
    final res = await ApiClient.instance.post(
      '/ai/smart-diet',
      body: {
        'residentName': info.residentName,
        'chronicDiseases': info.chronicDiseases,
        'allergies': info.allergies,
      },
      auth: true,
    );
    return MealPlan(
      residentName: info.residentName,
      breakfast: res['breakfast'] ?? 'شوفان مع فواكه',
      lunch: res['lunch'] ?? 'دجاج مشوي مع خضار مسلوق',
      dinner: res['dinner'] ?? 'زبادي وخيار',
      isAiGenerated: true,
      aiRationale: res['rationale'] ?? 'تم اختيار هذه الوجبات لتقليل نسبة السكر.',
    );
  }

  // 3. التنبؤ الصحي
  Future<List<AIInsight>> getPredictiveHealthAlerts(String residentId) async {
    final res = await ApiClient.instance.get('/ai/predictive-alerts/$residentId', auth: true);
    if (res['alerts'] is List) {
      return (res['alerts'] as List).map((e) {
        final rawName = (e['residentName'] ?? '').toString();
        final safeName = isUuid(rawName) ? 'مقيم' : rawName;
        return AIInsight(
          id: e['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          residentName: safeName.isEmpty ? 'مقيم' : safeName,
          roomNumber: e['roomNumber']?.toString(),
          summary: stripUuids((e['summary'] ?? '').toString()),
          rationale: stripUuids((e['rationale'] ?? '').toString()),
          generationDate: DateTime.now(),
          type: 'predictive_alert',
        );
      }).toList();
    }
    return [];
  }

  // 4. التدريب الذهني
  Future<AiChatResponse> playCognitiveGame(String residentId, String input) async {
    final res = await ApiClient.instance.post(
      '/ai/cognitive-game',
      body: {'residentId': residentId, 'input': input},
      auth: true,
    );
    return AiChatResponse.fromJson(res as Map<String, dynamic>);
  }

  // 5. التحديث العائلي التلقائي
  Future<String> generateFamilyWeeklyUpdate(String residentId) async {
    final res = await ApiClient.instance.post('/ai/family-update', body: {'residentId': residentId}, auth: true);
    return res['update']?.toString() ?? '';
  }

  // 6. التحليل الصوتي للمشاعر
  Future<AiChatResponse> analyzeVoiceSentiment(String base64Audio, String residentId) async {
    final res = await ApiClient.instance.post(
      '/ai/voice-sentiment',
      body: {'audio': base64Audio, 'residentId': residentId},
      auth: true,
    );
    return AiChatResponse.fromJson(res as Map<String, dynamic>);
  }
}
