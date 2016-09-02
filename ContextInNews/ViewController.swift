//
//  ViewController.swift
//  ContextInNews
//
//  Created by Emily Toop on 23/08/2016.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import WebKit
import Fuzi

class ViewController: UIViewController {

    var newsArticles: [Article] = [Article]()

    let newsSources:[String: String] = ["BBC": "http://feeds.bbci.co.uk/news/world/rss.xml",
                                        "The Guardian": "https://www.theguardian.com/world/rss",
                                        "The New York Times": "http://rss.nytimes.com/services/xml/rss/nyt/World.xml",
                                        "Washington Post": "http://feeds.washingtonpost.com/rss/world"]

    let cellIdentifier = "NewsCellIdentifier"

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.registerClass(NewsArticleTableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLineEtched
        tableView.separatorColor = UIColor.blackColor()
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.estimatedRowHeight = 100.0;
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Latest News"
        setupTableViewUI()
        findSimilarNewsStories()
    }

    func setupTableViewUI() {
        var constraints = [NSLayoutConstraint]()
        view.addSubview(tableView)
        constraints.appendContentsOf([tableView.topAnchor.constraintEqualToAnchor(view.topAnchor),
            tableView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            tableView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            tableView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor)
            ])

        NSLayoutConstraint.activateConstraints(constraints)
    }

    func findSimilarNewsStories() {

        let lockQueue = dispatch_queue_create("org.mozilla.LockQueue", nil)
        for (publication, url) in newsSources {
            print("Finding articles from \(publication)")
            newsItemsFromRSSFeed(publication, feedUri: url) { articles in
                if let articles = articles {
                    dispatch_sync(lockQueue) {
                        self.newsArticles.appendContentsOf(articles)
                        self.newsArticles.sortInPlace { (article1, article2) -> Bool in
                            if let date1 = article1.date, let date2 = article2.date {
                                let result = date1.compare(date2)
                                switch result {
                                case .OrderedDescending, .OrderedSame:
                                    return true
                                default: return false
                                }
                            } else {
                                return false
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.tableView.reloadData()
                        }
                    }
                }

                self.fetchCompleted(publication)
            }
        }
    }

    var completedSourceCount = 0

    func fetchCompleted(source: String) {
        print("Completed \(source)")
        completedSourceCount += 1
        print("\(completedSourceCount) == \(newsSources.keys.count)")
        if completedSourceCount == newsSources.keys.count {
            self.scanForRelatedNewsArticles()
        }
    }

    func newsItemsFromRSSFeed(publication: String, feedUri: String, completionHandler: ([Article]?) -> Void) {
        if let sourceURL = NSURL(string: feedUri) {
            let task = NSURLSession.sharedSession().dataTaskWithURL(sourceURL, completionHandler: { (data, response, error) in
                if let data = data,
                    let response = String(data: data, encoding: NSUTF8StringEncoding) {
//                    print("\(response)")
                    do {
                        // if encoding is omitted, it defaults to NSUTF8StringEncoding
                        let doc = try XMLDocument(string: response, encoding: NSUTF8StringEncoding)

                        if let root = doc.root,
                            let channel = root.firstChild(tag: "channel") {
                            let items = channel.children(tag: "item")
//                            print(items)
                            var articles = [Article]()
                            for item in items {
                                let articleTitle: TaggedString?
                                if let title = item.firstChild(tag: "title")?.stringValue {
                                    articleTitle = TaggedString(string: title, wordsOfInterestByFrequency: Set(self.wordsOfInterestIn(title)))
                                } else { articleTitle = nil }

                                let articleDescription: TaggedString?
                                if let description = item.firstChild(tag: "description")?.stringValue {
                                    articleDescription = TaggedString(string: description, wordsOfInterestByFrequency: Set(self.wordsOfInterestIn(description)))
                                } else { articleDescription = nil }

                                let articleDate: NSDate?
                                if let date = item.firstChild(tag: "pubDate")?.stringValue {
                                    let dateFormatter = NSDateFormatter()
                                    dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss zzz"
                                    dateFormatter.timeZone = NSTimeZone(name: "UTC")
                                    if let dateString = dateFormatter.dateFromString(date) {
                                        articleDate = dateString
                                    } else {
                                        print("publication has date format \(date)")
                                        articleDate = nil
                                    }
                                } else { articleDate = nil }

                                let articleURL: NSURL?
                                if let link = item.firstChild(tag: "link")?.stringValue {
                                    articleURL = NSURL(string: link)
                                } else { articleURL = nil }

                                articles.append(Article(publication: publication, date: articleDate, title: articleTitle, description: articleDescription, url: articleURL))
                            }
                            completionHandler(articles)
                        } else {
                            print("Unable to fetch articles for \(publication)")
                        }
                    } catch let error as XMLError {
                        switch error {
                        case .NoError: print("wth this should not appear")
                        case .ParserFailure, .InvalidData: print(error)
                        case .LibXMLError(let code, let message):
                            print("libxml error code: \(code), message: \(message)")
                        }
                    } catch {
                        print("Error")
                    }
                } else {
                    print("error \(error)")
                }
            })
            
            task.resume()
        }
    }

    func scanForRelatedNewsArticles() {
        for article in newsArticles {
            let articleTitleWords = article.title?.wordsOfInterestByFrequency
            let articleDescriptionWords = article.description?.wordsOfInterestByFrequency
            for comparisonArticle in newsArticles {
                if comparisonArticle.url == article.url {
                    continue
                }
                if let comparisonTitleWords = comparisonArticle.description?.wordsOfInterestByFrequency,
                    let articleTitleWords = articleTitleWords {
                    if comparisonTitleWords.intersect(articleTitleWords).count > (articleTitleWords.count / 2) {
                        article.relatedArticles.insert(comparisonArticle)
                        continue
                    }
                }
                if let comparisonDescriptionWords = comparisonArticle.description?.wordsOfInterestByFrequency,
                    let articleDescriptionWords = articleDescriptionWords {
                    if comparisonDescriptionWords.intersect(articleDescriptionWords).count > (articleDescriptionWords.count / 2) {
                        article.relatedArticles.insert(comparisonArticle)
                    }
                }
            }
            if article.relatedArticles.count > 0 {
                print("article \(article.title?.string) has \(article.relatedArticles.count) related articles")
            }
        }

        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func wordsOfInterestIn(string: String) -> [String] {
        let wordsOfInterest = NSCountedSet()

        let options: NSLinguisticTaggerOptions = [.JoinNames, .OmitWhitespace, .OmitPunctuation]
        let schemes = NSLinguisticTagger.availableTagSchemesForLanguage("en")
        let tagger = NSLinguisticTagger(tagSchemes: schemes, options: Int(options.rawValue))
        tagger.string = string
        tagger.enumerateTagsInRange(NSMakeRange(0, string.characters.count), scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { (tag, tokenRange, _, _) in
            let token = (string as NSString).substringWithRange(tokenRange)
            switch tag {
            case NSLinguisticTagNoun, NSLinguisticTagPlaceName, NSLinguisticTagOrganizationName, NSLinguisticTagPersonalName:
                if token.lowercaseString != "caption" && token.lowercaseString != "image" {
                    wordsOfInterest.addObject(token)
                }
                break
            default:
                break
            }
        }

        let wordsOfInterestByFrequency: [String] = wordsOfInterest.objectEnumerator().sort { (itemA, itemB) -> Bool in
            wordsOfInterest.countForObject(itemA) > wordsOfInterest.countForObject(itemB)
            }.map { $0 as! String }

        return wordsOfInterestByFrequency
    }


}

extension ViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor.lightGrayColor()
        } else {
            cell.backgroundColor = UIColor.whiteColor()
        }
        let article = newsArticles[indexPath.row]
        if article.relatedArticles.count > 0 {
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let article = newsArticles[indexPath.row]
        let nextVC = ViewArticleViewController()
        nextVC.article = article
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsArticles.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let article = newsArticles[indexPath.row]
        if article.relatedArticles.count > 0 {
            print("article \(article.title?.string) has \(article.relatedArticles.count) related articles")
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! NewsArticleTableViewCell
        cell.headline.text = article.title?.string
        cell.summary.text = article.description?.string
        cell.publication.text = article.publication
        //
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy HH:mm"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        if let date = article.date {
            let dateString = dateFormatter.stringFromDate(date)
            cell.date.text = dateString
        }
        cell.setRelatedArticleCount(article.relatedArticles.count)
        return cell
    }
}

struct TaggedString {
    let string: String
    let wordsOfInterestByFrequency: Set<String>
}

class Article: Hashable {
    let publication: String
    let date: NSDate?
    let title: TaggedString?
    let description: TaggedString?
    let url: NSURL?
    let body: TaggedString?
    var relatedArticles: Set<Article> = Set<Article>()

    init(publication: String, date: NSDate?, title: TaggedString?, description: TaggedString?, url: NSURL?) {
        self.publication = publication
        self.date = date
        self.title = title
        self.description = description
        self.url = url
        self.body = nil
    }

    var hashValue: Int {
        return self.url?.hashValue ?? 0
    }
}

func ==(lhs: Article, rhs: Article) -> Bool {
    return lhs.url == rhs.url
}

