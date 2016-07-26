//
//  ClientCreationViewController.swift
//  Pods
//
//  Created by Jordan Zucker on 7/18/16.
//
//

import Foundation
import PubNub

public class ClientCreationViewController: CollectionViewController {
    
    // MARK: - View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let section = BasicSection(items: [LabelItem(titleString: "Pub Key", contentsString: "demo-36"), LabelItem(titleString: "Sub Key", contentsString: "demo-36"), LabelItem(titleString: "Origin", contentsString: "pubsub.pubnub.com")])
        self.dataSource = BasicDataSource(sections: [section])
        guard let collectionView = self.collectionView else { fatalError("We expected to have a collection view by now. Please contact support@pubnub.com") }
        collectionView.registerClass(LabelCollectionViewCell.self, forCellWithReuseIdentifier: LabelCollectionViewCell.reuseIdentifier())
        collectionView.reloadData() // probably a good idea to reload data after all we just did
    }
    
    // MARK: - Actions
    
    func createPubNubClient() -> PubNub? {
        return nil
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        guard var selectedLabelItem = self.dataSource[indexPath] as? LabelItem else {
            fatalError("Please contact support@pubnub.com")
        }

        let alertController = UIAlertController.labelCellContentsUpdateAlertController(selectedLabelItem) { (action, updatedContentsString) in
            if let actionTitle = action.title, let alertAction = UIAlertController.LabelItemAction(rawValue: actionTitle) {
                switch (alertAction) {
                case .OK:
                    if let unwrappedUpdatedContentsString = updatedContentsString {
                        selectedLabelItem.contentsString = unwrappedUpdatedContentsString
                        self.dataSource[indexPath] = selectedLabelItem
                        collectionView.reloadItemsAtIndexPaths([indexPath])
                    }
                default:
                return
                }
            }
        }
        self.parentViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UINavigationItem
    
    public override var navBarTitle: String {
        return "PubNub Client Creation"
    }
}
