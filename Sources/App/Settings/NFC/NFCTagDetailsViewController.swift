import UIKit

class NFCTagDetailsViewController: UIViewController {
    private let tagId: String
    private let name: String

    init(tagId: String, name: String) {
        self.tagId = tagId
        self.name = name
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    private func setupUI() {
        let tagIdLabel = UILabel()
        tagIdLabel.text = "Tag ID: \(tagId)"
        tagIdLabel.textAlignment = .center
        tagIdLabel.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = "Name: \(name)"
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let triggerButton = UIButton(type: .system)
        triggerButton.setTitle("Tag auslösen", for: .normal)
        triggerButton.addTarget(self, action: #selector(triggerTag), for: .touchUpInside)
        triggerButton.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [tagIdLabel, nameLabel, triggerButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func triggerTag() {
        // Logik zum Auslösen des Tags
    }
}
