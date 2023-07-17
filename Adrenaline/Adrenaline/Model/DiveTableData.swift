//
//  DiveTableData.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/1/23.
//

import Foundation

struct DiveData: Codable {
    let name: String
    let dd: [String: Double]
}

func getDiveTableData() -> [String: DiveData]? {
    if let url = Bundle.main.url(forResource: "diveTable", withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            return try decoder.decode([String: DiveData].self, from: data)
        } catch {
            print("Error decoding JSON object: \(error)")
        }
    }
    
    return nil
}

func getDiveName(data: [String: DiveData], forKey key: String) -> String? {
    if let diveData = data[key] {
        return diveData.name
    }
    
    return nil
}

func getDiveDD(data: [String: DiveData], forKey key: String, height: Double) -> Double? {
    if let diveData = data[key] {
        // If value ends in .0, then convert to Int before converting to String, else convert
        // directly to String
        let h = Double(Int(height)) == height ? String(Int(height)) : String(height)
        
        if diveData.dd.keys.contains(h) {
            return diveData.dd[h]
        }
    }
    
    return nil
}

//func lookupInformation(forKey key: String) -> String? {
//    if let url = Bundle.main.url(forResource: "diveTable", withExtension: "json") {
//        do {
//            let data = try Data(contentsOf: url)
//            let decoder = JSONDecoder()
//
//            let decodedData = try decoder.decode([String: DiveData].self, from: data)
//
//            if let diveData = decodedData[key] {
//                let name = diveData.name
//                let difficulty = diveData.dd["3"] // Height
//
//                return "Dive: \(name), Degree of Difficulty: \(difficulty ?? 0.0)"
//            } else {
//                return nil
//            }
//        } catch {
//            print("Error decoding JSON: \(error)")
//        }
//    }
//
//    return nil
//}
