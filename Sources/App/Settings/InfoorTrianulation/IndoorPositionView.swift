import SwiftUI

struct IndoorPositionView: View {
    @StateObject var viewModel = BuildingViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.floors) { floor in
                    NavigationLink(destination: FloorView(floor: floor, viewModel: viewModel)) {
                        Text(floor.name)
                    }
                }
                .onDelete(perform: { indexSet in
                    indexSet.forEach { index in
                        viewModel.removeFloor(at: index)
                    }
                })
                
                Button("Add Floor") {
                    viewModel.showAddFloorAlert = true
                }
            }
            .navigationTitle("Floors")
            .alert(isPresented: $viewModel.showAddFloorAlert) {
                Alert(
                    title: Text("Add Floor"),
                    message: Text("Enter floor name"),
                    primaryButton: .default(Text("Add"), action: {
                        viewModel.addFloor(name: viewModel.newFloorName)
                        viewModel.newFloorName = ""
                    }),
                    secondaryButton: .cancel()
                )
            }
            .textFieldAlert(isPresented: $viewModel.showAddFloorAlert, text: $viewModel.newFloorName, placeholder: "Floor Name")
        }
    }
}

struct FloorView: View {
    var floor: Floor
    @ObservedObject var viewModel: BuildingViewModel
    
    var body: some View {
        List {
            ForEach(floor.rooms) { room in
                NavigationLink(destination: RoomView(room: room, viewModel: viewModel)) {
                    Text(room.name)
                }
            }
            .onDelete(perform: { indexSet in
                indexSet.forEach { index in
                    viewModel.removeRoom(from: floor, at: index)
                }
            })
            
            Button("Add Room") {
                viewModel.showAddRoomAlert = true
                viewModel.currentFloor = floor
            }
        }
        .navigationTitle(floor.name)
        .alert(isPresented: $viewModel.showAddRoomAlert) {
            Alert(
                title: Text("Add Room"),
                message: Text("Enter room name"),
                primaryButton: .default(Text("Add"), action: {
                    if let floor = viewModel.currentFloor {
                        viewModel.addRoom(to: floor, name: viewModel.newRoomName)
                        viewModel.newRoomName = ""
                    }
                }),
                secondaryButton: .cancel()
            )
        }
        .textFieldAlert(isPresented: $viewModel.showAddRoomAlert, text: $viewModel.newRoomName, placeholder: "Room Name")
    }
}

struct RoomView: View {
    var room: Room
    @ObservedObject var viewModel: BuildingViewModel
    
    var body: some View {
        VStack {
            Button("Start Scanning") {
                viewModel.startScanning(room: room)
            }
            
            Button("Stop Scanning and Save Room") {
                viewModel.stopScanning()
            }
            
            Spacer()
            
            Button("Analyze Rooms") {
                viewModel.analyzeRooms()
            }
            
            Text("Current Position: \(viewModel.currentPosition)")
                .padding()
        }
        .navigationTitle(room.name)
        .padding()
    }
}

struct IndoorPositionView_Previews: PreviewProvider {
    static var previews: some View {
        IndoorPositionView()
    }
}
