//
//  SelectedDevice.swift
//  myproject
//
//  Created by 李沅紘 on 2022/4/9.
//

import SwiftUI

struct SelectedDevice: View {
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var peripheral: Peripheral
    @State private var select_state = BluetoothStatus.ble_scan // choose what mode doing loop
    //@State var timeRemaing = 10.00
    @ObservedObject var bleManager: LoopBleManager
    
    init(peripheral: Peripheral)
    {
        self.peripheral = peripheral
        bleManager = LoopBleManager(peripheral: peripheral)
        //timeRemaing = bleManager.timeout
    }

    var body: some View {
        VStack{
            Text("Name: " + peripheral.name)
            Text("Identify: " + peripheral.id)
            HStack{
                Text("TimeOut(sec)")
                TextField("second", value: $bleManager.timeout, formatter: NumberFormatter())
                    .frame(width: 50)
                Text("Loop")
                TextField("Placeholder", value: $bleManager.loop_max, formatter: NumberFormatter())
                    .frame(width: 50)
            }
            
            Picker(selection: $select_state, label: Text("BLE Do: "))
            {
                Text("Scan").tag(BluetoothStatus.ble_scan)
                Text("Connect").tag(BluetoothStatus.ble_init)
            }.pickerStyle(RadioGroupPickerStyle())

            if bleManager.status != .ble_scan &&
                bleManager.status != .ble_init
            {
                Button("Start")
                {
                    print("LoopStart")
                    switch select_state
                    {
                    case .ble_scan:
                        bleManager.startLoopScanning()
                    case .ble_init:
                        bleManager.startLoopConnecting()
                    default:
                        print(select_state)
                    }
                    //timeRemaing = bleManager.timeout
                }
            }
            else
            {
                Button("Stop")
                {
                    print("LoopStop")
                    print("LoopStart")
                    switch select_state
                    {
                    case .ble_scan:
                        bleManager.stopLoopScanning()
                    case .ble_init:
                        bleManager.stopLoopConnecting()
                    default:
                        print(select_state)
                    }
                }
                
                Text("Loop \(bleManager.loop_index + 1): \(bleManager.timeRemaing)").onReceive(timer)
                {
                    _ in if bleManager.timeRemaing > 0
                    {
                        bleManager.timeRemaing -= 1
                    }
                    else
                    {
                        switch select_state
                        {
                        case .ble_scan:
                            bleManager.doNextLoopScaning()
                        case .ble_init:
                            bleManager.doNextLoopConnecting()
                        default:
                            print(select_state)
                        }                    }
                }
            }
            
            List(bleManager.recordLoopList)
            { recordLoop in
                if recordLoop.findDevice
                {
                    Text("Loop \(recordLoop.id): find \(recordLoop.peripheral.name) spend \(recordLoop.findDate - recordLoop.startDate) Success")
                }
                else
                {
                    Text("Loop \(recordLoop.id): find \(recordLoop.peripheral.name) Fail")
                }
            }
        }
        .frame(width: 500)
    }
}

struct SelectedDevice_Previews: PreviewProvider {
    static var previews: some View {
        let peripheral = Peripheral(id: "", name: "", rssi: 0, cbperipheral: nil)
        NavigationView{
            SelectedDevice(peripheral: peripheral)
        }
    }
}
