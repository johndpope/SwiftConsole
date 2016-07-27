//
//  ButtonCollectionViewCell.swift
//  Pods
//
//  Created by Jordan Zucker on 7/26/16.
//
//

import UIKit

typealias TargetSelector = (target: AnyObject?, selector: Selector)

protocol ButtonItem: Item {
    var title: String {get}
    var targetSelector: TargetSelector {get set}
}

extension UIControl {
    func removeAllTargets() {
        self.allTargets().forEach { (target) in
            self.removeTarget(target, action: nil, forControlEvents: .AllEvents)
        }
    }
}

public class ButtonCollectionViewCell: CollectionViewCell {
    private let button: UIButton
    
    override class var reuseIdentifier: String {
        return String(self.dynamicType)
    }
    
    override init(frame: CGRect) {
        self.button = UIButton(type: .System)
        super.init(frame: frame)
        self.button.setTitle("Create Client", forState: .Normal)
        self.button.sizeToFit()
        self.contentView.addSubview(self.button)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        self.button.center = self.contentView.center
        self.button.removeAllTargets()
    }
    
    func updateButton(item: ButtonItem) {
        self.button.setTitle(item.title, forState: .Normal)
        self.button.sizeToFit()
        self.button.addTarget(item.targetSelector.target, action: item.targetSelector.selector, forControlEvents: .TouchUpInside)
        self.setNeedsLayout() // now let's update layout
    }
    
    override func updateCell(item: Item) {
        guard let buttonItem = item as? ButtonItem else {
            fatalError("init(coder:) has not been implemented")
        }
        updateButton(buttonItem)
    }
}
