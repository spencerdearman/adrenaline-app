//
//  AppLaunchSequence.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/25/23.
//
//  Credits: https://betterprogramming.pub/typewriter-effect-in-swiftui-ba81db10b570
//

import SwiftUI
import SwiftUIGIF

//struct AppLaunchSequence: View {
//    @Environment(\.colorScheme) var currentMode
//    @State private var options: Bool = false
//    @State private var imageData: Data? = nil
//    @State private var isGIFPlaying = true
//    @State private var showTitle: Bool = false
//    @State private var firstShowing: Bool = true
//    @State var signupData = SignupData()
//    @State var loginData = LoginData()
//    @Binding var showSplash: Bool
//
//    func startTimer(delay: Double) {
//        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
//            withAnimation {
//                options.toggle()
//            }
//        }
//    }
//
//    func gifTimer(delay: Double) {
//        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
//            isGIFPlaying.toggle()
//        }
//    }
//
//    func titleTimer() {
//        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
//            showTitle.toggle()
//        }
//    }
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                VStack {
//                    if isGIFPlaying && imageData != nil {
//                        GIFImage(data: imageData!) // load from data
//                            .frame(width: 300, height: 400)
//                            .onAppear {
//                                gifTimer(delay: 1.93)
//                                titleTimer()
//                            }
//                    } else if !isGIFPlaying {
//                        currentMode == .light ?
//                        (Image("AnimationEnding")
//                            .frame(width: 300, height: 100)
//                            .scaleEffect(0.294)) :
//                        (Image("AnimationEndingDark")
//                                .frame(width: 300, height: 100)
//                                .scaleEffect(0.294))
//                    } else {
//                        Text("...")
//                            .onAppear {
//                                currentMode == .light ? loadLightData() : loadDarkData()
//                            }
//                    }
//                }
//                .scaleEffect(0.7)
//                if showTitle && firstShowing{
//                    TypeWriterView(finalText: "Welcome to Adrenaline.")
//                        .onAppear {
//                                startTimer(delay: 6.0)
//                        }
//                } else if !firstShowing {
//                    Text("Welcome to Adrenaline.")
//                        .font(.title)
//                        .fontWeight(.semibold)
//                }
//
//                if options {
//                    HStack {
//                        NavigationLink(destination: AdrenalineLoginView(showSplash: $showSplash, showBackButton: true)) {
//                            Text("Login")
//                        }
//                        .buttonStyle(.bordered)
//                        .cornerRadius(40)
//                        .foregroundColor(.primary)
//                        NavigationLink(destination: AccountTypeSelectView(signupData: $signupData,
//                                                                          showSplash: $showSplash)) {
//                            Text("Sign Up")
//                        }
//                        .buttonStyle(.bordered)
//                        .cornerRadius(40)
//                        .foregroundColor(.primary)
//                    }
//                    .onAppear {
//                        loginData.loadStoredCredentials()
//                        firstShowing = false
//                        if let username = loginData.username,
//                           let password = loginData.password {
//                            print("Username: \(username)")
//                            print("Password: \(password)")
//                        }
//                    }
//                }
//            }
//        }
//        .navigationViewStyle(StackNavigationViewStyle())
//    }
//
//    private func loadLightData() {
//        let task = URLSession.shared.dataTask(with: URL(string: "https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExb2ZjbXFsbDR4eTN5N2swYXFvOWMwMGpscXRidG9qY3FxMTR3ZG01cCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/cww4k4q1E7DJ7Gl8Ko/giphy.gif")!) { data, response, error in
//            imageData = data
//        }
//        task.resume()
//    }
//    private func loadDarkData() {
//        let task = URLSession.shared.dataTask(with: URL(string: "https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExY3gxYmxnOGlmeWVjYTN0OWlhOXluNTJnMnc3a2JsZGpqNTk2cm15ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Zgy382b6AtFkIAzL6i/giphy.gif")!) { data, response, error in
//            imageData = data
//        }
//        task.resume()
//    }
//
//}

struct TypeWriterView: View {
    @State var text: String = ""
    var finalText: String = "Welcome to Adrenaline."
    @State var secondTextReady: Bool = false
    
    var body: some View {
        VStack(spacing: 16.0) {
            Text(text)
                .font(.title)
                .fontWeight(.semibold)
                .onAppear{
                    typeWriter()
                }
        }
    }
    
    func typeWriter(at position: Int = 0) {
        if position == 0 {
            text = ""
        }
        if position < finalText.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                text.append(finalText[position])
                typeWriter(at: position + 1)
            }
            secondTextReady.toggle()
        }
    }
}

extension String {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}
