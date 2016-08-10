//
//  PresenceEventCollectionViewCell.swift
//  Pods
//
//  Created by Keith Martin on 8/10/16.
//
//

import UIKit
import PubNub

protocol PresenceEventItem: Item {
    var type: String {get}
    var occupancy: NSNumber? {get}
    var timeToken: NSNumber? {get}
}

extension PresenceEventItem {
    var title: String {
        return type
    }
}

class PresenceEventCollectionViewCell: CollectionViewCell {

    private let typeLabel: UILabel
    private let occupancyLabel: UILabel
    private let timeTokenLabel: UILabel
    
    override class var reuseIdentifier: String {
        return String(self.dynamicType)
    }
    override init(frame: CGRect) {
        typeLabel = UILabel(frame: CGRect(x: 5, y: 0, width: frame.size.width, height: frame.size.height/4))
        occupancyLabel = UILabel(frame: CGRect(x: 5, y: 30, width: frame.size.width, height: frame.size.height/4))
        timeTokenLabel = UILabel(frame: CGRect(x: 5, y: 60, width: frame.size.width, height: frame.size.height/4))
        super.init(frame: frame)
        contentView.addSubview(typeLabel)
        contentView.addSubview(occupancyLabel)
        contentView.addSubview(timeTokenLabel)
        contentView.layer.borderWidth = 3
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func updatePresence(item: PresenceEventItem) {
        typeLabel.text = "Type: \(item.title)"
        if let channelOccupancy = item.occupancy {
            occupancyLabel.hidden = false
            occupancyLabel.text = "Occupancy: \(channelOccupancy)"
        } else {
            occupancyLabel.hidden = true
        }
        if let eventTimeToken = item.timeToken {
            timeTokenLabel.hidden = false
            timeTokenLabel.text = "Time token: \(eventTimeToken)"
        } else {
            timeTokenLabel.hidden = true
        }
        setNeedsLayout()
    }
    
    override func updateCell(item: Item) {
        guard let presenceEventItem = item as? PresenceEventItem else {
            fatalError("init(coder:) has not been implemented")
        }
        updatePresence(presenceEventItem)
    }
    
    
}
