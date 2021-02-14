//
//  Search.swift
//  AnimeOsusume
//
//  Created by Nico Prananta on 12.02.21.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchInput: String

    @Binding var searching: Bool

    var body: some View {
        ZStack {
            // Background Color
            Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
            // Custom Search Bar (Search Bar + 'Cancel' Button)
            HStack {
                // Search Bar
                HStack {
                    // Magnifying Glass Icon
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)))

                    // Search Area TextField
                    TextField("", text: $searchInput)
                        .onChange(of: searchInput, perform: { searchText in
                            searching = true
                        })
                        .foregroundColor(.black)
                }
                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                .background(Color(#colorLiteral(red: 0.9443587661, green: 0.9445168376, blue: 0.9443380237, alpha: 1)).cornerRadius(8.0))

                // 'Cancel' Button
                Button(action: {
                    searching = false
                    searchInput = ""

                    // Hide Keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }, label: {
                    Text("Cancel")
                })
                    .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 8))
            }
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
        }
        .frame(height: 50)
    }
}
struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(searchInput: .constant(""), searching: .constant(false))
    }
}
