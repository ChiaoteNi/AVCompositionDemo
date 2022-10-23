//
//  BasicDemoVC.swift
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/9/11.
//

import UIKit
import AVFoundation
import AVKit

final class DemoVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction private func play() {
        let demo: PlayerItemMaker = {
//            BasicDemo()
//            SequentialPlayDemo()
//            ParallelPlayDemo()
            WatermarkDemo()
        }()

        guard let playerItem = demo.makePlayerItem() else {
            return
        }
        let player = AVPlayer(playerItem: playerItem)
        let playerVC = AVPlayerViewController()
            .set(\.player, to: player)
        navigationController?.pushViewController(playerVC, animated: true)

        player.play()
    }
}
