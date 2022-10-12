//
//  TLDCountries.swift
//  TimeLine
//
//  Created by Matt B on 31/10/2022.
//  Copyright © 2022 Mathieu Dutour. All rights reserved.
//

import Foundation

final class TLDCountries {

    static func getCountryName(from tls: String) -> String? {
        return loadCountries()?
            .compactMap { $0 }
            .first(where: { $0.tlds.contains(where: { $0 == tls }) })
            .map { $0.country }
    }
    
    static func loadCountries() -> [TLDCounry]? {
        if let url = Bundle.main.url(forResource: "TLDCountries", withExtension: "json") {
            do {
                return (try JSONDecoder().decode([TLDCounry].self, from: try Data(contentsOf: url)))
            } catch {
                print("❌ Failed to load TLDCountries: ", error)
            }
        }
        return nil
    }
    
}
