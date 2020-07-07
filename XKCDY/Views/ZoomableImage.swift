import UIKit
import SwiftUI
import Kingfisher

class UIShortTapGestureRecognizer: UITapGestureRecognizer {
    let tapMaxDelay: Double = 0.2 //anything below 0.3 may cause doubleTap to be inaccessible by many users

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        DispatchQueue.main.asyncAfter(deadline: .now() + tapMaxDelay) { [weak self] in
            if self?.state != UIGestureRecognizer.State.recognized {
                self?.state = UIGestureRecognizer.State.failed
            }
        }
    }
}

class ZoomableImage: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    var imageView: UIImageView!
    var singleTapRecognizer: UITapGestureRecognizer!
    var doubleTapRecognizer: UITapGestureRecognizer!
    var onSingleTap: () -> Void = {}

    convenience init(frame f: CGRect, image: UIImageView, onSingleTap: @escaping () -> Void) {
        self.init(frame: f)

        self.onSingleTap = onSingleTap

        imageView = image

        imageView.frame = f
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        setupScrollView()
        setupGestureRecognizer()
    }

    func updateFrame(_ f: CGRect) {
        frame = f
        imageView.frame = f
    }

    private func setupScrollView() {
        delegate = self
        minimumZoomScale = 1.0
        maximumZoomScale = 3.0
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }

    private func setupGestureRecognizer() {
        doubleTapRecognizer = UIShortTapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapRecognizer)

        singleTapRecognizer = UIShortTapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapRecognizer)

        singleTapRecognizer.require(toFail: doubleTapRecognizer)
    }

    @objc private func handleSingleTap() {
        onSingleTap()
    }

    @objc private func handleDoubleTap() {
        if zoomScale == 1 {
            zoom(to: zoomRectForScale(maximumZoomScale, center: doubleTapRecognizer.location(in: doubleTapRecognizer.view)), animated: true)
        } else {
            setZoomScale(1, animated: true)
        }
    }

    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale
        let newCenter = convert(center, from: imageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }

    internal func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

struct ZoomableImageView: UIViewRepresentable {
    var imageURL: URL
    var onSingleTap: () -> Void
    var frame: CGRect = .infinite

    func makeUIView(context: Context) -> ZoomableImage {
        let image = UIImageView()
        image.kf.setImage(with: imageURL)

        return ZoomableImage(frame: frame, image: image, onSingleTap: onSingleTap)
    }

    func updateUIView(_ uiView: ZoomableImage, context: Context) {
        uiView.updateFrame(frame)
    }
}

extension ZoomableImageView {
    func frame(from f: CGRect) -> Self {
        var copy = self
        copy.frame = f

        return copy
    }
}

//struct _OffsetEffect: GeometryEffect {
//    var offset: CGSize
//    
//    var animatableData: CGSize.AnimatableData {
//        get { CGSize.AnimatableData(offset.width, offset.height) }
//        set { offset = CGSize(width: newValue.first, height: newValue.second) }
//    }
//
//    public func effectValue(size: CGSize) -> ProjectionTransform {
//        return ProjectionTransform(CGAffineTransform(translationX: offset.width, y: offset.height))
//    }
//}
//
//extension ZoomableImageView {
//    func selfOffset(_ offset: CGSize) -> Self {
//        return modifier(_OffsetEffect(offset: offset))
//    }
//}
