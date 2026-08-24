import AppKit
import SwiftUI

enum SearchKeyCommand {
    case up
    case down
    case enter
    case escape
}

private final class CommandSearchField: NSSearchField {
    var commandHandler: ((SearchKeyCommand) -> Void)?

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: // Down arrow
            commandHandler?(.down)
        case 126: // Up arrow
            commandHandler?(.up)
        case 36, 76: // Return / keypad Enter
            commandHandler?(.enter)
        case 53: // Escape
            commandHandler?(.escape)
        default:
            super.keyDown(with: event)
        }
    }
}

struct KeyboardSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onCommand: (SearchKeyCommand) -> Void

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: KeyboardSearchField

        init(_ parent: KeyboardSearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSSearchField else { return }
            parent.text = field.stringValue
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let field = CommandSearchField()
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.sendsSearchStringImmediately = true
        field.focusRingType = .default
        field.font = .systemFont(ofSize: 16)
        field.commandHandler = onCommand

        NotificationCenter.default.addObserver(
            forName: .terminalAtFocusSearch,
            object: nil,
            queue: .main
        ) { [weak field] _ in
            guard let field else { return }
            field.window?.makeFirstResponder(field)
            field.selectText(nil)
        }

        DispatchQueue.main.async { [weak field] in
            field?.window?.makeFirstResponder(field)
        }

        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        context.coordinator.parent = self

        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        if let field = nsView as? CommandSearchField {
            field.commandHandler = onCommand
        }
    }
}

extension Notification.Name {
    static let terminalAtFocusSearch = Notification.Name("TerminalAt.FocusSearch")
}
