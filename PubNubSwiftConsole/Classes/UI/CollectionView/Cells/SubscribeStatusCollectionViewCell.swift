//
//  SubscribeStatusCollectionViewCell.swift
//  Pods
//
//  Created by Jordan Zucker on 8/1/16.
//
//

import UIKit
import PubNub

protocol SubscribeStatusItem: Item {
    var category: String {get}
    var operation: String {get}
    var creationDate: NSDate {get}
    var statusCode: Int {get}
    var timeToken: NSNumber? {get}
    var channel: [String]? {get}
    var channelGroup: [String]? {get}
    var client: PubNub {get}
}

extension SubscribeStatusItem {
    var title: String {
        return category
    }
}

struct SubscribeStatus: SubscribeStatusItem {
    let itemType: ItemType
    let category: String
    let operation: String
    let creationDate: NSDate
    let statusCode: Int
    var timeToken: NSNumber?
    var channel: [String]?
    var channelGroup: [String]?
    var client: PubNub
    init(itemType: ItemType, status: PNStatus, client: PubNub) {
        self.itemType = itemType
        self.category = status.stringifiedCategory()
        self.operation = status.stringifiedOperation()
        self.creationDate = NSDate()
        self.statusCode = status.statusCode
        if let subscribeStatus = status as? PNSubscribeStatus {
            self.timeToken = subscribeStatus.data.timetoken
            self.channel = subscribeStatus.subscribedChannels
            self.channelGroup = subscribeStatus.subscribedChannelGroups
        }
        self.client = client
    }
    var reuseIdentifier: String {
        return SubscribeStatusCollectionViewCell.reuseIdentifier
    }
}

class SubscribeStatusCollectionViewCell: CollectionViewCell {
    
    private let categoryLabel: UILabel
    private let operationLabel: UILabel
    private let timeStampLabel: UILabel
    private let statusCodeLabel: UILabel
    private let timeTokenLabel: UILabel
    private let channelLabel: UILabel
    private let channelGroupLabel: UILabel
    
    override class var reuseIdentifier: String {
        return String(self.dynamicType)
    }
    override init(frame: CGRect) {
        categoryLabel = UILabel(frame: CGRect(x: 5, y: 0, width: frame.size.width, height: frame.size.height/4))
        operationLabel = UILabel(frame: CGRect(x: 5, y: 30, width: frame.size.width, height: frame.size.height/4))
        timeStampLabel = UILabel(frame: CGRect(x: 5, y: 60, width: frame.size.width, height: frame.size.height/4))
        statusCodeLabel = UILabel(frame: CGRect(x: 5, y: 90, width: frame.size.width, height: frame.size.height/4))
        timeTokenLabel = UILabel(frame: CGRect(x: 5, y: 120, width: frame.size.width, height: frame.size.height/4))
        channelLabel = UILabel(frame: CGRect(x: 5, y: 150, width: frame.size.width, height: frame.size.height/4))
        channelGroupLabel = UILabel(frame: CGRect(x: 5, y: 180, width: frame.size.width, height: frame.size.height/4))
        super.init(frame: frame)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(operationLabel)
        contentView.addSubview(timeStampLabel)
        contentView.addSubview(statusCodeLabel)
        contentView.addSubview(timeTokenLabel)
        contentView.addSubview(channelLabel)
        contentView.addSubview(channelGroupLabel)
        contentView.layer.borderWidth = 3
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func updateStatus(item: SubscribeStatusItem) {
        categoryLabel.text = "Category: \(item.title)"
        operationLabel.text = "Operation: \(item.operation)"
        timeStampLabel.text = "Creation date: \(item.creationDate.creationTimeStampString())"
        statusCodeLabel.text = "Status code: \(item.statusCode)"
        if let timeToken = item.timeToken {
            timeTokenLabel.hidden = false
            timeTokenLabel.text = "Time token: \(timeToken)"
        } else {
            timeTokenLabel.hidden = true
        }
        if item.client.isSubscribingToChannels, let channelsLabelString = item.client.channelsString() {
            channelLabel.hidden = false
            channelLabel.text = "Channel(s): \(channelsLabelString)"
        } else {
            channelLabel.hidden = true
        }
        if item.client.isSubscribingToChannelGroups, let channelGroupLabelString = item.client.channelGroupsString() {
            channelGroupLabel.hidden = false
            channelGroupLabel.text = "Channel group(s): \(channelGroupLabelString)"
        } else {
            channelGroupLabel.hidden = true
        }
        setNeedsLayout()
    }
    
    override func updateCell(item: Item) {
        guard let subscribeStatusItem = item as? SubscribeStatusItem else {
            fatalError("init(coder:) has not been implemented")
        }
        updateStatus(subscribeStatusItem)
    }
}
