//
//  ContentView.swift
//  CS592 Project
//
//  Created by Benjamin Hardin on 10/27/21.
//

import SwiftUI
import Quartz

func parseUserEdits(editedAndArgs: [String], editedOrArgs: [String]) -> (String, [String], [String]) {
    // Yes this is basically duplicated code :(
    
    var andArgs : [String] = []
    var andArgsToShow : [String] = [] // Args to allow the user to edit
    var orArgs : [String] = []
    var orArgsToShow : [String] = [] // Args to allow the user to edit
    
    
    // Assumes a singular "and" with up to one nested "or" at the end
    // Future work should parse this string into a tree of conjunctions to avoid this
    
    var haveFoundOr = false
    
    let allArgs = editedAndArgs + editedOrArgs
    for i in stride(from: 0, to: allArgs.count-1, by: 2) {
        let term = allArgs[i]
        
            var arg = ""
            var arg1ToShow = ""
            var arg2ToShow = ""
            
            let kind = allArgs[i]
            let name1 = allArgs[i+1]
            
            
            // Current year
            let date = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: date)
            let year = components.year!
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            switch (kind) {
            case "kind":
                if (name1 == "presentation") {
                    arg = "(kMDItemFSName == *.pptx || kMDItemFSName == *.key)"
                    arg1ToShow = "kind"
                    arg2ToShow = "presentation"
                } else if (name1 == "PDF") {
                    arg = "kMDItemFSName == *.pdf"
                    arg1ToShow = "kind"
                    arg2ToShow = "pdf"
                } else if (name1 == "Microsoft") {
                    // Full string is Microsoft Word Document
                    arg = "(kMDItemFSName == *.docx || kMDItemFSName == *.pages)"
                    arg1ToShow = "kind"
                    arg2ToShow = "document"
                }
                break
            case "created in":
                if (Int(name1) == nil) {
                    // month
                    let moNo = convertMonthToNumber(month: name1)
                    let currentMoNo = components.month!
                    let monthDiff = currentMoNo - moNo
                    
                    arg = "kMDItemFSCreationDate >= $time.this_month(-\(monthDiff)) && kMDItemFSCreationDate <= $time.this_month(-\(monthDiff - 1))"
        
                } else {
                    // year
                    let earlierYear = Int(name1)
                    let yearDiff = year - (earlierYear ?? 2021)
                    
                    arg = "kMDItemFSCreationDate >= $time.this_year(-\(yearDiff)) && kMDItemFSCreationDate <= $time.this_year(-\(yearDiff - 1))"
                    
                }
                arg1ToShow = "created in"
                arg2ToShow = name1
                
                break
            case "modified on":
                // Note: for modified, name1 == "Month" and name2 == the actual month
                // 'kMDItemContentModificationDate < $time.iso(2018-10-30T16:00:00) && kMDItemContentModificationDate > $time.iso(2018-10-30T10:00:00)'
                print("modified on ", name1)
                let moNo = convertMonthToNumber(month: name1)
                let currentMoNo = components.month!
                let monthDiff = currentMoNo - moNo
                
                // kMDItemContentModificationDate
                
                arg = "kMDItemContentModificationDate >= $time.this_month(-\(monthDiff)) && kMDItemContentModificationDate <= $time.this_month(-\(monthDiff - 1))"
//                    var lowerDateComponents = DateComponents()
//                    lowerDateComponents.year = year
//                    lowerDateComponents.month = moNo
//                    lowerDateComponents.day = 1
//                    let userCalendar = Calendar(identifier: .gregorian) // since the components above (like year 1980) are for Gregorian
//                    let earlyDate = userCalendar.date(from: lowerDateComponents)
//                    let lowerDateString = formatter.string(from: earlyDate!)
//
//                    var upperDateComponents = DateComponents()
//                    upperDateComponents.year = year
//                    upperDateComponents.month = moNo
//                    upperDateComponents.day = getLastDay(month: moNo)
//                    let lateDate = userCalendar.date(from: lowerDateComponents)
//                    let upperDateString = formatter.string(from: lateDate!)
                arg1ToShow = "modified on"
                arg2ToShow = name1
                
                break
            case "from":
                // name2 is where downloaded from
                arg = "kMDItemWhereFroms == \(name1)"
                arg1ToShow = "from"
                arg2ToShow = name1
                break
            case "name includes":
                // name2 should be included in file
                arg = "kMDItemFSName == *\(name1)"
                arg1ToShow = "name includes"
                arg2ToShow = name1
                break
            case "size":
                if (name1 == "small") {
                    // Small file
                    arg = "kMDItemFSSize <= 5000"
                    arg1ToShow = "size"
                    arg2ToShow = "small"
                } else {
                    print("large")
                    // Large file
                    arg = "kMDItemFSSize >= 5000"
                    arg1ToShow = "size"
                    arg2ToShow = "large"
                }
                break
            default:
                break
            }
            
            
            if (i >= andArgs.count) {
                // Add to or arguments
                orArgs.append(arg)
                orArgsToShow.append(arg1ToShow)
                orArgsToShow.append(arg2ToShow)
            } else {
                // Add to and arguments
                andArgs.append(arg)
                andArgsToShow.append(arg1ToShow)
                andArgsToShow.append(arg2ToShow)
            }
        
    }
    
    var mdfindQuery = ""
    if (andArgs.count > 0) {
        //mdfindQuery = "\'"
    }

    for (index, arg) in andArgs.enumerated() {
        mdfindQuery += " " + arg
        if (index != andArgs.count - 1 || orArgs.count != 0) {
            mdfindQuery += " &&"
        }
    }
    
    if (orArgs.count != 0) {
        mdfindQuery += "("
    }
    for (index, arg) in orArgs.enumerated() {
        mdfindQuery += " (" + arg + ")"
        if (index != orArgs.count - 1) {
            mdfindQuery += " ||"
        }
    }
    
    if (orArgs.count != 0) {
        mdfindQuery += ")"
    }
    
    if (mdfindQuery != "") {
        //mdfindQuery += "\'"
    }
    
    
    // Todo: prioritize documents in documents, desktop and downloads folders. Run queries on those first, merge the queries, and then return all the results
    
    print("mdfind Query: ", mdfindQuery)
    return (mdfindQuery, andArgsToShow, orArgsToShow)
    
}


func parseSEMPREOutput(input: String) -> (String, [String], [String]) {
    // Example: (and (type presentation) (year 2019) (folder Downloads) (downloaded_from xyz.com))
    
    var andArgs : [String] = []
    var andArgsToShow : [String] = [] // Args to allow the user to edit
    var orArgs : [String] = []
    var orArgsToShow : [String] = [] // Args to allow the user to edit
    
    
    // Assumes a singular "and" with up to one nested "or" at the end
    // Future work should parse this string into a tree of conjunctions to avoid this
    
    print("about to parse query!")
    
    var haveFoundOr = false
    
    let terms = input.lowercased().components(separatedBy: "(")
    for term in terms {
        
        if (term.contains("string")) {
            if let termSubstring = term.range(of: "(?<=\")[^\"]+", options: .regularExpression) {
                // Term substring is the part between quotes
                var arg = ""
                var arg1ToShow = ""
                var arg2ToShow = ""
                
                let kindAndName = term.substring(with: termSubstring).components(separatedBy: " ")
                print("kind and name is ", kindAndName)
                let kind = kindAndName[0]
                let name1 = kindAndName[1]
                var name2 = ""
                if (kindAndName.count > 2) {
                    name2 = kindAndName[2]
                }
                
                
                // Current year
                let date = Date()
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month], from: date)
                let year = components.year!

                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                switch (kind) {
                case "kind":
                    if (name1 == "presentation") {
                        arg = "(kMDItemFSName == *.pptx || kMDItemFSName == *.key)"
                        arg1ToShow = "kind"
                        arg2ToShow = "presentation"
                    } else if (name1 == "PDF") {
                        arg = "pdf"
                        arg1ToShow = "kind"
                        arg2ToShow = "pdf"
                    } else if (name1 == "document") {
                        // Full string is Microsoft Word Document
                        arg = "(kMDItemFSName == *.docx || kMDItemFSName == *.pages)"
                        arg1ToShow = "kind"
                        arg2ToShow = "document"
                    }
                    break
                case "created":
                    if (name1 == "Month") {
                        // month
                        let moNo = convertMonthToNumber(month: name2)
                        let currentMoNo = components.month!
                        let monthDiff = currentMoNo - moNo
                        
                        arg = "kMDItemFSCreationDate >= $time.this_month(-\(monthDiff)) && kMDItemFSCreationDate <= $time.this_month(-\(monthDiff - 1))"
            
                    } else {
                        // year
                        let earlierYear = Int(name2)
                        let yearDiff = year - earlierYear!
                        
                        arg = "kMDItemFSCreationDate >= $time.this_year(-\(yearDiff)) && kMDItemFSCreationDate <= $time.this_year(-\(yearDiff - 1))"
                        
                    }
                    arg1ToShow = "created in"
                    arg2ToShow = name2
                    
                    break
                case "modified":
                    // Note: for modified, name1 == "Month" and name2 == the actual month
                    // 'kMDItemContentModificationDate < $time.iso(2018-10-30T16:00:00) && kMDItemContentModificationDate > $time.iso(2018-10-30T10:00:00)'
                    let moNo = convertMonthToNumber(month: name2)
                    let currentMoNo = components.month!
                    let monthDiff = currentMoNo - moNo
                    
                    // kMDItemContentModificationDate
                    
                    arg = "kMDItemContentModificationDate >= $time.this_month(-\(monthDiff)) && kMDItemContentModificationDate <= $time.this_month(-\(monthDiff - 1))"
//                    var lowerDateComponents = DateComponents()
//                    lowerDateComponents.year = year
//                    lowerDateComponents.month = moNo
//                    lowerDateComponents.day = 1
//                    let userCalendar = Calendar(identifier: .gregorian) // since the components above (like year 1980) are for Gregorian
//                    let earlyDate = userCalendar.date(from: lowerDateComponents)
//                    let lowerDateString = formatter.string(from: earlyDate!)
//
//                    var upperDateComponents = DateComponents()
//                    upperDateComponents.year = year
//                    upperDateComponents.month = moNo
//                    upperDateComponents.day = getLastDay(month: moNo)
//                    let lateDate = userCalendar.date(from: lowerDateComponents)
//                    let upperDateString = formatter.string(from: lateDate!)
                    arg1ToShow = "modified on"
                    arg2ToShow = name2
                    
                    break
                case "where":
                    if (name1 == "from") {
                        // name2 is where downloaded from
                        arg = "kMDItemWhereFroms == \(name2)"
                        arg1ToShow = "from"
                        arg2ToShow = name2
                    } else {
                        // name2 should be included in file
                        arg = "kMDItemFSName == *\(name2)"
                        arg1ToShow = "name includes"
                        arg2ToShow = name2
                    }
                    break
                case "size":
                    if (name1.contains("<")) {
                        // Small file
                        arg = "kMDItemFSSize <= 5000"
                        arg1ToShow = "size"
                        arg2ToShow = "small"
                    } else {
                        // Large file
                        arg = "kMDItemFSSize >= 5000"
                        arg1ToShow = "size"
                        arg2ToShow = "large"
                    }
                    break
                default:
                    break
                }
                
                
                if (haveFoundOr) {
                    // Add to or arguments
                    orArgs.append(arg)
                    orArgsToShow.append(arg1ToShow)
                    orArgsToShow.append(arg2ToShow)
                } else {
                    // Add to and arguments
                    andArgs.append(arg)
                    andArgsToShow.append(arg1ToShow)
                    andArgsToShow.append(arg2ToShow)
                }
            }
            
        }
        else if (term == "(or") {
            haveFoundOr = true
        }
        
        
        /*
        print(term)
        var term2 = term.components(separatedBy: "\"")
        if (term2.count > 1) {
            
            term2.removeAll(where: {$0 == "\""})
            print("removed quotes ", term2)
        let kindAndName = term2[1].components(separatedBy: " ")
        print("kindandname ", kindAndName)
            var query = ""
            var kind = ""
            if (kindAndName.count == 2) {
                 kind = kindAndName[0]
                query = kindAndName[1]
            }
            else if (kindAndName.count == 3) {
                kind = kindAndName[1]
                query = kindAndName[2]
            }
            
            print("kind and query:", kind, query)
            
            query.removeAll(where: {$0 == ")"})
            
            switch(kind) {
            case "kind":
                // Options accepted by mdfind for kind/type
                let kindOptions = ["application", "applications", "app", "audio", "music", "bookmark", "bookmarks", "contact", "contacts", "email", "emails", "mail message", "mail messages", "folder", "folders", "font", "fonts", "event", "events", "todo", "todos", "to do", "to dos", "image", "images", "movie", "movies", "pdf", "pdfs", "system preferences", "preferences", "presentations", "presentation"]
                if (kindOptions.contains(query)) {
                    print("right here")
                    mdfindQuery += "(kMDItemDisplayName == *.key*)"
                    print("md is ", mdfindQuery)
//                    mdfindQuery += " kind:" + query
                    //argumentsArray.append("kind")
                    //argumentsArray.append(query)
                }
                
                break
            case "year":
                
                // convert year to int and subtract from current year
                let yearInt = Int(query)!
                let year_diff = Calendar.current.component(.year, from: Date()) - yearInt
                if (year_diff == 0) {
                    query = "this year"
                    // Options accepted by mdfind for date
                    let dateOptions = ["today", "yesterday", "this week", "this month", "this year", "tomorrow", "next month", "next week", "next year"]
                    mdfindQuery += " date:" + query
                } else {
                    query = " && (kMDItemFSContentChangeDate >= $time.this_year(-\(year_diff)))"
                    mdfindQuery += query
                }
                
                
                //argumentsArray.append("date")
                //argumentsArray.append(query)
                print(query)
                break
            case "folder":
                let folderOptions = ["Documents", "Downloads", "Desktop"]
                if (folderOptions.contains(query)) {
                    mdfindQuery += " -onlyin " + query
                    //argumentsArray.append("-onlyin")
                    //argumentsArray.append(query)
                }
                
                break
            case "downloaded_from":
                mdfindQuery += " \"kMDItemWhereFroms:" + query + "\""
                //argumentsArray.append("Where From")
                //argumentsArray.append(query)
                break
            default:
                break
            }
        }*/
        
    }
    
    var mdfindQuery = ""
    if (andArgs.count > 0) {
        //mdfindQuery = "\'"
    }

    for (index, arg) in andArgs.enumerated() {
        mdfindQuery += " " + arg
        if (index != andArgs.count - 1 || orArgs.count != 0) {
            mdfindQuery += " &&"
        }
    }
    
    if (orArgs.count != 0) {
        mdfindQuery += "("
    }
    for (index, arg) in orArgs.enumerated() {
        mdfindQuery += " (" + arg + ")"
        if (index != orArgs.count - 1) {
            mdfindQuery += " ||"
        }
    }
    
    if (orArgs.count != 0) {
        mdfindQuery += ")"
    }
    
    if (mdfindQuery != "") {
        //mdfindQuery += "\'"
    }
    
    
    // Todo: prioritize documents in documents, desktop and downloads folders. Run queries on those first, merge the queries, and then return all the results
    
    print("mdfind Query: ", mdfindQuery)
    return (mdfindQuery, andArgsToShow, orArgsToShow)
    
}

func runSEMPRE(query: String) -> String {
    
    
    
    let stdOut = Pipe()
    let process = Process()
    // TODO: File path will need to be changed. Could prompt the user to show the location when they start the app
    //FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
    process.executableURL = URL(fileURLWithPath: "/Users/Ben/Downloads/sempre/test.sh")
    process.arguments = [query]
    process.standardOutput = stdOut

    var output = ""
    
    do {
        print("running")
        try process.run()
        process.waitUntilExit()
        print("ran")
        
        let data = stdOut.fileHandleForReading.readDataToEndOfFile()
        
        output = String(data: data, encoding: .utf8)!
        print("output ", output)
        
    }
    catch{ print(error)}
    
    print("Finished running SEMPRE")
    let file = "test"
    //let data = stdOut.fileHandleForReading.readDataToEndOfFile()
    //if let dir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {

    let fileURL = URL(fileURLWithPath: "/Users/Ben/Downloads/sempre/test")

    //reading
    do {
        let text2 = try String(contentsOf: fileURL, encoding: .utf8)
        print("printing output")
        var split = text2.components(separatedBy: "Top formula")
        output = split.last ?? ""
        split = output.components(separatedBy: "Top value")
        output = split.first ?? ""
        output = output.replacingOccurrences(of: "{", with: "")
        output = output.replacingOccurrences(of: "}", with: "")
        print(output)
        print("that was output")
    }
    catch {
        print("Couldn't find sempre file output")
        return "error"
        
    }

    return output
    
}

func runSpotlight(argumentsArray: [String]) -> String {
    let stdOut = Pipe()
    let process = Process()
    
    // Run the mdfind (Spotlight) process
    process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
//    var formattedArgs : [String] = []
//    if (argumentsArray.count - 2 > 0) {
//        for i in stride(from: 0, to: argumentsArray.count-1, by: 2) {
//            let arg = argumentsArray[i] + argumentsArray[i+1]
//            formattedArgs.append(arg)
//        }
//    }
//    print("Formatted args: ", formattedArgs)
    
    //print("args array ", argumentsArray)
    process.arguments = argumentsArray
    process.standardOutput = stdOut
    
    var output = ""
    do {
            try process.run()
        let data = stdOut.fileHandleForReading.readDataToEndOfFile()
        output = String(data: data, encoding: .utf8)!
        }
    catch{ print(error)}
    
    //print(output)
    
    return output
}

struct ContentView: View {
    
    @State var searchQuery = ""
    @State var searchResults = ""
    @State var searchResultsArray = [""]
    @State var showResults = false
    @State var selectedColor = [Color](repeatElement(Color.clear, count: 8))
    @State var argumentsArray : [String] = []
    @State var andArguments : [String] = []
    @State var orArguments : [String] = []
    
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
                    
                    // Run sempre and get output
                    let sempreOutput = runSEMPRE(query: searchQuery)
                    if (sempreOutput == "error") {
                        Text("SEMPRE parse error")
                        return;
                    }
                    
                    let (mdfindQuery, andArgsToShow, orArgsToShow) = parseSEMPREOutput(input: sempreOutput)
                    argumentsArray = andArgsToShow + orArgsToShow
                    andArguments = andArgsToShow
                    orArguments = orArgsToShow
                    
                    
                    searchResults = runSpotlight(argumentsArray: [mdfindQuery])
                    print("Search results: ", searchResults)
                    searchResultsArray = searchResults.components(separatedBy: "\n").filter({ $0 != ""})
                    if (searchResultsArray.count != 0) {
                        showResults = true
                    } else {
                        showResults = false
                    }
                    
                    // Todo: Don't keep this
                    //field1 = argumentsArray[0]
                    //close(stdOut)
                
                    
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
                        let andCount = andArguments.count
                        andArguments = []
                        orArguments = []
                        for (index, arg) in argumentsArray.enumerated() {
                            if (index < andCount) {
                                andArguments.append(arg)
                            } else {
                                orArguments.append(arg)
                            }
                        }
                        let (mdFindQuery, andArgs, orArgs) = parseUserEdits(editedAndArgs: andArguments, editedOrArgs: orArguments)
                        argumentsArray = andArgs + orArgs
                        andArguments = andArgs
                        orArguments = orArgs
                        searchResults = runSpotlight(argumentsArray: [mdFindQuery])
                        searchResultsArray = searchResults.components(separatedBy: "\n").filter({ $0 != ""})
                        if (searchResultsArray.count != 0) {
                            showResults = true
                        } else {
                            showResults = false
                        }
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

func convertMonthToNumber(month: String) -> Int {
    // Get current month number. Special thanks: https://stackoverflow.com/questions/30447058/convert-long-month-name-to-int
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "LLLL"  // if you need 3 letter month just use "LLL"
    if let date = df.date(from: month) {
        let mo = Calendar.current.component(.month, from: date)
        return mo
    }
    return 1
}

func getLastDay(month: Int) -> Int {
    let thirtyOne = [1, 3, 5, 7, 8, 10, 12]
    let thirty = [4, 6, 9, 11]
    if (thirtyOne.contains(month)) {
        return 31
    }
    else if (thirty.contains(month)) {
        return 30
    }
    return 28 // Ignore leap years :)
}
