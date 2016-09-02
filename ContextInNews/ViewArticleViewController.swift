//
//  ViewArticleViewController.swift
//  ContextInNews
//
//  Created by Emily Toop on 02/09/2016.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import WebKit


class ViewArticleViewController: UIViewController {

    let socialMediaNames = ["Twitter", "Facebook", "Pinterest", "WhatsApp", "LinkedIn", "Instagram"]
    let potentiallyBiasingAdjectives = ["mere", "significant", "intensifying"]

    var article: Article! {
        didSet {
            orderedRelatedArticles = article.relatedArticles.sort{ (article1, article2) -> Bool in
                let result = article1.date!.compare(article2.date!)
                switch result {
                case .OrderedDescending, .OrderedSame:
                    return true
                default: return false
                }
            }
        }
    }

    private var orderedRelatedArticles: [Article]!

    lazy var webView: WKWebView = {
        let wv = WKWebView()
        wv.translatesAutoresizingMaskIntoConstraints = false
        wv.navigationDelegate = self
        for resource in ["Readability", "ReaderParser"] {
            let path = NSBundle.mainBundle().pathForResource(resource, ofType: "js")!
            let source = try! String(contentsOfFile: path)
            let script = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
            wv.configuration.userContentController.addUserScript(script)
        }
        return wv
    }()


    let cellIdentifier = "RelatedNewsCellIdentifier"

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

        // Do any additional setup after loading the view.
        setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */



    func setupUI() {
        // Do any additional setup after loading the view, typically from a nib.
        var constraints = [NSLayoutConstraint]()

        let tableViewHeight: CGFloat = min(CGFloat(orderedRelatedArticles.count), CGFloat(4.0)) * 55.0

        webView.configuration.userContentController.addScriptMessageHandler(self, name: "readerHandler")
        view.addSubview(webView)
        constraints.appendContentsOf([webView.topAnchor.constraintEqualToAnchor(view.topAnchor),
            webView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            webView.bottomAnchor.constraintEqualToAnchor(tableView.topAnchor),
            webView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor)
            ])

        view.addSubview(tableView)
        constraints.appendContentsOf([tableView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            tableView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            tableView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            tableView.heightAnchor.constraintEqualToConstant(tableViewHeight)
            ])

        NSLayoutConstraint.activateConstraints(constraints)

        webView.loadRequest(NSURLRequest(URL: article.url!))

        // when page loads, load reader view in background
        // parse text to get relevant words
        // perform web search to get further information about relevant words
    }

    

}

extension ViewArticleViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor.lightGrayColor()
        } else {
            cell.backgroundColor = UIColor.whiteColor()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let article = orderedRelatedArticles[indexPath.row]
        let nextVC = ViewArticleViewController()
        nextVC.article = article
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}

extension ViewArticleViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderedRelatedArticles.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let article = orderedRelatedArticles[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! NewsArticleTableViewCell
        cell.headline.text = article.title?.string
        cell.publication.text = article.publication
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy HH:mm"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        if let date = article.date {
            let dateString = dateFormatter.stringFromDate(date)
            cell.date.text = dateString
        }
        return cell
    }
}



extension ViewArticleViewController: WKNavigationDelegate {

}

extension ViewArticleViewController: WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
//        guard let URL = message.frameInfo.request.URL,
//            let body = message.body as? [String: AnyObject],
//            var text = body["text"] as? String,
//            //            let doc = body["doc"] as? String,
//            let title = body["title"] as? String else { return }
//        print("Title:- \(title): ")
//
//        guard URL.host?.containsString("google") == false else { return }
//
//        // find index of title and trim text to exlude
//        if let rangeOfTitle = text.rangeOfString(title) {
//            text = text.substringFromIndex(rangeOfTitle.endIndex)
//        }
//
//        let byline = body["byline"] as? String
//        print("Byline:- \(byline): ")
//
//        let options: NSLinguisticTaggerOptions = [.JoinNames, .OmitWhitespace]
//        let schemes = NSLinguisticTagger.availableTagSchemesForLanguage("en")
//        let tagger = NSLinguisticTagger(tagSchemes: schemes, options: Int(options.rawValue))
//        let sentences = splitTextIntoSentences(text).filter { sentence in
//            let mentionedMedia = socialMediaNames.filter { name in
//                sentence.containsString(name)
//            }
//            return mentionedMedia.count == 0
//        }
//        //        var nouns = Set<String>()
//        //        var names = Set<String>()
//        let wordsOfInterest = NSCountedSet()
//        let bagOAdjectives = NSCountedSet()
//
//        var factualSentences = Set<String>()
//        var potentiallyBiasedSentences = Set<String>()
//        for sentence in sentences {
//            //            print("\nSentence:- \(sentence): ")
//            tagger.string = sentence
//            var isQuote = false
//            tagger.enumerateTagsInRange(NSMakeRange(0, (sentence as NSString).length), scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { (tag, tokenRange, _, _) in
//                let token = (sentence as NSString).substringWithRange(tokenRange)
//                switch tag {
//                    //                case NSLinguisticTagNoun:
//                    //                    guard token.characters.count > 1 else {
//                    //                        nouns.insert(token)
//                    //                        return
//                    //                    }
//                    //                    let index = token.startIndex
//                    //                    let firstLetter = String(token.characters[index])
//                    //                    let secondLetter = String(token.characters[index.successor()])
//                    //                    if firstLetter == firstLetter.capitalizedString &&
//                    //                        secondLetter == secondLetter.lowercaseString {
//                    //                        names.insert(token)
//                    //                    } else {
//                    //                        nouns.insert(token)
//                    //                    }
//                    //                    bagONouns.addObject(token)
//                //                    break
//                case NSLinguisticTagNoun, NSLinguisticTagPlaceName, NSLinguisticTagOrganizationName, NSLinguisticTagPersonalName:
//                    if token.lowercaseString != "caption" && token.lowercaseString != "image" {
//                        wordsOfInterest.addObject(token.lowercaseString)
//                    }
//                    break
//                case NSLinguisticTagNumber:
//                    factualSentences.insert(sentence)
//                case NSLinguisticTagOpenQuote:
//                    isQuote = true
//                case NSLinguisticTagCloseQuote:
//                    isQuote = false
//                    factualSentences.insert(sentence)
//                case NSLinguisticTagAdjective:
//                    if !isQuote {
//                        let potentiallyBiasedWords = self.potentiallyBiasingAdjectives.filter {
//                            sentence.containsString($0)
//                        }
//                        if potentiallyBiasedWords.count > 0 {
//                            print("potentiallyBiasedWords \(potentiallyBiasedWords) in sentence \(sentence)")
//                            potentiallyBiasedSentences.insert(sentence)
//                        }
//                    }
//                default:
//                    break
//                }
//                //                print("\(token): \(tag)")
//            }
//        }
//
//        print("Factual Sentences: ")
//        for sentence in factualSentences {
//            print("\(sentence)")
//        }
//
//        //        print("Potentially Biased Sentences: ")
//        //        for sentence in potentiallyBiasedSentences {
//        //            print("\(sentence)")
//        //        }
//        //        print("Nouns: \(nouns)")
//        //        print("Names: \(names)")
//        let wordsOfInterestByFrequency = wordsOfInterest.objectEnumerator().sort { (itemA, itemB) -> Bool in
//            wordsOfInterest.countForObject(itemA) > wordsOfInterest.countForObject(itemB)
//        }
//        print("Nouns by frequency \(wordsOfInterestByFrequency[0...10])")
//
//        //        let adejectivesByFrequency = bagOAdjectives.objectEnumerator().sort { (itemA, itemB) -> Bool in
//        //            bagOAdjectives.countForObject(itemA) > bagOAdjectives.countForObject(itemB)
//        //        }
//        //        print("Adjectives by frequency \(adejectivesByFrequency)")
//        // parse site
    }

    func splitTextIntoSentences(text: String) -> [String] {
        var range = [Range<String.Index>]()
        let tags = text.linguisticTagsInRange(
            text.characters.indices, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass,
            tokenRanges: &range)
        var result = [String]()
        let indexes = tags.enumerate().filter {
            let nextIndex = $0.index + 1
            let nextToken = nextIndex < tags.count ? tags[$0.index + 1] : NSLinguisticTagParagraphBreak
            if $0.1 == NSLinguisticTagSentenceTerminator && nextToken == NSLinguisticTagWhitespace {
                return true
            }
            return $0.1 == NSLinguisticTagParagraphBreak
            }.map {range[$0.0].startIndex}
        var prev = text.startIndex
        for index in indexes {
            let indexRange = prev...index
            result.append(
                text[indexRange].stringByTrimmingCharactersInSet(
                    NSCharacterSet.whitespaceCharacterSet()))
            prev = index.advancedBy(1)
        }
        
        return result
    }
}
