import 'package:kavach_hackvortex/services/dialogflow_service.dart';
import 'package:kavach_hackvortex/services/openrouter_service.dart';

class ChatService {
  final DialogflowService _dialogflowService;
  final OpenRouterService _openRouterService;

  ChatService._(this._dialogflowService, this._openRouterService);

  static Future<ChatService> create() async {
    final dialogflowService = await DialogflowService.create();
    final openRouterService = OpenRouterService();
    return ChatService._(dialogflowService, openRouterService);
  }

  Future<String> getResponse(String message) async {
    if (isGeneralQuery(message)) {
      return await _openRouterService.getResponse(message);
    }

    // Ask both Dialogflow and OpenRouter for app-related queries
    String dialogflowResponse = await _dialogflowService.getResponse(message);
    String openRouterResponse = await _openRouterService.getResponse(message);

    // Merge the responses intelligently
    return mergeResponses(dialogflowResponse, openRouterResponse);
  }

  bool isGeneralQuery(String message) {
    List<String> generalKeywords = [
      "CSS",
      "JavaScript",
      "Python",
      "AI",
      "Flutter",
      "programming",
      "coding",
      "technology",
      "website",
      "design",
      "database",
      "backend",
      "frontend",
      "history",
      "science",
      "math",
      "geography",
      "sports",
      "movies",
      "politics",
      "health",
      "finance",
      "biology",
    ];

    return generalKeywords.any(
      (keyword) => message.toLowerCase().contains(keyword.toLowerCase()),
    );
  }

  String mergeResponses(String dialogflowResponse, String openRouterResponse) {
    if (dialogflowResponse.isEmpty) return openRouterResponse;
    if (openRouterResponse.isEmpty) return dialogflowResponse;

    return "$dialogflowResponse\n\n $openRouterResponse";
  }
}