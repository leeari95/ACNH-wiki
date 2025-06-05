//
//  AboutItem.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/28.
//

import Foundation

public struct AboutItem {
    public let icon: String
    public let title: String
    public var url: URL?
    public var description: String?

    static var theApp: [AboutItem] {
        [
            AboutItem(
                icon: "chevron.left.slash.chevron.right",
                title: "Source code / report an issue",
                url: URL(string: "https://github.com/leeari95/ACNH-wiki")
            ),
            AboutItem(
                icon: "envelope.fill",
                title: "Contact / Mail",
                url: URL(string: "mailto:lee_ari95@icloud.com")
            ),
            AboutItem(
                icon: "photo.fill",
                title: "Contact / follow us on Instagram",
                url: URL(string: "https://www.instagram.com/nook_portal_plus/")
            ),
            AboutItem(
                icon: "star.fill",
                title: "Rate the app on the App Store",
                url: URL(string: "itms-apps://itunes.apple.com/app/itunes-u/id\(1636229399)?ls=1&mt=8&action=write-review")
            ),
            AboutItem(
                icon: "lock",
                title: "Privacy Policy",
                url: URL(string: "https://github.com/leeari95/ACNH-wiki/blob/develop/privacy-policy.md")
            ),
            AboutItem(
                icon: "dollarsign.circle.fill",
                title: "Donate",
                url: URL(string: "https://qr.kakaopay.com/Ej8LDsxFf")
            )
        ]
    }

    static var acknowledgement: [AboutItem] {
        return [
            AboutItem(
                icon: "heart.fill",
                title: "ACNH API",
                url: URL(string: "https://acnhapi.com/")
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

    static var versions: [AboutItem] {
        return [
            AboutItem(
                icon: "tag",
                title: "App version",
                description: "2.0.1"
            ),
            AboutItem(
                icon: "gamecontroller",
                title: "Game patch data",
                description: "2.0.0"
            )
        ]
    }
}
