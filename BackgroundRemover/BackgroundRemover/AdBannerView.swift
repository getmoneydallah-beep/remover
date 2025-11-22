import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

struct AdBannerView: View {
    // Test ad unit ID - replace with your real ad unit ID for production
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"

    var body: some View {
        BannerAdView(adUnitID: adUnitID)
            .frame(width: 320, height: 50)
    }
}
