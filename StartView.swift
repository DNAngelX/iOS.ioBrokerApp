import SwiftUI

struct StartView: View {
    @State private var systems: [IoBrokerSettings] = SettingsManager.shared.loadSettings()
    @State private var timer: Timer?

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("Welcome to IoBroker App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding([.top, .horizontal])

                    Text("IoBroker is an open-source IoT platform that enables you to manage and monitor your smart devices seamlessly. With IoBroker, you can connect various devices, set up automations, and visualize data in an intuitive manner. Get started by configuring your connection settings.")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding([.horizontal, .bottom])
                }
                .background(Color.blue)
                .cornerRadius(15)
                .shadow(radius: 10)

                VStack(spacing: 10) {
                    Text("Active Systems")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, 5)

                    ForEach(systems.filter { $0.isActive }, id: \.id) { system in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(system.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(system.url)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Circle()
                                .fill(system.onlineState ? Color.green : Color.red)
                                .frame(width: 20, height: 20)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)

                NavigationLink(destination: SettingsView()) {
                    Text("Go to Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .shadow(radius: 5)
            }
            .padding()
            .background(Color(.systemBackground))
            .navigationTitle("IoBroker App")
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            systems = SettingsManager.shared.loadSettings()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
