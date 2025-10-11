//
//  StatusBarController.swift
//  Prism
//
//  Created by okooo5km(十里) on 2025/9/30.
//

import SwiftUI
import AppKit

@MainActor
final class StatusBarController {
    static let shared = StatusBarController()
    
    private var statusBarItem: NSStatusItem?
    private let popover: NSPopover
    private var hostingController: NSHostingController<AnyView>?
    
    private init() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
    }
    
    func setup() {
        guard statusBarItem == nil else {
            refreshContentIfNeeded()
            return
        }
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        createHostingControllerIfNeeded()
        
        guard let button = statusBarItem?.button else {
            return
        }
        
        let image = NSImage(systemSymbolName: "rectangle.2.swap", accessibilityDescription: nil)
        image?.isTemplate = true
        button.image = image
        button.target = self
        button.action = #selector(togglePopover(_:))
    }
    
    private func createHostingControllerIfNeeded() {
        guard hostingController == nil else { return }
        
        let contentView = AnyView(ContentView())
        hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 360, height: 360)
    }
    
    @objc
    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusBarItem?.button else {
            return
        }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            refreshContentIfNeeded()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.becomeKey()
        }
    }
    
    private func refreshContentIfNeeded() {
        if hostingController == nil {
            createHostingControllerIfNeeded()
        }
    }
}
