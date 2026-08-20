import SwiftUI

struct StatusPane: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StatusHero()
                if let error = controller.lastError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
                PackageList()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
