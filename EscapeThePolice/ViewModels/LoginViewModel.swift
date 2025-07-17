//
//  LoginViewModel.swift
//  EscapeThePolice
//
//  Created by Aviad on 29/06/2025.
//

// Models/LoginViewModel.swift
import FirebaseAuth
import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""

    func login(onLogin: @escaping (String) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    onLogin(user.uid)
                }
            }
        }
    }
}


