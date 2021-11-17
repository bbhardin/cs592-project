//
//  ContentView.swift
//  CS592 Project
//
//  Created by Benjamin Hardin on 10/27/21.
//

import SwiftUI
import Quartz

// Preview code taken from https://stackoverflow.com/questions/59696367/how-do-i-show-qlpreviewpanel-with-swiftui-on-macos
func loadPreviewItem(with name: String) -> NSURL {

    //let file = name.components(separatedBy: ".")
    //let path = Bundle.main.path(forResource: file.first!, ofType: file.last!)
    let url = NSURL(fileURLWithPath: name)

    return url
}

struct MyPreview: NSViewRepresentable {
    var fileName: String

    func makeNSView(context: NSViewRepresentableContext<MyPreview>) -> QLPreviewView {
        let preview = QLPreviewView(frame: .zero, style: .normal)
        preview?.autostarts = true
        preview?.previewItem = loadPreviewItem(with: fileName) as QLPreviewItem
        return preview ?? QLPreviewView()
    }

    func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<MyPreview>) {
    }

    typealias NSViewType = QLPreviewView

}

struct ContentView: View {
    
    @State var searchQuery = ""
    @State var searchResults = ""
    @State var searchResultsArray = [""]
    @State var showResults = false
    @State var selectedColor = Color.clear
    
    var body: some View {
        
        VStack {
            
            HStack(alignment: .top) {
                TextField("Enter your search", text: $searchQuery)
                    .padding(.leading)
                
                Button(action: {
                    promptForWorkingDirectoryPermission()
                    let stdOut = Pipe()
                    let process = Process()
                    process.launchPath = "/usr/bin/mdfind"
                    process.arguments = [self.searchQuery]
                    process.standardOutput = stdOut
                    process.launch()
                    process.waitUntilExit()
                    
                    let data = stdOut.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)!
                        
                    searchResults = output
                    searchResultsArray = searchResults.components(separatedBy: "\n")
                    showResults = true

                    
                }) {
                    Text("Seach")
                }.padding(.trailing)
            
                
            }.padding(.top)
            
            
//            Text(self.searchResults)
//                .padding()
                
            
            if (showResults) {
                HStack(alignment: .top) {
                    
                    // Only show first four results
                    ForEach((0...min(3, searchResultsArray.count-1)), id: \.self) { i in
                        VStack{
                            VStack {
                                MyPreview(fileName: searchResultsArray[i]).frame(width: 100, height: 100, alignment: .center)
                                Text(searchResultsArray[i].components(separatedBy: "/").last ?? "")
                            }.padding(5)
                        }.contextMenu {
                            Button("Show in Finder", action: {
                                NSWorkspace.shared.selectFile(searchResultsArray[i], inFileViewerRootedAtPath: "/Users/")
                            })
                        }
                        .onTapGesture {
                            selectedColor = (selectedColor == .blue) ? Color.clear : Color.blue
                        }
                        .background(selectedColor)
                        .cornerRadius(10)
                        
                    }
                    
                }.padding(.top)
               
            }
            
            Spacer()
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private func promptForWorkingDirectoryPermission() -> URL? {
    let openPanel = NSOpenPanel()
    openPanel.message = "Choose your directory"
    openPanel.prompt = "Choose"
    openPanel.allowedFileTypes = ["none"]
    openPanel.allowsOtherFileTypes = false
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true
    
    let response = openPanel.runModal()
    print(openPanel.urls)
    return openPanel.urls.first
}


// Special thanks to https://benscheirman.com/2019/10/troubleshooting-appkit-file-permissions/#:~:text=A%20sandboxed%20macOS%20app%20doesn,documents%2C%20cache%2C%20and%20settings.
private func saveBookmarkData(for workDir: URL) {
    do {
        let bookmarkData = try workDir.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        
        // Save in UserDefaults
        //Preferences.workingDirectoryBookmark = bookmarkData
    } catch {
        print("Failed to save bookmark data for \(workDir)", error)
    }
}
