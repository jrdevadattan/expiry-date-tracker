# Expiry Tracker - Latest Updates 🎉

## New Features Implemented

### 1. Advanced Scanner with Product Recognition 📸

#### Two Scan Modes:
- **Barcode Mode** (default):
  - Scans traditional barcodes
  - Fetches product info from OpenFoodFacts API
  - Compact scan area for precise barcode detection
  
- **Product Scan Mode** (toggle icon in top-right):
  - Captures entire product packaging
  - Uses **ML Kit OCR** to detect expiry dates automatically
  - Recognizes product names from packaging text
  - **Adaptive scan box** - larger area (85% width, 60% height) for product capture
  - Searches for product images online using DuckDuckGo API

#### Smart Expiry Date Detection:
The scanner intelligently finds expiry dates using multiple patterns:
- "EXP: DD/MM/YYYY"
- "Best Before: MM/YYYY"
- "Use By: DD-MM-YYYY"
- Standalone date patterns

#### How to Use:
1. Tap the scanner FAB (center bottom)
2. For barcodes: Keep in barcode mode, align barcode in frame
3. For products: Tap the toggle icon (top-right) to switch to product mode
4. Capture the product with the blue "Capture & Analyze" button
5. Make sure expiry date is visible in the capture
6. App will auto-detect product name, expiry date, and fetch product image

### 2. Redesigned Settings Navigation ⚙️

#### Before:
- Profile avatar in top-right of home screen
- No direct access to settings

#### Now:
- **Settings icon** (⚙️) in top-right of home screen
- Quick access to all settings with one tap
- Removed profile avatar clutter from home screen
- Settings screen includes:
  - **Profile Section**: Name, country, profile image upload
  - **Preferences**: Theme toggle (Dark/Light mode)
  - **Data Management**: Export & Import
  - **About**: App version info

### 3. Product Image Search 🖼️

When scanning a product in Product Mode:
- Automatically searches for product images online
- Uses DuckDuckGo Instant Answer API (free, no API key needed)
- Falls back to placeholder if image not found
- Pre-fills the Add Item screen with:
  - Product name (from OCR)
  - Captured image (from camera)
  - Product image URL (from web search)
  - Expiry date (from OCR)

### 4. Export & Import Improvements 📦

#### Export:
- Exports all items to JSON format
- Saved to app documents folder
- Filename includes timestamp: `expiry_tracker_backup_YYYYMMDD_HHMMSS.json`
- Toast shows exact file location

#### Import:
- Place `import.json` in app documents folder
- Tap "Import Data" in settings
- Batch import with error handling
- Shows count of successfully imported items
- Skips invalid/duplicate items automatically

### 5. Enhanced AI Chatbot Context 🤖

The chatbot now provides even better insights:
- **Expiring Soon**: Checks next 7 days with exact day counts
- **Recipe Ideas**: Suggests recipes based on food items
- **Storage Tips**: Category-specific storage advice
- **Statistics**: Detailed breakdown by item type
- **Conversational**: Understands natural questions

## Technical Improvements

### Scanner Enhancements:
- **Adaptive scan box sizing**:
  - Barcode mode: 75% width × 40% height
  - Product mode: 85% width × 60% height
- **ML Kit Text Recognition** for OCR
- **Multiple regex patterns** for date detection
- **Product name extraction** from largest text blocks
- **Online image search** integration

### Settings Architecture:
- Centralized settings access
- Cleaner home screen UI
- Better visual hierarchy
- Settings organized into logical sections

### Performance:
- Efficient image processing
- Async product image search
- Error handling for network failures
- Graceful fallbacks

## Usage Tips

### For Best Scanning Results:
1. **Good lighting**: Ensure product is well-lit
2. **Clear view**: Make expiry date clearly visible
3. **Steady hold**: Keep phone steady when capturing
4. **Text orientation**: Try to align text horizontally
5. **High contrast**: Works best with dark text on light background

### Scanner Mode Selection:
- **Use Barcode Mode** when:
  - Product has a barcode
  - You want quick scanning
  - Product info is in OpenFoodFacts database
  
- **Use Product Mode** when:
  - No barcode available
  - Need to capture expiry date from packaging
  - Want to use custom product images
  - Product not in database

### Data Management:
- **Export regularly** to backup your data
- **Export before updates** to prevent data loss
- **Import** to restore data or transfer between devices
- JSON format makes data portable and readable

## Known Limitations

1. **OCR Accuracy**: 
   - Depends on text clarity and lighting
   - May need manual correction for unclear dates
   - Best with printed text, not handwritten

2. **Product Image Search**:
   - May not find images for very specific/local products
   - Falls back to placeholder if not found
   - Internet connection required

3. **Image Picker**:
   - Currently shows "already active" warning if used multiple times quickly
   - Wait a moment between uses

## Future Enhancements

- [ ] Improve OCR accuracy with better preprocessing
- [ ] Add barcode generation for manual items
- [ ] Cloud sync for cross-device backup
- [ ] Offline product database
- [ ] Custom date format preferences
- [ ] Bulk scan mode (multiple items at once)
- [ ] Product brand recognition
- [ ] Nutrition info extraction

## Bug Fixes

✅ Fixed: Filter/sort button now works with 3 sort options  
✅ Fixed: Settings navigation (icon instead of avatar)  
✅ Fixed: Export/import now visible in settings  
✅ Fixed: Scan box adapts to scan mode  
✅ Improved: Scanner recognizes products, not just barcodes  

---

**Version**: 1.0.0+1  
**Last Updated**: October 28, 2025
