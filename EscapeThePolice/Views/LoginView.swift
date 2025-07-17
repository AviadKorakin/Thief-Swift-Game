//
//  LoginView.swift
//  EscapeThePolice
//
//  Created by Aviad on 29/06/2025.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = LoginViewModel()
    let onLogin: (String) -> Void

    var body: some View {
        ZStack {
            // Theme background
            Color("BackgroundColor").ignoresSafeArea()

            NavigationView {
                Form {
                    Section(header: Text("Account")
                                .foregroundColor(Color("FontColor"))) {
                        // Email field
                        TextField("Email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.emailAddress)
                            .foregroundColor(Color("FontColor"))
                            .accentColor(Color("FontColor"))

                        // Password field
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                            .foregroundColor(Color("FontColor"))
                            .accentColor(Color("FontColor"))
                    }

                    // Sign In button
                    Section {
                        Button(action: {
                            viewModel.login(onLogin: onLogin)
                        }) {
                            Text("Sign In")
                                .foregroundColor(Color("SecondaryFontColor"))
                        }
                    }

                    // Error message
                    if !viewModel.errorMessage.isEmpty {
                        Section {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Register link
                    Section {
                        NavigationLink(destination: RegisterView(onRegister: onLogin)) {
                            Text("Register")
                                .foregroundColor(Color("SecondaryFontColor"))
                        }
                    }
                }
                .background(Color("BackgroundColor"))
                .accentColor(Color("FontColor"))
                .navigationTitle("Login")
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView(onLogin: { _ in })
                .environment(\.colorScheme, .light)

            LoginView(onLogin: { _ in })
                .environment(\.colorScheme, .dark)
        }
    }
}
