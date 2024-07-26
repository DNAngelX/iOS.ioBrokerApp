import Foundation
import CoreLocation
import Combine

class BuildingViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var floors: [Floor] = []
    @Published var currentRoom: Room?
    @Published var currentPosition: String = "Unknown"
    @Published var showAddFloorAlert = false
    @Published var showAddRoomAlert = false
    @Published var newFloorName = ""
    @Published var newRoomName = ""
    @Published var currentFloor: Floor?
    
    var locationManager: CLLocationManager?
    var beaconRegion: CLBeaconRegion?
    
    func addFloor(name: String) {
        let newFloor = Floor(name: name)
        floors.append(newFloor)
    }
    
    func removeFloor(at index: Int) {
        floors.remove(at: index)
    }
    
    func addRoom(to floor: Floor, name: String) {
        if let index = floors.firstIndex(where: { $0.id == floor.id }) {
            let newRoom = Room(name: name)
            floors[index].rooms.append(newRoom)
        }
    }
    
    func removeRoom(from floor: Floor, at index: Int) {
        if let floorIndex = floors.firstIndex(where: { $0.id == floor.id }) {
            floors[floorIndex].rooms.remove(at: index)
        }
    }
    
    func startScanning(room: Room) {
        currentRoom = room
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        
        beaconRegion = CLBeaconRegion(uuid: UUID(), identifier: "com.example.myRegion")
        locationManager?.startMonitoring(for: beaconRegion!)
        locationManager?.startRangingBeacons(in: beaconRegion!)
    }
    
    func stopScanning() {
        guard let beaconRegion = beaconRegion else { return }
        locationManager?.stopRangingBeacons(in: beaconRegion)
        locationManager?.stopMonitoring(for: beaconRegion)
        locationManager = nil
        currentRoom = nil
    }
    
    func analyzeRooms() {
        // Implement logic to analyze the rooms based on the scanned data
        // Example: Determine the strongest signal beacon for each room
        for floor in floors {
            for room in floor.rooms {
                if let strongestBeacon = room.beacons.max(by: { $0.rssi < $1.rssi }) {
                    print("Room: \(room.name), Strongest Beacon: \(strongestBeacon.uuid), RSSI: \(strongestBeacon.rssi)")
                }
            }
        }
        // Update current position based on analysis
        updateCurrentPosition()
    }
    
    func updateCurrentPosition() {
        // Implement logic to update the current position based on the analysis
        currentPosition = "Updated Position"
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard let currentRoom = currentRoom else { return }
        
        for beacon in beacons {
            let beaconData = BeaconData(uuid: beacon.uuid, rssi: beacon.rssi)
            if let index = floors.firstIndex(where: { $0.rooms.contains(where: { $0.id == currentRoom.id }) }) {
                if let roomIndex = floors[index].rooms.firstIndex(where: { $0.id == currentRoom.id }) {
                    floors[index].rooms[roomIndex].beacons.append(beaconData)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLBeaconRegion {
            manager.startRangingBeacons(in: region as! CLBeaconRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLBeaconRegion {
            manager.stopRangingBeacons(in: region as! CLBeaconRegion)
        }
    }
}
