import FirebaseDatabase
import SwiftUI

/// Represents a single leaderboard row.
struct LeaderboardEntry: Identifiable {
    let id         = UUID()
    let uid: String
    let nickname: String
    let region: String
    let totalCoins: Int

    var flag: String {
        region
            .uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + Int($0.value)) }
            .map(String.init)
            .joined()
    }
}

class LeaderboardViewModel: ObservableObject {
    @Published var leaderboard: [LeaderboardEntry] = []
    private let db = Database.database().reference()

    func fetchLeaderboard() {
        db.child("users")
          .queryOrdered(byChild: "totalCoins")
          .queryLimited(toLast: 10)
          .observeSingleEvent(of: .value) { snapshot in
            var entries: [LeaderboardEntry] = []
            for child in snapshot.children.reversed() {
                guard let snap  = child as? DataSnapshot,
                      let data  = snap.value as? [String:Any],
                      let coins = data["totalCoins"] as? Int,
                      let nick  = data["nickname"]   as? String,
                      let reg   = data["region"]     as? String
                else { continue }

                entries.append(
                  LeaderboardEntry(
                    uid:        snap.key,
                    nickname:   nick,
                    region:     reg,
                    totalCoins: coins
                  )
                )
            }
            DispatchQueue.main.async {
                self.leaderboard = entries
            }
        }
    }
}

