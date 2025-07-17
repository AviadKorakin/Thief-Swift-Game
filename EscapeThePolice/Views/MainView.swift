//
//  MainView.swift
//  EscapeThePolice
//
//  Created by Aviad on 24/06/2025.
//

import SwiftUI
import FirebaseAuth

struct UserModel { var uid: String? }

// MARK: — View model
class MainViewModel: ObservableObject {
    @Published var userModel = UserModel(uid: Auth.auth().currentUser?.uid)
    
    func logout() {
        try? Auth.auth().signOut()
        userModel.uid = nil
    }
}

// MARK: — Reusable menu button style
struct MenuButtonStyle: ButtonStyle {
    let bg: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .padding()
            .frame(maxWidth: .infinity)
            .background(bg.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(Color("SecondaryFontColor"))  // use secondary font color
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// MARK: — MainView
struct MainView: View {
    @StateObject private var vm = MainViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Escape the Police")
                    .font(.largeTitle.weight(.bold))
                    .padding(.bottom, 20)
                    .foregroundColor(Color("FontColor"))
                
                if vm.userModel.uid == nil {
                    guestView
                } else {
                    playerView
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .toolbar {
                // center the thief icon in place of the title
                ToolbarItem(placement: .principal) {
                    Image("player")               // your thief/player asset
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color("FontColor"))
                }
            }
        }
    }
    
    // MARK: — Guest buttons
    private var guestView: some View {
        VStack(spacing: 12) {
            NavigationLink("Login", destination: LoginView(onLogin: didAuth))
                .buttonStyle(MenuButtonStyle(bg: .blue))
            
            NavigationLink("Register", destination: RegisterView(onRegister: didAuth))
                .buttonStyle(MenuButtonStyle(bg: .green))
        }
    }
    
    // MARK: — Player buttons
    private var playerView: some View {
        VStack(spacing: 12) {
            NavigationLink("Play", destination:
                GameView(userUID: vm.userModel.uid!)
                    .navigationBarBackButtonHidden(true)
            )
            .buttonStyle(MenuButtonStyle(bg: .teal))
            
            NavigationLink("Leaderboard", destination: LeaderboardView())
                .buttonStyle(MenuButtonStyle(bg: .purple))
            
            Button("Logout", action: vm.logout)
                .buttonStyle(MenuButtonStyle(bg: .red))
        }
    }
    
    // MARK: — Authentication callback
    private func didAuth(_ uid: String) {
        vm.userModel.uid = uid
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainView()
                .environment(\.colorScheme, .light)
            MainView()
                .environment(\.colorScheme, .dark)
        }
    }
}
