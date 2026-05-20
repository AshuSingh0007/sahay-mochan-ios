import SwiftUI

struct AnxietyHeatmap: View {
    let values: [Double]

    var body: some View {
        GeometryReader { proxy in
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 6)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MochanTheme.purple.opacity(0.2 + min(0.8, value)))
                        .frame(height: max(18, proxy.size.width / 8))
                }
            }
        }
        .frame(height: 160)
    }
}
