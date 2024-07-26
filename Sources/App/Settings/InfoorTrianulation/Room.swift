import Foundation

struct Room: Identifiable {
    var id = UUID()
    var name: String
    var beacons: [BeaconData] = []
}
