//
//  DataExtension.swift
//  ScriptToolkit
//
//  Created by Daniel Cech on 20/07/2020.
//

import Foundation

extension Data {
    func indexOf(data: Data) -> Data.Index? {
        var selfIndex = self.startIndex
        var dataIndex = data.startIndex
        
        while selfIndex < self.endIndex && dataIndex < data.endIndex {
            if dataIndex == data.endIndex {
                return selfIndex - data.count
            }
            
            if self[selfIndex] == data[dataIndex] {
                dataIndex += 1
            }
            else {
                dataIndex = data.startIndex
            }
            selfIndex += 1
        }
        
        return nil
    }
}
