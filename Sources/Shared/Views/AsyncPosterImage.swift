import ImageIO
import SwiftUI
import UIKit

struct AsyncPosterImage: View {
    let urlString: String?
    var width: CGFloat? = 120
    var height: CGFloat = 72

    @StateObject private var loader = PosterImageLoader()

    private var normalizedURLString: String? {
        guard let urlString, !urlString.isEmpty else { return nil }
        return urlString.normalizedBiliURLString
    }

    var body: some View {
        ZStack {
            switch loader.phase {
            case .success(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            case .loading:
                placeholder(opacity: 0.92, showsProgress: true)
            case .failure, .empty:
                placeholder(opacity: 1, showsProgress: false)
            }
        }
        .frame(maxWidth: width ?? .infinity, minHeight: height, maxHeight: height)
        .background(Color(.secondarySystemBackground))
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task(id: normalizedURLString) {
            let targetWidth = width ?? max(height * 2, 240)
            await loader.load(
                from: normalizedURLString,
                targetSize: CGSize(width: targetWidth, height: height),
                scale: UIScreen.main.scale
            )
        }
    }

    private func placeholder(opacity: Double, showsProgress: Bool) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.96, green: 0.49, blue: 0.55), Color(red: 0.99, green: 0.78, blue: 0.39)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(opacity)

            if showsProgress {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}

@MainActor
private final class PosterImageLoader: ObservableObject {
    enum Phase {
        case empty
        case loading
        case success(UIImage)
        case failure
    }

    @Published private(set) var phase: Phase = .empty
    private var lastLoadedURLString: String?

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.waitsForConnectivity = false
        configuration.httpMaximumConnectionsPerHost = 10
        configuration.urlCache = URLCache(
            memoryCapacity: 96 * 1024 * 1024,
            diskCapacity: 512 * 1024 * 1024,
            diskPath: "poster-image-cache"
        )
        return URLSession(configuration: configuration)
    }()

    func load(from urlString: String?, targetSize: CGSize?, scale: CGFloat) async {
        guard let urlString,
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            lastLoadedURLString = nil
            phase = .empty
            return
        }

        if lastLoadedURLString == urlString, case .success = phase {
            return
        }

        lastLoadedURLString = urlString
        phase = .loading

        var request = URLRequest(url: url)
        request.setValue(BiliAPIClient.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("\(BiliBaseURL.web)/", forHTTPHeaderField: "Referer")
        request.setValue("image/avif,image/webp,image/apng,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await Self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                phase = .failure
                return
            }

            let image = try await Task.detached(priority: .utility) {
                Self.decodeImage(from: data, targetSize: targetSize, scale: scale)
            }.value

            guard lastLoadedURLString == urlString else { return }
            guard let image else {
                phase = .failure
                return
            }
            phase = .success(image)
        } catch is CancellationError {
            return
        } catch {
            phase = .failure
        }
    }

    private static func decodeImage(from data: Data, targetSize: CGSize?, scale: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return UIImage(data: data)
        }

        let maxDimension = max(targetSize?.width ?? 0, targetSize?.height ?? 0) * max(scale, 1)
        if maxDimension > 0 {
            let thumbnailOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceShouldCache: true,
                kCGImageSourceThumbnailMaxPixelSize: max(120, Int(maxDimension.rounded()))
            ]

            if let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) {
                return UIImage(cgImage: thumbnail)
            }
        }

        return UIImage(data: data)
    }
}
