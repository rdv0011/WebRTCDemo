//
// Copyright © 2019 Dmitry Rybakov. All rights reserved. 
    

import SwiftUI

struct ContentView: View {

    @ObservedObject var modelView = WebRTCBroadcastModelView()

    var body: some View {
        VStack {
            Spacer()
            TextField("Broadcast Room ID:", text: self.$modelView.broadcastRoomID)
            Spacer()
            Button(action: {
                self.modelView.saveRoomIDForAppExtension(roomID: self.modelView.broadcastRoomID)
            }) {
                Text("Save broadcast room ID")
            }
            Spacer()
            Button(action: {
                self.modelView.startBroadcast(to: self.modelView.broadcastRoomID)
            }) {
                Text("Start broadcasting")
            }
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
