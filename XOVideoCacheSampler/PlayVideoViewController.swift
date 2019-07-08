//
//  PlayVideoViewController.swift
//  XOVideoCacheSampler
//
//  Created by luo fengyuan on 2019/7/8.
//  Copyright © 2019 luo fengyuan. All rights reserved.
//

//import XOVideoCache
import UIKit
import AVKit

class PlayVideoViewController: UIViewController {
    
    private
    var _player: AVPlayer? //播放器对象
    private
    var _playerItem: CachingPlayerItem? //播放资源对象
    private
    var _timeObserver: Any! //时间观察者
    private
    var _playerLayer: AVPlayerLayer?
    
    var resourceURL: URL!
    
//    var cacheFile: URL!
//    var fileHandle: FileHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let url = resourceURL else {
            fatalError()
        }
        //AVPlayerItem(url: url) //
        self._playerItem = CachingPlayerItem(url: url, customFileExtension: url.lastPathComponent)
        self._playerItem?.delegate = self
//        self._playerItem?.download()
        
        self._player = AVPlayer(playerItem: self._playerItem)
        self._playerLayer = AVPlayerLayer(player: self._player)
        if #available(iOS 11.0, *) {
            self._playerLayer?.frame = self.view.bounds.inset(by: self.view.safeAreaInsets)
        } else {
            // Fallback on earlier versions
            self._playerLayer?.frame = self.view.bounds
        }
        self._playerLayer?.videoGravity = .resizeAspect //视频填充模式
        
        self.view.layer.addSublayer(self._playerLayer!)
//        __addPlayerItemObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self._player?.pause()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
#if false
//    private
    func __addPlayerItemObserver() {
        // 为AVPlayerItem添加status属性观察，得到资源准备好，开始播放视频
        _playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        // 监听AVPlayerItem的loadedTimeRanges属性来监听缓冲进度更新
        _playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(__playerItemDidReachEnd(notification:)),name: .AVPlayerItemDidPlayToEndTime, object: _playerItem)
    }
    
    //  通过KVO监控播放器状态
    //
    // - parameter keyPath: 监控属性
    // - parameter object:  监视器
    // - parameter change:  状态改变
    // - parameter context: 上下文
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard let object = object as? AVPlayerItem  else { return }
        guard let keyPath = keyPath else { return }

        if keyPath == "status" {
            if object.status == .readyToPlay { //当资源准备好播放，那么开始播放视频
//                SVProgressHUD.dismiss()
                _player?.play()
                debugPrint("开始播放")
//                _durationLabel.text = __formatPlayTime(seconds: CMTimeGetSeconds(object.duration))
                self.__addProgressObserver()
            } else if object.status == .failed || object.status == .unknown {
                //                print("播放出错")
                debugPrint("播放出错")
//                SVProgressHUD.showError(withStatus: "播放失败")
//                SVProgressHUD.dismiss(withDelay: 1.25)
            }
        } else if keyPath == "loadedTimeRanges" {
            // 喊出进度
            let loadedTime = __availableDurationWithplayerItem()
            //            debugLog("当前加载进度\(loadedTime)")
        }
    }
    
    // 将秒转成时间字符串的方法，因为我们将得到秒。
    private
    func __formatPlayTime(seconds: Float64) -> String {
        let min = Int(seconds / 60)
        let sec = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", min, sec)
    }
    
    
    @objc
    private func __playerItemDidReachEnd(notification: Notification) {
        _player?.seek(to: CMTime.zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
//        _progress.progress = 0.0
//        _playOrPauseButton.isSelected = true
//        _playOrPauseButton1.setImage(#imageLiteral(resourceName: "video_play"), for: UIControl.State.normal)
    }
    
    private
    func __availableDurationWithplayerItem() -> TimeInterval {
        guard let loadedTimeRanges = _player?.currentItem?.loadedTimeRanges,
            let first = loadedTimeRanges.first else {
                fatalError()
        }
        // 本次缓冲时间范围
        let timeRange = first.timeRangeValue
        let startSeconds = CMTimeGetSeconds(timeRange.start) // 本次缓冲起始时间
        let durationSecound = CMTimeGetSeconds(timeRange.duration)// 缓冲时间
        let result = startSeconds + durationSecound// 缓冲总长度
        return result
    }
    
    private
    func __addProgressObserver(){
        // 这里设置每秒执行一次.
        _timeObserver = _player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: Int64(1.0),timescale: Int32(1.0)),queue: DispatchQueue.main) { [weak self] (time: CMTime) in
            self?.__updateProgress(time)
        }
    }
    private var _totalTime: Float64 = 0
    private
    func __updateProgress(_ time: CMTime) {
        // CMTimeGetS econds函数是将CMTime转换为秒，如果CMTime无效，将返回NaN
        guard let playerItem = _playerItem else {
            return
        }
        let currentTime = CMTimeGetSeconds(time)
        let totalTime = CMTimeGetSeconds(playerItem.duration)
        // 更新显示的时间和进度条
        //        debugLog("显示进度", totalTime)
//        if totalTime > 6000 {
//            self._progress.progress = 0
//        } else {
//            self._timeLabel.text = self.__formatPlayTime(seconds: CMTimeGetSeconds(time))
//            let value = Float(currentTime/totalTime)
//            //            debugLog("设置播放进度", currentTime, totalTime, value)
//            if value == 0.0 {
//                self._progress.progress = 0
//            }else {
//                self._progress.setProgress(Float(currentTime/totalTime), animated: true)
//            }
//
//
//        }
        
    }
    
    @objc private
    func __playOrPauseButtonClicked(button: UIButton) {
        if let player = _player {
            if player.rate == 0 { // 点击时已暂停
                //                button.setImage(UIImage(named:"pause"), for: .normal)
//                _playOrPauseButton1.setImage(nil, for: UIControl.State.normal)
//                _playOrPauseButton.isSelected = false
                player.play()
                
            } else if player.rate == 1 {// 点击时正在播放
                player.pause()
//                _playOrPauseButton1.setImage(#imageLiteral(resourceName: "video_play"), for: UIControl.State.normal)
//                _playOrPauseButton.isSelected = true
            }
        }
    }
    private
    func __removeObserver() {
        _playerItem?.removeObserver(self, forKeyPath: "status")
        _playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        if let ob = _timeObserver {
            _player?.removeTimeObserver(ob)
        }
        NotificationCenter.default.removeObserver(self,name: .AVPlayerItemDidPlayToEndTime,object: _playerItem)
    }
    
    
    private
    func __didTapPreviewVideo() {
        
    }
    
    deinit {
        __removeObserver()
    }
    #endif
}

extension PlayVideoViewController: CachingPlayerItemDelegate {
    
    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        debugPrint("开始播放")
        _player?.play()
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        
    }
    
    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
        
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        debugPrint("视频下载完成", data.count)
        _player?.pause()
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didReceive data: Data, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        
    }
    

}
