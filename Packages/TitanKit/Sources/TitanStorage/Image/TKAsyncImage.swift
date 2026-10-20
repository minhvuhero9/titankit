import SwiftUI
import UIKit

/// Remote image that goes through the shared ImageCache from the environment.
public struct TKAsyncImage: View {
    private let url: URL?
    private let contentMode: ContentMode
    private let placeholder: Image?

    @Environment(\.imageCache) private var cache
    @State private var image: UIImage?

    public init(url: URL?, contentMode: ContentMode = .fill, placeholder: Image? = nil) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    public var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if let placeholder {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .foregroundStyle(.secondary)
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .task(id: url) {
            image = nil
            guard let url else { return }
            image = try? await cache.image(for: url)
        }
    }
}
