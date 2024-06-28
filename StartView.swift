import SwiftUI

struct StartView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to IoBroker App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Text("IoBroker is an open-source IoT platform that enables you to manage and monitor your smart devices seamlessly. With IoBroker, you can connect various devices, set up automations, and visualize data in an intuitive manner. Get started by configuring your connection settings.")
                    .font(.body)
                    .padding()

                NavigationLink(destination: SettingsView()) {
                    Text("Go to Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("IoBroker App")
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
