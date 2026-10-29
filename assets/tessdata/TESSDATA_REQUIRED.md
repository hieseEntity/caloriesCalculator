# Tesseract Trained Data Files Required / Các file dữ liệu Tesseract cần thiết

> **WARNING**: These traineddata files are NOT included in the repository due to their large size (~20MB each).
> You must download them manually before building the app on Linux.

## Required Files

| File | Language | Size |
|------|----------|------|
| `vie.traineddata` | Vietnamese (Tiếng Việt) | ~20MB |
| `eng.traineddata` | English | ~12MB |

## Download Links

- **Official Tesseract repository:**  
  https://github.com/tesseract-ocr/tessdata/tree/main

- **Direct download:**
  - Vietnamese: https://github.com/tesseract-ocr/tessdata/raw/main/vie.traineddata
  - English: https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata

## Instructions

1. Download both `.traineddata` files from the links above
2. Place them in this directory:
   - `assets/tessdata/vie.traineddata`
   - `assets/tessdata/eng.traineddata`
3. On **Android**, these files are NOT needed — Google ML Kit is used instead
4. On **Linux**, these files ARE required for Tesseract OCR to work

> **LƯU Ý (Android)**: Trên Android dùng Google ML Kit, không cần file tessdata.
> **LƯU Ý (Linux)**: Trên Linux dùng Tesseract OCR, cần đặt file traineddata vào thư mục này.

