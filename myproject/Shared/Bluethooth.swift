//
//  File.swift
//  myproject
//
//  Created by 李沅紘 on 2022/4/9.
//

import Foundation
import CoreBluetooth

struct Peripheral: Identifiable
{
    let id: String
    let name: String
    let rssi: Int
    let cbperipheral: CBPeripheral?
}

struct RecordLoop: Identifiable
{
    let id: Int
    let peripheral: Peripheral
    let findDevice: Bool
    let findDate: Date
    let startDate: Date
}

extension Date {
    static func - (left: Date, right: Date) -> TimeInterval {
        return left.timeIntervalSinceReferenceDate - right.timeIntervalSinceReferenceDate
    }
}

enum BluetoothStatus: String
{
    case ble_invalid = "ble_invalid"
    case ble_on = "ble_on"
    case ble_scan = "ble_scan"
    case ble_init = "ble_init"      //initiate connection
    case ble_link = "ble_connect"   //connection success
    case ble_cancel = "ble_cancel"
    
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {

    var myCentral: CBCentralManager!

    @Published var isSwitchedOn = false
    @Published var peripherals = [Peripheral]()
    @Published var status = BluetoothStatus.ble_invalid

    override init() {
        super.init()

        myCentral = CBCentralManager(delegate: self, queue: nil)
        myCentral.delegate = self
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isSwitchedOn = central.state == .poweredOn
        switch central.state
        {
        case .unknown:
            print("unknow")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("poweredOff")
        case .poweredOn:
            print("poweredOn")
        @unknown default:
            print("error")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if status != BluetoothStatus.ble_scan
        {
            return
        }
        
        var peripheralName: String!
       
        /*if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            peripheralName = name
        }
        else {
            peripheralName = "Unknown"
        }*/
        
        if peripheral.name != nil
        {
            peripheralName = peripheral.name
        }
        else
        {
            peripheralName = "Unknown"
        }
        
        print("advData: ", advertisementData)

        let find_idx = peripherals.firstIndex(where: {$0.id == peripheral.identifier.uuidString})
        
        if find_idx == nil
        {
            let newPeripheral = Peripheral(id: peripheral.identifier.uuidString, name: peripheralName, rssi: RSSI.intValue, cbperipheral: peripheral)
            //print(peripheral)
            //print(newPeripheral)
            //peripherals.append(newPeripheral)
            peripherals.insert(newPeripheral, at: 0)
        }
    }
    
    func startScanning() {
        peripherals.removeAll()
        myCentral.scanForPeripherals(withServices: nil, options: nil)
        status = BluetoothStatus.ble_scan
        print(status)

     }
    
    func stopScanning() {
        myCentral.stopScan()
        status = .ble_on
        print(status)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        print("connect success")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect, error")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnect, error")
    }
    
    func startConnecting(peripheral: CBPeripheral)
    {
        print("Connect Start traget: ", peripheral.identifier.uuidString)
        status = .ble_init
        myCentral.connect(peripheral, options: nil)
    }
    
    func stopConnecting(peripheral: CBPeripheral)
    {
        status = .ble_on
        myCentral.cancelPeripheralConnection(peripheral)
    }

}

class LoopBleManager: BLEManager
{
    @Published var loop_index = 0
    @Published var timeout = 10.00 //sec
    @Published var timeRemaing = 10.00 //sec
    @Published var loop_max = 100
    @Published var recordLoopList = [RecordLoop]()
    @Published var targetPeripheral: Peripheral
    var startDate = Date()
    
    init(peripheral: Peripheral) {
        targetPeripheral = peripheral
        super.init()
    }
    
    override func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        if status != BluetoothStatus.ble_scan
        {
            return
        }
        
        var peripheralName: String!
        
        if peripheral.name != nil
        {
            peripheralName = peripheral.name
        }
        else
        {
            peripheralName = "Unknown"
        }
                
        if peripheralName != "Unknown" && peripheralName == targetPeripheral.name
        {
            //let newPeripheral = Peripheral(id: peripheral.identifier.uuidString, name: peripheralName, rssi: RSSI.intValue)
            //peripherals.append(newPeripheral)
            print("find")
            doNextLoopScaning()
        }
        
    }
    
    func startLoopScanning()
    {
        print("Loop Star", loop_max, timeout)
        status = BluetoothStatus.ble_scan
        loop_index = 0
        startDate = Date()
        recordLoopList.removeAll()
        timeRemaing = timeout
        startScanning()
    }
    
    func stopLoopScanning() {
        status = BluetoothStatus.ble_on
        stopScanning()
    }
    
    func doNextLoopScaning()
    {
        stopScanning()
        loopRecord()
        let random = useconds_t.random(in: 0...1000000)
        usleep(random)
        timeRemaing = timeout
        if loop_index <= loop_max
        {
            loop_index += 1
            startDate = Date()
            startScanning()
        }
    }
    
    func startLoopConnecting()
    {
        if targetPeripheral.cbperipheral != nil
        {
            startConnecting(peripheral: targetPeripheral.cbperipheral!)
        }
    }
    
    func stopLoopConnecting()
    {
        if targetPeripheral.cbperipheral != nil
        {
            stopConnecting(peripheral: targetPeripheral.cbperipheral!)
        }
    }
    
    func doNextLoopConnecting()
    {
        print("doNextLoopConnecting")
        stopConnecting(peripheral: targetPeripheral.cbperipheral!)
        loopRecord()
        let random = useconds_t.random(in: 0...1000000)
        usleep(random)
        timeRemaing = timeout
        if loop_index <= loop_max
        {
            loop_index += 1
            startDate = Date()
            startLoopConnecting()
        }
    }
    
    func loopRecord()
    {
        let findtime = Date()
        let delta = findtime - startDate
        let find_device = (delta < timeout)
        
        let newRecord = RecordLoop(id: loop_index+1, peripheral: targetPeripheral, findDevice: find_device, findDate: findtime, startDate: startDate)
        
        recordLoopList.append(newRecord)
    }
}
