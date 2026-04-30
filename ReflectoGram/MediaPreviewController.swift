//
//  MediaPreviewController.swift
//  ReflectoGram
//
//  Created by spytaspund tbf on 12.03.2026.
//

import Foundation
import UIKit

class MediaPreviewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    var mediaID: String = ""
    var mediaURL: String = ""
    private var spinner: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        
        let dTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        dTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(dTap)
        
        setupContent()
    }

    func setupContent() {
        imageView.image = nil
        imageView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        scrollView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        let s = UIActivityIndicatorView(style: .whiteLarge)
        s.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        s.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        s.hidesWhenStopped = true
        view.addSubview(s)
        s.startAnimating()
        self.spinner = s
        
        self.imageView.setRemoteImage(url: mediaURL, cacheKey: "full_\(mediaID)", placeholder: "placeholder")
        stopSpinner()
    }

    private func stopSpinner() {
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
        spinner = nil
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let subView = imageView
        let offsetX = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0)
        let offsetY = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0)
        
        subView?.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                                 y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let pointInView = gesture.location(in: imageView)
            let zoomRect = CGRect(x: pointInView.x - 50, y: pointInView.y - 50, width: 100, height: 100)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }

    @IBAction func doneTapped(_ sender: Any) {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
