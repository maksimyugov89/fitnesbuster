import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fitnesbuster/core/ai/ai_exception.dart';
import 'package:fitnesbuster/core/ai/network/retry_handler.dart';
import 'package:fitnesbuster/core/ai/validators/json_validator.dart';
import 'package:fitnesbuster/core/localization/language_service.dart';

String _languageInstruction() {
  return switch (LanguageService.current) {
    AppLanguage.russian => 'Отвечай СТРОГО на русском языке',
    AppLanguage.english => 'Answer STRICTLY in English',
    AppLanguage.spanish => 'Responde ESTRICTAMENTE en español',
    AppLanguage.german => 'Antworte AUSSCHLIESSLICH auf Deutsch',
    AppLanguage.french => 'Réponds STRICTEMENT en français',
    AppLanguage.italian => 'Rispondi RIGOROSAMENTE in italiano',
    AppLanguage.portuguese => 'Responda ESTRITAMENTE em português',
    AppLanguage.turkish => 'KESİNLİKLE Türkçe cevap ver',
    AppLanguage.arabic => 'أجب باللغة العربية فقط',
    AppLanguage.chinese => '请严格使用中文回答',
    AppLanguage.japanese => '必ず日本語で回答すること',
    AppLanguage.korean => '반드시 한국어로 답변하세요',
    AppLanguage.hindi => 'सख्ती से हिंदी में उत्तर दें',
    AppLanguage.ukrainian => 'Відповідай СТРОГО українською мовою',
    AppLanguage.belarusian => 'Адказвай СТРОГА на беларускай мове',
  };
}

String _productLanguageInstruction() {
  return switch (LanguageService.current) {
    AppLanguage.russian =>
      'ВСЕ названия продуктов, блюд, добавок и описания выводи СТРОГО на русском языке',
    AppLanguage.english =>
      'ALL product, dish, supplement names and descriptions MUST be output in English',
    AppLanguage.spanish =>
      'TODOS los nombres de productos, platos, suplementos y descripciones DEBEN estar en español',
    AppLanguage.german =>
      'ALLE Produkt-, Gerichts-, Supplementnamen und Beschreibungen MÜSSEN auf Deutsch ausgegeben werden',
    AppLanguage.french =>
      'TOUS les noms de produits, plats, suppléments et descriptions DOIVENT être en français',
    AppLanguage.italian =>
      'TUTTI i nomi di prodotti, piatti, integratori e descrizioni DEVONO essere in italiano',
    AppLanguage.portuguese =>
      'TODOS os nomes de produtos, pratos, suplementos e descrições DEVEM estar em português',
    AppLanguage.turkish =>
      'TÜM ürün, yemek, takviye adları ve açıklamalar KESİNLİKLE Türkçe olmalıdır',
    AppLanguage.arabic =>
      'جميع أسماء المنتجات والأطباق والمكملات والأوصاف يجب أن تكون باللغة العربية',
    AppLanguage.chinese => '所有产品、菜肴、补充剂名称和描述必须使用中文',
    AppLanguage.japanese => 'すべての製品、料理、サプリメント名と説明は日本語で出力すること',
    AppLanguage.korean => '모든 제품, 요리, 보충제 이름과 설명은 한국어로 출력해야 합니다',
    AppLanguage.hindi =>
      'सभी उत्पाद, व्यंजन, सप्लीमेंट के नाम और विवरण हिंदी में होने चाहिए',
    AppLanguage.ukrainian =>
      'ВСІ назви продуктів, страв, добавок та описи виводь СТРОГО українською мовою',
    AppLanguage.belarusian =>
      'УСЕ назвы прадуктаў, страў, дабавак і апісанні выводзь СТРОГА на беларускай мове',
  };
}

class BaseClient {
  Future<String> sendMessage(
    String prompt, {
    int maxTokens = 8192,
    double temperature = 0.7,
  }) {
    return withRetry(() async {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('deepseekProxy');
      final result = await callable.call<Map<String, dynamic>>({
        'messages': [
          {
            'role': 'system',
            'content':
                'Ты — профессиональный персональный тренер и диетолог. ${_languageInstruction()}',
          },
          {'role': 'user', 'content': prompt},
        ],
        'maxTokens': maxTokens,
        'temperature': temperature,
      });
      final content = result.data['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const AiException('Пустой ответ от AI. Попробуйте ещё раз.');
      }
      return content;
    }, shouldRethrow: (e) => e.statusCode == 401 || e.statusCode == 429);
  }

  Future<String> sendMessagesList(
    List<Map<String, String>> messages, {
    int maxTokens = 2048,
    double temperature = 0.8,
  }) {
    return withRetry(() async {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('deepseekProxy');
      final result = await callable.call<Map<String, dynamic>>({
        'messages': messages,
        'maxTokens': maxTokens,
        'temperature': temperature,
      });
      final content = result.data['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const AiException('Пустой ответ от AI. Попробуйте ещё раз.');
      }
      return content;
    }, shouldRethrow: (e) => e.statusCode == 401 || e.statusCode == 429);
  }

  Future<String> callWithValidation({
    required List<Map<String, String>> messages,
    required int maxTokens,
    required double temperature,
    required String Function(String raw) validator,
  }) {
    return withRetry(() async {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('deepseekProxy');
      final result = await callable.call<Map<String, dynamic>>({
        'messages': messages,
        'maxTokens': maxTokens,
        'temperature': temperature,
      });
      final content = result.data['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const AiException('Пустой ответ от AI. Попробуйте ещё раз.');
      }
      return validator(extractJson(content));
    }, shouldRethrow: (e) => e.statusCode == 401 || e.statusCode == 429);
  }

  String get languageInstruction => _languageInstruction();
  String get productLanguageInstruction => _productLanguageInstruction();

  void dispose() {}
}
