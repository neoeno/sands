//
//  Draw2D.swift
//  sands
//
//  Created by Caden Lovelace on 01/02/2015.
//  Copyright (c) 2015 Caden Lovelace. All rights reserved.
//

import UIKit

class Draw2D: UIView {
    
    var drawTimer : NSTimer?
    var autonGrid : [Int]?
    var pixelGrid : PixelGrid?
    
    override func didMoveToSuperview() {
        // If we have active timers, stop them
        if var drawTimer = self.drawTimer {
            // This stops the timer
            drawTimer.invalidate()
            self.drawTimer = nil
        }
        
        // If we're actually part of the view hierarchy, start the timers
        if self.superview != nil {
            //Creating the looping draw timer
            self.drawTimer = NSTimer.scheduledTimerWithTimeInterval(
                0.01,
                target: self,
                selector: Selector("timerDraw"),
                userInfo: nil,
                repeats: true)

        }
    }
    
    func timerDraw() {
        self.setNeedsDisplay()
    }

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        pixelGrid = PixelGrid(width: 128, height: 256, size: 2)
        
        if autonGrid != nil {
            passAutonGrid(pixelGrid!)
            addNewCells(pixelGrid!)
        } else {
            autonGrid = generateAutonGrid(pixelGrid!)
        }
        
        drawGrid(
            UIGraphicsGetCurrentContext(),
            grid: pixelGrid!,
            autonGrid: autonGrid!
        )
    }
    
    func drawGrid(context: CGContext, grid: PixelGrid, autonGrid: [Int]) {
        coordList(grid).map { (coord: (x: Int, y: Int)) -> Pixel in
            return self.makePixel(grid, autonGrid: autonGrid, x: coord.x, y: coord.y)
        }.map { (pixel: Pixel) in
            self.drawPixel(context, pixel: pixel)
        }
    }
    
    func drawPixel(context: CGContext, pixel: Pixel) {
        CGContextAddRect(context, pixel.rect)
        let colors = [UIColor.whiteColor().CGColor, UIColor.blackColor().CGColor]
        CGContextSetFillColorWithColor(context, colors[pixel.value])
        CGContextFillRect(context, pixel.rect)
    }
    
    func makePixel(grid: PixelGrid, autonGrid: [Int], x: Int, y: Int) -> Pixel {
        return Pixel(
            rect: CGRectMake(CGFloat(x * grid.size), CGFloat(y * grid.size), CGFloat(grid.size), CGFloat(grid.size)),
            value: autonGrid[y * grid.width + x]
        )
    }
    
    func coordList(grid: PixelGrid) -> [(x: Int, y: Int)] {
        return reduce(0..<grid.height, []) { (memo: [(x: Int, y: Int)], y: Int) -> [(x: Int, y: Int)] in
            return memo + map(0..<grid.width) { (x: Int) -> (x: Int, y: Int) in
                return (x: x, y: y)
            }
        }
    }
    
    func generateAutonGrid(pixelGrid: PixelGrid) -> ([Int]) {
        return coordList(pixelGrid).map { (g: (x: Int, y: Int)) -> Int in
            return 0
        }
    }
    
    func getOffset(x: Int, y: Int) -> Int {
        return pixelGrid!.width * y + x
    }
    
    func isValidOffset(x: Int, y: Int) -> Bool {
        if y < pixelGrid!.height && x < pixelGrid!.width {
            return true
        } else {
            return false
        }
    }
    
    func passAutonGrid(pixelGrid: PixelGrid) {
        for y in stride(from: pixelGrid.height - 1, through: 0, by: -1) {
            for x in stride(from: 0, to: pixelGrid.width, by: 1) {
                if(autonGrid![getOffset(x, y: y)] == 1) {
                    var randomFlop = [-1, 1][(Int(rand()) % 2)]
                    if isValidOffset(x, y: y + 1) && autonGrid![getOffset(x, y: y + 1)] == 0 {
                        autonGrid![getOffset(x, y: y)] = 0
                        autonGrid![getOffset(x, y: y + 1)] = 1
                    } else if isValidOffset(x + randomFlop, y: y + 1) && (autonGrid![getOffset(x + randomFlop, y: y + 1)] == 0) {
                        autonGrid![getOffset(x, y: y)] = 0
                        autonGrid![getOffset(x + randomFlop, y: y + 1)] = 1
                    }
                }
            }
        }
    }
    
    func addNewCells(pixelGrid: PixelGrid) {
        for i in 0...3 {
            autonGrid![getOffset(pixelGrid.width / 2 + ((Int(rand()) % 5) - 2), y: 0)] = 1
        }
    }

}
