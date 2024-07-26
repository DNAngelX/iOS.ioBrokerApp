import UIKit

class IndoorLocationViewController: UIViewController {
    @IBOutlet weak var currentRoomLabel: UILabel!
    @IBOutlet weak var learnButton: UIButton!
    
    var indoorLocationManager: IndoorLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        indoorLocationManager = IndoorLocationManager()
    }
    
    @IBAction func startLearning(_ sender: UIButton) {
        // Implement logic to start learning mode
    }
    
    @IBAction func determineRoom(_ sender: UIButton) {
        let currentRoom = indoorLocationManager.determineCurrentRoom()
        currentRoomLabel.text = "Current Room: \(currentRoom)"
    }
}
