//
//  ConsoleViewController.swift
//  Pods
//
//  Created by Jordan Zucker on 7/26/16.
//
//

import UIKit
import PubNub

extension String {
    var isOnlyWhiteSpace: Bool {
        let whitespaceSet = NSCharacterSet.whitespaceCharacterSet()
        return self.stringByTrimmingCharactersInSet(whitespaceSet).isEmpty
    }
    var containsPubNubKeyWords: Bool {
        let keywordCharacterSet = NSCharacterSet(charactersInString: ",:.*/\\")
        if let _ = self.rangeOfCharacterFromSet(keywordCharacterSet, options: .CaseInsensitiveSearch) {
            return true
        }
        else {
            return false
        }
    }
}

enum PubNubStringParsingError: ErrorType, CustomStringConvertible {
    case Empty
    case ChannelNameContainsInvalidCharacters(channel: String)
    case ChannelNameTooLong(channel: String)
    case OnlyWhitespace(channel: String)
    var description: String {
        switch self {
        case .Empty:
            return "string has no length"
        case let .OnlyWhitespace(channel):
            return channel + " is only whitespace"
        case let .ChannelNameContainsInvalidCharacters(channel):
            return channel + " contains keywords that cannot be used with PubNub"
        case let .ChannelNameTooLong(channel):
            return channel + " is too long (over 92 characters)"
        }
    }
}

extension UIAlertController {
    static func alertControllerForPubNubStringParsingIntoSubscribablesArrayError(source: String?, error: PubNubStringParsingError, handler: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let blame = source ?? "string Parsing"
        let title = "Issue with " + blame
        let message = "Could not parse " + blame + " into array because \(error)"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        return alertController
    }
}

extension PubNub {
    // TODO: Implement this, should eventually be a universal function in the PubNub framework
    func stringToSubscribablesArray(channels: String?, commaDelimited: Bool = true) throws -> [String]? {
        guard let actualChannelsString = channels else {
            return nil
        }
        var channelsArray: [String]
        if commaDelimited {
            channelsArray = actualChannelsString.componentsSeparatedByString(",")
        } else {
            channelsArray = [actualChannelsString]
        }
        for channel in channelsArray {
            guard !channel.isOnlyWhiteSpace else {
                throw PubNubStringParsingError.OnlyWhitespace(channel: channel)
            }
            guard channel.characters.count > 0 else {
                throw PubNubStringParsingError.Empty
            }
            guard channel.characters.count <= 92 else {
                throw PubNubStringParsingError.ChannelNameTooLong(channel: channel)
            }
            guard !channel.containsPubNubKeyWords else {
                throw PubNubStringParsingError.ChannelNameContainsInvalidCharacters(channel: channel)
            }
        }
        return channelsArray
    }
    
    func channelsString() -> String? {
        return self.subscribablesToString(self.channels())
    }
    func channelGroupsString() -> String? {
        return self.subscribablesToString(self.channelGroups())
    }
    internal func subscribablesToString(subscribables: [String]) -> String? {
        if subscribables.isEmpty {
            return nil
        }
        return subscribables.reduce("", combine: { $0! + "," + $1 })
    }
}

public class ConsoleViewController: CollectionViewController, CollectionViewControllerDelegate {
    
    // MARK: - DataSource
    
    struct ConsoleSubscribeStatusItem: SubscribeStatusItem {
        let itemType: ItemType
        let title: String
        init(itemType: ConsoleItemType, status: PNStatus) {
            self.title = status.stringifiedCategory() + " \(status.statusCode)"
            self.itemType = itemType
        }
        init(status: PNStatus) {
            self.init(itemType: .SubscribeStatus, status: status)
        }
        var reuseIdentifier: String {
            return SubscribeStatusCollectionViewCell.reuseIdentifier
        }
    }
    
    struct ConsoleMessageItem: MessageItem {
        let itemType: ItemType
        let payload: AnyObject?
        init(itemType: ConsoleItemType, message: PNMessageResult) {
            self.itemType = itemType
            payload = message.data.message
        }
        init(message: PNMessageResult) {
            self.init(itemType: .Message, message: message)
        }
        var reuseIdentifier: String {
            return MessageCollectionViewCell.reuseIdentifier
        }
    }
    
    struct ConsoleLabelItem: LabelItem {
        let itemType: ItemType
        init(itemType: ConsoleItemType) {
            self.init(itemType: itemType, contents: itemType.defaultValue)
        }
        
        init(itemType: ConsoleItemType, contents: String) {
            self.itemType = itemType
            self.contents = contents
        }
        
        init(itemType: ConsoleItemType, client: PubNub) {
            self.init(itemType: itemType, contents: itemType.contents(client))
        }
        
        var contents: String
        var reuseIdentifier: String {
            return LabelCollectionViewCell.reuseIdentifier
        }
        
    }
    
    struct ConsoleSegmentedControlItem: SegmentedControlItem {
        enum Segment: Int {
            case All, SubscribeStatuses, Messages
            var title: String {
                switch self {
                case .All:
                    return "All"
                case .SubscribeStatuses:
                    return "Subscribes"
                case .Messages:
                    return "Messages"
                }
            }
            var consoleItemType: ConsoleItemType {
                switch self {
                case .All:
                    return ConsoleItemType.All
                case .Messages:
                    return ConsoleItemType.Message
                case .SubscribeStatuses:
                    return ConsoleItemType.SubscribeStatus
                }
            }
            static var allValues: [Segment] {
                return [All, SubscribeStatuses, Messages]
            }
            static var allValuesTitles: [String] {
                return allValues.map({ (segment) -> String in
                    segment.title
                })
            }
            
        }
        var selectedSegmentIndex: Int = Segment.All.rawValue
        let itemType: ItemType
        let items: [String]
        var targetSelector: TargetSelector
        init(itemType: ConsoleItemType, items: [String], targetSelector: TargetSelector) {
            self.itemType = itemType
            self.items = items
            self.targetSelector = targetSelector
        }
        init(items: [String], targetSelector: TargetSelector) {
            self.init(itemType: ConsoleItemType.ConsoleSegmentedControl, items: items, targetSelector: targetSelector)
        }
        init(targetSelector: TargetSelector) {
            self.init(items: Segment.allValuesTitles, targetSelector: targetSelector)
        }
        var reuseIdentifier: String {
            return SegmentedControlCollectionViewCell.reuseIdentifier
        }
        var defaultSelectedSegmentIndex: Int {
            return Segment.All.rawValue
        }
    }
    
    struct ConsoleButtonItem: ButtonItem {
        let itemType: ItemType
        init(itemType: ConsoleItemType, selected: Bool, targetSelector: TargetSelector) {
            self.itemType = itemType
            self.selected = selected
            self.targetSelector = targetSelector
        }
        init(itemType: ConsoleItemType, targetSelector: TargetSelector) {
            self.init(itemType: itemType, selected: false, targetSelector: targetSelector)
        }
        
        var selected: Bool = false
        var targetSelector: TargetSelector
        
        var reuseIdentifier: String {
            return ButtonCollectionViewCell.reuseIdentifier
        }
        
        
    }
    
    enum ConsoleSectionType: Int, ItemSectionType {
        case Subscribables = 0, SubscribeLoopControls, ConsoleSegmentedControl, Console
    }
    
    enum ConsoleItemType: ItemType {
        case Channels
        case ChannelGroups
        case SubscribeButton
        case All
        case SubscribeStatus
        case Message
        case ConsoleSegmentedControl
        indirect case Console(ConsoleItemType)
        
        func size(collectionViewSize: CGSize) -> CGSize {
            switch self {
            case .Channels, .ChannelGroups:
                return CGSize(width: 150.0, height: 125.0)
            case .SubscribeButton:
                return CGSize(width: 250.0, height: 100.0)
            case .SubscribeStatus, .Message, .All:
                return CGSize(width: collectionViewSize.width, height: 150.0)
            case .ConsoleSegmentedControl:
                return CGSize(width: 300.0, height: 75.0)
            case let Console(consoleItemType):
                switch consoleItemType {
                case .SubscribeStatus, .Message, .All:
                    return consoleItemType.size(collectionViewSize)
                default:
                    fatalError("Invalid type passed in")
                }
            }
        }
        
        
        func contents(client: PubNub) -> String {
            switch self {
            case .Channels:
                return client.channelsString() ?? ""
            case .ChannelGroups:
                return client.channelGroupsString() ?? ""
            default:
                return ""
            }
        }
        
        var title: String {
            switch self {
            case .Channels:
                return "Channels"
            case .ChannelGroups:
                return "Channel Groups"
            case .SubscribeButton:
                return "Subscribe"
            default:
                return ""
            }
        }
        
        var selectedTitle: String? {
            switch self {
            case .SubscribeButton:
                return "Unsubscribe"
            default:
                return nil
            }
        }
        
        var sectionType: ItemSectionType {
            switch self {
            case .Channels, .ChannelGroups:
                return ConsoleSectionType.Subscribables
            case .SubscribeButton:
                return ConsoleSectionType.SubscribeLoopControls
            case .SubscribeStatus, .Message, .All:
                return ConsoleSectionType.Console
            case .ConsoleSegmentedControl:
                return ConsoleSectionType.ConsoleSegmentedControl
            case let .Console(consoleItemType):
                switch consoleItemType {
                case .SubscribeStatus, .Message, .All:
                    return consoleItemType.sectionType
                default:
                    fatalError("Invalid type passed in")
                }

            }
        }
        
        var defaultValue: String {
            switch self {
            default:
                return ""
            }
        }
        
        var item: Int {
            switch self {
            case .Channels:
                return 0
            case .ChannelGroups:
                return 1
            case .SubscribeButton:
                return 0
            case .SubscribeStatus:
                return 0
            case .Message:
                return 0
            case .All:
                return 0
            case .ConsoleSegmentedControl:
                return 0
            case let .Console(consoleItemType):
                switch consoleItemType {
                case .SubscribeStatus, .Message, .All:
                    return consoleItemType.item
                default:
                    print("Invalid type passed in")
                    fatalError("Invalid type passed in")
                }
            }
        }
    }
 
    // MARK: - Constructors
    public required init(client: PubNub) {
        super.init()
        self.client = client
    }
    
    public required init() {
        super.init()
        self.client?.addListener(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        guard let currentClient = self.client else {
            return
        }
        let subscribablesSection = BasicDataSource.BasicSection(items: [ConsoleLabelItem(itemType: .Channels, client: currentClient), ConsoleLabelItem(itemType: .ChannelGroups, client: currentClient)])
        let subscribeButtonItem = ConsoleButtonItem(itemType: .SubscribeButton, targetSelector: (self, #selector(self.subscribeButtonPressed(_:))))
        let subscribeLoopButtonsSection = BasicDataSource.BasicSection(items: [subscribeButtonItem])
        let consoleSegmentedControl = ConsoleSegmentedControlItem(targetSelector: (self, #selector(self.consoleSegmentedControlValueChanged(_:))))
        let segmentedControlSection = BasicDataSource.SingleSegmentedControlSection(segmentedControl: consoleSegmentedControl)
        let allSection = BasicDataSource.ScrollingSection()
        let subscribeStatusSection = BasicDataSource.ScrollingSection()
        let messageSection = BasicDataSource.ScrollingSection()
        let consoleSection = BasicDataSource.SelectableSection(selectableItemSections: [allSection, subscribeStatusSection, messageSection])
        dataSource = BasicDataSource(sections: [subscribablesSection, subscribeLoopButtonsSection, segmentedControlSection, consoleSection])
        guard let collectionView = self.collectionView else { fatalError("We expected to have a collection view by now. Please contact support@pubnub.com") }
        collectionView.registerClass(LabelCollectionViewCell.self, forCellWithReuseIdentifier: LabelCollectionViewCell.reuseIdentifier)
        collectionView.registerClass(ButtonCollectionViewCell.self, forCellWithReuseIdentifier: ButtonCollectionViewCell.reuseIdentifier)
        collectionView.registerClass(SubscribeStatusCollectionViewCell.self, forCellWithReuseIdentifier: SubscribeStatusCollectionViewCell.reuseIdentifier)
        collectionView.registerClass(MessageCollectionViewCell.self, forCellWithReuseIdentifier: MessageCollectionViewCell.reuseIdentifier)
        collectionView.registerClass(SegmentedControlCollectionViewCell.self, forCellWithReuseIdentifier: SegmentedControlCollectionViewCell.reuseIdentifier)
        collectionView.reloadData() // probably a good idea to reload data after all we just did
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        collectionView?.performBatchUpdates({ 
            self.dataSource?.clear(ConsoleItemType.SubscribeStatus.section)
            self.dataSource?.clear(ConsoleItemType.Message.section)
            self.dataSource?.clear(ConsoleItemType.All.section)
            self.collectionView?.reloadSections(ConsoleItemType.SubscribeStatus.indexSet)
            self.collectionView?.reloadSections(ConsoleItemType.Message.indexSet)
            self.collectionView?.reloadSections(ConsoleItemType.All.indexSet)
            }, completion: nil)
    }
    
    // MARK: - Actions
    func subscribeButtonPressed(sender: UIButton!) {
        // TODO: clean this up
        if sender.selected {
            client?.unsubscribeFromAll()
            return
        }
        guard let currentDataSource = dataSource, let channelsItem = currentDataSource[ConsoleItemType.Channels.indexPath] as? ConsoleLabelItem, let channelGroupsItem = currentDataSource[ConsoleItemType.ChannelGroups.indexPath] as? ConsoleLabelItem else {
            return
        }
        do {
            guard let channels = try client?.stringToSubscribablesArray(channelsItem.contents) else {
                return
            }
            client?.subscribeToChannels(channels, withPresence: true)
        } catch let pubNubError as PubNubStringParsingError {
            // TODO: implement all errors
            print("\(#function) " + "error: " + "\(pubNubError)")
            let alertController = UIAlertController.alertControllerForPubNubStringParsingIntoSubscribablesArrayError(channelsItem.title, error: pubNubError, handler: nil)
            presentViewController(alertController, animated: true, completion: nil)
            return
        } catch {
            fatalError(#function + " error: \(error)")
        }
        do {
            guard let channelGroups = try client?.stringToSubscribablesArray(channelGroupsItem.contents) else {
                return
            }
            client?.subscribeToChannelGroups(channelGroups, withPresence: true)
        } catch let pubNubError as PubNubStringParsingError {
            // TODO: implement all errors
            print("\(#function) " + "error: " + "\(pubNubError)")
            let alertController = UIAlertController.alertControllerForPubNubStringParsingIntoSubscribablesArrayError(channelGroupsItem.title, error: pubNubError, handler: nil)
            presentViewController(alertController, animated: true, completion: nil)
            return
        } catch {
            fatalError(#function + " error: \(error)")
        }
    }
    
    func consoleSegmentedControlValueChanged(sender: UISegmentedControl!) {
        collectionView?.performBatchUpdates({ 
            self.dataSource?.updateSelectedSegmentIndex(ConsoleItemType.ConsoleSegmentedControl.indexPath, updatedSelectedSegmentIndex: sender.selectedSegmentIndex)
            guard let currentSegmentedControlValue = ConsoleSegmentedControlItem.Segment(rawValue: sender.selectedSegmentIndex) else {
                fatalError()
            }
            self.dataSource?.updateSelectedSection(ConsoleItemType.Console(currentSegmentedControlValue.consoleItemType).section, selectedSubSection: currentSegmentedControlValue.rawValue)
            self.collectionView?.reloadSections(ConsoleItemType.Console(currentSegmentedControlValue.consoleItemType).indexSet)
            }, completion: nil)
    }
    
    // MARK: - CollectionViewControllerDelegate
    
    public func collectionView(collectionView: UICollectionView, didUpdateItemWithTextFieldAlertControllerAtIndexPath indexPath: NSIndexPath, selectedAlertAction: UIAlertAction, updatedTextFieldString updatedString: String?) {
        if let actionTitle = selectedAlertAction.title, let alertDecision = UIAlertController.ItemAction(rawValue: actionTitle) {
            switch (alertDecision) {
            case .OK:
                client?.unsubscribeFromAll() // unsubscribe whenever a subscribable is changed
            default:
                return
            }
        }
    }
    
    // MARK: - Update from Client
    
    public func updateSubscribableLabelCells() {
        guard let currentClient = self.client, let currentDataSource = dataSource else {
            return
        }
        dataSource?.updateLabelContentsString(ConsoleItemType.Channels.indexPath, updatedContents: client?.channelsString())
        dataSource?.updateLabelContentsString(ConsoleItemType.ChannelGroups.indexPath, updatedContents: client?.channelGroupsString())
        collectionView?.reloadItemsAtIndexPaths([ConsoleItemType.Channels.indexPath, ConsoleItemType.ChannelGroups.indexPath])
    }
    
    public func updateSubscribeButtonState() {
        guard let currentClient = self.client else {
            return
        }
        let subscribing = !(currentClient.channels().isEmpty && currentClient.channelGroups().isEmpty)
        let indexPath = ConsoleItemType.SubscribeButton.indexPath
        dataSource?.updateSelected(indexPath, selected: subscribing)
        collectionView?.reloadItemsAtIndexPaths([indexPath])
        
    }
    
    // MARK: - PNObjectEventListener
    
    public func client(client: PubNub, didReceiveStatus status: PNStatus) {
        print(status.debugDescription)
        if (
            (status.operation == .SubscribeOperation) ||
            (status.operation == .UnsubscribeOperation)
            ){
            updateSubscribableLabelCells() // this ensures we receive updates to available channels and channel groups even if the changes happen outside the scope of this view controller
            updateSubscribeButtonState()
            
            // TODO: add push to data source here
            let subscribeStatus = ConsoleSubscribeStatusItem(status: status)
            dataSource?.push(ConsoleItemType.SubscribeStatus.section, subSection: ConsoleSegmentedControlItem.Segment.SubscribeStatuses.rawValue, item: subscribeStatus)
            dataSource?.push(ConsoleItemType.All.section, subSection: ConsoleSegmentedControlItem.Segment.All.rawValue, item: subscribeStatus)
            guard let consoleSegmentedControlIndex = dataSource?.selectedSegmentIndex(ConsoleItemType.ConsoleSegmentedControl.indexPath) else {
                return
            }
            guard let currentSegmentedControlValue = ConsoleSegmentedControlItem.Segment(rawValue: consoleSegmentedControlIndex) else {
                fatalError()
            }
            if currentSegmentedControlValue == .All || currentSegmentedControlValue == .SubscribeStatuses {
                collectionView?.reloadSections(ConsoleItemType.Console(currentSegmentedControlValue.consoleItemType).indexSet)
            }
        }

    }
    
    public func client(client: PubNub, didReceiveMessage message: PNMessageResult) {
        print(message.debugDescription)
        let message = ConsoleMessageItem(message: message)
        dataSource?.push(ConsoleItemType.Message.section, subSection: ConsoleSegmentedControlItem.Segment.Messages.rawValue, item: message)
        dataSource?.push(ConsoleItemType.All.section, subSection: ConsoleSegmentedControlItem.Segment.All.rawValue, item: message)
        guard let consoleSegmentedControlIndex = dataSource?.selectedSegmentIndex(ConsoleItemType.ConsoleSegmentedControl.indexPath) else {
            return
        }
        guard let currentSegmentedControlValue = ConsoleSegmentedControlItem.Segment(rawValue: consoleSegmentedControlIndex) else {
            fatalError()
        }
        if currentSegmentedControlValue == .All || currentSegmentedControlValue == .Messages {
            collectionView?.reloadSections(ConsoleItemType.Console(currentSegmentedControlValue.consoleItemType).indexSet)
        }
    }
    
    // MARK: - UINavigationItem
    
    public override var navBarTitle: String {
        return "PubNub Console"
    }

}
