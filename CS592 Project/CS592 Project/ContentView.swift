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
        let preview = QLPreviewView(frame: .init(x: 0, y: 0, width: 100, height: 100), style: .normal)
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
    @State var selectedColor = [Color](repeatElement(Color.clear, count: 8))
    
    var body: some View {
        
        VStack {
            
            Button("Allow Permissions", action: {
                promptForWorkingDirectoryPermission()
            })
            
            HStack(alignment: .top) {
                TextField("Enter your search", text: $searchQuery)
                    .padding(.leading)
                
                Button(action: {
                    if (searchQuery == "") {
                        return
                    }
                    
                    let stdOut = Pipe()
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
                    process.arguments = [self.searchQuery]
                    process.standardOutput = stdOut
                    
//                    process.waitUntilExit()
                    
                    do {
                            try process.run()
                        }
                    catch{ print(error)}
                        
                    let data = stdOut.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)!
                    
                    searchResults = output
                    searchResultsArray = searchResults.components(separatedBy: "\n").filter({ $0 != ""})
                    if (searchResultsArray.count != 0) {
                        showResults = true
                    } else {
                        showResults = false
                    }
                
                    
                }) {
                    Text("Seach")
                }.padding(.trailing)
            
                // TODO: Add loading indicator and disable button for slow search
            }
            .padding(.top)
            
            
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
                            }
                        }.contextMenu {
                            Button("Show in Finder", action: {
                                NSWorkspace.shared.selectFile(searchResultsArray[i], inFileViewerRootedAtPath: "/Users/")
                            })
                        }
                        .onTapGesture {
                            selectedColor[i] = (selectedColor[i] == .blue) ? Color.clear : Color.blue
                            for l in 0...selectedColor.count-1 {
                                if (l != i) {
                                    selectedColor[l] = Color.clear
                                }
                            }
                        }
                        .background(selectedColor[i])
                        .cornerRadius(10)
                        
                    }
                    
                }.padding(.top)
                
                HStack(alignment: .top) {
                    
                    // Only show first four results
                    if (searchResultsArray.count - 1 >= 4) {
                        ForEach((4...min(7, searchResultsArray.count-1)), id: \.self) { i in
                            VStack{
                                VStack {
                                    MyPreview(fileName: searchResultsArray[i]).frame(width: 100, height: 100, alignment: .center)
                                    Text(searchResultsArray[i].components(separatedBy: "/").last ?? "")
                                }.padding(5)
                            }.contextMenu {
                                Button("Show in Finder", action: {
                                    NSWorkspace.shared.selectFile(searchResultsArray[i], inFileViewerRootedAtPath: "/Users/")
                                })
                            }.onTapGesture {
                                selectedColor[i] = (selectedColor[i] == .blue) ? Color.clear : Color.blue
                                for l in 0...selectedColor.count-1 {
                                    if (l != i) {
                                        selectedColor[l] = Color.clear
                                    }
                                }
                            }
                            .background(selectedColor[i])
                            .cornerRadius(10)
                        }
                    }
                    
                }.padding(.top)
               
            } else {
                Text("No Results")
            }
            
            Spacer()
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .onAppear(perform: {promptForWorkingDirectoryPermission()})
        
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private func promptForWorkingDirectoryPermission() -> Void {
    let openPanel = NSOpenPanel()
    openPanel.message = "Choose your directory"
    openPanel.prompt = "Choose"
    openPanel.allowedFileTypes = ["none"]
    openPanel.allowsOtherFileTypes = false
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true
    
    let response = openPanel.runModal()
    print(openPanel.urls)
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
