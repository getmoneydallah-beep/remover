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

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .background(
                            Image(systemName: "checkerboard.rectangle")
                                .resizable()
                                .foregroundStyle(.gray.opacity(0.3))
                        )
                        .cornerRadius(12)
                        .padding()
                } else if let originalImage {
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(12)
                        .padding()
                } else {
                    ContentUnavailableView(
                        "No Image Selected",
                        systemImage: "photo.badge.plus",
                        description: Text("Select an image to remove its background")
                    )
                    .frame(maxHeight: 400)
                }

                if isProcessing {
                    ProgressView("Removing background...")
                        .padding()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding()
                }

                Spacer()

                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Select Image", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isProcessing)

                    if processedImage != nil {
                        Button {
                            saveImage()
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                    }
                }
                .padding(.horizontal)

                // AdMob Banner
                AdBannerView()
                    .padding(.bottom, 8)
            }
            .navigationTitle("Background Remover")
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await loadAndProcessImage(from: newItem)
                }
            }
            .alert("Image Saved", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveSuccess ? "The image has been saved to your photo library." : "Failed to save image.")
            }
        }
    }

    private func loadAndProcessImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        errorMessage = nil
        processedImage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Failed to load image"
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
