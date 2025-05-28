import 'package:dialog_flowtter/dialog_flowtter.dart' as dialog_flowtter;

class DialogflowService {
  late final dialog_flowtter.DialogFlowtter _dialogFlowtter;

  // Private constructor
  DialogflowService._(this._dialogFlowtter);

  // Factory constructor for async initialization
  static Future<DialogflowService> create() async {
    try {
      print("Initializing DialogFlow...");

      // Initialize DialogFlow with credentials file path
      final dialogFlowtter = dialog_flowtter.DialogFlowtter(
        jsonPath: 'assets/dialog_flow_auth.json',
      );

      print("DialogFlow Initialized Successfully!");
      return DialogflowService._(dialogFlowtter);
    } catch (e) {
      print("DialogFlow Init Failed: $e"); // Debugging error output
      throw Exception('DialogFlow Initialization Failed: $e');
    }
  }

  // Fetch response from Dialogflow
  Future<String> getResponse(String message) async {
    try {
      final response = await _dialogFlowtter.detectIntent(
        queryInput: dialog_flowtter.QueryInput(
          text: dialog_flowtter.TextInput(text: message, languageCode: 'en-US'),
        ),
      );

      // Extract the response text
      final textResponse = response.text?.trim() ?? "";

      // Handle fallback scenarios
      if (textResponse.isEmpty ||
          textResponse == "I missed what you said." ||
          textResponse == "One more time?") {
        return "I'm sorry, I didn't understand that. Can you rephrase your question?";
      }

      return textResponse;
    } catch (e) {
      print("DialogFlow Error: $e"); // Debugging error output
      return "Safety services are currently unavailable. Please try later.";
    }
  }

  void dispose() => _dialogFlowtter.dispose();
}