//
//  ExpandedDiversView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 1/7/24.
//

import SwiftUI

struct ExpandedDiversView: View {
    @State private var draggedItem: NewUser? = nil
    @Binding var divers: [NewUser]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 5) {
                    ForEach(Array(divers.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            AdrenalineProfileView(newUser: $divers[index].wrappedValue)
                        } label: {
                            ItemView(index: index, item: $divers[index])
                                .onDrag {
                                    self.draggedItem = item
                                    return NSItemProvider()
                                }
                                .onDrop(
                                    of: [.text],
                                    delegate: DropViewDelegate(
                                        destinationItem: item,
                                        items: $divers,
                                        draggedItem: $draggedItem
                                    )
                                )
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.top)
        }
    }
}

// https://ondrej-kvasnovsky.medium.com/how-to-implement-custom-list-with-drag-and-drop-animated-reordering-6ce1f9fd107d
struct ItemView: View {
    @State var index: Int
    @Binding var item: NewUser
    @State var name: String = ""
    
    var body: some View {
        HStack {
            TextField("", text: $name)
                .disabled(true)
            Spacer()
        }
        .foregroundColor(.primary)
        .padding(20)
        .background(.white)
        .modifier(OutlineOverlay(cornerRadius: 30))
        .backgroundStyle(cornerRadius: 30)
        .padding(10)
        .shadow(radius: 5)
        .onAppear {
            name = item.firstName + " " + item.lastName
        }
    }
}

struct DropViewDelegate: DropDelegate {
    
    let destinationItem: NewUser
    @Binding var items: [NewUser]
    @Binding var draggedItem: NewUser?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        if let draggedItem {
            let fromIndex = items.firstIndex(of: draggedItem)
            if let fromIndex {
                let toIndex = items.firstIndex(of: destinationItem)
                if let toIndex, fromIndex != toIndex {
                    withAnimation {
                        self.items.move(fromOffsets: IndexSet(integer: fromIndex), 
                                        toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
                    }
                }
            }
        }
    }
}
