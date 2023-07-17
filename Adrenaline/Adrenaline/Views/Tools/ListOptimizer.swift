//
//  ListOptimizer.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/31/23.
//

import SwiftUI
import Foundation

enum ListViewType: String, CaseIterable {
    case six = "6 Dives"
    case eleven = "11 Dives"
}

struct ListOptimizer: View {
    @Environment(\.colorScheme) var currentMode
    @StateObject private var parser = DiveStatisticsParser()
    @State private var selection: ListViewType = .six
    @State var data: [String: (String, Double)] = [:]
    
    private let cornerRadius: CGFloat = 30
    private let textColor: Color = Color.primary
    private let grayValue: CGFloat = 0.90
    private let grayValueDark: CGFloat = 0.10
    @ScaledMetric private var typeBubbleWidth: CGFloat = 110
    @ScaledMetric private var typeBubbleHeight: CGFloat = 35
    @ScaledMetric private var typeBGWidth: CGFloat = 40
    
    private var typeBGColor: Color {
        currentMode == .light ? Color(red: grayValue, green: grayValue, blue: grayValue)
        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
    }
    private var typeBubbleColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    
    @ViewBuilder
    var body: some View {
        ZStack{}
            .onAppear {
                Task {
                    await parser.parse(urlString: "https://secure.meetcontrol.com/divemeets/system/profile.php?number=60480")
                    data = parser.diveDict
                    //print(data)
                }
            }
        ZStack {
            (currentMode == .light ? Color.white : Color.black)
                .ignoresSafeArea()
            
            VStack {
                VStack {
                    Text("List Optimizer")
                        .font(.title)
                        .bold()
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: typeBubbleWidth * 2 + 5,
                                   height: typeBGWidth)
                            .foregroundColor(typeBGColor)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: typeBubbleWidth,
                                   height: typeBubbleHeight)
                            .foregroundColor(typeBubbleColor)
                            .offset(x: selection == .six
                                    ? -typeBubbleWidth / 2
                                    : typeBubbleWidth / 2)
                            .animation(.spring(response: 0.2), value: selection)
                        HStack(spacing: 0) {
                            Button(action: {
                                if selection == .eleven {
                                    selection = .six
                                }
                            }, label: {
                                Text(ListViewType.six.rawValue)
                                    .animation(nil, value: selection)
                            })
                            .frame(width: typeBubbleWidth,
                                   height: typeBubbleHeight)
                            .foregroundColor(textColor)
                            .cornerRadius(cornerRadius)
                            Button(action: {
                                if selection == .six {
                                    selection = .eleven
                                }
                            }, label: {
                                Text(ListViewType.eleven.rawValue)
                                    .animation(nil, value: selection)
                            })
                            .frame(width: typeBubbleWidth + 2,
                                   height: typeBubbleHeight)
                            .foregroundColor(textColor)
                            .cornerRadius(cornerRadius)
                        }
                    }
                }
                Spacer()
                if selection == .six {
                    sixDiveView(data: $data)
                } else {
                    elevenDiveView(data: $data)
                }
                Spacer()
            }
        }
        .onSwipeGesture(trigger: .onEnded) { direction in
            if direction == .left && selection == .six {
                selection = .eleven
            } else if direction == .right && selection == .eleven {
                selection = .six
            }
            
        }
    }
}


struct sixDiveView: View {
    @State var tableData: [String: DiveData]?
    @Binding var data: [String: (String, Double)]
    
    var body: some View {
        VStack {
            Text(getDiveName(data: tableData ?? [:], forKey: "109C") ?? "No information found")
                .padding()
            let v = findTopSixDives(data: data)
        }
        .onAppear {
            tableData = getDiveTableData()
        }
    }
}

struct elevenDiveView: View {
    @State var tableData: [String: DiveData]?
    @Binding var data: [String: (String, Double)]
    
    var body: some View {
        VStack {
            Text(getDiveName(data: tableData ?? [:], forKey: "109C") ?? "No information found")
                .padding()
        }
        .onAppear {
            tableData = getDiveTableData()
        }
    }
}

func findTopSixDives(data: [String: (String, Double)]) -> [(String, Double)] {
    for (key, value) in data {
        print(key)
        print(value)
    }
    return [("S", 0.0)]
}
