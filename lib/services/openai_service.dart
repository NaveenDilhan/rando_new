import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_keys.dart';

class OpenAIService {
  Future<Map<String, dynamic>> generateTasks(String category) async {
    const String apiUrl = "https://api.openai.com/v1/chat/completions";
      const String model = "gpt-3.5-turbo";

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
            {"role": "system", "content": "You generate 4 daily tasks and 1 fun fact for a given category."},
            {"role": "user", "content": 
              "Provide four unique daily tasks and one fun fact related to $category in JSON format like this: "
              "{ 'tasks': ['Task 1', 'Task 2', 'Task 3', 'Task 4'], 'fact': 'A fun fact here' }."
            }
          ],
          "max_tokens": 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        return jsonDecode(content);  // Extracts JSON formatted response
      } else {
        return {"error": "OpenAI API Error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": "Failed to connect to OpenAI API: $e"};
    }
  }
}
