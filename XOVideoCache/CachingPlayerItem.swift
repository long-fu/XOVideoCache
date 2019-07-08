//
//  CachingPlayerItem.swift
//  XOVideoCache
//
//  Created by luo fengyuan on 2019/7/8.
//  Copyright © 2019 luo fengyuan. All rights reserved.
//

import Foundation
import AVFoundation

fileprivate extension URL {
    
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
    
}

@objc public protocol CachingPlayerItemDelegate {
    
    /// Is called when the media file is fully downloaded.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
    
    /// Is called every time a new portion of data is received.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didReceive data: Data ,didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
    
    /// Is called after initial prebuffering is finished, means
    /// we are ready to play.
    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)
    
    /// Is called when the data being downloaded did not arrive in time to
    /// continue playback.
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)
    
    /// Is called on downloading error.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
    
}

struct VideoInfoCache {
    static var shared = VideoInfoCache()
    lazy var cache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>.init()
        cache.countLimit = 500
        cache.name = "Cache_Video"
        cache.totalCostLimit = 1024 * 1024
        return cache
    }()
}

class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    var cache: NSCache<AnyObject, AnyObject> = VideoInfoCache.shared.cache
    
    var playingFromData = false
    var mimeType: String? // is required when playing from Data
    var session: URLSession?
    var mediaData: Data?
    var response: URLResponse?
    var pendingRequests = Set<AVAssetResourceLoadingRequest>()
    
    lazy var documentDirectory: URL = {
        guard let documentDirectory = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            fatalError()
        }
        return documentDirectory
    }()
    
    var url: URL?
    var length: UInt64 = 0
    var offset: UInt64 = 0
    var cachePath: URL?
    weak var owner: CachingPlayerItem?
    var fileHandle: FileHandle?
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        if playingFromData {
            
            // Nothing to load.
            
        } else if session == nil {
            
            // If we're playing from a url, we need to download the file.
            // We start loading the file on first request only.
            guard let initialUrl = owner?.url else {
                fatalError("internal inconsistency")
            }
            
            startDataRequest(with: initialUrl)
        }
        
        pendingRequests.insert(loadingRequest)
        processPendingRequests()
        return true
        
    }
    
    func startDataRequest(with url: URL) {
        self.url = url
        
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        cachePath = documentDirectory.appendingPathComponent(url.lastPathComponent, isDirectory: false)
        if FileManager.default.fileExists(atPath: cachePath!.path) {
            
            guard let st = cache.object(forKey: url.lastPathComponent as AnyObject) as? String else {
                fatalError()
            }
            
            let ar = st.components(separatedBy: ",")
            guard let length = UInt64(ar[2]),let offset = UInt64(ar[3]) else {
                fatalError()
            }
            
            
            self.offset = offset
            self.length = length
            self.mediaData = try! Data.init(contentsOf: cachePath!)
            self.mimeType = ar[1]
            self.playingFromData = true
            
            if offset == length - 1 {
                debugPrint("数据已经下载完成")
            }
            
            if configuration.httpAdditionalHeaders == nil {
                configuration.httpAdditionalHeaders = ["Range":"bytes=\(offset)=\(length)"]
            } else {
                configuration.httpAdditionalHeaders?["Range"] = "bytes=\(offset)=\(length)"
            }
            debugPrint("断点续传", "\(offset)/\(length)")
        } else {
            debugPrint("没有缓存数据")
        }
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session?.dataTask(with: url).resume()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests.remove(loadingRequest)
    }
    
    // MARK: URLSession delegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        mediaData?.append(data)
        fileHandle?.write(data)
        guard let url = self.url,let mimeType = self.mimeType else {
            return
        }
        
        // 更新缓存结构
        let sring = "\(url.lastPathComponent),\(mimeType),\(length),\(data.count)"
        debugPrint("更新缓存数据",sring)
        cache.setObject(sring as AnyObject, forKey: url.lastPathComponent as AnyObject, cost: data.count)
        
        processPendingRequests()
        owner?.delegate?.playerItem?(owner!,didReceive: data, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(Foundation.URLSession.ResponseDisposition.allow)
        mediaData = Data()
        
        guard let url = self.url else {
            return
        }
        let mimeType = response.mimeType ?? "video/mp4"
        
        self.mimeType = mimeType
        self.length = UInt64(response.expectedContentLength)
        self.offset = 0
        
        debugPrint("开始响应", mimeType , response.expectedContentLength, url)
        cachePath = documentDirectory.appendingPathComponent(url.lastPathComponent, isDirectory: false)
        
        if FileManager.default.fileExists(atPath: cachePath!.path) {
            fileHandle = try! FileHandle(forWritingTo: cachePath!)
            mediaData = fileHandle?.readDataToEndOfFile()
            self.offset = UInt64(mediaData?.count ?? 0)
        } else {
            // 创建缓存文件
            FileManager.default.createFile(atPath: cachePath!.path, contents: nil, attributes: nil)
            fileHandle = try! FileHandle(forWritingTo: cachePath!)
        }
        
        // 创建缓存数据结构
        if cache.object(forKey: url.lastPathComponent as AnyObject) == nil {
            let sring = "\(url.lastPathComponent),\(mimeType),\(response.expectedContentLength),0"
            cache.setObject(sring as AnyObject, forKey: url.lastPathComponent as AnyObject, cost: 0)
        } else {
            debugPrint("存在cache")
        }
        
        self.response = response
        processPendingRequests()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let errorUnwrapped = error {
            owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
            return
        }
        debugPrint("数据接收完成",mediaData?.count ?? 0)
        processPendingRequests()
        owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
    }
    
    // MARK: -
    
    func processPendingRequests() {
        
        // get all fullfilled requests
        let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
            self.fillInContentInformationRequest($0.contentInformationRequest)
            if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
                $0.finishLoading()
                return $0
            }
            return nil
        })
        
        // remove fulfilled requests from pending requests
        _ = requestsFulfilled.map { self.pendingRequests.remove($0) }
        
    }
    
    func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
        
        // if we play from Data we make no url requests, therefore we have no responses, so we need to fill in contentInformationRequest manually
        if playingFromData {
            contentInformationRequest?.contentType = self.mimeType
            contentInformationRequest?.contentLength = Int64(mediaData!.count)
            contentInformationRequest?.isByteRangeAccessSupported = true
            return
        }
        
        guard let responseUnwrapped = response else {
            // have no response from the server yet
            return
        }
        
        contentInformationRequest?.contentType = responseUnwrapped.mimeType
        contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
        contentInformationRequest?.isByteRangeAccessSupported = true
        
    }
    
    func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        
        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength
        let currentOffset = Int(dataRequest.currentOffset)
        
        guard let songDataUnwrapped = mediaData,
            songDataUnwrapped.count > currentOffset else {
                // Don't have any data at all for this request.
                return false
        }
        
        let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
        let dataToRespond = songDataUnwrapped.subdata(in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond)))
        dataRequest.respond(with: dataToRespond)
        
        return songDataUnwrapped.count >= requestedLength + requestedOffset
        
    }
    
    deinit {
        session?.invalidateAndCancel()
    }
    
}

open class CachingPlayerItem: AVPlayerItem {
    
    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()
    fileprivate let url: URL
    fileprivate let initialScheme: String?
    fileprivate var customFileExtension: String?
    
    open var delegate: CachingPlayerItemDelegate?
    
    open func download() {
        if resourceLoaderDelegate.session == nil {
            resourceLoaderDelegate.startDataRequest(with: url)
        }
    }
    
    private let cachingPlayerItemScheme = "cachingPlayerItemScheme"
    
    /// Is used for playing remote files.
    convenience init(url: URL) {
        self.init(url: url, customFileExtension: nil)
    }
    
    /// Override/append custom file extension to URL path.
    /// This is required for the player to work correctly with the intended file type.
    public init(url: URL, customFileExtension: String?) {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let scheme = components.scheme,
            var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
                fatalError("Urls without a scheme are not supported")
        }
        
        self.url = url
        self.initialScheme = scheme
        
        if let ext = customFileExtension {
            urlWithCustomScheme.deletePathExtension()
            urlWithCustomScheme.appendPathExtension(ext)
            self.customFileExtension = ext
        }
        
        let asset = AVURLAsset(url: urlWithCustomScheme)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        
        resourceLoaderDelegate.owner = self
        
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
        
    }
    
    /// Is used for playing from Data.
    public init(data: Data, mimeType: String, fileExtension: String) {
        
        guard let fakeUrl = URL(string: cachingPlayerItemScheme + "://whatever/file.\(fileExtension)") else {
            fatalError("internal inconsistency")
        }
        
        self.url = fakeUrl
        self.initialScheme = nil
        
        resourceLoaderDelegate.mediaData = data
        resourceLoaderDelegate.playingFromData = true
        resourceLoaderDelegate.mimeType = mimeType
        
        let asset = AVURLAsset(url: fakeUrl)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        resourceLoaderDelegate.owner = self
        
//        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        // 为AVPlayerItem添加status属性观察，得到资源准备好，开始播放视频
        addObserver(self, forKeyPath: "status", options: .new, context: nil)
        // 监听AVPlayerItem的loadedTimeRanges属性来监听缓冲进度更新
        addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
        
    }
    
    // MARK: KVO
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let object = object as? AVPlayerItem  else { return }
        guard let keyPath = keyPath else { return }
        
        if keyPath == "status" {
            if object.status == .readyToPlay { //当资源准备好播放，那么开始播放视频
                delegate?.playerItemReadyToPlay?(self)
                
            } else if object.status == .failed || object.status == .unknown {
                
            }
        } else if keyPath == "loadedTimeRanges" {
            // 喊出进度
            debugPrint("数据缓冲进度")
//            let loadedTime = __availableDurationWithplayerItem()
        }
        
        
    }
    
    // MARK: Notification hanlers
    
    @objc func playbackStalledHandler() {
        delegate?.playerItemPlaybackStalled?(self)
    }
    
    // MARK: -
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObserver(self, forKeyPath: "status")
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }
    
}
