import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_keys.dart';

class OpenAIService {
  Future<String> generateTask(String category) async {
    const String apiUrl = "https://api.openai.com/v1/chat/completions";
    const String model = "gpt-3.5-turbo";  // Use GPT-3.5 Turbo model

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $openAIApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": model,
          "messages": [
            {"role": "system", "content": "You are an assistant that generates interesting daily tasks."},
            {"role": "user", "content": "Give me a random daily task related to $category."}  // Dynamic category input
          ],
          "max_tokens": 100,  // Limit the response length
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = "Error ${response.statusCode}: ${response.reasonPhrase}";

        if (errorData.containsKey('error')) {
          final errorCode = errorData['error']['code'] ?? "Unknown Code";
          final errorMessageText = errorData['error']['message'] ?? "No message provided";

          // Check if the error is related to insufficient credit
          if (errorCode == "insufficient_quota") {
            return "Error: Insufficient OpenAI quota. Please check your billing and available credits.";
          } else {
            return "OpenAI API Error [$errorCode]: $errorMessageText";
          }
        }
        return errorMessage;
      }
    } catch (e) {
      return "Failed to connect to OpenAI API: $e";
    }
  }
}
