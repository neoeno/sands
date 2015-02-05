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
    var sandGrid : [Byte]! = nil
    var sandGridDiff : [Byte?]! = nil
    var orientation = "Landscape" // UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)
    var currentColor : Byte = 1
    var particleList = [Int]()
    let aroundMaps : [(x: Int, y: Int)] = [(x: 0, y: -1), (x: -1, y: -1), (x: +1, y: -1), (x: -1, y: 0), (x: -1, y: +1)]
    
    required init() {
    }
    
    func frame() {
        if sandGrid == nil {
            sandGrid = generateSandGrid()
            sandGridDiff = generateSandGridDiff()
        }
        
        resetSandGridDiff()
        passSandGrid()
        addNewSand()
    }
    
    func frameDiff() -> [Byte?] {
        frame()
        return sandGridDiff
    }
    
    func generateSandGrid() -> [Byte] {
        return [Byte](count: pixelGrid.width * pixelGrid.height, repeatedValue: 0)
    }
    
    func generateSandGridDiff() -> [Byte?] {
        return [Byte?](count: pixelGrid.width * pixelGrid.height, repeatedValue: nil)
    }
    
    func generateParticleList() -> [Int?] {
        return [Int?](count: pixelGrid.width * pixelGrid.height, repeatedValue: nil)
    }
    
    func resetSandGridDiff() {
        sandGridDiff = generateSandGridDiff()
    }
    
    func getOffset(x: Int, y: Int) -> Int {
        return pixelGrid.width * y + x
    }
    
    func getOffset(t: (x: Int, y: Int)) -> Int {
        return pixelGrid.width * t.y + t.x
    }
    
    func getXY(offset: Int) -> (x: Int, y: Int) {
        return (y: offset / pixelGrid.width, x: offset % pixelGrid.width)
    }
    
    func isValidOffset(x: Int, y: Int) -> Bool {
        if x < 0 || y < 0 { return false }
        return y < pixelGrid.height && x < pixelGrid.width
    }
    
    func isValidOffset(t: (x: Int, y: Int)) -> Bool {
        if t.x < 0 || t.y < 0 { return false }
        return t.y < pixelGrid.height && t.x < pixelGrid.width
    }
    
    func passSandGrid() {
        if particleList.count == 0 { return }
        
        for index in 0...(particleList.count-1) {
            let offset = particleList[index]
            let x = getXY(offset).x
            let y = getXY(offset).y
            let thisVal = sandGrid[offset]
            
            if (thisVal & 0b00111111) == 0b00000000 { continue } // Black cell
            if (thisVal & 0b11000000) == 0b11000000 { continue } // Frozen cell
            if sandGridDiff[offset]   != nil        { continue } // Already done
        
            let randomFlop = (Int(rand()) % 2) == 0 ? -1 : 1
            
            var belowTrav = (x: x, y: y + 1)
            var diagTrav = (x: x + randomFlop, y: y + 1)
            
            if orientation == "Portrait" {
                belowTrav = (x: x + 1, y: y)
                diagTrav = (x: x + 1, y: y + randomFlop)
            }
            
            let belowOffset = getOffset(belowTrav)
            let diagOffset = getOffset(diagTrav)
            
            if isValidOffset(belowTrav) && sandGrid[belowOffset] == 0 {
                sandGrid[belowOffset] = thisVal & 0b00111111
                sandGrid[offset] = 0
                queuePixelDraw(belowOffset)
                queuePixelDraw(offset)
                
                particleList[index] = belowOffset
                refreshAround(offset)
            } else if isValidOffset(diagTrav) && (sandGrid[diagOffset] == 0) {
                sandGrid[diagOffset] = thisVal & 0b00111111
                sandGrid[offset] = 0
                queuePixelDraw(diagOffset)
                queuePixelDraw(offset)
                
                particleList[index] = diagOffset
                refreshAround(offset)
            } else {
                sandGrid[offset] = sandGrid[offset] | 0b01000000
                
                if (isValidOffset(x, y: y - 1) &&     (sandGrid[getOffset(x, y: y - 1)]     & 0b01000000) != 0b01000000) { continue }
                if (isValidOffset(x + 1, y: y - 1) && (sandGrid[getOffset(x + 1, y: y - 1)] & 0b01000000) != 0b01000000) { continue }
                if (isValidOffset(x - 1, y: y - 1) && (sandGrid[getOffset(x - 1, y: y - 1)] & 0b01000000) != 0b01000000) { continue }
                if (isValidOffset(x - 1, y: y) &&     (sandGrid[getOffset(x - 1, y: y)]     & 0b01000000) != 0b01000000) { continue }
                if (isValidOffset(x - 1, y: y + 1) && (sandGrid[getOffset(x - 1, y: y + 1)] & 0b01000000) != 0b01000000) { continue }
                
                sandGrid[offset] = sandGrid[offset] | 0b11000000
                queuePixelDraw(offset)
            }
        }
    }
    
    func refreshAround(offset: Int) {
        let (x, y) = getXY(offset)
        
        for map in aroundMaps {
            if !isValidOffset(x + map.y, y: y + map.y) { continue }
            let mapOffset = getOffset(x + map.y, y: y + map.y)
            let val = sandGrid[mapOffset]
            
            if (val & 0b01000000) != 0b01000000 { continue }
            
            sandGrid[mapOffset] = val & 0b00111111
        }
    }
    
    func queuePixelDraw(x: Int, y: Int) {
        sandGridDiff[getOffset(x, y: y)] = sandGrid[getOffset(x, y: y)]
    }
    
    func queuePixelDraw(offset: Int) {
        sandGridDiff[offset] = sandGrid[offset]
    }
    
    func addNewSand() {
        if orientation == "Portrait" {
            for i in 0...2 {
                let y = pixelGrid.height / 2 + ((Int(rand()) % 6) - 4)
                let offset = getOffset(0, y: y)
                sandGrid[offset] = currentColor
                queuePixelDraw(offset)
                particleList.append(offset)
            }
        } else {
            for i in 0...2 {
                let x = pixelGrid.width / 2 + ((Int(rand()) % 6) - 4)
                let offset = x
                sandGrid[offset] = currentColor
                queuePixelDraw(offset)
                particleList.append(offset)
            }
        }
    }
}
