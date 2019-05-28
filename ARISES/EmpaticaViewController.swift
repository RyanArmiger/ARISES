//
//  ViewController.swift
//  E4 tester
//


import UIKit

class EmpaticaViewController: UITableViewController {
    
    
    static var EMPATICA_API_KEY = "" 
    
    private var tempCount: Int = 0
    private var tempArray: [Float] = []
    
    private var devices: [EmpaticaDeviceManager] = []
    
    private var allDisconnected : Bool {
        
        return self.devices.reduce(true) { (value, device) -> Bool in
        
            value && device.deviceStatus == kDeviceStatusDisconnected
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tempCount = 0
        tempArray = []

        self.tableView.delegate = self
        
        self.tableView.dataSource = self
        
        self.beginAuthenticate()
        
    }
    
    func beginAuthenticate() {
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            EmpaticaAPI.authenticate(withAPIKey: EmpaticaViewController.EMPATICA_API_KEY) { (status, message) in
                
                if status {
                    let nc = NotificationCenter.default
                    nc.post(name: Notification.Name("empaticaAuth"), object: nil)
                    
                    
                    // "Authenticated"
                    print("Authenticated")
                    
                    DispatchQueue.main.async {
                        
                        self.discover()
                    }
                }
            }
        }
    }
    
    private func discover() {
        
        EmpaticaAPI.discoverDevices(with: self)
    }
    
    private func disconnect(device: EmpaticaDeviceManager) {
        
        if device.deviceStatus == kDeviceStatusConnected {
            
            device.disconnect()
        }
        else if device.deviceStatus == kDeviceStatusConnecting {
            
            device.cancelConnection()
        }
    }
    
    private func connect(device: EmpaticaDeviceManager) {
        
        device.connect(with: self)
    }
    
    private func updateValue(device : EmpaticaDeviceManager, string : String = "") {
        
        if let row = self.devices.index(of: device) {
            
            DispatchQueue.main.async {
                
                for cell in self.tableView.visibleCells {
                    
                    if let cell = cell as? DeviceTableViewCell {
                        
                        if cell.device == device {
                            
                            let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: 0))
                            
                            if !device.allowed {
                                
                                cell?.detailTextLabel?.text = "NOT ALLOWED"
                                
                                cell?.detailTextLabel?.textColor = UIColor.orange
                            }
                            else if string.count > 0 {
                                
                                cell?.detailTextLabel?.text = "\(self.deviceStatusDisplay(status: device.deviceStatus)) • \(string)"
                                
                                cell?.detailTextLabel?.textColor = UIColor.gray
                            }
                            else {
                                
                                cell?.detailTextLabel?.text = "\(self.deviceStatusDisplay(status: device.deviceStatus))"
                                
                                cell?.detailTextLabel?.textColor = UIColor.gray
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func deviceStatusDisplay(status : DeviceStatus) -> String {
        
        switch status {
            
        case kDeviceStatusDisconnected:
            return "Disconnected"
        case kDeviceStatusConnecting:
            return "Connecting..."
        case kDeviceStatusConnected:
            return "Connected"
        case kDeviceStatusFailedToConnect:
            return "Failed to connect"
        case kDeviceStatusDisconnecting:
            return "Disconnecting..."
        default:
            return "Unknown"
        }
    }
    
    private func restartDiscovery() {
        
        print("restartDiscovery")
        
        guard EmpaticaAPI.status() == kBLEStatusReady else { return }
        
        if self.allDisconnected {
            
            print("restartDiscovery • allDisconnected")
            
            self.discover()
        }
    }
    
//    private func storeTemperature(timestamp: Double, temp: Float){
//        if tempCount < 10 {
//            tempArray.append(temp)
//            tempCount += 1
//        } else {
//            tempArray.append(temp)
//            ModelController().addTemp(timestamp: timestamp, array: tempArray)
//        }
//    }
}


extension EmpaticaViewController: EmpaticaDelegate {
    
    func didDiscoverDevices(_ devices: [Any]!) {
        
        print("didDiscoverDevices")
        
        if self.allDisconnected {
            
            print("didDiscoverDevices • allDisconnected")
            
            self.devices.removeAll()
            
            self.devices.append(contentsOf: devices as! [EmpaticaDeviceManager])
            
            DispatchQueue.main.async {
                
                self.tableView.reloadData()
                
                if self.allDisconnected {
                
                    EmpaticaAPI.discoverDevices(with: self)
                }
            }
        }
    }
    
    func didUpdate(_ status: BLEStatus) {
        
        switch status {
        case kBLEStatusReady:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusReady")
            break
        case kBLEStatusScanning:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusScanning")
            break
        case kBLEStatusNotAvailable:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusNotAvailable")
            break
        default:
            print("[didUpdate] status \(status.rawValue)")
        }
    }
}

extension EmpaticaViewController: EmpaticaDeviceDelegate {
    
    func didReceiveTemperature(_ temp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        let date = Date.init(timeIntervalSince1970: timestamp)
        EmpaticaModelController().addTemp(temp: temp, timestamp: date)

    }
    
    func didReceiveAccelerationX(_ x: Int8, y: Int8, z: Int8, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
//        print("\(device.serialNumber!) ACC > {x: \(x), y: \(y), z: \(z)}")
        let date = Date.init(timeIntervalSince1970: timestamp)
        EmpaticaModelController().addAcc(x: Int16(x), y: Int16(y), z: Int16(z), timestamp: date)
    }
    
    func didReceiveTag(atTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        let date = Date.init(timeIntervalSince1970: timestamp)
        EmpaticaModelController().addTag(timestamp: date)
        
//        print("\(device.serialNumber!) TAG received { \(timestamp) }")
    }
    
    func didReceiveGSR(_ gsr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        let date = Date.init(timeIntervalSince1970: timestamp)
        EmpaticaModelController().addGSR(gsr: gsr, timestamp: date)
//        print("\(device.serialNumber!) GSR { \(abs(gsr)) }")
        
        self.updateValue(device: device, string: "\(String(format: "%.2f", abs(gsr))) µS")
    }
    
    func didReceiveHR(_ hr: Float, andQualityIndex qualityIndex: Int32, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        print("HEART RATE FOUND: ", hr)
        let date = Date.init(timeIntervalSince1970: timestamp)
        EmpaticaModelController().addHR(hr: hr, qualityIndex: qualityIndex, timestamp: date)
//        print("\(device.serialNumber!) HR { \(hr) }")

    }
    
    func didReceiveBVP(_ bvp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        let date = Date.init(timeIntervalSince1970: timestamp)
        EmpaticaModelController().addBVP(bvp: bvp, timestamp: date)
        
//        print("\(device.serialNumber!) BVP { \(bvp) }")

    }
    
    func didReceiveIBI(_ ibi: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        let date = Date.init(timeIntervalSince1970: timestamp)
        EmpaticaModelController().addIBI(ibi: ibi, timestamp: date)
//        print("\(device.serialNumber!) IBI { \(ibi) }")

    }
    
//    func didReceiveBatteryLevel(_ level: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
//
//    }
    
    func didUpdate( _ status: DeviceStatus, forDevice device: EmpaticaDeviceManager!) {
        
        self.updateValue(device: device)
        
        switch status {
            
        case kDeviceStatusDisconnected:
            
            print("[didUpdate] Disconnected \(device.serialNumber!).")
//            if !device.isFaulty && device.allowed {
//
//                self.connect(device: device)
//            }
            self.restartDiscovery()
            
            break
            
        case kDeviceStatusConnecting:
            
            print("[didUpdate] Connecting \(device.serialNumber!).")
            break
            
        case kDeviceStatusConnected:
            
            print("[didUpdate] Connected \(device.serialNumber!).")
            break
            
        case kDeviceStatusFailedToConnect:
            
            print("[didUpdate] Failed to connect \(device.serialNumber!).")
            
            self.restartDiscovery()
            
            break
            
        case kDeviceStatusDisconnecting:
            
            print("[didUpdate] Disconnecting \(device.serialNumber!).")
            
            break
            
        default:
            break
            
        }
    }
}

extension EmpaticaViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        EmpaticaAPI.cancelDiscovery()
        
        let device = self.devices[indexPath.row]
        
        if device.deviceStatus == kDeviceStatusConnected || device.deviceStatus == kDeviceStatusConnecting {
            
            self.disconnect(device: device)
        }
        else if !device.isFaulty && device.allowed {
            
            self.connect(device: device)
        }
        
        self.updateValue(device: device)
    }
}

extension EmpaticaViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let device = self.devices[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "device") as? DeviceTableViewCell ?? DeviceTableViewCell(device: device)
        
        cell.device = device
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        cell.textLabel?.text = "E4 \(device.serialNumber!)"
        
        cell.alpha = device.isFaulty || !device.allowed ? 0.2 : 1.0
        
        return cell
    }
}

class DeviceTableViewCell : UITableViewCell {
    
    
    var device : EmpaticaDeviceManager
    
    
    init(device: EmpaticaDeviceManager) {
        
        self.device = device
        
        super.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "device")
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
}
