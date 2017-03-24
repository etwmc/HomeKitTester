//
//  ViewController.swift
//  HomeKitTester
//
//  Created by Wai Man Chan on 3/21/17.
//  Copyright © 2017 Wai Man Chan. All rights reserved.
//

import UIKit
import HomeKit

var onlyVC: UIViewController!

class ViewController: UITableViewController, HMAccessoryBrowserDelegate, HMHomeManagerDelegate {
    let manager = HMHomeManager()
    var home: HMHome! = nil
    let accessoryBrowser = HMAccessoryBrowser()
    var stateStruct: WMCactivityIndicatorOverlay!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        home = manager.homes.first
        if (home == nil) {
            manager.addHome(withName: "Test Home 1234", completionHandler: { (h: HMHome?, err: Error?) in
                if let h = h {self.home = h}
                self.tableView.reloadData()
            })
        }
        // Do any additional setup after loading the view, typically from a nib.
        onlyVC = self
        accessoryBrowser.delegate = self
        
        //Doing state check
        NotificationCenter.default.addObserver(forName: HKTAccessoryTestProgressName, object: nil, queue: nil) { (notification: Notification) in
            DispatchQueue.main.async {
                if let state = notification.object as? HKTAccessoryTestProgress {
                    switch state {
                    case .fail, .stop:
                        self.stateStruct.setHidden(true)
                        self.tableView.isUserInteractionEnabled = true
                        break
                    case .start:
                        self.stateStruct.setHidden(false)
                        self.tableView.isUserInteractionEnabled = false
                        break
                    default: break
                    }
                    self.stateStruct.label.text = state.rawValue
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        stateStruct = createActivityIndicatorOverlay(superView: self.view.superview!)
        stateStruct.setHidden(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        accessoryBrowser.stopSearchingForNewAccessories()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accessoryBrowser.discoveredAccessories.count
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        if home != nil { return 1 }
        else  { return 0 }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Accessory")
        cell?.textLabel?.text = accessoryBrowser.discoveredAccessories[indexPath.row].name
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let accessory = accessoryBrowser.discoveredAccessories[indexPath.row]
        //Add the accessory
        let test = HTKAccessoryTest()
        test.testAccessory(accessory: accessory, home: home)
    }
    
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        tableView.reloadData()
    }
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
        tableView.reloadData()
    }
    
    func homeManager(_ manager: HMHomeManager, didAdd _home: HMHome) {
        home = _home
        self.tableView.reloadData()
    }
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        if let _home = manager.primaryHome { home = _home }
        accessoryBrowser.startSearchingForNewAccessories()
        self.tableView.reloadData()
    }
    
}

