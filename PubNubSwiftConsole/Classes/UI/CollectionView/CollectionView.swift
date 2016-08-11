//
//  CollectionView.swift
//  Pods
//
//  Created by Jordan Zucker on 7/13/16.
//
//

import Foundation

@objc(PNCCollectionView)
class CollectionView: UICollectionView {
    
    required override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        assert((layout is CollectionViewFlowLayout), "How dare you use anything but CollectionViewFlowLayout: \(layout)")
        super.init(frame: frame, collectionViewLayout: layout)
        self.backgroundColor = UIColor.redColor()
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
}
