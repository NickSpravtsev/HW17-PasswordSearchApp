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

    var currentBrurePassword: String? {
        didSet {
            DispatchQueue.main.async {
                self.currentBrutePasswordLabel.text = self.currentBrurePassword ?? ""
            }
        }
    }

    var foundedPassword: String? {
        didSet {
            DispatchQueue.main.async {
                self.foundedPaswordLabel.text = self.foundedPassword ?? ""
                self.activityIndicator.isHidden = true
                self.bruteButton.setTitle("Подобрать", for: .normal)
                self.isBruteActive = false
                self.passwordTextField.isSecureTextEntry = false
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

    @IBAction func generateButtonPressed(_ sender: Any) {
        self.passwordTextField.isSecureTextEntry = true
        let password = generateRandomPassword(length: 3)
        passwordTextField.text = password
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

    @objc private func passwordTextFieldTouched() {
        passwordTextField.isSecureTextEntry = true
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

        passwordTextField.addTarget(self, action: #selector(passwordTextFieldTouched), for: .touchDown)
    }

    // Func to hide keyboard
    @objc private func hideKeyboard() {
        self.view.endEditing(true)
    }

    // MARK: - Generate random password funtionality

    private func generateRandomPassword(length: Int) -> String {
        let letters: [String] = String().printable.map { String($0) }
        var password = ""
        var passwordLength = length

        while passwordLength > 0 {
            password.append(letters.randomElement() ?? "")
            passwordLength -= 1
        }
        return password
    }

    // MARK: - Bruteforce funtionality
    
    func bruteForce(passwordToUnlock: String) {
        let letters: [String] = String().printable.map { String($0) }
        var password: String = ""

        // Will strangely ends at 0000 instead of ~~~
        while password != passwordToUnlock { // Increase MAXIMUM_PASSWORD_SIZE value for more
            if bruteWorkItem?.isCancelled ?? true {
                return
            }
            password = generateBruteForce(password, fromArray: letters)
            currentBrurePassword = password
        }
        foundedPassword = password
    }
}

func indexOf(character: Character, _ array: [String]) -> Int {
    return array.firstIndex(of: String(character)) ?? array.count
}

func characterAt(index: Int, _ array: [String]) -> Character {
    return index < array.count ? Character(array[index])
    : Character("")
}

func generateBruteForce(_ string: String, fromArray array: [String]) -> String {
    var password: String = string

    if password.count <= 0 {
        password.append(characterAt(index: 0, array))
    }
    else {
        password.replace(at: password.count - 1,
                         with: characterAt(index: (indexOf(character: password.last ?? Character(""), array) + 1) % array.count, array))

        if indexOf(character: password.last ?? Character(""), array) == 0 {
            password = String(generateBruteForce(String(password.dropLast()), fromArray: array)) + String(password.last ?? Character(""))
        }
    }
    return password
}
