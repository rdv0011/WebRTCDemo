//
// Copyright © 2019 Dmitry Rybakov. All rights reserved.
    

import ReplayKit
import WebRTC
import WebRTCDemoSignalling
import os.log

class WebRTCDemoBroadcastSampleHandler: RPBroadcastSampleHandler {
    let client: ARDAppClient = ARDAppClient()
    let logging = RTCCallbackLogger()
    let sharedSettings = UserDefaults(suiteName: .sharedGroupName)
    var capturer: ARDExternalSampleDelegate?

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        self.logging.start { (logMessage: String, _) in
            OSLog.info(logMessage: logMessage, log: OSLog.webRTC)
        }
        let roomID = sharedSettings?.string(forKey: .broadcastRoomIDKey) ?? String.broadcastRandomRoomID
        let settings = ARDSettingsModel()
        client.isBroadcast = true
        client.delegate = self
        client.connectToRoom(withId: roomID, settings: settings, isLoopback: false)

        let logMessage = "Try to connect to room \(roomID)"
        OSLog.info(logMessage: logMessage, log: OSLog.broadcastExtension)
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        self.logging.stop()
        self.client.disconnect()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            capturer?.didCapture(sampleBuffer)
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}

extension WebRTCDemoBroadcastSampleHandler: ARDAppClientDelegate {
    func appClient(_ client: ARDAppClient!, didChange state: ARDAppClientState) {
    }

    func appClient(_ client: ARDAppClient!, didChange state: RTCIceConnectionState) {
    }

    func appClient(_ client: ARDAppClient!, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack!) {
    }

    func appClient(_ client: ARDAppClient!, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack!) {
    }

    func appClient(_ client: ARDAppClient!, didCreateLocalExternalSampleCapturer externalSampleCapturer: ARDExternalSampleCapturer!) {
        self.capturer = externalSampleCapturer
    }

    func appClient(_ client: ARDAppClient!, didError error: Error!) {
    }

    func appClient(_ client: ARDAppClient!, didGetStats stats: [Any]!) {
    }

}

