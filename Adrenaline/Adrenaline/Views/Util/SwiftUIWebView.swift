//
//  SwiftUIWebView.swift
//  Divemeets-Parser
//
//  Created by Logan Sherwin on 3/13/23.
//

import SwiftUI
import WebKit
import SwiftSoup

struct SwiftUIWebView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @State var request: String =
    "https://secure.meetcontrol.com/divemeets/system/memberlist.php"
    @State var parsedHTML: String = ""
    @Binding var parsedLinks: DiverProfileRecords
    @Binding var dmSearchSubmitted: Bool
    @Binding var linksParsed: Bool
    @Binding var timedOut: Bool
    
    var body: some View {
        VStack {
            WebView(request: $request, parsedHTML: $parsedHTML,
                    parsedLinks: $parsedLinks, firstName: $firstName, lastName: $lastName,
                    dmSearchSubmitted: $dmSearchSubmitted, linksParsed: $linksParsed, timedOut: $timedOut)
        }
    }
}

struct WebView: UIViewRepresentable {
    @Binding var request: String
    @Binding var parsedHTML: String
    @Binding var parsedLinks: DiverProfileRecords
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var dmSearchSubmitted: Bool
    @Binding var linksParsed: Bool
    @Binding var timedOut: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView: WKWebView = {
            let pagePrefs = WKWebpagePreferences()
            pagePrefs.allowsContentJavaScript = true
            let config = WKWebViewConfiguration()
            config.defaultWebpagePreferences = pagePrefs
            let webview = WKWebView(frame: .zero,
                                    configuration: config)
            webview.translatesAutoresizingMaskIntoConstraints = false
            return webview
        }()
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    // from SwiftUI to UIKit
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: request) else { return }
        uiView.load(URLRequest(url: url))
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval) {
            if !linksParsed {
                timedOut = true
            }
        }
    }
    
    // From UIKit to SwiftUI
    func makeCoordinator() -> Coordinator {
        return Coordinator(html: $parsedHTML, links: $parsedLinks, firstName: $firstName,
                           lastName: $lastName, dmSearchSubmitted: $dmSearchSubmitted,
                           linksParsed: $linksParsed, timedOut: $timedOut)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let htmlParser: HTMLParser = HTMLParser()
        @Binding var parsedHTML: String
        @Binding var parsedLinks: DiverProfileRecords
        @Binding var firstName: String
        @Binding var lastName: String
        @Binding var dmSearchSubmitted: Bool
        @Binding var linksParsed: Bool
        @Binding var timedOut: Bool
        
        init(html: Binding<String>, links: Binding<DiverProfileRecords>, firstName: Binding<String>,
             lastName: Binding<String>, dmSearchSubmitted: Binding<Bool>,
             linksParsed: Binding<Bool>, timedOut: Binding<Bool>) {
            self._parsedHTML = html
            self._parsedLinks = links
            self._firstName = firstName
            self._lastName = lastName
            self._dmSearchSubmitted = dmSearchSubmitted
            self._linksParsed = linksParsed
            self._timedOut = timedOut
        }
        
        private func getRecords(_ html: String) -> DiverProfileRecords {
            let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
            var result: DiverProfileRecords = [:]
            do {
                let document: Document = try SwiftSoup.parse(html)
                guard let body = document.body() else {
                    return [:]
                }
                let content = try body.getElementById("dm_content")
                let links = try content?.getElementsByClass("showresults").select("a")
                try links?.forEach({ l in
                    // Adds an empty list value to a new key
                    if !result.keys.contains(try l.text()) {
                        result[try l.text()] = []
                    }
                    result[try l.text()]!.append(try leadingLink + l.attr("href"))
                })
            }
            catch {
                print("Parsing records failed")
            }
            return result
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            webView.reload()
//            print("reloading")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let error = error as NSError
//            print(error.code)
//            print("failed")
            switch(error.code) {
                case NSURLErrorCancelled:
//                    print("cancelled")
                    webView.reload()
                default:
                    break
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = "document.getElementById('first').value = '\(firstName)';"
            + "document.getElementById('last').value = '\(lastName)'"
            if !dmSearchSubmitted {
                // Fill boxes with search values
                webView.evaluateJavaScript(js, completionHandler: nil)
                
                // Click Submit
                webView.evaluateJavaScript(
                    "document.getElementsByTagName('input')[2].click()") {
                        _, _ in
                        self.dmSearchSubmitted = true
                    }
            } else if !linksParsed {
                // Gets HTML after submitting request
                webView.evaluateJavaScript("document.body.innerHTML") {
                    [weak self] result, error in
                    guard let html = result as? String, error == nil else { return }
                    self?.parsedHTML = html
                    self?.parsedLinks = (self?.getRecords(html)) ?? [:]
                    self?.linksParsed = true
                }
            }
        }
    }
}
