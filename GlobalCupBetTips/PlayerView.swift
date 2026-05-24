import Foundation

import SwiftUI
import AVKit
import AVFoundation

struct PlayerView: UIViewRepresentable {
    let fileName: String
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
    }
    
    func makeUIView(context: Context) -> UIView {
        return VideoPlayerBackground(fileName: fileName)
    }
}

class VideoPlayerBackground: UIView {
    private let playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    private var player: AVQueuePlayer?
    
    init(fileName: String) {
        super.init(frame: .zero)
        
        // Load the local video from file name
        let fileUrl = Bundle.main.url(forResource: fileName, withExtension: "mp4")!
        let asset = AVAsset(url: fileUrl)
        let item = AVPlayerItem(asset: asset)
        
        // Setup the player
        let player = AVQueuePlayer()
        self.player = player
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        
        // Create a new player looper with the queue player and template item
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        
        // Start the movie
        player.play()
        
        // Add observers for app lifecycle events
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    @objc private func applicationDidEnterBackground() {
        player?.pause()
    }
    
    @objc private func applicationWillEnterForeground() {
        player?.play()
    }
    
    deinit {
        // Remove observers when the view is deallocated
        NotificationCenter.default.removeObserver(self)
    }
}
