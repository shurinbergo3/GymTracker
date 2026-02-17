import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Image("LaunchScreen")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    LaunchScreenView()
}
