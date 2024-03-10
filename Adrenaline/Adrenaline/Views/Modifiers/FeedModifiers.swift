//
//  FeedModifiers.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//  Credit Meng To
//

import SwiftUI

struct OutlineModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    .linearGradient(
                        colors: [
                            .white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                            .black.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                )
        )
    }
}

struct OutlineVerticalModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    .linearGradient(
                        colors: [.black.opacity(0.2), .white.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom)
                )
                .blendMode(.overlay)
        )
    }
}

struct SlideFadeIn: ViewModifier {
    var show: Bool
    var offset: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : offset)
    }
}

extension View {
    func slideFadeIn(show: Bool, offset: Double = 10) -> some View {
        self.modifier(SlideFadeIn(show: show, offset: offset))
    }
}

struct OutlineOverlay: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    .linearGradient(
                        colors: [
                            .white.opacity(colorScheme == .dark ? 0.6 : 0.3),
                            .black.opacity(colorScheme == .dark ? 0.3 : 0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom)
                )
                .blendMode(.overlay)
        )
    }
}


struct CustomDatePickerView: View {
    @Binding var date: Date
    var icon: String
    var iconColor: Color? = nil
    @State private var showingDatePicker = false

    var body: some View {
        VStack {
            Text(dateString(from: date))
                .foregroundColor(.primary)
                .offset(x: -27)
        }
        .overlay(
            HStack {
                Image(systemName: icon)
                    .frame(width: 36, height: 36)
                    .foregroundColor(iconColor != nil
                                     ? iconColor
                                     : .gray.opacity(0.5))
                    .background(.thinMaterial)
                    .cornerRadius(14)
                    .modifier(OutlineOverlay(cornerRadius: 14))
                    .offset(x: -72)
                    .foregroundStyle(.secondary)
                    .accessibility(hidden: true)
                Spacer()
            }
        )
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .padding(15)
        .padding(.leading, 40)
        .background(.thinMaterial)
        .cornerRadius(20)
        .modifier(OutlineOverlay(cornerRadius: 20))
        .onTapGesture {
            self.showingDatePicker = true
        }
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                Text("Birthday")
                    .font(.largeTitle).bold()
                    .foregroundColor(.primary)
                DatePicker("Select Date", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                Button("Done") {
                    self.showingDatePicker = false
                }
                .padding()
            }
        }
        .animation(.easeInOut, value: showingDatePicker)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long 
        return formatter.string(from: date)
    }
}



struct BackgroundColor: ViewModifier {
    var opacity: Double = 0.6
    @Environment(\.colorScheme) var currentMode
    
    func body(content: Content) -> some View {
        content
            .overlay(
                (currentMode == .light ? Color.white : Color.black)
                    .opacity(currentMode == .dark ? opacity : 0)
                    .blendMode(.overlay)
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func backgroundColor(opacity: Double = 0.6) -> some View {
        self.modifier(BackgroundColor(opacity: opacity))
    }
}

struct BackgroundStyle: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.6
    @AppStorage("isLiteMode") var isLiteMode = true
    
    func body(content: Content) -> some View {
        content
            .backgroundColor(opacity: opacity)
            .cornerRadius(cornerRadius)
            .shadow(color: Color("Shadow").opacity(isLiteMode ? 0 : 0.3), radius: 20, x: 0, y: 10)
            .modifier(OutlineOverlay(cornerRadius: cornerRadius))
    }
}

extension View {
    func backgroundStyle(cornerRadius: CGFloat = 20, opacity: Double = 0.6) -> some View {
        self.modifier(BackgroundStyle(cornerRadius: cornerRadius, opacity: opacity))
    }
}
