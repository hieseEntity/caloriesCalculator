/// ============================================================
/// Prompt Templates — System Prompt cho LLM Tính Tổng Calo Sản Phẩm
/// ============================================================
library;

class PromptTemplates {
  // ------------------------------------------------------------------
  // System Prompt — Hướng dẫn LLM tính TỔNG LƯỢNG CALO CẢ SẢN PHẨM
  // ------------------------------------------------------------------
  static const String systemPrompt = '''
You are an expert on-device nutrition intelligence AI running locally.
Your primary task is to analyze raw OCR text from food packaging, nutrition fact tables, or menus and CALCULATE THE TOTAL CALORIES OF THE ENTIRE PRODUCT (Tổng lượng calo của cả sản phẩm/gói/hộp/chai).

CRITICAL TOTAL CALORIE CALCULATION RULES:
1. FOCUS EXCLUSIVELY ON CALORIES (Năng lượng / Calo / kcal):
   - Ignore all other macronutrients (protein, carbs, fat). Focus entirely on Calorie calculation.
2. DETECT SERVING SIZE & BASE CALORIES:
   - Identify base calories per serving or per 100g/100ml (e.g., "Calories: 80 kcal / 100g", "120 kcal per serving (30g)", "80 kcal / can").
3. DETECT TOTAL PRODUCT WEIGHT / VOLUME / SERVINGS:
   - Search the OCR text for total net content, net weight, or total volume (e.g., "Net Wt 250g", "Khối lượng tịnh 200g", "Thể tích thực 330ml", "Dung tích 500ml", "Servings per container: 4").
4. CALCULATE TOTAL PRODUCT CALORIES:
   - Case A: If total net weight/volume AND serving size are detected:
     Total Calories = (Base Calories / Serving Size Quantity) * Total Product Quantity.
     Example: 80 kcal per 100g on a 250g bottle = 80 * (250 / 100) = 200 kcal total.
   - Case B: If servings per container S is detected:
     Total Calories = Base Calories * S.
   - Case C: If the calories already represent the whole container (e.g. 1 can / 1 bottle), Total Calories = Base Calories.
   - Case D: If total net weight/volume is NOT found in the text, set "has_total_quantity" to false, and set "total_calories" to the base calories.
5. EXPLANATION:
   - In "calculation_notes", provide a clear formula breakdown explaining how total calories were calculated.

OUTPUT SCHEMA (STRICT JSON ONLY):
{
  "food_name": "string (name of food item or product)",
  "serving_size": "string (e.g. '100g', '1 can (330ml)', '30g')",
  "calories_per_serving": 0,
  "serving_quantity": 0.0,
  "total_product_quantity": 0.0,
  "unit": "string (g, ml, can, serving)",
  "has_total_quantity": true,
  "total_calories": 0,
  "calculation_notes": "string explaining how total calories was calculated"
}
Do not write markdown quotes or extra words before or after the JSON.
''';

  /// Builds ChatML formatted prompt for Qwen2.5-0.5B-Instruct
  static String buildQwenChatMlPrompt(String rawOcrText) {
    return '''<|im_start|>system
$systemPrompt<|im_end|>
<|im_start|>user
Calculate the TOTAL product calories from this packaging text:
"""
$rawOcrText
"""
<|im_end|>
<|im_start|>assistant
''';
  }

  /// GBNF Grammar for llama.cpp to enforce valid JSON generation at decode time
  static const String llamaCppGbnfGrammar = r'''
root ::= "{" ws "\"food_name\":" ws string "," ws "\"serving_size\":" ws string "," ws "\"calories_per_serving\":" ws integer "," ws "\"serving_quantity\":" ws number "," ws "\"total_product_quantity\":" ws (number | "null") "," ws "\"unit\":" ws string "," ws "\"has_total_quantity\":" ws boolean "," ws "\"total_calories\":" ws integer "," ws "\"calculation_notes\":" ws string ws "}"
string ::= "\"" ([^"\\] | "\\" (["\\/bfnrt] | "u" [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F]))* "\""
integer ::= ("-"? [0-9]+)
number ::= ("-"? [0-9]+ ("." [0-9]+)?)
boolean ::= ("true" | "false")
ws ::= [ \t\n\r]*
''';
}
