//
//  RegisterView.swift
//  EscapeThePolice
//
//  Created by Aviad on 29/06/2025.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RegisterViewModel()
    let onRegister: (String) -> Void

    var body: some View {
        ZStack {
            // Theme background
            Color("BackgroundColor").ignoresSafeArea()

            NavigationStack {
                Form {
                    Section(header: Text("Profile")
                                .foregroundColor(Color("FontColor"))) {
                        TextField("Nickname", text: $vm.nickname)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .textContentType(.name)
                            .foregroundColor(Color("FontColor"))
                            .accentColor(Color("FontColor"))
                    }

                    Section(header: Text("Account")
                                .foregroundColor(Color("FontColor"))) {
                        TextField("Email", text: $vm.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                            .foregroundColor(Color("FontColor"))
                            .accentColor(Color("FontColor"))

                        SecureField("Password (min 6 chars)", text: $vm.password)
                            .textContentType(.newPassword)
                            .foregroundColor(Color("FontColor"))
                            .accentColor(Color("FontColor"))
                    }

                    Section {
                        Button(action: {
                            vm.register { uid in
                                onRegister(uid)
                                dismiss()
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text("Create Account")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("SecondaryFontColor"))
                                Spacer()
                            }
                        }
                        .disabled(!vm.isFormValid || vm.isLoading)
                    }

                    if !vm.errorMessage.isEmpty {
                        Section {
                            Text(vm.errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .background(Color("BackgroundColor"))
                .accentColor(Color("FontColor"))
                .navigationTitle("Register")
                .disabled(vm.isLoading)
            }

            // Loading Overlay
            if vm.isLoading {
                Color("BackgroundColor")
                    .opacity(0.4)
                    .ignoresSafeArea()
                ProgressView("Signing you up…")
                    .foregroundColor(Color("FontColor"))
                    .padding(24)
                    .background(Color("BackgroundColor"))
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegisterView(onRegister: { _ in })
                .environment(\.colorScheme, .light)

            RegisterView(onRegister: { _ in })
                .environment(\.colorScheme, .dark)
        }
    }
}
