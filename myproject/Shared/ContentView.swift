//
//  ContentView.swift
//  Shared
//
//  Created by 李沅紘 on 2022/4/3.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()

    var body: some View {
        NavigationView{
            VStack{
                Text("Bluetooth Devices " + bleManager.status.rawValue)
                List(bleManager.peripherals)
                { peripheral in
                    HStack {
                        NavigationLink()
                        {
                            SelectedDevice(peripheral: peripheral)
                                .onAppear()
                                {
                                    bleManager.stopScanning()
                                }
                        }label:
                        {
                            Text(peripheral.name)
                            Text(String(peripheral.rssi))
                            Text(peripheral.id)
                        
                        }
                    }
                }.frame(height: 300)
                
                Spacer()
                Text("STATUS")
                // Status goes here check BT on/off
                if bleManager.isSwitchedOn {
                    Text("Bluetooth is switched on")
                        .foregroundColor(.green)
                }
                else {
                    Text("Bluetooth is NOT switched on")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                if bleManager.status != .ble_scan
                {
                    Button("Search Device")
                    {
                        bleManager.startScanning()
                    }.padding()
                }
                else
                {
                    Button("Stop Searching")
                    {
                        bleManager.stopScanning()
                    }.padding()
                }
            }
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
    
}


