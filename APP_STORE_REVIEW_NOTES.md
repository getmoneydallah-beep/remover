# App Store Review Notes - Background Remover App

## How to Test the App

### Option 1: Use Demo Mode (Recommended)
1. Launch the app
2. Tap the button **"تجربة مع صورة نموذجية"** (Try with Sample Image)
3. The app will load a sample image and automatically remove the background
4. Tap **"حفظ الصورة"** (Save Image) to watch the rewarded video ad
5. After watching the ad, the image will be saved to the photo library

### Option 2: Use Your Own Photo
1. Launch the app
2. Tap **"اختر صورة"** (Select Image)
3. Choose any photo from the photo library
4. The app will automatically remove the background using remove.bg API
5. Tap **"حفظ الصورة"** (Save Image) to watch the rewarded video ad
6. After watching the ad, the image will be saved

## Features
- **Arabic Interface**: Fully localized in Arabic with RTL layout
- **Background Removal**: Uses remove.bg API for high-quality background removal
- **Monetization**:
  - Banner ads at the bottom of the screen
  - Rewarded video ads before saving images
- **App Tracking Transparency**: Properly implements ATT framework
- **Dark/Light Mode**: Full support for system appearance

## Permissions
1. **Photo Library Access**: Required to select and save images
2. **Tracking Permission**: Optional - for personalized ads via AdMob

## Technical Details
- Built with SwiftUI
- Uses Google Mobile Ads SDK
- remove.bg API for background removal
- Supports iOS 17.0+

## Test Credentials
No login required - the app is fully functional without authentication.

## Notes for Reviewers
- The app requires internet connection for background removal API
- Demo mode works without selecting photos from library
- Ads may show test ads during review process
- All text is in Arabic as this is an Arabic-language app
