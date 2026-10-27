class PromptTemplates {
  static const String systemPrompt = '''
You are an expert on-device nutrition intelligence AI running locally.
Your task is to analyze raw OCR text from food packaging, nutrition fact tables, restaurant menus, or receipts and CALCULATE the TOTAL nutritional values.

CRITICAL CALCULATION & SUMMATION RULES:
1. DETECT MULTIPLE ITEMS & PORTIONS:
   - Identify all distinct food items, components, or serving counts in the OCR text.
   - If multiple food items or servings are present (e.g., Combo meal, multiple lines on a receipt, or servings per container > 1), you MUST CALCULATE THE SUM across all items to produce total cumulative calories and macros.
2. CALCULATE TOTAL NUTRIENTS:
   - Total Calories (kcal, integer): Sum of calories from all detected items or portions.
   - Total Protein (grams, number): Sum of protein from all items.
   - Total Carbohydrates (grams, number): Sum of carbs from all items.
   - Total Fat (grams, number): Sum of fat from all items.
3. ATWATER CALORIE CROSS-CHECK:
   - If calories are missing or incomplete, calculate total calories using the standard Atwater formula:
     Total Calories = (Total Protein * 4) + (Total Carbs * 4) + (Total Fat * 9).
4. EXPLANATION OF CALCULATION:
   - Provide a clear, brief summary in "calculation_notes" showing how the totals were calculated (e.g., "Summed 2 items: Chicken Bowl (450 kcal) + Yogurt (150 kcal) = 600 kcal total").

OUTPUT SCHEMA (STRICT JSON ONLY):
{
  "food_name": "string (name of food item or summary of meal combo)",
  "serving_size": "string (e.g. '1 bar', '2 items combined', '1 bowl')",
  "calories": 0,
  "protein": 0.0,
  "carbs": 0.0,
  "fat": 0.0,
  "calculation_notes": "string"
}
Do not write markdown quotes or extra words before or after the JSON.
''';

  /// Builds ChatML formatted prompt for Qwen2.5-0.5B-Instruct
  static String buildQwenChatMlPrompt(String rawOcrText) {
    return '''<|im_start|>system
$systemPrompt<|im_end|>
<|im_start|>user
Calculate the total nutrients from this OCR text:
"""
$rawOcrText
"""
<|im_end|>
<|im_start|>assistant
''';
  }

  /// GBNF Grammar for llama.cpp to enforce valid JSON generation at decode time
  static const String llamaCppGbnfGrammar = r'''
root ::= "{" ws "\"food_name\":" ws string "," ws "\"serving_size\":" ws string "," ws "\"calories\":" ws integer "," ws "\"protein\":" ws number "," ws "\"carbs\":" ws number "," ws "\"fat\":" ws number "," ws "\"calculation_notes\":" ws string ws "}"
string ::= "\"" ([^"\\] | "\\" (["\\/bfnrt] | "u" [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F]))* "\""
integer ::= ("-"? [0-9]+)
number ::= ("-"? [0-9]+ ("." [0-9]+)?)
ws ::= [ \t\n\r]*
''';
}
