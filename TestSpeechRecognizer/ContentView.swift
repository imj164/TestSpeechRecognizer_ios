//
//  ContentView.swift
//  TestSpeechRecognizer
//
//  Created by Hiroshi IMAJO on 2022/11/12.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = SpeechRecognizeManager()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(manager.text)
            Spacer()
            HStack {
                Spacer()
                Button(manager.running ? "Stop" : "Start", action: {
                    if manager.running {
                        manager.stop()
                    } else {
                        manager.start()
                    }
                })
                .buttonStyle(.borderedProminent)
                .tint(manager.running ? .red : .accentColor)
                //.disabled(!manager.available)
                Spacer()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
