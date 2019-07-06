//
//  XOVideoRequestTask.swift
//  XOVideoCache
//
//  Created by luo fengyuan on 2019/7/1.
//  Copyright © 2019 luo fengyuan. All rights reserved.
//

import Foundation

protocol XOVideoRequestTaskDelegate {
    func task(_ task: XOVideoRequestTask, didReceiveVideoLength videoLength: Int,mimeType:String)
    func didReceiveVideoDataWithTask(_ task: XOVideoRequestTask)
    func didFinishLoadingWithTask(_ task: XOVideoRequestTask)
    func didFailLoadingWithTask(_ task: XOVideoRequestTask, error: Error)
}

open class XOVideoRequestTask {
    
    private var _url: URL?
    
    private var _offset: Int = 0
    
    open var videoLength: Int = 0
    
    private var _downLoadingOffset: Int = 0
    
    open var mimeType = ""
    
    open var isFinishLoad: Bool = false
    
    private var _connection: NSURLConnection?
    
    private var _tasks = [NSURLConnection]()
    
    
    private var _fileHandle: FileHandle?
    
    private var _filePath: URL?
    
    
    
    init() {
        
    }
    
    func set(url: URL, offset: Int) {
        _url = url
        _offset = offset
        
        if self._tasks.count > 0 {
            //如果建立第二次请求，先移除原来文件，再创建新的
        }
        
        _downLoadingOffset = 0;
        
        
    }
    
    func cancel() {
        
    }
    
    func continueLoading() {
        
    }
    
    func clear() {
        
    }
}
