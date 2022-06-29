//
//  AboutItem.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/28.
//

import Foundation

struct AboutItem {
    let icon: String
    let title: String
    let url: URL?
    
    static var theApp: [AboutItem] {
        [
            AboutItem(
                icon: "chevron.left.slash.chevron.right",
                title: "Source code",
                url: nil
            ),
            AboutItem(
                icon: "envelope.fill",
                title: "Contact / Mail",
                url: URL(string: "mailto:lee_ari95@icloud.com")
            ),
            AboutItem(
                icon: "photo.fill",
                title: "Contact / follow us on Instagram",
                url: nil
            ),
            AboutItem(
                icon: "star.fill",
                title: "Rate the app on the App Store",
                url: nil
            ),
            AboutItem(
                icon: "lock",
                title: "Privacy Policy",
                url: nil
            ),
            AboutItem(
                icon: "tag",
                title: "App version",
                url: nil
            ),
            AboutItem(
                icon: "gamecontroller",
                title: "Game patch data",
                url: nil
            )
        ]
    }
    
    static var acknowledgement: [AboutItem] {
        return [
            AboutItem(
                icon: "heart.fill",
                title: "Nookipedia API",
                url: URL(string: "https://api.nookipedia.com/")
            ),
            AboutItem(
                icon: "heart.fill",
                title: "Turnip prophet",
                url: URL(string: "https://github.com/elxris/Turnip-Calculator")
            ),
            AboutItem(
                icon: "heart.fill",
                title: "Animal Crossing / Spreadsheet",
                url: URL(
                    string: "https://docs.google.com/spreadsheets/d/1mo7myqHry5r_TKvakvIhHbcEAEQpSiNoNQoIS8sMpvM/edit#gid=1397507627"
                )
            )
        ]
    }
}
