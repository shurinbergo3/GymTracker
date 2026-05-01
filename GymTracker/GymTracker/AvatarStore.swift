//
//  AvatarStore.swift
//  GymTracker
//
//  Local storage for the user's chosen avatar photo.
//  File-based, per-UID, JPEG-compressed.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class AvatarStore: ObservableObject {
    static let shared = AvatarStore()

    /// Reactive token — bumped whenever the avatar changes so SwiftUI re-renders.
    @Published private(set) var version: Int = 0

    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Paths

    private var documentsDir: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private func fileURL(for uid: String) -> URL? {
        documentsDir?.appendingPathComponent("avatar_\(uid).jpg")
    }

    /// Returns the avatar file URL for the current user, if any.
    func currentFileURL(uid: String?) -> URL? {
        guard let uid, !uid.isEmpty, let url = fileURL(for: uid) else { return nil }
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Mutations

    /// Save raw image data (already loaded from PhotosPicker).
    /// Down-scales to 1024 px max and re-encodes as JPEG 0.85.
    @discardableResult
    func save(_ rawData: Data, for uid: String?) -> Bool {
        guard let uid, !uid.isEmpty, let url = fileURL(for: uid) else { return false }
        guard let image = UIImage(data: rawData) else { return false }

        let resized = image.downscaled(maxDimension: 1024)
        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { return false }

        do {
            try jpeg.write(to: url, options: .atomic)
            bumpVersion()
            return true
        } catch {
            #if DEBUG
            print("⚠️ AvatarStore: failed to save avatar — \(error)")
            #endif
            return false
        }
    }

    /// Remove the user's avatar file.
    func clear(uid: String?) {
        guard let uid, !uid.isEmpty, let url = fileURL(for: uid) else { return }
        try? fileManager.removeItem(at: url)
        bumpVersion()
    }

    private func bumpVersion() {
        version &+= 1
    }
}

// MARK: - UIImage helpers

private extension UIImage {
    /// Down-scale (preserving aspect ratio) so the longest side is `maxDimension`.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
