//
//  EventMonitors.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import Cocoa
import Combine

class EventMonitors {
    static let shared = EventMonitors()

    private var mouseMoveEvent: EventMonitor!
    private var mouseDownEvent: EventMonitor!
    private var enterDownEvent: EventMonitor!
    private var escapeDownEvent: EventMonitor!

    let mouseLocation: CurrentValueSubject<NSPoint, Never> = .init(.zero)
    let mouseDown: PassthroughSubject<Void, Never> = .init()
    let enterDown: PassthroughSubject<Void, Never> = .init()
    let escapeDown: PassthroughSubject<Void, Never> = .init()

    private init() {
        mouseMoveEvent = EventMonitor(mask: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            let mouseLocation = NSEvent.mouseLocation
            self.mouseLocation.send(mouseLocation)
        }
        mouseMoveEvent.start()

        mouseDownEvent = EventMonitor(mask: .leftMouseDown) { [weak self] _ in
            guard let self else { return }
            mouseDown.send()
        }
        mouseDownEvent.start()
        
        enterDownEvent = EventMonitor(mask: .keyDown) { [weak self] event in
            guard let self else { return }
            if event?.specialKey == .carriageReturn || event?.specialKey == .enter {
                enterDown.send()
            }
        }
        enterDownEvent.start()
        
        escapeDownEvent = EventMonitor(mask: .keyDown) { [weak self] event in
            guard let self else { return }
            if event?.keyCode == 53 {
                escapeDown.send()
            }
        }
        escapeDownEvent.start()
    }
}
