import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:bhart/models/parsed_product.dart';

/// Direct port of src/lib/ai.ts.
///
/// ⚠️ SECURITY NOTE: exactly like the original app's NEXT_PUBLIC_* env vars,
/// keys passed via --dart-define are still bundled into the compiled APK/IPA
/// and can be extracted. This works for a hackathon demo, but before any real
/// release, move these calls behind a Supabase Edge Function (or any thin
/// server proxy) so the actual Groq/Gemini/remove.bg keys never ship to
/// device. The parsing/fallback *logic* below stays identical either way —
/// only the fetch target changes (your edge function instead of the
/// provider directly).
class AiService {
  static const _groqKey = String.fromEnvironment('GROQ_API_KEY');
  static const _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _removeBgKey = String.fromEnvironment('REMOVE_BG_KEY');
  static const _hfToken = String.fromEnvironment('HF_TOKEN');

  // Model IDs can be overridden at build time without touching code, e.g.
  //   --dart-define=GROQ_VISION_MODEL=<id>
  // If one of these IDs is wrong/retired you'll now see the provider's error
  // message in the debug console before the app falls back.
  static const _groqVisionModel =
      String.fromEnvironment('GROQ_VISION_MODEL', defaultValue: 'qwen/qwen3.8-27b');
  static const _groqTextModel =
      String.fromEnvironment('GROQ_TEXT_MODEL', defaultValue: 'openai/gpt-oss-120b');
  static const _geminiModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.7-flash');

  static const _timeout = Duration(seconds: 30);

  static const _imagePrompt =
      'Analyze this image of a product or handicraft. Identify what it is, the likely material, '
      'and estimate the quantity shown. Also generate a professional English and Hindi description '
      'for e-commerce. Return ONLY a valid JSON object with these exact keys: name (string, English name), '
      'nameHi (string, Hindi name of the product), material (string), quantity (number), '
      'userSuggestedPrice (null), descriptionEn (string), descriptionHi (string). Do not wrap in markdown tags.';

  static String _pricePrompt(String name, String material) => '''
You are an expert appraiser for the Indian retail market (like Amazon India, Flipkart, Meesho, ONDC, Delhi Haat). Estimate a realistic, fair-market selling price in INR that an Indian buyer would actually pay online for this item: Name: $name, Material: $material.

CRITICAL PRICING RULES:
1. GEOGRAPHY: You are pricing items for the Indian domestic retail market. All prices MUST reflect local purchasing power. Do not use Western boutique pricing.
2. VALUATION LOGIC: Calculate price based on estimated Indian raw material cost + daily artisan labor + a standard 30% to 50% fair-trade markup.
3. BENCHMARKS:
   - Basic Terracotta/Clay pots (Matka, Kulhad, Planters): ₹80 - ₹180 (never exceed ₹200 for a basic pot)
   - Bamboo/Cane baskets or small crafts: ₹200 - ₹600
   - Commercial standard goods (e.g., steel water bottles, thermos): ₹400 - ₹1200
   - Handloom cotton scarves/small textiles: ₹300 - ₹800
   - Wooden carved home decor: ₹400 - ₹1200
   - Small Dhokra/Brass metal crafts: ₹500 - ₹1500
4. FLEXIBLE UPPER BOUND: Never predict an inflated price for basic goods. However, DO NOT limit the price if the item is clearly a large, highly intricate piece of furniture (like a chair or table, e.g. ₹2000 - ₹15000+), heavy metalwork, or premium silk.
5. ANTI-INFLATION: When in doubt for standard crafts, lean towards a lower, competitive baseline.

Return ONLY the final number in INR. Do not include currency symbols, commas, or any text.''';

  static void _log(String message) => debugPrint('[AiService] $message');

  static ParsedProduct? _parseAiResponse(String text) {
    try {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (match == null) throw Exception('No JSON object found in response');
      var cleanText = match.group(0)!.trim();
      cleanText = cleanText.replaceAll(RegExp(r'```json', caseSensitive: false), '').replaceAll('```', '').trim();
      return ParsedProduct.fromJson(jsonDecode(cleanText) as Map<String, dynamic>);
    } catch (e) {
      _log('Failed to parse AI JSON. Raw text was: $text ($e)');
      return null;
    }
  }

  /// Pulls the FIRST number out of a model reply and rounds it to whole rupees.
  /// "₹150 - ₹200" -> 150, "1,200" -> 1200, "150.50" -> 151, "no idea" -> null.
  /// (The old approach stripped every non-digit, turning "150-200" into 150200.)
  static int? _extractPrice(String text) {
    final match = RegExp(r'\d[\d,]*(?:\.\d+)?').firstMatch(text);
    if (match == null) return null;
    final value = double.tryParse(match.group(0)!.replaceAll(',', ''));
    if (value == null) return null;
    final price = value.round();
    return price > 0 ? price : null;
  }

  // ---- Provider calls -------------------------------------------------------
  // Each helper catches its own errors and returns null, so a network failure
  // or timeout on one provider always falls through to the next one (before,
  // a thrown exception from Groq skipped Gemini and went straight to mock data).

  static Future<String?> _groqChat({
    required String model,
    required List<Map<String, dynamic>> messages,
    required int maxTokens,
    required String label,
  }) async {
    if (_groqKey.isEmpty) return null;
    try {
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_groqKey'},
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': 0.3,
              'max_tokens': maxTokens,
            }),
          )
          .timeout(_timeout);
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        _log('Groq API error ($label, model=$model): ${data['error']}');
        return null;
      }
      return data['choices']?[0]?['message']?['content'] as String?;
    } catch (e) {
      _log('Groq request failed ($label): $e');
      return null;
    }
  }

  static Future<String?> _callGroqVision(String base64Image) {
    return _groqChat(
      model: _groqVisionModel,
      label: 'vision',
      maxTokens: 1024,
      messages: [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _imagePrompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
            },
          ],
        }
      ],
    );
  }

  static Future<String?> _callGroqText(String prompt) {
    return _groqChat(
      model: _groqTextModel,
      label: 'text',
      maxTokens: 256,
      messages: [
        {'role': 'user', 'content': prompt}
      ],
    );
  }

  static Future<String?> _geminiGenerate(List<Map<String, dynamic>> parts, String label) async {
    if (_geminiKey.isEmpty) return null;
    try {
      final response = await http
          .post(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent'),
            // Key goes in a header instead of the URL so it doesn't end up in
            // logs / proxies / crash reports.
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': _geminiKey},
            body: jsonEncode({
              'contents': [
                {'parts': parts}
              ],
            }),
          )
          .timeout(_timeout);
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        _log('Gemini API error ($label, model=$_geminiModel): ${data['error']['message']}');
        return null;
      }
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    } catch (e) {
      _log('Gemini request failed ($label): $e');
      return null;
    }
  }

  static Future<String?> _callGeminiVision(String base64Image) {
    return _geminiGenerate([
      {'text': _imagePrompt},
      {
        'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image}
      },
    ], 'vision');
  }

  static Future<String?> _callGeminiText(String prompt) {
    return _geminiGenerate([
      {'text': prompt}
    ], 'text');
  }

  // ---- Public API -----------------------------------------------------------

  /// Groq vision -> Gemini vision -> mock data, same order as identifyProductFromImage().
  static Future<({ParsedProduct? product, bool isMockData})> identifyProductFromImage(String base64Image) async {
    try {
      final groqResult = await _callGroqVision(base64Image);
      if (groqResult != null) {
        final product = _parseAiResponse(groqResult);
        if (product != null) return (product: product, isMockData: false);
      }

      _log('Groq unavailable, trying Gemini fallback...');
      final geminiResult = await _callGeminiVision(base64Image);
      if (geminiResult != null) {
        final product = _parseAiResponse(geminiResult);
        if (product != null) return (product: product, isMockData: false);
      }

      _log('All AI providers failed. Returning mock data.');
      return (product: ParsedProduct.mock, isMockData: true);
    } catch (e) {
      _log('AI Image Error: $e');
      return (product: ParsedProduct.mock, isMockData: true);
    }
  }

  /// Groq Whisper transcription + Groq LLM JSON extraction, same as parseAudioWithGroq().
  static Future<ParsedProduct?> parseAudioWithGroq(String audioFilePath, {ParsedProduct? existingProduct}) async {
    if (_groqKey.isEmpty) return existingProduct;

    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_groqKey'
        ..fields['model'] = 'whisper-large-v3'
        ..files.add(await http.MultipartFile.fromPath('file', audioFilePath));

      final streamedResponse = await request.send().timeout(_timeout);
      final whisperResponse = await http.Response.fromStream(streamedResponse);
      final whisperData = jsonDecode(whisperResponse.body);

      if (whisperData['error'] != null) {
        _log('Groq Whisper API error: ${whisperData['error']}');
        return existingProduct ?? ParsedProduct.mock;
      }

      final transcript = whisperData['text'] as String?;
      if (transcript == null || transcript.isEmpty) return existingProduct;

      final contextText = existingProduct != null
          ? 'Here is the current product info: ${jsonEncode(existingProduct.toJson())}. '
              'The artisan just said this: "$transcript". Update the product details based on what they said.'
          : 'The artisan just described a product: "$transcript". Extract the product details.';

      final prompt = 'You are an assistant for rural artisans. $contextText Return ONLY a valid JSON object with '
          'these exact keys: name, nameHi (Hindi name of the product), material, quantity, userSuggestedPrice '
          '(number, extract from audio if present, otherwise keep null), descriptionEn, descriptionHi. Do not wrap in markdown.';

      final llmResult = await _callGroqText(prompt);
      if (llmResult != null) return _parseAiResponse(llmResult);
      return null;
    } catch (e) {
      _log('Groq Audio Pipeline Error: $e');
      return existingProduct;
    }
  }

  /// Groq text -> Gemini text -> heuristic fallback, same as estimateFairPrice().
  static Future<int?> estimateFairPrice({required String name, required String material, num? userSuggestedPrice}) async {
    final prompt = _pricePrompt(name, material);
    final fallback = userSuggestedPrice != null ? (userSuggestedPrice * 1.3).round() : 250;

    try {
      final groqResult = await _callGroqText(prompt);
      if (groqResult != null) {
        final price = _extractPrice(groqResult);
        if (price != null) return price;
      }

      _log('Groq pricing unavailable, trying Gemini...');
      final geminiResult = await _callGeminiText(prompt);
      if (geminiResult != null) {
        final price = _extractPrice(geminiResult);
        if (price != null) return price;
      }

      return fallback;
    } catch (e) {
      _log('Pricing Error: $e');
      return fallback;
    }
  }

  /// remove.bg -> HuggingFace RMBG -> raw image fallback, same as processImage().
  /// Returns (bytes, isFallback) — bytes are either the bg-removed image or the original.
  static Future<({List<int> bytes, bool isFallback})> processImage(List<int> imageBytes) async {
    try {
      if (_removeBgKey.isNotEmpty) {
        try {
          final request = http.MultipartRequest('POST', Uri.parse('https://api.remove.bg/v1.0/removebg'))
            ..headers['X-Api-Key'] = _removeBgKey
            ..fields['size'] = 'auto'
            ..files.add(http.MultipartFile.fromBytes('image_file', imageBytes, filename: 'image.jpg'));

          final streamed = await request.send().timeout(_timeout);
          final response = await http.Response.fromStream(streamed);

          if (response.statusCode == 200) {
            return (bytes: response.bodyBytes, isFallback: false);
          } else {
            _log('Remove.bg failed: ${response.body}');
          }
        } catch (e) {
          _log('Remove.bg fetch failed: $e');
        }
      }

      final headers = <String, String>{};
      if (_hfToken.isNotEmpty) headers['Authorization'] = 'Bearer $_hfToken';

      http.Response bgResponse;
      try {
        bgResponse = await http
            .post(
              Uri.parse('https://api-inference.huggingface.co/models/briaai/RMBG-1.4'),
              headers: headers,
              body: imageBytes,
            )
            .timeout(_timeout);
      } catch (e) {
        _log('HF Fetch failed: $e');
        return (bytes: imageBytes, isFallback: true);
      }

      if (bgResponse.statusCode != 200) {
        _log('HF API error: ${bgResponse.statusCode}');
        return (bytes: imageBytes, isFallback: true);
      }

      return (bytes: bgResponse.bodyBytes, isFallback: false);
    } catch (e) {
      _log('Image Processing Error: $e');
      return (bytes: imageBytes, isFallback: true);
    }
  }
}