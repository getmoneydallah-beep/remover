import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct BackgroundRemoverApp: App {

    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestTrackingPermission()
                }
        }
    }

    private func requestTrackingPermission() {
        // Wait a bit before showing the prompt for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("Tracking authorized")
                case .denied:
                    print("Tracking denied")
                case .notDetermined:
                    print("Tracking not determined")
                case .restricted:
                    print("Tracking restricted")
                @unknown default:
                    break
                }
            }
        }
    }
}
