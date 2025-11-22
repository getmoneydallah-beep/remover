import SwiftUI
import GoogleMobileAds

class RewardedAdManager: NSObject, ObservableObject, GADFullScreenContentDelegate {
    @Published var isAdLoaded = false
    @Published var isShowingAd = false

    private var rewardedAd: GADRewardedAd?
    private var onRewardEarned: (() -> Void)?

    // Test ad unit ID - replace with your real ad unit ID for production
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    override init() {
        super.init()
        loadAd()
    }

    func loadAd() {
        GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            self?.isAdLoaded = true
        }
    }

    func showAd(from viewController: UIViewController, onReward: @escaping () -> Void) {
        guard let rewardedAd = rewardedAd else {
            print("Ad not ready")
            onReward() // Still give reward if ad fails
            return
        }

        self.onRewardEarned = onReward
        isShowingAd = true

        rewardedAd.present(fromRootViewController: viewController) { [weak self] in
            // User earned reward
            self?.onRewardEarned?()
            self?.onRewardEarned = nil
        }
    }

    // MARK: - GADFullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isShowingAd = false
        isAdLoaded = false
        loadAd() // Preload next ad
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isShowingAd = false
        isAdLoaded = false
        onRewardEarned?() // Give reward if ad fails to show
        onRewardEarned = nil
        loadAd()
    }
}

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
