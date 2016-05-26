//
//  ViewController.swift
//  VideoPlayer
//
//  Created by Mihael Isaev on 26/05/16.
//  Copyright © 2016 Mihael Isaev. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,  AVAssetResourceLoaderDelegate, NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate {

    enum PlayerMode {
        case Local, Stream
    }
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    let videoURL = NSURL(string: "http://alohabrowser.com/tmp/test_video.mp4")!
    
    var player: AVPlayer?
    var playerMode: PlayerMode?
    var dataToDownload = NSMutableData()
    var downloadSize: Int64 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadButton.setTitle(checkVideoAlreadySaved() ? "Play local" : "Download", forState: .Normal)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    func createPlayer(url: NSURL) {
        if let playerLayer = view.layer.sublayers?.last as? AVPlayerLayer {
            playerLayer.removeFromSuperlayer()
        }
        player?.pause()
        player = AVPlayer(URL: url)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = playerView.bounds
        view.layer.addSublayer(playerLayer)
    }
    
    func checkPlayerMode(mode: PlayerMode) -> Bool {
        if playerMode == mode {
            if player?.rate == 1 {
                player?.pause()
            } else {
                player?.play()
            }
            return true
        }
        return false
    }
    
    @IBAction func play() {
        if checkPlayerMode(.Stream) {
            return
        }
        playerMode = .Stream
        createPlayer(videoURL)
        player?.play()
    }
    
    func checkVideoAlreadySaved() -> Bool {
        return NSFileManager().fileExistsAtPath(savedVideoURL().path!)
    }
    
    func savedVideoURL() -> NSURL {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return documentsUrl.URLByAppendingPathComponent(videoURL.lastPathComponent!)
    }
    
    @IBAction func download() {
        if checkVideoAlreadySaved() {
            if checkPlayerMode(.Local) {
                return
            }
            playerMode = .Local
            createPlayer(savedVideoURL())
            player?.play()
        } else {
            let sessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.mihaelisaev.backgroundDownload")
            sessionConfig.allowsCellularAccess = true
            
            let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
            let downloadTask = session.downloadTaskWithURL(videoURL)
            downloadTask.resume()
            progressView.hidden = false
            downloadButton.enabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Rotation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (context) in
            let playerLayer = self.view.layer.sublayers?.last as! AVPlayerLayer
            playerLayer.frame = self.playerView.bounds
        }) { (context) in
            
        }
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
    
    //MARK: NSURLSession Delegate
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progressView.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let data = NSData(contentsOfURL: location)
        do {
            try data?.writeToURL(savedVideoURL(), options: .AtomicWrite)
        } catch let error as NSError {
            print("save error: \(error)")
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        progressView.hidden = true
        downloadButton.setTitle("Play local", forState: .Normal)
        downloadButton.enabled = true
    }
}

