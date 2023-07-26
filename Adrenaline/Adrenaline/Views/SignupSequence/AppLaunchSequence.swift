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

struct AppLaunchSequence: View {
    @Namespace var n
    @State var options: Bool = false
    @State var signupData = SignupData()
    @State var loginData = LoginData()
    
    func startTimer(delay: Double) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
            options.toggle()
            
        }
    }
    
    @State private var imageData: Data? = nil
       
    @State private var isGIFPlaying = true // Add a state variable to control GIF animation

       var body: some View {
           VStack {
               if isGIFPlaying && imageData != nil { // Only play the GIF when 'isGIFPlaying' is true and image data is available
                   GIFImage(data: imageData!) // load from data
                       .frame(width: 300)
                       //.onAppear(perform: { isGIFPlaying = false }) // Pause the GIF after it has been played once
               } else if !isGIFPlaying {
                   Image("AnimationEnding")
                       .frame(width: 300)
               } else {
                   Text("Loading...")
                       .onAppear(perform: loadData)
               }
           }
       }
       
       private func loadData() {
           let task = URLSession.shared.dataTask(with: URL(string: "https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExb2ZjbXFsbDR4eTN5N2swYXFvOWMwMGpscXRidG9qY3FxMTR3ZG01cCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/cww4k4q1E7DJ7Gl8Ko/giphy.gif")!) { data, response, error in
               imageData = data
           }
           task.resume()
       }
//    var body: some View {
//        NavigationView {
//            VStack {
//                Image("Logo")
//                    .scaleEffect(0.23)
//                    .frame(width: 50, height: 50)
//                    .padding(.bottom, 60)
//                TypeWriterView(finalText: "Welcome to Adrenaline.")
//                    .onAppear {
//                        withAnimation(.easeOut(duration: 1)) {
//                            startTimer(delay: 6.0)
//                        }
//                    }
//
//                if options {
//                    HStack {
//                        NavigationLink(destination: ProfileView(profileLink: "")) {
//                            Text("Login")
//                        }
//                        .buttonStyle(.bordered)
//                        .cornerRadius(40)
//                        .foregroundColor(.primary)
//                        .matchedGeometryEffect(id: "login", in: n)
//                        NavigationLink(destination: AccountTypeSelectView(signupData: $signupData)) {
//                            Text("Sign Up")
//                        }
//                        .buttonStyle(.bordered)
//                        .cornerRadius(40)
//                        .foregroundColor(.primary)
//                        .matchedGeometryEffect(id: "signup", in: n)
//                    }
//                    .onAppear {
//                        loginData.loadStoredCredentials()
//
//                        if let username = loginData.username,
//                           let password = loginData.password {
//                            print("Username: \(username)")
//                            print("Password: \(password)")
//                        }
//                    }
//                }
//            }
//        }
//    }
}

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
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
