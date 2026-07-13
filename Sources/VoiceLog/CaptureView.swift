import SwiftUI

struct CaptureView: View {
    @ObservedObject var session: VoiceLogSession
    @FocusState private var focused: Bool

    var body: some View {
        TextEditor(text: $session.text)
            .font(.body)
            .focused($focused)
            .scrollContentBackground(.hidden)
            .padding(12)
            .frame(minWidth: 400, minHeight: 180)
            .background(Color(nsColor: .textBackgroundColor))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    focused = true
                }
            }
            .onDisappear {
                session.flush()
            }
    }
}
