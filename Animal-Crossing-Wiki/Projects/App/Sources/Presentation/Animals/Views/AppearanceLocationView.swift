//
//  AppearanceLocationView.swift
//  ACNH-wiki
//
//  Created by Ari on 11/27/24.
//

import SwiftUI
import ACNHCore
import ACNHShared

struct AppearanceLocationView: View {
    let item: AppearanceLocation
    
    var body: some View {
        VStack(spacing: 10) {
            infoView(title: "place".localized, description: item.place.localized)
            if let time = item.time?.formatted {
                infoView(title: "time".localized, description: time)
            }
            if let conditions = item.conditions {
                infoView(title: "conditions".localized, description: conditions.localized)
            }
            if let features = item.features?.map({ $0.localized }).joined(separator: "\n") {
                infoView(title: "features".localized, description: features)
            }
        }
        .background(SwiftUI.Color.clear)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    func infoView(title: String, description: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(SwiftUI.Color(uiColor: .acText))
            
            Spacer(minLength: 8)
            
            Text(description)
                .font(.footnote)
                .fontWeight(.regular)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(SwiftUI.Color(uiColor: .acSecondaryText))
            
        }
        .background(SwiftUI.Color.clear)
    }
}
