//
//  ColorServiceManager.swift
//  ConnectedColors
//
//  Created by Ralf Ebert on 28/04/15.
//  Copyright (c) 2015 Ralf Ebert. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol GameServiceManagerDelegate {
    
    func connectedDevicesChanged(_ manager : GameServiceManager, connectedDevices: [String])
    
    func receiveMove(_ manager : GameServiceManager, toPosition : CGPoint, rotation: CGFloat)
    //func colorChanged(_ manager : GameServiceManager, colorString: String)
    
}

class GameServiceManager : NSObject {
    
    fileprivate let GameServiceType = "example-color"
    fileprivate let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    fileprivate let serviceAdvertiser : MCNearbyServiceAdvertiser
    fileprivate let serviceBrowser : MCNearbyServiceBrowser
    var delegate : GameServiceManagerDelegate?
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: GameServiceType)

        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: GameServiceType)

        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.required)
        session.delegate = self
        return session
    }()

    func sendMove(_ position : CGPoint, rotation: CGFloat) {
        NSLog("%@", "send position: \(position)")
        // sender
        var pointToSend = (position, rotation)
        
        let pairToSend = (Double(pointToSend.0.x), Double(pointToSend.0.y), Double(rotation))
        let data = NSData(bytes: &pointToSend, length: MemoryLayout.size(ofValue: pairToSend))
        
        do {
            _ = try self.session.send(data as Data, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
        } catch {
            print("error: \(error)")
        }
        
        /*
        do {
            _ = try self.session.send(position.data(using: String.Encoding.utf8, allowLossyConversion: false)!, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
        } catch {
            print("error: \(error)")
        }*/
        
    }

    
}


//------------------------------------------------------------//

extension GameServiceManager : MCNearbyServiceAdvertiserDelegate {
    @available(iOS 7.0, *)
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)

    }

    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
}

extension GameServiceManager : MCNearbyServiceBrowserDelegate {
    @available(iOS 7.0, *)
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }

    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
        case .notConnected: return "NotConnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        default: return "Unknown"
        }
    }
    
}

extension GameServiceManager : MCSessionDelegate {
    
    //change state? - fix
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
    }
    
    //receive data
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data.count) bytes")
        typealias DoublePoint = (x: Double, y: Double, z: Double)
        // receiver
        if (data.count == MemoryLayout<DoublePoint>.size) {
            //var receivedPair = UnsafePointer<DoublePoint>?(data.bytes).memory
            //not tested
            let receivedPair = data.withUnsafeBytes({ (ptr: UnsafePointer<DoublePoint>) -> DoublePoint in
                return ptr.pointee
            })
            let receivedPoint = CGPoint(x: CGFloat(receivedPair.x), y: CGFloat(receivedPair.y))
            //..
            print("receivedPair.z = ", receivedPair.z)
            let roation = CGFloat(receivedPair.z)
            self.delegate?.receiveMove(self, toPosition: receivedPoint, rotation: roation)
        } else {
            // error
        }
        //let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
        //self.delegate?.colorChanged(self, colorString: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
}
