//
//  PushViewController.swift
//  Pods
//
//  Created by Jordan Zucker on 8/16/16.
//
//

import Foundation
import PubNub

@objc(PNCPushViewControllerDelegate)
public protocol PushViewControllerDelegate {
    @objc optional func pushView(pushView: PushViewController, receivedResult: PNResult)
}

//// Intended to launch from the toolbar
@objc(PNCPushViewController)
public class PushViewController: CollectionViewController, CollectionViewControllerDelegate {
    
    // MARK: - Properties
    var pushDelegate: PushViewControllerDelegate?

    // MARK: - DataSource

    enum PushSectionType: Int, ItemSectionType {
        case clientConfiguration = 0, pushConfiguration, pushActions
    }
    
    enum PushItemType: ItemType {
        case publishKey
        case subscribeKey
        case uuid
        case channelsLabel
        case devicePushTokenLabel
        case addPushNotificationsButton
        case removePushNotificationsButton
        case removeAllPushNotificationsButton
        case pushNotificationChannelsForDeviceTokenButton

        var cellClass: CollectionViewCell.Type {
            switch self {
            case .publishKey, .subscribeKey, .uuid:
                return TitleContentsCollectionViewCell.self
            case .channelsLabel, .devicePushTokenLabel:
                return TitleContentsCollectionViewCell.self
            case .addPushNotificationsButton, .removeAllPushNotificationsButton, .removePushNotificationsButton, .pushNotificationChannelsForDeviceTokenButton:
                return ButtonCollectionViewCell.self
            }
        }
        
        var selectedTitle: String? {
            return nil
        }
        
        var title: String {
            switch self {
            case .publishKey:
                return "Publish Key"
            case .subscribeKey:
                return "Subscribe Key"
            case .uuid:
                return "UUID"
            case .channelsLabel:
                return "Channels"
            case .devicePushTokenLabel:
                return "Device Push Token"
            case .addPushNotificationsButton:
                return "Add Push Notifications"
            case .removePushNotificationsButton:
                return "Remove Push Notifications"
            case .removeAllPushNotificationsButton:
                return "Remove All Push Notifications"
            case .pushNotificationChannelsForDeviceTokenButton:
                return "Push Notification Channels for Device Token"
            }
        }
        
        func contents(client: PubNub) -> String {
            switch self {
            case .publishKey:
                return client.currentConfiguration().publishKey
            case .subscribeKey:
                return client.currentConfiguration().subscribeKey
            case .uuid:
                return client.currentConfiguration().uuid
            default:
                return ""
            }
        }
        
        var sectionType: ItemSectionType {
            switch self {
            case .publishKey, .subscribeKey, .uuid:
                return PushSectionType.clientConfiguration
            case .channelsLabel:
                return PushSectionType.pushConfiguration
            case .channelsLabel, .devicePushTokenLabel:
                return PushSectionType.pushConfiguration
            case .addPushNotificationsButton, .removePushNotificationsButton, .removeAllPushNotificationsButton, .pushNotificationChannelsForDeviceTokenButton:
                return PushSectionType.pushActions
            }
        }
        
        var defaultValue: String {
            switch self {
            case .channelsLabel:
                return ""
            case .devicePushTokenLabel:
                return ""
            default:
                return ""
            }
        }
        
        var item: Int {
            switch self {
            case .publishKey:
                return 0
            case .subscribeKey:
                return 1
            case .uuid:
                return 2
            case .channelsLabel:
                return 0
            case .devicePushTokenLabel:
                return 1
            case .addPushNotificationsButton:
                return 0
            case .pushNotificationChannelsForDeviceTokenButton:
                return 1
            case .removePushNotificationsButton:
                return 2
            case .removeAllPushNotificationsButton:
                return 3
            }
        }
    }
    
    struct PushButtonItem: ButtonItem {
        let itemType: ItemType
        init(itemType: PushItemType, selected: Bool, targetSelector: TargetSelector) {
            self.itemType = itemType
            self.selected = selected
            self.targetSelector = targetSelector
        }
        init(itemType: PushItemType, targetSelector: TargetSelector) {
            self.init(itemType: itemType, selected: false, targetSelector: targetSelector)
        }
        var selected: Bool = false
        var targetSelector: TargetSelector
    }
    
    struct PushUpdatableLabelItem: UpdatableTitleContentsItem {
        init(itemType: PushItemType) {
            self.init(itemType: itemType, contentsString: itemType.defaultValue)
        }
        
        init(itemType: PushItemType, contentsString: String) {
            self.itemType = itemType
            self.contents = contentsString
        }
        
        let itemType: ItemType
        var contents: String
    }
    
    struct PushLabelItem: TitleContentsItem {
        let itemType: ItemType
        var contents: String
        init(itemType: PushItemType, contents: String) {
            self.itemType = itemType
            self.contents = contents
        }
        init(itemType: PushItemType, client: PubNub) {
            self.init(itemType: itemType, contents: itemType.contents(client: client))
        }
    }
    
    struct PushTextViewItem: TextViewItem {
        init(itemType: PushItemType) {
            self.init(itemType: itemType, contentsString: itemType.defaultValue)
        }
        
        init(itemType: PushItemType, contentsString: String) {
            self.itemType = itemType
            self.contents = contentsString
        }
        
        let itemType: ItemType
        var contents: String
    }
    
    final class PushDataSource: BasicDataSource {
        required init(sections: [ItemSection]) {
            super.init(sections: sections)
        }
        convenience init(client: PubNub, addChannelsButton: TargetSelector, channelsForDeviceTokenButton: TargetSelector, removeChannelsButton: TargetSelector, removeAllButton: TargetSelector) {
            let subscribeLabelItem = PushLabelItem(itemType: .subscribeKey, client: client)
            let publishLabelItem = PushLabelItem(itemType: .publishKey, client: client)
            let uuidLabelItem = PushLabelItem(itemType: .uuid, client: client)
            let channelsLabelItem = PushUpdatableLabelItem(itemType: .channelsLabel)
            let pushTokenLabelItem = PushUpdatableLabelItem(itemType: .devicePushTokenLabel)
            let addPushChannelsButtonItem = PushButtonItem(itemType: .addPushNotificationsButton, targetSelector: addChannelsButton)
            let channelsForDeviceTokenButtonItem = PushButtonItem(itemType: .pushNotificationChannelsForDeviceTokenButton, targetSelector: channelsForDeviceTokenButton)
            let removeChannelsButtonItem = PushButtonItem(itemType: .removePushNotificationsButton, targetSelector: removeChannelsButton)
            let removeAllButtonItem = PushButtonItem(itemType: .removeAllPushNotificationsButton, targetSelector: removeAllButton)
            let clientConfigSection = BasicSection(items: [publishLabelItem, subscribeLabelItem, uuidLabelItem])
            let pushConfigurationSection = BasicSection(items: [channelsLabelItem, pushTokenLabelItem])
            let pushActionsSection = BasicSection(items: [addPushChannelsButtonItem, channelsForDeviceTokenButtonItem, removeChannelsButtonItem, removeAllButtonItem])
//            let pushConsoleSection = ScrollingSection()
//            self.init(sections: [clientConfigSection, pushConfigurationSection, pushActionsSection, pushConsoleSection])
            self.init(sections: [clientConfigSection, pushConfigurationSection, pushActionsSection])
            
        }
        
        // add helper method for extracting channels and device token from fields
        
//        func push(result: PNResult) -> IndexPath {
//            let publishStatusItem = publishStatus.createItem(itemType: result.publishStatus)
//            return push(section: PublishItemType.publishStatus.section, item: publishStatusItem)
//        }
    }
    
    // MARK: - Constructors
    public required init(client: PubNub) {
        super.init()
        self.client = client
    }
    
    public required init() {
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.client?.remove(self)
    }
    
    // MARK: - View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let currentClient = self.client else {
            fatalError()
        }
        self.delegate = self
        let addChannelsButton: TargetSelector = (self, #selector(self.addChannelsButtonPressed(sender:)))
        let removeChannelsButton: TargetSelector = (self, #selector(self.removeChannelsButtonPressed(sender:)))
        let channelsForDeviceTokenButton: TargetSelector = (self, #selector(self.channelsForDeviceTokenPressed(sender:)))
        let removeAllButton: TargetSelector = (self, #selector(self.removeAllButtonPressed(sender:)))
        dataSource = PushDataSource(client: currentClient, addChannelsButton: addChannelsButton, channelsForDeviceTokenButton: channelsForDeviceTokenButton, removeChannelsButton: removeChannelsButton, removeAllButton: removeAllButton)
        guard let collectionView = self.collectionView else { fatalError("We expected to have a collection view by now. Please contact support@pubnub.com") }
        collectionView.register(TitleContentsCollectionViewCell.self, forCellWithReuseIdentifier: TitleContentsCollectionViewCell.reuseIdentifier)
        collectionView.register(ButtonCollectionViewCell.self, forCellWithReuseIdentifier: ButtonCollectionViewCell.reuseIdentifier)
        collectionView.reloadData() // probably a good idea to reload data after all we just did
    }
    
    // MARK: - Actions
    
    public func addChannelsButtonPressed(sender: UIButton) {
        let channels = ["a"]
        let deviceToken = Data(capacity: 64)
        self.client?.addPushNotifications(onChannels: channels, withDevicePushToken: deviceToken, andCompletion: { (status) in
            
        })
    }
    
    public func removeChannelsButtonPressed(sender: UIButton) {
        let channels = ["a"]
        let deviceToken = Data(capacity: 64)
        self.client?.removePushNotifications(fromChannels: channels, withDevicePushToken: deviceToken, andCompletion: { (status) in
            
        })
    }
    
    public func removeAllButtonPressed(sender: UIButton) {
        let channels = ["a"]
        let deviceToken = Data(capacity: 64)
        self.client?.removeAllPushNotificationsFromDevice(withPushToken: deviceToken, andCompletion: { (status) in
            
        })
    }
    
    public func channelsForDeviceTokenPressed(sender: UIButton) {
        let channels = ["a"]
        let deviceToken = Data(capacity: 64)
        self.client?.pushNotificationEnabledChannelsForDevice(withPushToken: deviceToken, andCompletion: { (result, errorStatus) in
            
        })
    }
    
    // MARK: - CollectionViewControllerDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didUpdateItemWithTextViewAtIndexPath indexPath: IndexPath, textView: UITextView, updatedTextFieldString updatedString: String?) {
    }
    
    // MARK: - UINavigationItem
    
    public override var navBarTitle: String {
        return "PubNub Push"
    }
}
