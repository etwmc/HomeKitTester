//
//  HKTTest.swift
//  HomeKitTester
//
//  Created by Wai Man Chan on 3/21/17.
//  Copyright © 2017 Wai Man Chan. All rights reserved.
//

import UIKit

//These should be run on main queue
var currentRecorder: HKTRecorderManager?
func setRecorder(recorder: HKTRecorderManager) { currentRecorder = recorder }
func submitError(errorMsg: String, fatal: Bool = false) { currentRecorder?.submitError(errorMsg: errorMsg) }
func submitSummary(summaryMsg: String) { currentRecorder?.submitSummary(summaryMsg: summaryMsg) }
func submitBenchmark(objUUID: UUID, type: String, value: Double, recorder: HKTRecorderManager) { recorder.submitBenchmark(objUUID: objUUID, typeStr: type, value: value) }
func promptManualInteraction(title: String, detail: String) {
    let sem = DispatchSemaphore(value: 0)
    DispatchQueue.main.async {
        //Block until confirm
        let con = UIAlertController(title: title, message: detail, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: { _ in
            sem.signal()
        })
        con.addAction(action)
        onlyVC.present(con, animated: true, completion: nil)
    }
    sem.wait()
}

class HKTTest: NSObject {
    
}
