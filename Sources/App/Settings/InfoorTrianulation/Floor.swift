import Foundation

struct Floor: Identifiable {
    var id = UUID()
    var name: String
    var rooms: [Room] = []
}
