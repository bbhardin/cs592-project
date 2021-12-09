//
//  ContentView.swift
//  CS592 Project
//
//  Created by Benjamin Hardin on 10/27/21.
//

import SwiftUI
import Quartz

func parseSEMPREOutput(input: String) -> [String] {
    // Example: (and (type presentation) (year 2019) (folder Downloads) (downloaded_from xyz.com))
    
    print("here")
    
    var argumentsArray : [String] = []
    
    var mdfindQuery = ""
    let terms = input.components(separatedBy: "(")
    for term in terms {
        print(term)
        let kindAndName = term.components(separatedBy: " ")
        let kind = kindAndName.first
        var query = ""
        if (kindAndName.count > 1) {
            query = kindAndName[1]
        }
        
        query.removeAll(where: {$0 == ")"})
        
        switch(kind) {
        case "type":
            // Options accepted by mdfind for kind/type
            let kindOptions = ["application", "applications", "app", "audio", "music", "bookmark", "bookmarks", "contact", "contacts", "email", "emails", "mail message", "mail messages", "folder", "folders", "font", "fonts", "event", "events", "todo", "todos", "to do", "to dos", "image", "images", "movie", "movies", "pdf", "pdfs", "system preferences", "preferences", "presentations", "presentation"]
            if (kindOptions.contains(query)) {
                print("here a queryr", query)
                mdfindQuery += " kind:" + query
                argumentsArray.append("kind")
                argumentsArray.append(query)
            }
            
            break
        case "year":
            
            if (query == Calendar.current.component(.year, from: Date()).description) {
                query = "this year"
            }
            
            // Options accepted by mdfind for date
            let dateOptions = ["today", "yesterday", "this week", "this month", "this year", "tomorrow", "next month", "next week", "next year"]
            
            if (dateOptions.contains(query)) {
                mdfindQuery += " date:" + query
                argumentsArray.append("date")
                argumentsArray.append(query)
            }
            print(query)
            break
        case "folder":
            let folderOptions = ["Documents", "Downloads", "Desktop"]
            if (folderOptions.contains(query)) {
                mdfindQuery += " -onlyin " + query
                argumentsArray.append("-onlyin")
                argumentsArray.append(query)
            }
            
            break
        case "downloaded_from":
            mdfindQuery += " \"kMDItemWhereFroms:" + query + "\""
            argumentsArray.append("Where From")
            argumentsArray.append(query)
            break
        default:
            break
        }
    }
    
    // Todo: prioritize documents in documents, desktop and downloads folders. Run queries on those first, merge the queries, and then return all the results
    
    print(mdfindQuery)
    return argumentsArray
    
}

struct ContentView: View {
    
    @State var searchQuery = ""
    @State var searchResults = ""
    @State var searchResultsArray = [""]
    @State var showResults = false
    @State var selectedColor = [Color](repeatElement(Color.clear, count: 8))
    @State var argumentsArray : [String] = []
    
    @State var field1 = ""
    @State var field2 = ""
    @State var field3 = ""
    
    // Show mdfind arguments
    @State var showArguments = false
    
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
                    
                    argumentsArray = parseSEMPREOutput(input: searchQuery)
                    
                    let stdOut = Pipe()
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
                    //process.arguments = [self.searchQuery]
                    process.arguments = argumentsArray
                    process.standardOutput = stdOut
                    
//                    process.waitUntilExit()
                    
                    do {
                            try process.run()
                        }
                    catch{ print(error)}
                        
                    let data = stdOut.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)!
                    //print(output)
                    
                    searchResults = output
                    searchResultsArray = searchResults.components(separatedBy: "\n").filter({ $0 != ""})
                    if (searchResultsArray.count != 0) {
                        showResults = true
                    } else {
                        showResults = false
                    }
                    
                    // Todo: Don't keep this
                    field1 = argumentsArray[0]
                
                    
                }) {
                    Text("Seach")
                }.padding(.trailing)
            
                // TODO: Add loading indicator and disable button for slow search
            }
            .padding(.top)
            
            Button("Show/Hide Options", action: {
                showArguments = !showArguments
            })
            
            if (showArguments && argumentsArray.count > 0) {
                HStack(alignment: .top) {
                    ForEach((0...argumentsArray.count-1), id: \.self) { i in
                        HStack {
                            if (i % 2 == 0) {
                                // It's a label
                                Text(argumentsArray[i])
                            } else {
                                // It's a modifiable value
                                TextField("Enter your search", text: self.$argumentsArray[i]).frame(width: 100)
                            }
                            
                        }
                    }
                    Button("Search with these options", action: {
                        
                    })
                }
            }
            
            if (showResults) {
                HStack(alignment: .top) {
                    
                    // Only show first four results
                    ForEach((0...min(3, searchResultsArray.count-1)), id: \.self) { i in
                        let filePath : String = searchResultsArray[i]
                        
                        VStack{
                            MyPreview(fileName: filePath).frame(width: 100, height: 100, alignment: .center)
                            Spacer().frame(height: 10)
                            Text(filePath.components(separatedBy: "/").last ?? "")
                        }.padding(5)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2, perform: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
                            
                        })
                        .contextMenu {
                            Button("Open", action: {
                                NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
                            })
                            Button("Show in Finder", action: {
                                NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: "/Users/")
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
                            let filePath = searchResultsArray[i]
                            VStack{
                                MyPreview(fileName: filePath).frame(width: 100, height: 100, alignment: .center)
                                Spacer().frame(height: 10)
                                Text(filePath.components(separatedBy: "/").last ?? "")
                            }
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2, perform: {
                                NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
                                
                            })
                            .contextMenu {
                                Button("Open", action: {
                                    NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
                                })
                                Button("Show in Finder", action: {
                                    NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: "/Users/")
                                })
                            }.onTapGesture(count: 1, perform: {
                                selectedColor[i] = (selectedColor[i] == .blue) ? Color.clear : Color.blue
                                for l in 0...selectedColor.count-1 {
                                    if (l != i) {
                                        selectedColor[l] = Color.clear
                                    }
                                }
                            }).gesture(TapGesture(count: 2).onEnded {
                                // Opent a file on double click
                                print("double clicked")
                            })
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

