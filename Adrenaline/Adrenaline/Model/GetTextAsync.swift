//
//  GetTextAsync.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/4/23.
//

import Foundation

class GetTextAsyncLoader {
    func handleResponse(data: Data?, response: URLResponse?) -> String? {
        guard let data = data,
              let text = String(data: data, encoding: .utf8),
              let response = response as? HTTPURLResponse,
              response.statusCode >= 200 && response.statusCode < 300 else {
            return nil
        }
        return text
    }
    
    func getText(url: URL) async throws -> String? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            return handleResponse(data: data, response: response)
        } catch {
            throw error
        }
    }
}

class GetTextAsyncModel: ObservableObject {
    @Published var text: String? = nil
    let loader = GetTextAsyncLoader()
    
    func fetchText(url: URL) async {
        let text = try? await loader.getText(url: url)
        await MainActor.run {
            self.text = text
        }
    }
}
