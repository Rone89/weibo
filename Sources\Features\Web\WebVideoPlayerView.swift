import SwiftUI
import WebKit

struct WebVideoPlayerScreen: View {
    let url: URL

    var body: some View {
        WebVideoPlayerView(url: url)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(L10n.playerTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebVideoPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = BiliAPIClient.userAgent
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.backgroundColor = .black
        webView.isOpaque = false
        load(url, in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard uiView.url != url else { return }
        load(url, in: uiView)
    }

    private func load(_ url: URL, in webView: WKWebView) {
        var request = URLRequest(url: url)
        request.setValue(BiliAPIClient.userAgent, forHTTPHeaderField: "User-Agent")
        webView.load(request)
    }
}
