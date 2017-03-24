//
//  HKTRecorderManager.swift
//  HomeKitTester
//
//  Created by Wai Man Chan on 3/22/17.
//  Copyright © 2017 Wai Man Chan. All rights reserved.
//

import CoreData

extension RecordType {
    func avg()->Double {
        if let count = self.instances?.count {
            let count = Double(count)
            return self.instances!.reduce(0.0, { (result: Double, _benchmark: Benchmark) -> Double in
                return result+(_benchmark.value/count)
            })
        } else {
            return Double.nan
        }
    }
}

class HKTRecorderManager: NSObject {
    let managedContext: NSManagedObjectContext
    override init() {
        let modelURL = Bundle.main.url(forResource: "HKTSpeedRecord", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        let persistent = NSPersistentStoreCoordinator(managedObjectModel: model)
        managedContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedContext.persistentStoreCoordinator = persistent
    }
    
    let msgQueue = DispatchQueue(label: "Msg Queue")
    var msg: [String] = []
    func submitError(errorMsg: String) {
        msgQueue.async {
            self.msg.append(Date().description+" Error: "+errorMsg)
        }
    }
    func submitSummary(summaryMsg: String) {
        msgQueue.async {
            self.msg.append(Date().description+" Summary: "+summaryMsg)
        }
    }
    
    func submitBenchmark(objUUID: UUID, typeStr: String, value: Double) {
        var obj: Benchmark!
        managedContext.perform {
            obj = NSEntityDescription.insertNewObject(forEntityName: "Benchmark", into: self.managedContext) as! Benchmark
            obj.value = value
        }
        
        let typeReq = RecordType.fetchRequest()
        typeReq.predicate = NSPredicate(format: "self.typeName == %@ && self.charRec.identifier == %@", typeStr, objUUID.uuidString)
        var type: RecordType?
        managedContext.perform {
            do {
                type = try self.managedContext.fetch(typeReq).first
                if type == nil {
                    //There is no type
                    type = NSEntityDescription.insertNewObject(forEntityName: "RecordType", into: self.managedContext) as? RecordType
                    type!.typeName = typeStr
                    
                    let charaReq = CharacteristicRecord.fetchRequest()
                    charaReq.predicate = NSPredicate(format: "self.identifier == %@", objUUID.uuidString)
                    if let chara = try self.managedContext.fetch(charaReq).first {
                        chara.addTypesObject(type!)
                    } else {
                        let chara = NSEntityDescription.insertNewObject(forEntityName: "CharacteristicRecord", into: self.managedContext) as! CharacteristicRecord
                        chara.identifier = objUUID.uuidString
                        chara.addTypesObject(type!)
                    }
                }
            } catch {
            }
        }
        
        managedContext.perform {
            type?.addInstancesObject(obj)
        }
    }
    func save() {
        let folderPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)[0]
        let msgLogPath = (folderPath as NSString).appendingPathComponent("HKT"+Date().description+".log")
        managedContext.performAndWait {
            //Calculate averages
            let typeReq = RecordType.fetchRequest()
            do {
                let types = try self.managedContext.fetch(typeReq)
                for type in types {
                    self.submitSummary(summaryMsg: "Benchmark Summary: "+type.charRec!.identifier!+" "+type.typeName!+" "+type.avg().description)
                }
            } catch {}
        }
        msgQueue.async {
            let log = self.msg.joined(separator: "\n")
            do { try log.write(toFile: msgLogPath, atomically: true, encoding: String.Encoding.utf8) } catch {}
        }
        
        let filePath = (folderPath as NSString).appendingPathComponent("HKT"+Date().description+".report.sqlite")
        let fileURL = URL.init(fileURLWithPath: filePath)
        managedContext.performAndWait {
            do {
                try self.managedContext.persistentStoreCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileURL, options: nil)
                try self.managedContext.save()
            } catch {
                
            }
        }
        msgQueue.sync {
            NotificationCenter.default.post(name: HKTAccessoryTestProgressName, object: HKTAccessoryTestProgress.save)
        }
    }
}
