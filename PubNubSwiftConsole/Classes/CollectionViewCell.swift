//
//  CollectionViewCell.swift
//  Pods
//
//  Created by Jordan Zucker on 7/26/16.
//
//

import UIKit

public class CollectionViewCell: UICollectionViewCell {
    static func reuseIdentifier() -> String {
        return String(self.dynamicType)
    }
    
    func updateCell(item: Item) {
        // override in subclass, this used by the generic collection view subclass
    }
}
