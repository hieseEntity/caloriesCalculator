class PromptTemplates {
  static const String systemPrompt = '''
You are a specialized nutritional extraction AI running on-device.
Your task is to analyze the raw OCR text from food labels, receipts, or menus and extract:
1. Food name / description
2. Serving size
3. Calories (kcal, integer)
4. Protein (grams, number)
5. Carbohydrates (grams, number)
6. Total Fat (grams, number)

Output strictly in JSON format matching this schema:
{
  "food_name": "string",
  "serving_size": "string",
  "calories": 0,
  "protein": 0.0,
  "carbs": 0.0,
  "fat": 0.0
}
Do not write markdown quotes or extra words before or after the JSON.
''';

  /// Builds ChatML formatted prompt for Qwen2.5-0.5B-Instruct
  static String buildQwenChatMlPrompt(String rawOcrText) {
    return '''<|im_start|>system
$systemPrompt<|im_end|>
<|im_start|>user
OCR Input Text:
"""
$rawOcrText
"""
<|im_end|>
<|im_start|>assistant
''';
  }

  /// GBNF Grammar for llama.cpp to enforce valid JSON generation at decode time
  static const String llamaCppGbnfGrammar = r'''
root ::= "{" ws "\"food_name\":" ws string "," ws "\"serving_size\":" ws string "," ws "\"calories\":" ws integer "," ws "\"protein\":" ws number "," ws "\"carbs\":" ws number "," ws "\"fat\":" ws number ws "}"
string ::= "\"" ([^"\\] | "\\" (["\\/bfnrt] | "u" [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F]))* "\""
integer ::= ("-"? [0-9]+)
number ::= ("-"? [0-9]+ ("." [0-9]+)?)
ws ::= [ \t\n\r]*
''';
}

