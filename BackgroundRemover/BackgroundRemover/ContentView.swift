import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingSaveAlert = false
    @State private var saveSuccess = false
    @StateObject private var rewardedAdManager = RewardedAdManager()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("إزالة الخلفية")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("اختر صورة لإزالة خلفيتها تلقائياً")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity)

                    // Image Display Area
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray4),
                                        style: StrokeStyle(lineWidth: 1, dash: [8])
                                    )
                            )

                        if let processedImage {
                            Image(uiImage: processedImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(16)
                        } else if let originalImage {
                            Image(uiImage: originalImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(16)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)

                                Text("لم يتم اختيار صورة")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if isProcessing {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)

                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("جارِ إزالة الخلفية...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: 320)
                    .padding(.horizontal, 20)

                    if let errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 20)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("اختر صورة")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isProcessing)

                        if processedImage != nil {
                            Button {
                                showRewardedAdAndSave()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("حفظ الصورة")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isProcessing || rewardedAdManager.isShowingAd)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemBackground))
            .environment(\.layoutDirection, .rightToLeft)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await loadAndProcessImage(from: newItem)
                }
            }
            .alert("تم الحفظ", isPresented: $showingSaveAlert) {
                Button("حسناً", role: .cancel) {}
            } message: {
                Text(saveSuccess ? "تم حفظ الصورة في مكتبة الصور." : "فشل في حفظ الصورة.")
            }
            .safeAreaInset(edge: .bottom) {
                AdBannerView()
                    .frame(height: 50)
                    .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemBackground))
            }
        }
        .tint(.primary)
    }

    private func loadAndProcessImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        errorMessage = nil
        processedImage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "فشل في تحميل الصورة"
                return
            }

            originalImage = image
            isProcessing = true

            let result = try await BackgroundRemovalService.shared.removeBackground(from: image)
            processedImage = result

        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    private func showRewardedAdAndSave() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            saveImage()
            return
        }

        rewardedAdManager.showAd(from: rootViewController) {
            saveImage()
        }
    }

    private func saveImage() {
        guard let processedImage else { return }

        UIImageWriteToSavedPhotosAlbum(processedImage, nil, nil, nil)
        saveSuccess = true
        showingSaveAlert = true
    }
}

#Preview {
    ContentView()
}
