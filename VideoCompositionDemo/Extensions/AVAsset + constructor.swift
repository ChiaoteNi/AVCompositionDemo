//
//  AVAsset + constructor.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/10/23.
//

import Foundation
import AVFoundation

extension AVAsset {

    convenience init?(
        for bundleResource: String,
        withExtension fileExtension: String
    ) {
        guard let url = Bundle.main.url(
            forResource: bundleResource,
            withExtension: fileExtension
        ) else {
            return nil
        }
        self.init(url: url)
    }
}
