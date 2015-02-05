//
//  SandGrid.swift
//  sands
//
//  Created by Caden Lovelace on 05/02/2015.
//  Copyright (c) 2015 Caden Lovelace. All rights reserved.
//

import Foundation

class SandGrid {
    let pixelGrid = PixelGrid(width: 142*2, height: 80*2, size: 2)
    var sandGrid : [Byte] = []
    var sandGridDiff : [Byte?] = []
    var orientation = "Landscape" // UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)
    var currentColor : Byte = 1
    
    required init() {
    }
    
    func frame() {
        if sandGrid.count == 0 {
            sandGrid = generateSandGrid(pixelGrid)
            sandGridDiff = generateSandGridDiff(pixelGrid)
        }
        
        resetSandGridDiff()
        passSandGrid()
        addNewSand()
    }
    
    func frameDiff() -> [Byte?] {
        frame()
        return sandGridDiff
    }
    
    func generateSandGrid(pixelGrid: PixelGrid) -> [Byte] {
        return [Byte](count: pixelGrid.width * pixelGrid.height, repeatedValue: 0)
    }
    
    func generateSandGridDiff(pixelGrid: PixelGrid) -> [Byte?] {
        return [Byte?](count: pixelGrid.width * pixelGrid.height, repeatedValue: nil)
    }
    
    func resetSandGridDiff() {
        for i in 0...(sandGridDiff.count-1) {
            sandGridDiff[i] = nil
        }
    }
    
    func getOffset(x: Int, y: Int) -> Int {
        return pixelGrid.width * y + x
    }
    
    func isValidOffset(x: Int, y: Int) -> Bool {
        if x < 0 || y < 0 { return false }
        return y < pixelGrid.height && x < pixelGrid.width
    }
    
    func passSandGrid() {
        for y in stride(from: pixelGrid.height - 1, through: 0, by: -1) {
            for x in stride(from: pixelGrid.width - 1, through: 0, by: -1) {
                let thisOffset = getOffset(x, y: y)
                let thisVal = sandGrid[thisOffset]
                
                if(thisVal != 0) {
                    if orientation != "Portrait" {
                        let randomFlop = (Int(rand()) % 2) == 0 ? -1 : 1
                        let belowOffset = getOffset(x, y: y + 1)
                        let diagOffset = getOffset(x + randomFlop, y: y + 1)
                        
                        if isValidOffset(x, y: y + 1) && sandGrid[belowOffset] == 0 {
                            sandGrid[belowOffset] = thisVal
                            sandGrid[thisOffset] = 0
                            self.queuePixelDraw(x, y: y + 1)
                            self.queuePixelDraw(x, y: y)
                        } else if isValidOffset(x + randomFlop, y: y + 1) && (sandGrid[diagOffset] == 0) {
                            sandGrid[diagOffset] = thisVal
                            sandGrid[thisOffset] = 0
                            self.queuePixelDraw(x + randomFlop, y: y + 1)
                            self.queuePixelDraw(x, y: y)
                        }
                    } else {
                        let randomFlop = (Int(rand()) % 2) == 0 ? -1 : 1
                        let belowOffset = getOffset(x + 1, y: y)
                        let diagOffset = getOffset(x + 1, y: y + randomFlop)
                        
                        if isValidOffset(x + 1, y: y) && sandGrid[belowOffset] == 0 {
                            sandGrid[belowOffset] = thisVal
                            sandGrid[thisOffset] = 0
                            self.queuePixelDraw(x + 1, y: y)
                            self.queuePixelDraw(x, y: y)
                        } else if isValidOffset(x + 1, y: y + randomFlop) && (sandGrid[diagOffset] == 0) {
                            sandGrid[diagOffset] = thisVal
                            sandGrid[thisOffset] = 0
                            self.queuePixelDraw(x + 1, y: y + randomFlop)
                            self.queuePixelDraw(x, y: y)
                        }
                    }
                }
            }
        }
    }
    
    func queuePixelDraw(x: Int, y: Int) {
        sandGridDiff[getOffset(x, y: y)] = sandGrid[getOffset(x, y: y)]
    }
    
    func addNewSand() {
        if orientation != "portrait" {
            for i in 0...2 {
                let x = pixelGrid.width / 2 + ((Int(rand()) % 6) - 4)
                sandGrid[getOffset(x, y: 0)] = currentColor
                queuePixelDraw(x, y: 0)
            }
        } else {
            for i in 0...2 {
                let y = pixelGrid.height / 2 + ((Int(rand()) % 6) - 4)
                sandGrid[getOffset(0, y: y)] = currentColor
                queuePixelDraw(0, y: y)
            }
        }
    }
}
