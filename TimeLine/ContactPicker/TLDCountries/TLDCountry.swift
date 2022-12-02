//
//  TLDCounry.swift
//  TimeLine
//
//  Created by Matt B on 31/10/2022.
//  Copyright © 2022 Mathieu Dutour. All rights reserved.
//

import Foundation

struct TLDCounry: Decodable {
    let country: String
    let tlds: [String]
}
