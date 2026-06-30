//
//  AnimatedExerciseImage.swift
//  GymTracker
//
//  Воспроизведение GIF-демонстраций упражнений из бандла (asset catalog, Data Set).
//

import SwiftUI
import UIKit
import ImageIO

enum ExerciseAnimations {
    /// Глобальный переключатель анимаций. Если по какой-то причине их нужно
    /// убрать - выключаем здесь, и весь UI откатывается на отсутствие демо.
    static var enabled = true
}

/// Декодированная и закэшированная анимация.
private final class GifCache {
    static let shared = GifCache()
    private let cache = NSCache<NSString, UIImage>()

    func animatedImage(for assetName: String) -> UIImage? {
        if let cached = cache.object(forKey: assetName as NSString) { return cached }
        guard let data = NSDataAsset(name: assetName)?.data,
              let img = UIImage.animated(from: data) else { return nil }
        cache.setObject(img, forKey: assetName as NSString)
        return img
    }
}

private extension UIImage {
    /// Собирает анимированный UIImage из данных GIF с учётом задержек кадров.
    /// UIImage.animatedImage распределяет общую длительность поровну между кадрами,
    /// поэтому, чтобы соблюсти разные задержки (например паузу в верхней точке),
    /// раскладываем кадры на равный шаг и повторяем каждый пропорционально его задержке.
    static func animated(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else {
            if let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) { return UIImage(cgImage: cg) }
            return nil
        }

        var images: [UIImage] = []
        var delays: [Double] = []
        for i in 0..<count {
            guard let cg = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            images.append(UIImage(cgImage: cg))
            delays.append(frameDelay(source, i))
        }
        guard !images.isEmpty else { return nil }

        let step = delays.filter { $0 > 0 }.min() ?? 0.1
        var frames: [UIImage] = []
        for (img, delay) in zip(images, delays) {
            let repeats = max(1, Int((delay / step).rounded()))
            frames.append(contentsOf: repeatElement(img, count: repeats))
        }
        let total = step * Double(frames.count)
        return UIImage.animatedImage(with: frames, duration: total)
    }

    static func frameDelay(_ source: CGImageSource, _ index: Int) -> Double {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = props[kCGImagePropertyGIFDictionary] as? [CFString: Any] else { return 0.1 }
        let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gif[kCGImagePropertyGIFDelayTime] as? Double
        let delay = unclamped ?? clamped ?? 0.1
        return delay < 0.02 ? 0.1 : delay
    }
}

/// Показывает GIF-анимацию упражнения по имени ассета (Data Set в каталоге).
struct AnimatedExerciseImage: View {
    let assetName: String
    var contentMode: UIView.ContentMode = .scaleAspectFit

    var body: some View {
        if ExerciseAnimations.enabled, let image = GifCache.shared.animatedImage(for: assetName) {
            GifImageView(image: image, contentMode: contentMode)
        }
    }
}

private struct GifImageView: UIViewRepresentable {
    let image: UIImage
    let contentMode: UIView.ContentMode

    func makeUIView(context: Context) -> UIImageView {
        let v = UIImageView()
        v.contentMode = contentMode
        v.clipsToBounds = true
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        v.setContentHuggingPriority(.defaultLow, for: .vertical)
        return v
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
        uiView.startAnimating()
    }
}
