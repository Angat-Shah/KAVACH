import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiUrl = "https://openrouter.ai/api/v1/chat/completions";
  final String apiKey =
      "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";

  Future<String> getResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "mistralai/devstral-small:free",
          "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": message},
          ],
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        return responseData['choices'][0]['message']['content'] ??
            "I'm not sure how to answer that.";
      } else {
        return "Error retrieving response from AI.";
      }
    } catch (e) {
      return "AI services unavailable. Please try later.";
    }
  }
}