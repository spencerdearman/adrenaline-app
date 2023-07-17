//
//  LiveResultsWebView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/8/23.
//

import SwiftUI
import WebKit

// Wrapper around LRWebView to provide some basic States like would be provided
// in other outer views
struct LiveResultsWebView: View {
    @State var request: String = "https://secure.meetcontrol.com/divemeets/system/index.php"
    @State var html: String = ""
    
    var body: some View {
        VStack {
            LRWebView(request: request, html: $html)
        }
    }
    
    private func startTimer() {
            Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                // Update the request binding to reload the web page
                request = request
            }
        }
}


// Use this struct for the WebView functionality and having bindings to request
// and html available on init
struct LRWebView: UIViewRepresentable {
    var request: String
    @Binding var html: String
    static private var delay: UInt32 = 1_000_000
    var urlRequest: URLRequest {
        guard let url = URL(string: request) else {
            return URLRequest(url: URL(string:"https://google.com")!)
        }
        
        return URLRequest(url: url)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView: WKWebView = {
            let pagePrefs = WKWebpagePreferences()
            pagePrefs.allowsContentJavaScript = true
            let config = WKWebViewConfiguration()
            config.defaultWebpagePreferences = pagePrefs
            let webview = WKWebView(frame: .zero,
                                    configuration: config)
            webview.translatesAutoresizingMaskIntoConstraints = false
            webview.load(urlRequest)
            return webview
        }()
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    // from SwiftUI to UIKit
    func updateUIView(_ uiView: WKWebView, context: Context) {
        //guard let url = URL(string: request) else { return }
        //uiView.load(urlRequest)
    }
    
    // From UIKit to SwiftUI
    func makeCoordinator() -> Coordinator {
        return Coordinator(html: $html)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var html: String
        
        init(html: Binding<String>) {
            self._html = html
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Value is in millionths of a second, so 100_000 = 0.1s
            // 0.1s seems to be a safe enough delay to avoid JS not finishing
            usleep(LRWebView.delay)
            webView.evaluateJavaScript("document.body.innerHTML") {
                [weak self] result, error in
                guard let html = result as? String, error == nil else { return }
                self?.html = html
            }
            print("being called")
        }
    }
}
