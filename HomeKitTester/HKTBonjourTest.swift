//
//  HKTBonjourTest.swift
//  HomeKitTester
//
//  Created by Wai Man Chan on 3/21/17.
//  Copyright © 2017 Wai Man Chan. All rights reserved.
//

import Foundation
import HomeKit

class HKTBonjourSeek: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    let browser = NetServiceBrowser()
    let target: String
    var callback: ((HKTBonjourTest)->Void)?
    init(targetStr: String, foundServiceCallback: @escaping ((HKTBonjourTest)->Void)) {
        target = targetStr
        callback = foundServiceCallback
        super.init()
        browser.delegate = self
        browser.searchForServices(ofType: "_hap._tcp", inDomain: "")
    }
    var candidate: [NetService] = []
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        if (target == service.name) {
            candidate.append(service)
            service.delegate = self
            service.resolve(withTimeout: 3)
        }
    }
    func netServiceDidResolveAddress(_ sender: NetService) {
        if let service = HKTBonjourTest.init(accBonjour: sender), let callback = callback {
            callback(service)
            self.callback = nil
        } else {
            submitError(errorMsg: "Bonjour TXT Record incorrect->fatal", fatal: true)
        }
    }
}

class HKTBonjourTest: HKTTest, NetServiceBrowserDelegate, NetServiceDelegate {
    let accIDBinary: Data
    let versionStr: String; let versionData: Data
    var txtDict: [String: Data] = [:]
    
    var model: HKTAccessoryModel!
    func setModel(targetModel: HKTAccessoryModel) {
        model = targetModel
    }
    
    init?(accBonjour: NetService) {
        //Get the TXT Data
        if let txtData = accBonjour.txtRecordData() {
            txtDict = NetService.dictionary(fromTXTRecord: txtData)
            //Get the accessory ID
            if let idBin = txtDict["id"] {
                accIDBinary = idBin
                if let verBin = txtDict["pv"], let verStr = (NSString.init(data: verBin, encoding: String.Encoding.utf8.rawValue) as? String) {
                    versionData = verBin
                    versionStr = verStr
                } else {
                    versionData = Data()
                    versionStr = "1.0"
                }
                
                super.init()
                
                //Setup monitor
                startMonitorServiceAddDrop()
                startMonitorService(netService: accBonjour)
            } else {
                //Missing accessory ID
                submitError(errorMsg: "Accessory ID missing", fatal: true)
                return nil
            }
        } else {
            //No Bonjour TXT
            submitError(errorMsg: "Bonjour TXT missing", fatal: true)
            return nil
        }
        
    }
    var bonjourBrowser: NetServiceBrowser!
    func startMonitorServiceAddDrop() {
        bonjourBrowser = NetServiceBrowser()
        bonjourBrowser.delegate = self
        bonjourBrowser.searchForServices(ofType: "_hap._tcp", inDomain: "")
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        submitError(errorMsg: "HKTBonjourTest: failed to search")
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        //Get the TXT Data
        if let txtData = service.txtRecordData() {
            txtDict = NetService.dictionary(fromTXTRecord: txtData)
            //Get the accessory ID
            if let idBin = txtDict["id"], (accIDBinary as NSData).isEqual(to: idBin) {
                //Found the new network service
                startMonitorService(netService: service)
                testNetService(service: service)
            }
        }
    }
    func startMonitorService(netService: NetService) {
        netService.delegate = self
        netService.startMonitoring()
    }
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        testNetService(service: sender)
    }
    
    func testNetService(service accBonjour: NetService) {
        //Check bonjour TXT sanity
        if let txtData = accBonjour.txtRecordData() {
            txtDict = NetService.dictionary(fromTXTRecord: txtData)
            
            //Write metadata
            //Write down model name and category
            if let modelBin = txtDict["md"], let modelStr = String(data: modelBin, encoding: String.Encoding.utf8) {
                submitSummary(summaryMsg: "Model Name: "+modelStr)
            } else {
                submitError(errorMsg: "Model Name missing")
            }
            if let catBin = txtDict["ci"], let catStr = String(data: catBin, encoding: String.Encoding.utf8) {
                submitSummary(summaryMsg: "Acessory Cateogy: "+catStr)
            } else {
                submitError(errorMsg: "Acessory Cateogy missing")
            }
            
            //Get the accessory ID
            if let idBin = txtDict["id"] {
                if !(accIDBinary as NSData).isEqual(to: idBin) {
                    submitError(errorMsg: "Accessory ID changed")
                }
            } else {
                //Missing accessory ID
                submitError(errorMsg: "Accessory ID missing")
            }
            
            //Get the primary version
            if let pvBin = txtDict["pv"] {
                if !(versionData as NSData).isEqual(to: pvBin) {
                    submitSummary(summaryMsg: "Primary Version changed")
                }
            } else {
                //Missing primary version
                submitError(errorMsg: "Primary Version missing")
            }
            
            //Get the configuration number
            if let cBin = txtDict["c#"], let confNumStr = String(data: cBin, encoding: String.Encoding.utf8) {
                let confNum = (confNumStr as NSString).integerValue
                if (confNum < model.configurationNumber) {
                    //The configuration number got roll back
                    submitError(errorMsg: "Configuration Number Rollback")
                } else {
                    model.configurationNumber = confNum
                }
            } else {
                //Missing primary version
                submitError(errorMsg: "Configuration Version missing")
            }
            
            //Get the configuration number
            if let discoverBin = txtDict["sf"], let discoverStr = String(data: discoverBin, encoding: String.Encoding.utf8) {
                let discoverNum = (discoverStr as NSString).integerValue
                if (model.paired && discoverNum == 1) {
                    submitError(errorMsg: "Pair device remain discoverable")
                } else if (!model.paired && discoverNum == 0) {
                    submitError(errorMsg: "Unpair device remain undiscoverable")
                }
            } else {
                //Missing primary version
                submitError(errorMsg: "Pair state missing")
            }
            
            //Check MFi
            if let mfiBin = txtDict["ff"], let mfiStr = String(data: mfiBin, encoding: String.Encoding.utf8) {
                let mfiNum = (mfiStr as NSString).integerValue
                if mfiNum == 0 {
                    submitError(errorMsg: "MFi is not enabled")
                }
            }
            
        } else {
            //No Bonjour TXT
            submitError(errorMsg: "Bonjour TXT missing")
        }
    }
}
