//
//  ViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa
import Combine
import Providers
import Utils
import Models
import NSObject_Combine
import NSAttributedStringBuilder

/// Protocol for announcing changes to the toolbar. Needed because the VC does not have direct access to the toolbar (handled by WindowController)
///
protocol ViewControllerDelegate: AnyObject {
    /// Invoked when localization groups should be set in the toolbar's dropdown list
    func shouldSetLocalizationGroups(groups: [LocalizationGroup])

    /// Invoiked when search and filter should be reset in the toolbar
    func shouldResetSearchTermAndFilter()

    /// Invoked when localization group should be selected in the toolbar's dropdown list
    func shouldSelectLocalizationGroup(title: String)
}

final class ViewController: NSViewController {
    enum FixedColumn: String {
        case key
        case actions
        case drag
        var identifier: NSUserInterfaceItemIdentifier {
            .init(rawValue: rawValue)
        }
    }

    // MARK: - Outlets

    @IBOutlet
    private var tableView: NSTableView!
    @IBOutlet
    private var progressIndicator: NSProgressIndicator!

    // MARK: - Properties

    weak var delegate: ViewControllerDelegate?

    /// 当前的过滤器
    private var currentFilter: Filter = .all
    /// 当前的搜索词
    private var currentSearchTerm: String = ""
    
    private let dataSource = LocalizationsDataSource()
    
    private var presendedAddViewController: AddViewController?
    
    /// 当前打开的文件夹的URL
    private var currentOpenFolderUrl: URL?
    
    private var currentEditCell: LocalizationCell?
    
    private var fileMonitor: FolderContentMonitor?
    
    private let operationQueue: OperationQueue = .init()
    
    private var isDrag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
    }

    // MARK: - Setup

    private func setupData() {
        let cellIdentifiers = [KeyCell.identifier, LocalizationCell.identifier, ActionsCell.identifier, DragCell.identifier]
        cellIdentifiers.forEach { identifier in
            let cell = NSNib(nibNamed: identifier, bundle: nil)
            tableView.register(cell, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier))
        }
        
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.allowsColumnResizing = true
        tableView.usesAutomaticRowHeights = true
        tableView.registerForDraggedTypes([.rowIndex])
        tableView.selectionHighlightStyle = .none
    }

    private func reloadData(with languages: [String], title: String?) {
        delegate?.shouldResetSearchTermAndFilter()

        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        if #available(macOS 11, *) {
            view.window?.title = appName
            view.window?.subtitle = title ?? ""
        } else {
            view.window?.title = title.flatMap { "\(appName) [\($0)]" } ?? appName
        }

        let columns = tableView.tableColumns
        columns.forEach {
            tableView.removeTableColumn($0)
        }

        // not sure why this is needed but without it autolayout crashes and the whole tableview breaks visually
        // 不知道为什么这是必要的，但没有它，自动布局崩溃和整个表视图样式被破坏
        tableView.reloadData()

        let column = NSTableColumn(identifier: FixedColumn.key.identifier)
        column.title = "key".localized
        tableView.addTableColumn(column)

        languages.forEach { language in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(language))
            column.title = Flag(languageCode: language).emoji
            column.maxWidth = 460
            column.minWidth = 50
            tableView.addTableColumn(column)
        }

        let actionsColumn = NSTableColumn(identifier: FixedColumn.actions.identifier)
        actionsColumn.headerCell.attributedStringValue = NSAttributedString {
            AText("actions".localized)
                .paragraphStyle(NSMutableParagraphStyle().then { $0.alignment = .center })
        }
        actionsColumn.maxWidth = 48
        actionsColumn.minWidth = 32
        tableView.addTableColumn(actionsColumn)

        
        tableView.reloadData()

        // Also resize the columns:
        tableView.sizeToFit()

        // Needed to properly size the actions column
        DispatchQueue.main.async {
            self.tableView.sizeToFit()
            self.tableView.layout()
        }
    }

    private func filter() {
        dataSource.filter(by: currentFilter, searchString: currentSearchTerm)
        tableView.reloadData()
    }

    private func handleOpenFolder(_ url: URL) {
        OperationQueue.main.addOperation {
            self.progressIndicator.startAnimation(self)
        }
        dataSource.load(folder: url) { [unowned self] languages, title, localizationFiles in
            currentOpenFolderUrl = url
            reloadData(with: languages, title: title)
            
            OperationQueue.main.addOperation {
                self.progressIndicator.stopAnimation(self)
            }

            if let title = title {
                delegate?.shouldSetLocalizationGroups(groups: localizationFiles)
                delegate?.shouldSelectLocalizationGroup(title: title)
            }
        }
    }

    private func openFolder(forPath path: String? = nil) {
        if let path = path {
            let url = URL(fileURLWithPath: path)
            handleOpenFolder(url)
            observeFileChange(for: url)
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.begin { result in
            guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let url = openPanel.url else {
                return
            }
            self.observeFileChange(for: url)
            self.handleOpenFolder(url)
        }
    }

    private func observeFileChange(for url: URL) {
        fileMonitor = FolderContentMonitor(url: url)
        fileMonitor?.publisher
            .filter { $0.change.contains([.isFile, .renamed]) && $0.filename != ".DS_Store" }
            .debounce(for: 1, scheduler: RunLoop.current)
            .sink { [unowned self] _ in

                guard let window = view.window else { return }
                let alert = NSAlert()
                alert.addButton(withTitle: "重新载入")
                alert.addButton(withTitle: "暂时不要")
                alert.alertStyle = .critical
                alert.messageText = "检测到源文件已更改，是否重新载入数据"
                alert.informativeText = "如果在没有重新载入的情况下操作会覆盖你在其他地方的更改"
                OperationQueue.main.addOperation {
                    alert.beginSheetModal(for: window) { response in

                        switch response {
                        case .alertFirstButtonReturn:
                            self.operationQueue.addOperation {
                                self.handleOpenFolder(url)
                            }
                        case .alertSecondButtonReturn:
                            break
                        default:
                            break
                        }
                    }
                }
            }
            .store(in: &combine.cancellables)
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }

        switch identifier.rawValue {
        case FixedColumn.key.rawValue:
            let cell = tableView.makeView(withIdentifier: KeyCell.itemIdentifier, owner: self) as! KeyCell
            cell.key = dataSource.getKey(row: row)
            cell.message = dataSource.getMessage(row: row)
            return cell
        case FixedColumn.actions.rawValue:
            let cell = tableView.makeView(withIdentifier: ActionsCell.itemIdentifier, owner: self) as! ActionsCell
            cell.delegate = self
            cell.key = dataSource.getKey(row: row)
            return cell
        case FixedColumn.drag.rawValue:
            let cell = tableView.makeView(withIdentifier: DragCell.itemIdentifier, owner: self) as! DragCell
            return cell
        default:
            let language = identifier.rawValue
            let cell = tableView.makeView(withIdentifier: LocalizationCell.itemIdentifier, owner: self) as! LocalizationCell
            cell.delegate = self
            cell.language = language
            cell.value = row < dataSource.numberOfRows(in: tableView) ? dataSource.getLocalization(language: language, row: row) : nil
            return cell
        }
    }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        50
    }
    
}

// MARK: - LocalizationCellDelegate

extension ViewController: LocalizationCellDelegate {
    func userDidUpdateLocalizationString(language: String, key: String, with value: String, message: String?, willUpdate: Closure?, didUpdate: Closure?) {
        dataSource.updateLocalization(language: language, key: key, value: value, message: message, willUpdate: willUpdate, didUpdate: didUpdate)
    }
    
    func userDidFocusLocalizationString(_ cell: LocalizationCell) {
        currentEditCell = cell
    }
}

// MARK: - ActionsCellDelegate

extension ViewController: ActionsCellDelegate {
    func userDidRequestRemoval(of key: String) {
        removeTranslation(key: key)
    }
}

// MARK: - WindowControllerToolbarDelegate

extension ViewController: WindowControllerToolbarDelegate {
    /// Invoked when user requests adding a new translation
    func userDidRequestAddNewTranslation() {
        let addViewController = storyboard!.instantiateController(withIdentifier: "Add") as! AddViewController
        addViewController.delegate = self
        presendedAddViewController = addViewController
        presentAsSheet(addViewController)
    }

    /// Invoked when user requests filter change
    ///
    /// - Parameter filter: new filter setting
    func userDidRequestFilterChange(filter: Filter) {
        guard currentFilter != filter else { return }
        
        currentFilter = filter
        self.filter()
    }

    /// Invoked when user requests searching
    ///
    /// - Parameter searchTerm: new search term
    func userDidRequestSearch(searchTerm: String) {
        guard currentSearchTerm != searchTerm else { return }

        currentSearchTerm = searchTerm
        filter()
    }

    /// Invoked when user request change of the selected localization group
    ///
    /// - Parameter group: new localization group title
    func userDidRequestLocalizationGroupChange(group: String) {
        let languages = dataSource.selectGroupAndGetLanguages(for: group)
        reloadData(with: languages, title: group)
    }

    /// Invoked when user requests opening a folder
    func userDidRequestFolderOpen() {
        openFolder()
    }

    /// Invoked when user requests opening a folder for specific path
    func userDidRequestFolderOpen(withPath path: String) {
        openFolder(forPath: path)
    }

    /// Invoked when user requests reload selected folder
    func userDidRequestReloadData() {
        guard let currentOpenFolderUrl = currentOpenFolderUrl else { return }
        handleOpenFolder(currentOpenFolderUrl)
    }
    
    func userDidRequestDragRow() {
        if isDrag {
            if let tableColumn = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(FixedColumn.drag.rawValue)) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    tableView.animator().removeTableColumn(tableColumn)
                    tableView.animator().sizeToFit()
                }
            }
            isDrag = false
        } else {
            let dragColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.drag.rawValue))
            dragColumn.headerCell.attributedStringValue = NSAttributedString {
                AText("drag".localized)
                    .paragraphStyle(NSMutableParagraphStyle().then { $0.alignment = .center })
            }
            dragColumn.maxWidth = 48
            dragColumn.minWidth = 32
            
            NSAnimationContext.runAnimationGroup { _ in
                tableView.animator().addTableColumn(dragColumn)
            }
            isDrag = true
            print(DragCell.identifier)
        }
    }
    
    func userDidRequestAddRowAbove() {
        guard let currentEditCell = currentEditCell else { return }
        let rowIndex = tableView.row(for: currentEditCell)
        guard rowIndex > 0, rowIndex < tableView.numberOfRows else { return }
        let addViewController = storyboard!.instantiateController(withIdentifier: "Add") as! AddViewController
        addViewController.delegate = self
        addViewController.addMode = .insert(rowIndex)
        presendedAddViewController = addViewController
        presentAsSheet(addViewController)
    }
    
    func userDidRequestAddRowBelow() {
        guard let currentEditCell = currentEditCell else { return }
        let rowIndex = tableView.row(for: currentEditCell) + 1
        guard rowIndex > 0, rowIndex < tableView.numberOfRows else { return }
        let addViewController = storyboard!.instantiateController(withIdentifier: "Add") as! AddViewController
        addViewController.delegate = self
        addViewController.addMode = .insert(rowIndex)
        presendedAddViewController = addViewController
        presentAsSheet(addViewController)
    }
}

// MARK: - AddViewControllerDelegate

extension ViewController: AddViewControllerDelegate {
    func userDidCancel() {
        dismiss()
    }

    func userDidAddTranslation(key: String, message: String?, addMode: AddViewController.AddMode) {
        switch addMode {
        case .append:
            addTranslation(key: key, message: message)
        case .insert(let row):
            addTranslation(key: key, message: message, row: row)
        }
    }

    private func dismiss() {
        guard let presendedAddViewController = presendedAddViewController else { return }
        dismiss(presendedAddViewController)
    }
}

extension ViewController {
    func addTranslation(key: String, message: String?, row: Int? = nil) {
        dismiss()
        
        undoManager?.registerUndo(withTarget: self) { target in
            target.removeTranslation(key: key)
        }
        
        if let row = row {
            dataSource.insertLocalization(key: key, message: message, row: row)
        } else {
            dataSource.addLocalization(key: key, message: message)
        }
        filter()

        if let row = dataSource.getRow(key: key) {
            DispatchQueue.main.async {
                self.tableView.scrollRowToVisible(row)
            }
        }
    }
    
    func removeTranslation(key: String) {
        let rowData = dataSource.getLocalizationRowData(key: key)
        let message = dataSource.getMessage(row: dataSource.getRow(key: key))
        let rowIndex = dataSource.getRow(key: key)
        
        if let rowData = rowData, let rowIndex = rowIndex {
            undoManager?.registerUndo(withTarget: self) { target in
                target.addTranslation(key: key, message: message, row: rowIndex)
                target.dataSource.updateLocalizationRow(key: key, rowData: rowData, rowIndex: rowIndex)
                target.filter()
            }
        }
        
        dataSource.deleteLocalization(key: key)

        // reload keeping scroll position
        let rect = tableView.visibleRect
        filter()
        tableView.scrollToVisible(rect)
    }
    
}

