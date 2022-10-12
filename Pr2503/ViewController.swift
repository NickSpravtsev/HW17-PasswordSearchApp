import UIKit

class ViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var button: UIButton!

    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var foundedPaswordLabel: UILabel!

    @IBOutlet weak var bruteButton: UIButton!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var currentBrutePasswordLabel: UILabel!

    // MARK: - Propierties

    var isBlack: Bool = false {
        didSet {
            if isBlack {
                self.view.backgroundColor = .black
            } else {
                self.view.backgroundColor = .white
            }
        }
    }

    private let bruteQueue = DispatchQueue(label: "Bruteforce")

    private var bruteWorkItem: DispatchWorkItem?

    private var isBruteActive = false

    // MARK: - Actions
    
    @IBAction func onBut(_ sender: Any) {
        isBlack.toggle()
    }

    @IBAction func bruteButtonTapped(_ sender: Any) {

        if !isBruteActive {
            isBruteActive.toggle()

            foundedPaswordLabel.text = ""
            currentBrutePasswordLabel.text = ""
            bruteButton.setTitle("Остановить", for: .normal)
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()

            if let password = passwordTextField.text {
                bruteWorkItem = DispatchWorkItem {
                    self.bruteForce(passwordToUnlock: password)
                }

                bruteQueue.async(execute: bruteWorkItem ?? DispatchWorkItem { print("Error with brute work item!") })
            }
        } else {
            isBruteActive.toggle()

            bruteWorkItem?.cancel()

            bruteButton.setTitle("Подобрать", for: .normal)
            activityIndicator.isHidden = true
            foundedPaswordLabel.text = "Пароль не взломан"
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        foundedPaswordLabel.text = ""
        currentBrutePasswordLabel.text = ""
        activityIndicator.isHidden = true

        // Code to dismiss a keyboard with tap on view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }

    // Func to hide keyboard
        @objc private func hideKeyboard() {
            self.view.endEditing(true)
        }

    // MARK: - Bruteforce funtionality
    
    func bruteForce(passwordToUnlock: String) {
        let ALLOWED_CHARACTERS:   [String] = String().printable.map { String($0) }

        var password: String = ""

        // Will strangely ends at 0000 instead of ~~~
        while password != passwordToUnlock { // Increase MAXIMUM_PASSWORD_SIZE value for more

            if bruteWorkItem?.isCancelled ?? true {
                return
            }

            password = generateBruteForce(password, fromArray: ALLOWED_CHARACTERS)

            DispatchQueue.main.async {
                self.currentBrutePasswordLabel.text = password
            }
        }

        DispatchQueue.main.async {
            self.foundedPaswordLabel.text = password
            self.activityIndicator.isHidden = true
            self.bruteButton.setTitle("Подобрать", for: .normal)
            self.isBruteActive = false
        }
    }
}

extension String {
    var digits:      String { return "0123456789" }
    var lowercase:   String { return "abcdefghijklmnopqrstuvwxyz" }
    var uppercase:   String { return "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
    var punctuation: String { return "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~" }
    var letters:     String { return lowercase + uppercase }
    var printable:   String { return digits + letters + punctuation }



    mutating func replace(at index: Int, with character: Character) {
        var stringArray = Array(self)
        stringArray[index] = character
        self = String(stringArray)
    }
}

func indexOf(character: Character, _ array: [String]) -> Int {
    return array.firstIndex(of: String(character))!
}

func characterAt(index: Int, _ array: [String]) -> Character {
    return index < array.count ? Character(array[index])
    : Character("")
}

func generateBruteForce(_ string: String, fromArray array: [String]) -> String {
    var str: String = string

    if str.count <= 0 {
        str.append(characterAt(index: 0, array))
    }
    else {
        str.replace(at: str.count - 1,
                    with: characterAt(index: (indexOf(character: str.last!, array) + 1) % array.count, array))

        if indexOf(character: str.last!, array) == 0 {
            str = String(generateBruteForce(String(str.dropLast()), fromArray: array)) + String(str.last!)
        }
    }

    return str
}
