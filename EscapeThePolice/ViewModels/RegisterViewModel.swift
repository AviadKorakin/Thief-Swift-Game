import FirebaseAuth
import FirebaseDatabase
import SwiftUI

class RegisterViewModel: ObservableObject {
    // MARK: Inputs
    @Published var email       = ""
    @Published var password    = ""
    @Published var nickname    = ""
    
    // MARK: State
    @Published var errorMessage = ""
    @Published var isLoading    = false

    private let db = Database.database().reference()
    
    /// Two-letter ISO region code, using `Locale.Region` on iOS 16+ or falling back to `regionCode`
    private var region: String {
        if #available(iOS 16.0, *) {
            return Locale.current.region?.identifier
                   ?? Locale.current.regionCode
                   ?? "US"
        } else {
            return Locale.current.regionCode ?? "US"
        }
    }

    /// Return `true` when all fields meet basic criteria
    var isFormValid: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        password.count >= 6
    }

    /// Creates the user in Firebase Auth, then writes the profile (coins, level, nickname, region) to Realtime DB
    func register(onRegister: @escaping (String) -> Void) {
        guard isFormValid else { return }
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let self = self,
                      let user = result?.user else { return }
                
                // Store extra profile fields in your Realtime DB
                let entry: [String: Any] = [
                    "totalCoins": 0,
                    "level":      1,
                    "nickname":   self.nickname,
                    "region":     self.region
                ]
                
                self.db
                  .child("users")
                  .child(user.uid)
                  .setValue(entry) { dbError, _ in
                      if let dbError = dbError {
                          self.errorMessage = dbError.localizedDescription
                      } else {
                          onRegister(user.uid)
                      }
                  }
            }
        }
    }
}
