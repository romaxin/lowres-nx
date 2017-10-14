//
//  LowResNXWindowController.swift
//  LowRes NX macOS
//
//  Created by Timo Kloss on 30/4/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import Cocoa

class LowResNXWindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet weak var lowResNXView: LowResNXView!
    @IBOutlet weak var backgroundView: NSView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    var timer: Timer? = nil
    var coreWrapper: CoreWrapper?
    var coreDelegate = CoreDelegate()

    override func windowDidLoad() {
        super.windowDidLoad()
        window!.delegate = self
        
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = CGColor(gray: 0, alpha: 1)
        
        let lowResNXDocument = document as! LowResNXDocument
        coreWrapper = lowResNXDocument.coreWrapper
        
        if let coreWrapper = coreWrapper {
            coreDelegate.context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            coreDelegate.interpreterDidFail = interpreterDidFail
            coreDelegate.diskDriveWillAccess = diskDriveWillAccess
            coreDelegate.diskDriveDidSave = diskDriveDidSave
            coreDelegate.controlsDidChange = controlsDidChange
            core_setDelegate(&coreWrapper.core, &coreDelegate)
            
            let secondsSincePowerOn = -(NSApp.delegate as! AppDelegate).launchDate.timeIntervalSinceNow
            core_willRunProgram(&coreWrapper.core, Int(secondsSincePowerOn))
            
            // keyboard counts as physical gamepads
            core_setNumPhysicalGamepads(&coreWrapper.core, 2)
            
            timer = Timer.scheduledTimer(timeInterval: 1.0/30.0, target: self, selector: #selector(LowResNXWindowController.update), userInfo: nil, repeats: true)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        timer?.invalidate()
    }
    
    func windowDidResize(_ notification: Notification) {
        if let contentView = window?.contentView {
            let screenWidth = contentView.bounds.size.width
            let screenHeight = contentView.bounds.size.height
            let maxWidthFactor = floor(screenWidth / CGFloat(SCREEN_WIDTH))
            let maxHeightFactor = floor(screenHeight / CGFloat(SCREEN_HEIGHT))
            widthConstraint.constant = (maxWidthFactor < maxHeightFactor) ? maxWidthFactor * CGFloat(SCREEN_WIDTH) : maxHeightFactor * CGFloat(SCREEN_WIDTH)
        }
    }
    
    @objc func update() {
        if let coreWrapper = coreWrapper {
            core_update(&coreWrapper.core)
            lowResNXView.render(coreWrapper: coreWrapper)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        switch event.keyCode {
        case 123:
            core_gamepadPressed(&coreWrapper.core, 0, GamepadButtonLeft)
        case 124:
            core_gamepadPressed(&coreWrapper.core, 0, GamepadButtonRight)
        case 125:
            core_gamepadPressed(&coreWrapper.core, 0, GamepadButtonDown)
        case 126:
            core_gamepadPressed(&coreWrapper.core, 0, GamepadButtonUp)
        case 6, 43: // Z, ,
            core_gamepadPressed(&coreWrapper.core, 0, GamepadButtonA)
        case 7, 47: // X, .
            core_gamepadPressed(&coreWrapper.core, 0, GamepadButtonB)
        case 2: // D
            core_gamepadPressed(&coreWrapper.core, 1, GamepadButtonLeft)
        case 5: // G
            core_gamepadPressed(&coreWrapper.core, 1, GamepadButtonRight)
        case 3: // F
            core_gamepadPressed(&coreWrapper.core, 1, GamepadButtonDown)
        case 15: // R
            core_gamepadPressed(&coreWrapper.core, 1, GamepadButtonUp)
        case 0: // A
            core_gamepadPressed(&coreWrapper.core, 1, GamepadButtonA)
        case 1: // S
            core_gamepadPressed(&coreWrapper.core, 1, GamepadButtonB)
        default:
            break
        }
        let characters = event.charactersIgnoringModifiers!
        if !characters.isEmpty {
            if characters == "\r" {
                core_returnPressed(&coreWrapper.core)
            } else if characters == "\u{7F}" {
                core_backspacePressed(&coreWrapper.core)
            } else {
                let text = characters.uppercased()
                let codes = text.unicodeScalars
                let key = codes[codes.startIndex]
                if key.value < 127 {
                    core_keyPressed(&coreWrapper.core, Int8(key.value))
                }
            }
        }
    }
    
    override func keyUp(with event: NSEvent) {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        switch event.keyCode {
        case 123:
            core_gamepadReleased(&coreWrapper.core, 0, GamepadButtonLeft)
        case 124:
            core_gamepadReleased(&coreWrapper.core, 0, GamepadButtonRight)
        case 125:
            core_gamepadReleased(&coreWrapper.core, 0, GamepadButtonDown)
        case 126:
            core_gamepadReleased(&coreWrapper.core, 0, GamepadButtonUp)
        case 6, 43: // Z, ,
            core_gamepadReleased(&coreWrapper.core, 0, GamepadButtonA)
        case 7, 47: // X, .
            core_gamepadReleased(&coreWrapper.core, 0, GamepadButtonB)
        case 2: // D
            core_gamepadReleased(&coreWrapper.core, 1, GamepadButtonLeft)
        case 5: // G
            core_gamepadReleased(&coreWrapper.core, 1, GamepadButtonRight)
        case 3: // F
            core_gamepadReleased(&coreWrapper.core, 1, GamepadButtonDown)
        case 15: // R
            core_gamepadReleased(&coreWrapper.core, 1, GamepadButtonUp)
        case 0: // A
            core_gamepadReleased(&coreWrapper.core, 1, GamepadButtonA)
        case 1: // S
            core_gamepadReleased(&coreWrapper.core, 1, GamepadButtonB)
        default:
            break
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let coreWrapper = coreWrapper {
            let point = screenPoint(event: event)
            core_touchDragged(&coreWrapper.core, Int32(point.x), Int32(point.y), nil)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if let coreWrapper = coreWrapper {
            let point = screenPoint(event: event)
            if point.y >= 0 {
                core_touchPressed(&coreWrapper.core, Int32(point.x), Int32(point.y), nil)
            }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if let coreWrapper = coreWrapper {
            core_touchReleased(&coreWrapper.core, nil)
        }
    }
    
    func screenPoint(event: NSEvent) -> CGPoint {
        let point = event.locationInWindow
        let viewPoint = window!.contentView!.convert(point, to: lowResNXView)
        let x = viewPoint.x * CGFloat(SCREEN_WIDTH) / lowResNXView.bounds.size.width;
        let y = CGFloat(SCREEN_HEIGHT) - viewPoint.y * CGFloat(SCREEN_HEIGHT) / lowResNXView.bounds.size.height;
        return CGPoint(x: x, y: y);
    }
    
    // MARK: - Core Delegate
    
    func coreInterpreterDidFail(coreError: CoreError) -> Void {
        let nxDocument = document as! LowResNXDocument
        presentError(nxDocument.getProgramError(error: coreError))
    }
    
    func coreDiskDriveWillAccess(diskDataManager: UnsafeMutablePointer<DataManager>?) -> Bool {
        let nxDocument = document as! LowResNXDocument
        
        let panel = NSOpenPanel()
        panel.prompt = "Use as Disk"
        panel.allowedFileTypes = ["nx"]
        panel.beginSheetModal(for: window!, completionHandler: { (response) in
            if response == .OK {
                nxDocument.nxDiskUrl = panel.url
            } else {
                nxDocument.nxDiskUrl = nxDocument.fileURL!.deletingLastPathComponent().appendingPathComponent("disk.nx")
            }
            
            if let nxDiskUrl = nxDocument.nxDiskUrl {
                do {
                    let data = try Data(contentsOf: nxDiskUrl)
                    let error = data.withUnsafeBytes({ (chars: UnsafePointer<Int8>) -> CoreError in
                        data_import(diskDataManager, chars, true)
                    })
                    if error.code != ErrorNone {
                        //TODO
                    }
                } catch let error as NSError {
                    self.presentError(error)
                }
            }
            
            core_diskLoaded(&self.coreWrapper!.core)
        })
        return false
    }
    
    func coreDiskDriveDidSave(diskDataManager: UnsafeMutablePointer<DataManager>?) -> Void {
        let nxDocument = document as! LowResNXDocument
        
        if let diskUrl = nxDocument.nxDiskUrl {
            let output = data_export(diskDataManager)
            if let output = output {
                let data = Data(bytes: output, count: Int(strlen(output)))
                do {
                    try data.write(to: diskUrl)
                } catch let error as NSError {
                    presentError(error)
                }
                free(output);
            } else {
                //TODO
            }
        } else {
            //TODO
        }
    }

}

func interpreterDidFail(context: UnsafeMutableRawPointer?, coreError: CoreError) -> Void {
    let windowController = Unmanaged<LowResNXWindowController>.fromOpaque(context!).takeUnretainedValue()
    windowController.coreInterpreterDidFail(coreError: coreError)
}

func diskDriveWillAccess(context: UnsafeMutableRawPointer?, diskDataManager: UnsafeMutablePointer<DataManager>?) -> Bool {
    let windowController = Unmanaged<LowResNXWindowController>.fromOpaque(context!).takeUnretainedValue()
    return windowController.coreDiskDriveWillAccess(diskDataManager: diskDataManager)
}

func diskDriveDidSave(context: UnsafeMutableRawPointer?, diskDataManager: UnsafeMutablePointer<DataManager>?) -> Void {
    let windowController = Unmanaged<LowResNXWindowController>.fromOpaque(context!).takeUnretainedValue()
    windowController.coreDiskDriveDidSave(diskDataManager: diskDataManager)
}

func controlsDidChange(context: UnsafeMutableRawPointer?, controlsInfo: ControlsInfo) -> Void {
}
