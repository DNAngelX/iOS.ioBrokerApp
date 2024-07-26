import Foundation
import CoreLocation
import WatchConnectivity

class IndoorLocationInterfaceController: NSObject, CLLocationManagerDelegate, WCSessionDelegate {
    var locationManager: CLLocationManager!
    var session: WCSession?
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        startScanning()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func startScanning() {
        let uuid = UUID(uuidString: "YOUR-IBEACON-UUID")!
        let beaconRegion = CLBeaconRegion(uuid: uuid, identifier: "com.example.myRegion")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        for beacon in beacons {
            let beaconInfo = ["uuid": beacon.uuid.uuidString, "rssi": beacon.rssi] as [String : Any]
            session?.sendMessage(beaconInfo, replyHandler: nil, errorHandler: nil)
        }
    }
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation completion
        print("WCSession activated with state: \(activationState)")
        if let error = error {
            print("WCSession activation error: \(error.localizedDescription)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation
        print("WCSession deactivated")
        // Reactivate session
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle messages received from the iPhone
        print("Received message: \(message)")
    }
}
