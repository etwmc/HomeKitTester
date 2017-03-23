//
//  HKTAccessoryModel.swift
//  HomeKitTester
//
//  Created by Wai Man Chan on 3/21/17.
//  Copyright © 2017 Wai Man Chan. All rights reserved.
//

import Foundation
import HomeKit

class HKTAccessoryModel: NSObject {
    public var configurationNumber = 0
    public var serviceNumber = 0
    public var modelName: String
    public var paired = false
    init?(accessory: HMAccessory) {
        modelName = accessory.name
    }
}
