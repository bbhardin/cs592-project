//
//  ContentView.swift
//  CS592 Project
//
//  Created by Benjamin Hardin on 10/27/21.
//

import SwiftUI

struct ContentView: View {
    
    @State var searchQuery = "appetyte"
    @State var searchResults = ""
    
    var body: some View {
        
        VStack {
            
            HStack {
                TextField("Enter your search", text: $searchQuery)
                    .padding(.leading)
                
                Button(action: {
                    let stdOut = Pipe()
                    let process = Process()
                    process.launchPath = "/usr/bin/mdfind"
                    process.arguments = [self.searchQuery]
                    process.standardOutput = stdOut
                    process.launch()
                    process.waitUntilExit()
    //                let executableURL = URL(fileURLWithPath: )
    //                try! Process.run(executableURL,
    //                                 arguments: [self.message],
    //                                 terminationHandler: nil)
                    
                    let data = stdOut.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)!
                        
                    searchResults = output

                    
                }) {
                    Text("Seach")
                }.padding(.trailing)
            }
            
            
            Text(self.searchResults)
                .padding()
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
