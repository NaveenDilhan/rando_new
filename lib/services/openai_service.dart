import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_keys.dart';

class OpenAIService {
  Future<String> generateTask() async {
    const String apiUrl = "https://api.openai.com/v1/completions";
    const String model = "text-davinci-003";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $openAIApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": model,
        "prompt": "Give me a random daily task",
        "max_tokens": 50,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['choices'][0]['text'].trim();
    } else {
      return "Failed to generate task.";
    }
  }
}
