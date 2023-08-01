//
//  SearchView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/2/23.
//

import SwiftUI

private enum SearchType: String, CaseIterable {
    case person = "Person"
    case meet = "Meet"
}

enum SearchField: Int, Hashable, CaseIterable {
    case firstName
    case lastName
    case meetName
    case meetOrg
}

private enum FilterType: String, CaseIterable {
    case name = "Name"
    case startDate = "Start Date"
    case state = "State"
}

private extension SearchInputView {
    var hasReachedPersonStart: Bool {
        self.focusedField == SearchField.allCases.first
    }
    
    var hasReachedMeetStart: Bool {
        self.focusedField == SearchField.meetName
    }
    
    var hasReachedPersonEnd: Bool {
        self.focusedField == SearchField.lastName
    }
    
    var hasReachedMeetEnd: Bool {
        self.focusedField == SearchField.allCases.last
    }
    
    func dismissKeyboard() {
        self.focusedField = nil
    }
    
    func nextPersonField() {
        guard let currentInput = focusedField else { return }
        let lastIndex = SearchField.lastName.rawValue
        
        let index = min(currentInput.rawValue + 1, lastIndex)
        self.focusedField = SearchField(rawValue: index)
    }
    
    func nextMeetField() {
        guard let currentInput = focusedField,
              let lastIndex = SearchField.allCases.last?.rawValue else { return }
        
        let index = min(currentInput.rawValue + 1, lastIndex)
        self.focusedField = SearchField(rawValue: index)
    }
    
    func previousPersonField() {
        guard let currentInput = focusedField,
              let firstIndex = SearchField.allCases.first?.rawValue else { return }
        
        let index = max(currentInput.rawValue - 1, firstIndex)
        self.focusedField = SearchField(rawValue: index)
    }
    
    func previousMeetField() {
        guard let currentInput = focusedField else { return }
        let firstIndex = SearchField.meetName.rawValue
        
        let index = max(currentInput.rawValue - 1, firstIndex)
        self.focusedField = SearchField(rawValue: index)
    }
    
    func next() {
        if selection == .person {
            nextPersonField()
        } else {
            nextMeetField()
        }
    }
    
    func previous() {
        if selection == .person {
            previousPersonField()
        } else {
            previousMeetField()
        }
    }
}

// Checks that for a given SearchType, at least one of the relevant fields has a value, and returns true if so.
// If all relevant fields are empty, returns false
private func checkFields(selection: SearchType, firstName: String = "",
                         lastName: String = "", meetName: String = "",
                         orgName: String = "", meetYear: String = "") -> Bool {
    switch selection {
    case .person:
        return firstName != "" || lastName != ""
    case .meet:
        return meetName != "" || orgName != "" || meetYear != ""
    }
}

// Converts the arguments passed into getPredicate into the list of unpacked parameters necessary to init
// NSPredicate; returns nil if all fields are empty
private func argsToPredParams(
    pred: String, name: String, org: String, year: String) -> NSPredicate? {
        let haveName = name != ""
        let haveOrg = org != ""
        let haveYear = year != ""
        var startDate: NSDate? = nil
        var endDate: NSDate? = nil
        
        if haveYear {
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            let startDateStr: String = "Jan 1, " + year
            startDate = df.date(from: startDateStr) as? NSDate
            let endDateStr: String = "Dec 31, " + year
            endDate = df.date(from: endDateStr) as? NSDate
        }
        
        if haveName && haveOrg && haveYear {
            guard let startDate = startDate, let endDate = endDate else { return nil }
            return NSPredicate(format: pred, name, org, startDate, endDate)
        } else if haveName && haveOrg {
            return NSPredicate(format: pred, name, org)
        } else if haveName && haveYear {
            guard let startDate = startDate, let endDate = endDate else { return nil }
            return NSPredicate(format: pred, name, startDate, endDate)
        } else if haveOrg && haveYear {
            guard let startDate = startDate, let endDate = endDate else { return nil }
            return NSPredicate(format: pred, org, startDate, endDate)
        } else if haveName {
            return NSPredicate(format: pred, name)
        } else if haveOrg {
            return NSPredicate(format: pred, org)
        } else if haveYear {
            guard let startDate = startDate, let endDate = endDate else { return nil }
            return NSPredicate(format: pred, startDate, endDate)
        }
        
        return nil
    }

// Produces Optional NSPredicate string based on which values are filled or not filled, returns nil if all fields
// are empty
private func getPredicate(name: String, org: String, year: String) -> NSPredicate? {
    if name == "" && org == "" && year == "" {
        return nil
    }
    
    var subqueries: [String] = []
    
    if name != "" {
        subqueries.append("%@ in[cd] name")
    }
    
    if org != "" {
        subqueries.append("%@ in[cd] organization")
    }
    
    if year != "" {
        subqueries.append("startDate BETWEEN {%@, %@}")
    }
    
    var resultString: String = ""
    
    // Joins all the statements together with AND
    for (idx, query) in subqueries.enumerated() {
        resultString += query
        if idx < subqueries.count - 1 {
            resultString += " AND "
        }
    }
    
    return argsToPredParams(pred: resultString, name: name, org: org, year: year)
}

struct SearchView: View {
    @State private var selection: SearchType = .person
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var meetName: String = ""
    @State private var orgName: String = ""
    @State private var meetYear: String = ""
    @State private var searchSubmitted: Bool = false
    @State var parsedLinks: DiverProfileRecords = [:]
    @State var dmSearchSubmitted: Bool = false
    @State var linksParsed: Bool = false
    @State var personTimedOut: Bool = false
    
    private var personSearchSubmitted: Bool {
        searchSubmitted && selection == .person
    }
    private var meetSearchSubmitted: Bool {
        searchSubmitted && selection == .meet
    }
    
    @ViewBuilder
    var body: some View {
        ZStack {
            if personSearchSubmitted && !personTimedOut {
                SwiftUIWebView(firstName: $firstName, lastName: $lastName,
                               parsedLinks: $parsedLinks, dmSearchSubmitted: $dmSearchSubmitted,
                               linksParsed: $linksParsed, timedOut: $personTimedOut)
            }
            
            SearchInputView(selection: $selection, firstName: $firstName, lastName: $lastName,
                            meetName: $meetName, orgName: $orgName, meetYear: $meetYear,
                            searchSubmitted: $searchSubmitted, parsedLinks: $parsedLinks,
                            dmSearchSubmitted: $dmSearchSubmitted, linksParsed: $linksParsed,
                            personTimedOut: $personTimedOut)
        }
        .ignoresSafeArea(.keyboard)
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .onDisappear {
            searchSubmitted = false
        }
        
    }
}

struct SearchInputView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.isIndexingMeets) var isIndexingMeets
    @Environment(\.getUsers) private var getUsers
    
    @State private var debounceWorkItem: DispatchWorkItem?
    @State private var showError: Bool = false
    @State var fullScreenResults: Bool = false
    @State var resultSelected: Bool = false
    @State var profileSelection: SearchDiveMeetsOrAdrenaline = .adrenaline
    @State var firstNameUsers: [User]? = []
    @State var lastNameUsers: [User]? = []
    @State var firstLastUsers: [User]? = []
    @State var results: [User]? = []
    @State var showResults: Bool = false
    @State var showAdrenalineError: Bool = false
    @State var adrenalineFormattedResults: [String: User?] = [:]
    // Tracks if the user is inside of a text field to determine when to show the keyboard
    @FocusState private var focusedField: SearchField?
    @Binding fileprivate var selection: SearchType
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var meetName: String
    @Binding var orgName: String
    @Binding var meetYear: String
    @Binding var searchSubmitted: Bool
    
    @Binding var parsedLinks: DiverProfileRecords
    @Binding var dmSearchSubmitted: Bool
    @Binding var linksParsed: Bool
    @Binding var personTimedOut: Bool
    
    @State var predicate: NSPredicate?
    @State private var filterType: FilterType = .name
    @State var isSortedAscending: Bool = true
    @ScaledMetric private var resultsOffsetScaled = 350.0
    @ScaledMetric private var resultsIconSizeScaled = 30.0
    
    var resultsOffset: CGFloat {
        min(max(resultsOffsetScaled, 410.0), UIScreen.main.bounds.height - 410)
    }
    
    var resultsIconSize: CGFloat {
        max(resultsIconSizeScaled, 15.0)
    }
    
    @FetchRequest(sortDescriptors: []) private var items: FetchedResults<DivingMeet>
    // Useful link:
    // https://stackoverflow.com/questions/61631611/swift-dynamicfetchview-fetchlimit/61632618#61632618
    // Updates the filteredItems value dynamically with predicate and sorting changes;
    // Sorts ascending/descending based on flag, but always sorts secondarily by name ascending if
    // another option is chosen
    var filteredItems: FetchedResults<DivingMeet> {
        get {
            let descriptors: [NSSortDescriptor]
            switch(filterType) {
            case .name:
                descriptors = [NSSortDescriptor(key: "name", ascending: isSortedAscending)]
                break
            case .startDate:
                descriptors = [NSSortDescriptor(key: "startDate", ascending: isSortedAscending),
                               NSSortDescriptor(key: "name", ascending: true)]
                break
            case .state:
                descriptors = [NSSortDescriptor(key: "state", ascending: isSortedAscending),
                               NSSortDescriptor(key: "name", ascending: true)]
                break
            }
            
            _items.wrappedValue.nsSortDescriptors = descriptors
            _items.wrappedValue.nsPredicate = predicate
            return items
        }
    }
    
    // Light gray
    private let deselectedBGColor: Color = Color(red: 0.94, green: 0.94,
                                                 blue: 0.94)
    private let selectedTextColor: Color = Color.white
    private let deselectedTextColor: Color = Color.blue
    
    private let cornerRadius: CGFloat = 30
    private let selectedBGColor: Color = Color.accentColor
    private let grayValue: CGFloat = 0.90
    private let grayValueDark: CGFloat = 0.10
    private let textColor: Color = Color.primary
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    @ScaledMetric private var typeBubbleWidth: CGFloat = 100
    @ScaledMetric private var typeBubbleHeight: CGFloat = 35
    
    @ScaledMetric private var typeBGWidth: CGFloat = 40
    
    private var personResultsReady: Bool {
        selection == .person && linksParsed
    }
    private var meetResultsReady: Bool {
        selection == .meet && predicate != nil
    }
    
    private func clearStateFlags() {
        showError = false
        searchSubmitted = false
        dmSearchSubmitted = false
        linksParsed = false
        parsedLinks = [:]
        predicate = nil
    }
    
    private func trimFields() {
        firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        meetName = meetName.trimmingCharacters(in: .whitespacesAndNewlines)
        orgName = orgName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatAdrenalineResults(results: [User]?) -> [String: User?] {
        var userDictionary: [String: User?] = [:]
        if let unwrappedResults = results {
            for u in unwrappedResults {
                let nameStr = (u.firstName ?? "") + " " + (u.lastName ?? "")
                userDictionary[nameStr] = u
            }
        }
        return userDictionary
    }
    
    var body: some View {
        
        NavigationView{
            ZStack {
                SearchColorfulView()
                    .ignoresSafeArea(.keyboard)
                    .onTapGesture {
                        focusedField = nil
                    }
                VStack {
                    if selection == .meet {
                        MeetSearchView(meetName: $meetName, orgName: $orgName,
                                       meetYear: $meetYear,
                                       focusedField: $focusedField)
                        .offset(y: -screenHeight * 0.15)
                    } else {
                        DiverSearchView(selection: $profileSelection, firstName: $firstName,
                                        lastName: $lastName, focusedField: $focusedField)
                        .frame(width: screenWidth * 0.85)
                        .offset(y: -screenHeight * 0.15)
                    }
                    
                    VStack {
                        Button(action: {
                            if profileSelection == .diveMeets {
                                // Need to initially set search to false so webView gets recreated
                                searchSubmitted = false
                                
                                // Resets focusedField so keyboard disappears
                                focusedField = nil
                                
                                // Only submits a search if one of the relevant fields is filled,
                                // otherwise toggles error
                                if checkFields(selection: selection, firstName: firstName,
                                               lastName: lastName, meetName: meetName,
                                               orgName: orgName, meetYear: meetYear) {
                                    clearStateFlags()
                                    trimFields()
                                    
                                    searchSubmitted = true
                                    
                                    if selection == .meet {
                                        predicate = getPredicate(name: meetName, org: orgName,
                                                                 year: meetYear)
                                    }
                                } else {
                                    clearStateFlags()
                                    showError = true
                                }
                            } else {
                                results = []
                                adrenalineFormattedResults = [:]
                                showError = false
                                showResults = false
                                results = getUsers(firstName, lastName)
                                if results == [] {
                                    showAdrenalineError = true
                                } else {
                                    showResults = true
                                }
                                adrenalineFormattedResults = formatAdrenalineResults(results: results)
                            }
                        }, label: {
                            Text("Submit")
                                .animation(nil, value: selection)
                                .foregroundColor(.primary)
                        })
                        .buttonStyle(.bordered)
                        .cornerRadius(cornerRadius)
                        .animation(nil, value: selection)
                        if selection == .person && searchSubmitted && !linksParsed {
                            ProgressView()
                        }
                    }
                    .frame(width: screenWidth * 0.85)
                    .ignoresSafeArea(.keyboard)
                    .offset(y: selection == .person ? -screenHeight * 0.188 : isIndexingMeets ? -screenHeight * 0.38 : -screenHeight * 0.24)
                    if showError {
                        Text("You must enter at least one field to search")
                            .foregroundColor(Color.red)
                        
                    } else {
                        Text("")
                    }
                }
                .ignoresSafeArea(.keyboard)
                .overlay {
                    VStack {
                        ZStack{
                            Rectangle()
                                .foregroundColor(Custom.grayThinMaterial)
                                .mask(RoundedRectangle(cornerRadius: 40))
                                .frame(width: 120, height: 40)
                                .shadow(radius: 6)
                            Text("Search")
                                .font(.title2).bold()
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: typeBubbleWidth * 2 + 5,
                                       height: typeBGWidth)
                                .foregroundColor(Custom.grayThinMaterial)
                                .shadow(radius: 5)
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: typeBubbleWidth,
                                       height: typeBubbleHeight)
                                .foregroundColor(Custom.darkGray)
                                .offset(x: selection == .person
                                        ? -typeBubbleWidth / 2
                                        : typeBubbleWidth / 2)
                                .animation(.spring(response: 0.2), value: selection)
                            HStack(spacing: 0) {
                                Button(action: {
                                    if selection == .meet {
                                        clearStateFlags()
                                        debounceTabSelection(.person)
                                    }
                                }, label: {
                                    Text(SearchType.person.rawValue)
                                        .animation(nil, value: selection)
                                })
                                .frame(width: typeBubbleWidth,
                                       height: typeBubbleHeight)
                                .foregroundColor(textColor)
                                .cornerRadius(cornerRadius)
                                Button(action: {
                                    if selection == .person {
                                        clearStateFlags()
                                        debounceTabSelection(.meet)
                                    }
                                }, label: {
                                    Text(SearchType.meet.rawValue)
                                        .animation(nil, value: selection)
                                })
                                .frame(width: typeBubbleWidth,
                                       height: typeBubbleHeight)
                                .foregroundColor(textColor)
                                .cornerRadius(cornerRadius)
                            }
                        }
                    }
                    .offset(y: -screenHeight * 0.4)
                }
                .ignoresSafeArea(.keyboard)
                
                if showResults {
                    ZStack (alignment: .topLeading) {
                        (RecordList(records: $parsedLinks, adrenalineRecords: $adrenalineFormattedResults,
                                    resultSelected: $resultSelected,
                                    fullScreenResults: $fullScreenResults,
                                    selectionType: $profileSelection))
                        .onAppear {
                            fullScreenResults = true
                            resultSelected = false
                        }
                        HStack {
                            if !resultSelected {
                                Button(action: { () -> () in fullScreenResults.toggle() }) {
                                    Image(systemName: "chevron.down")
                                }
                                .rotationEffect(.degrees(fullScreenResults ? 0: -180))
                                .frame(width: resultsIconSize, height: resultsIconSize)
                                .clipShape(Rectangle())
                            }
                            
                            Spacer()
                            if meetResultsReady {
                                Menu {
                                    Picker("", selection: $filterType) {
                                        ForEach(FilterType.allCases, id: \.self) {
                                            Text($0.rawValue)
                                                .tag($0)
                                        }
                                    }
                                    Button(action: { isSortedAscending.toggle() }) {
                                        Label("Sort: \(isSortedAscending ? "Ascending" : "Descending")",
                                              systemImage: "arrow.up.arrow.down")
                                    }
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                }
                            }
                        }
                        .offset(y: 15)
                        .padding(EdgeInsets(top: 5, leading: 18, bottom: 10, trailing: 18))
                        .foregroundColor(.primary)
                        .font(.title)
                    }
                    .cornerRadius(30)
                    .shadow(radius: 10)
                    .offset(y: fullScreenResults ? screenHeight * 0.05 : resultsOffset)
                    .animation(.linear(duration: 0.2), value: fullScreenResults)
                }
                
                if personResultsReady || meetResultsReady {
                    ZStack (alignment: .topLeading) {
                        (selection == .person
                         ? AnyView(RecordList(records: $parsedLinks, adrenalineRecords: $adrenalineFormattedResults,
                                              resultSelected: $resultSelected,
                                              fullScreenResults: $fullScreenResults,
                                              selectionType: $profileSelection))
                         : AnyView(MeetResultsView(records: filteredItems)))
                        .onAppear {
                            fullScreenResults = true
                            resultSelected = false
                        }
                        HStack {
                            if !resultSelected {
                                Button(action: { () -> () in fullScreenResults.toggle() }) {
                                    Image(systemName: "chevron.down")
                                }
                                .rotationEffect(.degrees(fullScreenResults ? 0: -180))
                                .frame(width: resultsIconSize, height: resultsIconSize)
                                .clipShape(Rectangle())
                            }
                            
                            Spacer()
                            if meetResultsReady {
                                Menu {
                                    Picker("", selection: $filterType) {
                                        ForEach(FilterType.allCases, id: \.self) {
                                            Text($0.rawValue)
                                                .tag($0)
                                        }
                                    }
                                    Button(action: { isSortedAscending.toggle() }) {
                                        Label("Sort: \(isSortedAscending ? "Ascending" : "Descending")",
                                              systemImage: "arrow.up.arrow.down")
                                    }
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                }
                            }
                        }
                        .offset(y: 15)
                        .padding(EdgeInsets(top: 5, leading: 18, bottom: 10, trailing: 18))
                        .foregroundColor(.primary)
                        .font(.title)
                    }
                    .cornerRadius(30)
                    .shadow(radius: 10)
                    .offset(y: fullScreenResults ? screenHeight * 0.05 : resultsOffset)
                    .animation(.linear(duration: 0.2), value: fullScreenResults)
                }
            }
            .ignoresSafeArea(.keyboard)
            .onSwipeGesture(trigger: .onEnded) { direction in
                if direction == .left && selection == .person {
                    selection = .meet
                } else if direction == .right && selection == .meet {
                    selection = .person
                }
                
            }
            .onAppear {
                showError = false
            }
            // Keyboard toolbar with up/down arrows and Done button
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: previous) {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(hasReachedPersonStart || hasReachedMeetStart)
                    
                    Button(action: next) {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(hasReachedPersonEnd || hasReachedMeetEnd)
                    
                    Spacer()
                    
                    Button(action: dismissKeyboard) {
                        Text("**Done**")
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func debounceTabSelection(_ newSelection: SearchType) {
        debounceWorkItem?.cancel() // Cancel previous debounce work item if exists
        
        let workItem = DispatchWorkItem { [self] in
            self.selection = newSelection
        }
        
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
}

struct IndexingCounterView: View {
    @Environment(\.meetsParsedCount) var meetsParsedCount
    @Environment(\.totalMeetsParsedCount) var totalMeetsParsedCount
    @Environment(\.isFinishedCounting) var isFinishedCounting
    private let screenWidth = UIScreen.main.bounds.width
    
    private func getPercentString(count: Int, total: Int) -> String {
        return String(Int(trunc(Double(count) / Double(total) * 100)))
    }
    
    var body: some View {
        VStack {
            // Displays loading bar if counts are done, otherwise shows indefinite
            // progress bar
            Group {
                if isFinishedCounting {
                    VStack(alignment: .leading) {
                        Text("Indexing...")
                            .font(.headline)
                            .padding(.leading)
                        ProgressView(value: Double(meetsParsedCount),
                                     total: Double(totalMeetsParsedCount))
                        .progressViewStyle(.linear)
                        .frame(width: 250)
                        .padding(.leading)
                        Text(getPercentString(count: meetsParsedCount,
                                              total: totalMeetsParsedCount)
                             + "%")
                        .foregroundColor(.gray)
                        .padding(.leading)
                    }
                } else {
                    VStack {
                        Text("Indexing...")
                            .font(.headline)
                            .padding(.leading)
                        ProgressView()
                    }
                }
            }
            .padding(.bottom)
            Text("Some results may not appear in Search yet")
                .dynamicTypeSize(.xSmall ... .large)
                .frame(width: 0.8 * screenWidth)
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

struct DiverSearchView: View {
    //false means diveMeets
    @Binding var selection: SearchDiveMeetsOrAdrenaline
    @Binding var firstName: String
    @Binding var lastName: String
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    fileprivate var focusedField: FocusState<SearchField?>.Binding
    
    var body: some View {
        VStack {
            DiveMeetsAdrenalineSelection(selection: $selection)
                .padding(.top, screenHeight * 0.1)
                .padding(.bottom, screenHeight * 0.03)
            BackgroundBubble(vPadding: 80) {
                VStack {
                    HStack {
                        Text("First Name:")
                            .padding([.leading, .bottom, .top])
                        TextField("First Name", text: $firstName)
                            .modifier(TextFieldClearButton(text: $firstName,
                                                           fieldType: .firstName,
                                                           focusedField: focusedField))
                            .multilineTextAlignment(.leading)
                            .disableAutocorrection(true)
                            .textFieldStyle(.roundedBorder)
                            .padding(.trailing)
                            .focused(focusedField, equals: .firstName)
                    }
                    HStack {
                        Text("Last Name:")
                            .padding([.leading])
                        TextField("Last Name", text: $lastName)
                            .modifier(TextFieldClearButton(text: $lastName,
                                                           fieldType: .lastName,
                                                           focusedField: focusedField))
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                            .padding(.trailing)
                            .focused(focusedField, equals: .lastName)
                        
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .offset(y: -screenHeight * 0.03)
        .frame(width: screenWidth * 0.85, height: screenHeight * 0.3)
    }
}


struct MeetSearchView: View {
    @Environment(\.meetsParsedCount) var meetsParsedCount
    @Environment(\.totalMeetsParsedCount) var totalMeetsParsedCount
    @Environment(\.isIndexingMeets) var isIndexingMeets
    @Binding var meetName: String
    @Binding var orgName: String
    @Binding var meetYear: String
    @State var meetYearIndex: Int = 0
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var focusedField: FocusState<SearchField?>.Binding
    private let currentYear: Int = Calendar.current.component(.year, from: Date())
    
    @ScaledMetric var pickerFontSize: CGFloat = 18
    
    private func meetIndexToString(_ index: Int) -> String {
        return index == 0 ? "" : String(currentYear - index + 1)
    }
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    
    fileprivate init(meetName: Binding<String>, orgName: Binding<String>,
                     meetYear: Binding<String>, focusedField: FocusState<SearchField?>.Binding) {
        self._meetName = meetName
        self._orgName = orgName
        self._meetYear = meetYear
        self.focusedField = focusedField
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .mask(RoundedRectangle(cornerRadius: 50))
                .foregroundColor(Custom.grayThinMaterial)
                .shadow(radius: 10)
                .frame(width: screenWidth * 0.9, height: isIndexingMeets ? screenHeight * 0.6 : screenHeight * 0.31)
                .offset(y: isPhone ? (isIndexingMeets ? screenWidth * 0.33 : screenWidth * 0.015) : isIndexingMeets ? screenHeight * 0.15 : screenWidth * 0.015)
            VStack {
                Spacer()
                HStack {
                    Text("Meet Name:")
                        .padding(.leading)
                    TextField("Meet Name", text: $meetName)
                        .disableAutocorrection(true)
                        .modifier(TextFieldClearButton(text: $meetName,
                                                       fieldType: .meetName,
                                                       focusedField: focusedField))
                        .multilineTextAlignment(.leading)
                        .textFieldStyle(.roundedBorder)
                        .padding(.trailing)
                        .focused(focusedField, equals: .meetName)
                }
                .padding(.top, 20)
                HStack {
                    Text("Organization Name:")
                        .padding(.leading)
                    TextField("Organization Name", text: $orgName)
                        .disableAutocorrection(true)
                        .modifier(TextFieldClearButton(text: $orgName,
                                                       fieldType: .meetOrg,
                                                       focusedField: focusedField))
                        .multilineTextAlignment(.leading)
                        .textFieldStyle(.roundedBorder)
                        .padding(.trailing)
                        .focused(focusedField, equals: .meetOrg)
                }
                HStack {
                    Text("Meet Year:")
                        .padding(.leading)
                    NoStickPicker(selection: $meetYearIndex,
                                  rowCount: (2004...currentYear).count + 1) { r in
                        let label = UILabel()
                        label.attributedText = NSMutableAttributedString(string: meetIndexToString(r))
                        label.font = UIFont.systemFont(ofSize: pickerFontSize)
                        label.sizeToFit()
                        label.layer.masksToBounds = true
                        return label
                    }
                                  .pickerStyle(.wheel)
                                  .frame(width: 125, height: 85)
                                  .padding(.trailing)
                                  .onChange(of: meetYearIndex) { newValue in
                                      meetYear = meetIndexToString(newValue)
                                  }
                }
                .offset(y: -20)
                if isIndexingMeets {
                    IndexingCounterView()
                        .offset(y: screenHeight * 0.1)
                }
                Spacer()
            }
            .dynamicTypeSize(.xSmall ... .xxxLarge)
            .frame(width: screenWidth * 0.9, height: screenHeight * 0.3)
            .offset(y: isIndexingMeets ? screenHeight * 0.04: -screenHeight * 0.02)
            .padding([.top, .leading, .trailing])
            .onAppear {
                meetName = ""
                orgName = ""
                meetYear = ""
            }
        }
    }
}


struct MeetResultsView : View {
    @Environment(\.colorScheme) var currentMode
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    @ScaledMetric private var rowSpacing: CGFloat = 20
    
    var records: FetchedResults<DivingMeet>
    private let grayValue: CGFloat = 0.95
    private let grayValueDark: CGFloat = 0.10
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private var grayColor: Color {
        currentMode == .light
        ? Color(red: grayValue, green: grayValue, blue: grayValue)
        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
    }
    
    private func dateToString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: date)
    }
    
    var body: some View {
        ZStack {
            Custom.specialGray.ignoresSafeArea()
            VStack(alignment: .leading) {
                Text("Results")
                    .bold()
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                    .padding(.leading, 20)
                    .padding(.top, 50)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !records.isEmpty {
                    ScalingScrollView(records: records, bgColor: Custom.specialGray,
                                      rowSpacing: rowSpacing, shadowRadius: 5) { (e) in
                        NavigationLink(destination: MeetPageView(meetLink: e.link ?? "")) {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(Custom.darkGray)
                                    .cornerRadius(40)
                                VStack {
                                    if let name = e.name, let city = e.city, let state = e.state,
                                       let startDate = e.startDate, let endDate = e.endDate {
                                        HStack(alignment: .top) {
                                            Text(name)
                                                .font(.title3)
                                                .bold()
                                            Spacer()
                                            Text(city + ", " + state)
                                        }
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(2)
                                        Spacer()
                                        HStack {
                                            Text(e.organization ?? "")
                                            Spacer()
                                            Text(dateToString(startDate)
                                                 + " - " + dateToString(endDate))
                                        }
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(1)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                                      .padding(.bottom, maxHeightOffset)
                }
                Spacer()
            }
        }
    }
}

enum SearchDiveMeetsOrAdrenaline: String, CaseIterable {
    case diveMeets = "DiveMeets"
    case adrenaline = "Adrenaline"
}

struct DiveMeetsAdrenalineSelection: View {
    @Binding var selection: SearchDiveMeetsOrAdrenaline
    
    private let cornerRadius: CGFloat = 30
    private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Custom.darkGray)
                .shadow(radius: 10)
            HStack(spacing: 0) {
                ForEach(SearchDiveMeetsOrAdrenaline.allCases, id: \.self) { s in
                    ZStack {
                        // Weird padding stuff to have end options rounded on the outside edge
                        // only when selected
                        // https://stackoverflow.com/a/72435691/22068672
                        Rectangle()
                            .fill(selection == s ? selectedGray : .clear)
                            .padding(.trailing, s == SearchDiveMeetsOrAdrenaline.allCases.first
                                     ? cornerRadius
                                     : 0)
                            .padding(.leading, s == SearchDiveMeetsOrAdrenaline.allCases.last
                                     ? cornerRadius
                                     : 0)
                            .cornerRadius(s == SearchDiveMeetsOrAdrenaline.allCases.first ||
                                          s == SearchDiveMeetsOrAdrenaline.allCases.last
                                          ? cornerRadius
                                          : 0)
                            .padding(.trailing, s == SearchDiveMeetsOrAdrenaline.allCases.first
                                     ? -cornerRadius
                                     : 0)
                            .padding(.leading, s == SearchDiveMeetsOrAdrenaline.allCases.last
                                     ? -cornerRadius
                                     : 0)
                        Text(s.rawValue)
                    }
                    .dynamicTypeSize(.xSmall ... .xxxLarge)
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .onTapGesture {
                        selection = s
                    }
                    if s != SearchDiveMeetsOrAdrenaline.allCases.last {
                        Divider()
                    }
                }
            }
        }
        .frame(height: 50)
        .padding([.leading, .trailing])
    }
}
