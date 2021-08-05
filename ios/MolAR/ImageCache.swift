//
//  ImageCache.swift
//  MolAR
//
//  Created by Sukolsak on 3/11/21.
//

// Based on https://developer.apple.com/documentation/uikit/views_and_controls/table_views/asynchronously_loading_images_into_table_and_collection_views

import UIKit
import Foundation

public class ImageCache {

    public static let publicCache = ImageCache()
    var placeholderImage = UIImage(named: "Blank")! //UIImage(systemName: "rectangle")!
    private let cachedImages = NSCache<NSURL, UIImage>()
    private var loadingResponses = [NSURL: [(UIImage?) -> Swift.Void]]()

    // private let concurrentQueue = DispatchQueue(label: "com.sukolsak.queue", attributes: .concurrent)


    private final func image(url: NSURL) -> UIImage? {
        return cachedImages.object(forKey: url)
    }
    /// - Tag: cache
    // Returns the cached image if available, otherwise asynchronously loads and caches it.
    final func load(url: NSURL, item: Item, completion: @escaping (UIImage?) -> Swift.Void) {
        // Check for a cached image.
        if let cachedImage = image(url: url) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        // In case there are more than one requestor for the image, we append their completion block.
        if loadingResponses[url] != nil {
            loadingResponses[url]?.append(completion)
            return
        } else {
            loadingResponses[url] = [completion]
        }
        // Go fetch the image.
        /*
        let task = URLSession.shared.dataTask(with: url as URL) {(data, response, error) in
            guard let data = data,
                  let httpURLResponse = response as? HTTPURLResponse,
                  error == nil,
                  httpURLResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    // completion(item, nil)
                    self.loadingResponses.removeValue(forKey: url)
                }
                return
            }
            DispatchQueue.main.async {
                // Cache the image.
                self.cachedImages.setObject(image, forKey: url, cost: data.count)
                // Iterate over each requestor for the image and pass it back.
                if let blocks = self.loadingResponses[url] {
                    for block in blocks {
                        block(image)
                    }
                    self.loadingResponses.removeValue(forKey: url)
                }
            }
        }
        task.resume()
         */

        item.getImage() { image in
            guard let image = image else {
                DispatchQueue.main.async {
                    // completion(item, nil)
                    self.loadingResponses.removeValue(forKey: url)
                }
                return
            }

            DispatchQueue.main.async {
                // Cache the image.
                self.cachedImages.setObject(image, forKey: url, cost: 0)
                // Iterate over each requestor for the image and pass it back.
                if let blocks = self.loadingResponses[url] {
                    for block in blocks {
                        block(image)
                    }
                    self.loadingResponses.removeValue(forKey: url)
                }
            }
        }
    }

}
