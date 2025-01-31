//
//  WindowController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 05/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Cocoa
import Models
import Providers
import NSObject_Combine

/// Protocol for announcing user interaction with the toolbar
///
protocol WindowControllerToolbarDelegate: AnyObject {
    /// Invoked when user requests opening a folder
    func userDidRequestFolderOpen()

    /// Invoked when user requests opening a folder for a specific path
    func userDidRequestFolderOpen(withPath: String)

    /// Invoked when user requests filter change
    ///
    /// - Parameter filter: new filter setting
    func userDidRequestFilterChange(filter: Filter)

    /// Invoked when user requests searching
    ///
    /// - Parameter searchTerm: new search term
    func userDidRequestSearch(searchTerm: String)

    /// Invoked when user requests change of the selected localization group
    ///
    /// - Parameter group: new localization group title
    func userDidRequestLocalizationGroupChange(group: String)

    /// Invoked when user requests adding a new translation
    func userDidRequestAddNewTranslation()

    /// Invoked when user requests reload selected folder
    func userDidRequestReloadData()

    /// Invoked when user requests drag row
    func userDidRequestDragRow()

    func userDidRequestAddRowAbove()

    func userDidRequestAddRowBelow()
}

final class WindowController: NSWindowController {
    // MARK: - Outlets

    @IBOutlet private var openButton: NSToolbarItem!
    @IBOutlet private var searchField: NSSearchField!
    @IBOutlet private var selectButton: NSPopUpButton!
    @IBOutlet private var filterButton: NSPopUpButton!
    @IBOutlet private var newButton: NSToolbarItem!
    @IBOutlet private var dragButton: NSToolbarItem!
    @IBOutlet private var undoButton: NSToolbarItem!
    @IBOutlet private var redoButton: NSToolbarItem!
    @IBOutlet private var addRowBelowButton: NSToolbarItem!
    @IBOutlet private var addRowAboveButton: NSToolbarItem!

    // MARK: - Properties

    weak var delegate: WindowControllerToolbarDelegate?

    override func windowDidLoad() {
        super.windowDidLoad()

        setupUI()
        setupSearch()
        setupFilter()
        setupMenu()
        setupDelegates()
    }

    // MAKR: - Interfaces

    func openFolder(withPath path: String) {
        delegate?.userDidRequestFolderOpen(withPath: path)
    }

    // MARK: - Setup

    private func setupUI() {
        openButton.image = NSImage(named: NSImage.folderName)
        openButton.toolTip = "open_folder".localized
        searchField.toolTip = "search".localized
        filterButton.toolTip = "filter".localized
        selectButton.toolTip = "string_table".localized
        newButton.toolTip = "new_translation".localized
        newButton.isEnabled = false
        dragButton.isEnabled = false
        addRowAboveButton.isEnabled = false
        addRowBelowButton.isEnabled = false
        window?.publisher(for: \.firstResponder)
            .receive(on: RunLoop.main)
            .sink { [unowned self] firstResponder in
                undoButton.isEnabled = firstResponder?.undoManager?.canUndo ?? false
                redoButton.isEnabled = firstResponder?.undoManager?.canRedo ?? false
            }
            .store(in: &combine.cancellables)
    }

    private func setupSearch() {
        searchField.delegate = self
        searchField.stringValue = ""

        _ = searchField.resignFirstResponder()
    }

    private func setupFilter() {
        filterButton.menu?.removeAllItems()

        for option in Filter.allCases {
            let item = NSMenuItem(title: "\(option.description)".capitalizedFirstLetter, action: #selector(WindowController.filterAction(sender:)), keyEquivalent: "")
            item.tag = option.rawValue
            filterButton.menu?.addItem(item)
        }
    }

    private func setupMenu() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.openFolderMenuItem.action = #selector(WindowController.openFolderAction(_:))
        appDelegate.reloadMenuItem.action = #selector(WindowController.reloadDataAction(_:))
    }

    private func enableControls() {
        searchField.isEnabled = true
        filterButton.isEnabled = true
        selectButton.isEnabled = true
        newButton.isEnabled = true
        dragButton.isEnabled = true
        addRowBelowButton.isEnabled = true
        addRowAboveButton.isEnabled = true
    }

    private func setupDelegates() {
        guard let mainViewController = window?.contentViewController as? ViewController else {
            fatalError("Broken window hierarchy")
        }

        // informing the window about toolbar appearence
        mainViewController.delegate = self

        // informing the VC about user interacting with the toolbar
        delegate = mainViewController
    }

    // MARK: - Actions

    @objc private func selectAction(sender: NSMenuItem) {
        let groupName = sender.title
        delegate?.userDidRequestLocalizationGroupChange(group: groupName)
    }

    @objc private func filterAction(sender: NSMenuItem) {
        guard let filter = Filter(rawValue: sender.tag) else { return }

        delegate?.userDidRequestFilterChange(filter: filter)
    }

    @IBAction private func openFolder(_ sender: Any) {
        delegate?.userDidRequestFolderOpen()
    }

    @IBAction private func addAction(_ sender: Any) {
        guard newButton.isEnabled else { return }

        delegate?.userDidRequestAddNewTranslation()
    }

    @objc private func openFolderAction(_ sender: NSMenuItem) {
        delegate?.userDidRequestFolderOpen()
    }

    @objc private func reloadDataAction(_ sender: NSMenuItem) {
        delegate?.userDidRequestReloadData()
    }

    @IBAction func dragRowAction(_ sender: NSToolbarItem) {
        delegate?.userDidRequestDragRow()
    }

    @IBAction func undoAction(_ sender: NSToolbarItem) {
        window?.firstResponder?.undoManager?.undo()
        undoButton.isEnabled = window?.firstResponder?.undoManager?.canUndo ?? false
        redoButton.isEnabled = window?.firstResponder?.undoManager?.canRedo ?? false
    }

    @IBAction func redoAction(_ sender: NSToolbarItem) {
        window?.firstResponder?.undoManager?.redo()
        undoButton.isEnabled = window?.firstResponder?.undoManager?.canUndo ?? false
        redoButton.isEnabled = window?.firstResponder?.undoManager?.canRedo ?? false
    }

    @IBAction func addRowAboveAction(_ sender: NSToolbarItem) {
        delegate?.userDidRequestAddRowAbove()
    }

    @IBAction func addRowBelowAction(_ sender: NSToolbarItem) {
        delegate?.userDidRequestAddRowBelow()
    }
}

// MARK: - NSSearchFieldDelegate

extension WindowController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        delegate?.userDidRequestSearch(searchTerm: searchField.stringValue)
    }
}

// MARK: - ViewControllerDelegate

extension WindowController: ViewControllerDelegate {
    /// Invoked when localization groups should be set in the toolbar's dropdown list
    func shouldSetLocalizationGroups(groups: [LocalizationGroup]) {
        selectButton.menu?.removeAllItems()
        groups.map { NSMenuItem(title: $0.name, action: #selector(WindowController.selectAction(sender:)), keyEquivalent: "") }.forEach { selectButton.menu?.addItem($0) }
    }

    /// Invoiked when search and filter should be reset in the toolbar
    func shouldResetSearchTermAndFilter() {
        setupSearch()
        setupFilter()

        delegate?.userDidRequestSearch(searchTerm: "")
        delegate?.userDidRequestFilterChange(filter: .all)
    }

    /// Invoked when localization group should be selected in the toolbar's dropdown list
    func shouldSelectLocalizationGroup(title: String) {
        enableControls()
        selectButton.selectItem(at: selectButton.indexOfItem(withTitle: title))
    }
}

extension WindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        item.isEnabled
    }
}
