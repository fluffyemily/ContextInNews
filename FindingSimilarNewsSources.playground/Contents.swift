//: Playground - noun: a place where people can play

import UIKit
import Foundation
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

var newsSources:[String] = ["http://feeds.bbci.co.uk/news/world/rss.xml?edition=uk",
"https://www.theguardian.com/world/rss",
"http://rss.nytimes.com/services/xml/rss/nyt/World.xml",
"http://www.aljazeera.com/?feed=rss2"]


let firstNewsSite = newsSources[0]

if let sourceURL = URL(string: firstNewsSite) {
    let task = URLSession.shared.dataTask(with: sourceURL) { (data, response, error) in
        if let data = data,
            let response = String(data: data, encoding: String.Encoding.utf8) {
            print("\(response)")
        } else {
            print("error \(error)")
        }
    }

    task.resume()
}
