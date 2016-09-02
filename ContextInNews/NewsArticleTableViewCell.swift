//
//  NewsArticleTableViewCell.swift
//  ContextInNews
//
//  Created by Emily Toop on 02/09/2016.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class NewsArticleTableViewCell: UITableViewCell {

    lazy var headline: UILabel = {
        let label =  UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFontOfSize(12)
        label.numberOfLines = 0
        return label
    }()

    lazy var summary: UILabel = {
        let label =  UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFontOfSize(10)
        label.numberOfLines = 3
        return label
    }()

    lazy var publication: UILabel = {
        let label =  UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFontOfSize(10)
        return label
    }()

    lazy var date: UILabel = {
        let label =  UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFontOfSize(10)
        label.textAlignment = .Right
        return label
    }()

    lazy var relatedArticlesLabel: UILabel = {
        let label =  UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFontOfSize(8)
        return label
    }()


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        var constraints = [NSLayoutConstraint]()

        contentView.addSubview(headline)

        constraints.appendContentsOf([headline.topAnchor.constraintEqualToAnchor(contentView.topAnchor, constant: 5),
            headline.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor, constant: 5),
            headline.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor, constant: -5)
        ])

        contentView.addSubview(summary)

        constraints.appendContentsOf([summary.topAnchor.constraintEqualToAnchor(headline.bottomAnchor, constant: 2),
            summary.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor, constant: 5),
            summary.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor, constant: -5)
        ])

        contentView.addSubview(publication)

        constraints.appendContentsOf([publication.topAnchor.constraintEqualToAnchor(summary.bottomAnchor, constant: 2),
            publication.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor, constant: 5)
            ])


        contentView.addSubview(date)

        constraints.appendContentsOf([date.topAnchor.constraintEqualToAnchor(summary.bottomAnchor, constant: 2),
            date.leadingAnchor.constraintEqualToAnchor(publication.trailingAnchor, constant: 2),
            date.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor, constant: -5)
            ])

        contentView.addSubview(relatedArticlesLabel)

        constraints.appendContentsOf([relatedArticlesLabel.topAnchor.constraintEqualToAnchor(publication.bottomAnchor, constant: 2),
            relatedArticlesLabel.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor, constant: 5),
            relatedArticlesLabel.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor, constant: -5),
            relatedArticlesLabel.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor, constant: -5),
            ])

//        contentView.addSubview(relatedArticlesLabel)
//
//        constraints.appendContentsOf([relatedArticlesLabel.topAnchor.constraintEqualToAnchor(publication.bottomAnchor, constant: 2),
//            relatedArticlesLabel.leadingAnchor.constraintEqualToAnchor(contentView.trailingAnchor, constant: 5),
//            relatedArticlesLabel.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor, constant: -5),
//            relatedArticlesLabel.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor, constant: -5)
//            ])

        NSLayoutConstraint.activateConstraints(constraints)

        self.accessoryType = .DetailDisclosureButton
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setRelatedArticleCount(count: Int) {
        if count == 0 {
            relatedArticlesLabel.text = nil
        } else if count == 1 {
            relatedArticlesLabel.text = "This article has \(count) related article "
        }else {
            relatedArticlesLabel.text = "This article has \(count) related articles"
        }
    }

}
