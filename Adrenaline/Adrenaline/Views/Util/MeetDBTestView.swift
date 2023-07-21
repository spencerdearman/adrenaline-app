//
//  MeetDBTestView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/3/23.
//

import SwiftUI
import CoreData

struct MeetDBTestView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.modelDB) var db
    @State var liveResultsLink: String = ""
    @State var liveResultHTML: String = ""
    @State var finishedParsing: Bool = false
    
    @StateObject private var getTextModel = GetTextAsyncModel()
    @StateObject private var p = MeetParser()
    
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "meetId", ascending: false)]
    ) var meets: FetchedResults<DivingMeet>
    // Note: predicate formats use %@ for strings instead of %s, still use %d for ints
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(
            format: "startDate <= %@", Date() as NSDate)
    ) var filteredMeets: FetchedResults<DivingMeet>
    
    func displayDivingMeet(meet: DivingMeet) -> HStack<TupleView<(Text, Text, Text, Text, Text)>> {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return HStack {
            Text(String(meet.meetId))
            Text(meet.name ?? "Unknown")
            Text(meet.organization ?? "Unknown")
            Text(meet.state ?? "Unknown")
            Text(df.string(from: meet.startDate ?? Date()))
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button("Drop All") {
                        db.dropAllMeetRecords()
                    }
                    Spacer()
                    Button("Fix Dates") {
                        for meet in meets {
                            db.fixDates(meet)
                        }
                        print("Fixed dates")
                    }
                    Spacer()
                    Button("Drop Duplicates") {
                        for meet in meets {
                            db.dropDuplicateRecords(Int(exactly: meet.meetId)!, keepLatest: true)
                        }
                        print("Dropped all duplicates")
                    }
                }
                .padding()
                HStack {
                    if !finishedParsing {
                        Button("Run") {
                            Task {
                                finishedParsing = false
                                
                                // This sets p's upcoming, current, and past meets fields
                                try await p.parseMeets(storedMeets: meets)
                                
                                finishedParsing = true
                                print("Finished parsing")
                            }
                            
                        }
                        Spacer()
                        Button("Drop nil orgs") {
                            db.dropNullOrgRecords()
                        }
                    } else {
                        Spacer()
                        Button("Print") {
                            print("Upcoming:\n", p.upcomingMeets ?? [:])
                            print("Current:\n", p.currentMeets ?? [])
                            print("Past:")
                            p.printPastMeets()
                        }
                        Spacer()
                        Button("Tuples") {
                            if finishedParsing {
                                print("Upcoming:", db.dictToTuple(dict: p.upcomingMeets ?? [:]))
                                print("Current:", db.dictToTuple(dict: p.currentMeets ?? []))
                                if p.pastMeets != nil {
                                    let past = db.dictToTuple(dict: p.pastMeets!)
                                    let left = past[0 ..< past.count / 2]
                                    let right = past[past.count / 2 ..< past.count]
                                    
                                    print("Past: [")
                                    for k in left {
                                        print(k, ",")
                                    }
                                    for k in right {
                                        print(k, ",")
                                    }
                                    print("]")
                                }
                            } else {
                                print([(Int, String, String, Int, String)]())
                            }
                        }
                        Spacer()
                        Button("Add Upcoming") {
                            if finishedParsing {
                                db.addRecords(records: db.dictToTuple(dict: p.upcomingMeets!))
                            }
                        }
                        Spacer()
                        Button("Add Current") {
                            if finishedParsing {
                                db.addRecords(records: db.dictToTuple(dict: p.currentMeets!))
                            }
                        }
                        Spacer()
                        Button("Add Past") {
                            if finishedParsing {
                                db.addRecords(records: db.dictToTuple(dict: p.pastMeets!))
                            }
                        }
                    }
                }.padding()
                
                List(meets) { meet in
                    displayDivingMeet(meet: meet)
                }
                
                List(filteredMeets) { meet in
                    displayDivingMeet(meet: meet)
                }
                
            }
        }
    }
}
