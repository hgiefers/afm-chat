import SwiftUI

#if os(macOS)
import AppKit

/// Mehrzeiliges Eingabefeld auf AppKit-Basis, weil SwiftUIs `TextField`/`onKeyPress`
/// die Return-Taste bei einem mehrzeiligen Feld intern verschluckt, bevor sich
/// Enter (senden) und Shift+Enter (Zeilenumbruch) sauber unterscheiden lassen.
/// `NSTextView.doCommandBy:` bekommt den Tastendruck dagegen zuverlässig vor der
/// Standardverarbeitung zu sehen.
struct ChatInputTextView: NSViewRepresentable {
    @Binding var text: String
    var isDisabled: Bool
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainerInset = NSSize(width: 0, height: 6)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        textView.isEditable = !isDisabled
        context.coordinator.onSubmit = onSubmit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var onSubmit: () -> Void
        weak var textView: NSTextView?

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            self.text = text
            self.onSubmit = onSubmit
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
            let shiftHeld = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
            if shiftHeld {
                return false // Standardverhalten: Zeilenumbruch einfügen
            }
            onSubmit()
            return true // Tastendruck verbraucht, kein Zeilenumbruch
        }
    }
}

#elseif os(iOS)
import UIKit

/// iOS-Variante: Touch-Tastaturen kennen kein verlässliches "Shift"-Signal beim
/// Tippen von Return, daher gilt hier die auf iOS übliche Konvention – Return
/// fügt immer einen Zeilenumbruch ein, gesendet wird über den sichtbaren
/// Senden-Button. An eine externe Tastatur angeschlossen (iPad) sendet
/// zusätzlich ⌘+Return, per `UIKeyCommand`.
struct ChatInputTextView: UIViewRepresentable {
    @Binding var text: String
    var isDisabled: Bool
    var onSubmit: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = SubmittableTextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        textView.onCommandReturn = { context.coordinator.onSubmit() }
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
        textView.isEditable = !isDisabled
        context.coordinator.onSubmit = onSubmit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var onSubmit: () -> Void

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            self.text = text
            self.onSubmit = onSubmit
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }

    private final class SubmittableTextView: UITextView {
        var onCommandReturn: (() -> Void)?

        override var keyCommands: [UIKeyCommand]? {
            [UIKeyCommand(input: "\r", modifierFlags: .command, action: #selector(handleCommandReturn))]
        }

        @objc private func handleCommandReturn() {
            onCommandReturn?()
        }
    }
}
#endif
