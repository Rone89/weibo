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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task(id: normalizedURLString) {
            await loader.load(from: normalizedURLString)
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

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.httpMaximumConnectionsPerHost = 10
        configuration.urlCache = URLCache(
            memoryCapacity: 96 * 1024 * 1024,
            diskCapacity: 512 * 1024 * 1024,
            diskPath: "poster-image-cache"
        )
        return URLSession(configuration: configuration)
    }()

    func load(from urlString: String?) async {
        guard let urlString,
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            phase = .empty
            return
        }

        phase = .loading

        var request = URLRequest(url: url)
        request.setValue(BiliAPIClient.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("\(BiliBaseURL.web)/", forHTTPHeaderField: "Referer")
        request.setValue("image/avif,image/webp,image/apng,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await Self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode,
                  let image = UIImage(data: data) else {
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
}
