//
//  SectionContainerView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 12/24/25.
//

import SwiftUI

// MARK: - Section Container View

struct SectionContainerView<Content: View>: View {
    let title: String
    let iconName: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderRowView(title: title, iconName: iconName)

            content
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(SwiftUI.Color(uiColor: .acSecondaryBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Section Header Row View

struct SectionHeaderRowView: View {
    let title: String
    let iconName: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.subheadline)
                .foregroundStyle(SwiftUI.Color(uiColor: .acHeaderBackground))
                .frame(width: 20, height: 20)

            Text(title.uppercased())
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }
}
