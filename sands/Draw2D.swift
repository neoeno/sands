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
    var calcTimer : NSTimer?
    var autonGridWork : [Int]?
    var autonGrid : [Int]?
    var pixelGrid : PixelGrid?
    var coordList : [(x: Int, y: Int)]?
    let colors = [UIColor.blackColor().CGColor, UIColor.yellowColor().CGColor]
    var isBackgroundRunning = false
    var context : CGContext?
    var throttle = false
    
    override func didMoveToSuperview() {
        // If we have active timers, stop them
        if var drawTimer = self.drawTimer {
            // This stops the timer
            drawTimer.invalidate()
            self.drawTimer = nil
        }
        
        if var calcTimer = self.calcTimer {
            // This stops the timer
            calcTimer.invalidate()
            self.calcTimer = nil
        }
        
        // If we're actually part of the view hierarchy, start the timers
        if self.superview != nil {
            //Creating the looping draw timer
            self.drawTimer = NSTimer.scheduledTimerWithTimeInterval(
                0.04,
                target: self,
                selector: Selector("timerDraw"),
                userInfo: nil,
                repeats: true)

            self.calcTimer = NSTimer.scheduledTimerWithTimeInterval(
                0.04,
                target: self,
                selector: Selector("calculateData"),
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
        if pixelGrid == nil {
            pixelGrid = PixelGrid(width: 80, height: 142, size: 4)
            coordList = makeCoordList(pixelGrid!)
            autonGridWork = generateAutonGrid(pixelGrid!)
            autonGrid = autonGridWork
            context = UIGraphicsGetCurrentContext()
        }
        
        drawGrid(
            context!,
            grid: pixelGrid!,
            autonGrid: autonGrid!
        )
    }
    
    func drawGrid(context: CGContext, grid: PixelGrid, autonGrid: [Int]) {
        CGContextSetFillColorWithColor(context, colors[1])
        
        for y in stride(from: grid.height - 1, through: 0, by: -1) {
            // We're going to try to draw contiguous areas with a single rectangle.
            // But only in rows, at the moment.
            var contiguousSince = 0
            var contiguous = false
            
            for x in stride(from: 0, to: grid.width, by: 1) {
                if contiguous {
                    if autonGrid[y * grid.width + x] != 1 {
                        let from = contiguousSince
                        let to = x - 1
                        let rect = CGRectMake(CGFloat(from * grid.size), CGFloat(y * grid.size), CGFloat((to - from) * grid.size), CGFloat(grid.size))
                        CGContextAddRect(context, rect)
                        CGContextFillRect(context, rect)
                        contiguous = false
                    }
                } else {
                    if autonGrid[y * grid.width + x] == 1 {
                        contiguous = true
                        contiguousSince = x
                    }
                }
            }
            
            if contiguous {
                let from = contiguousSince
                let to = grid.width
                let rect = CGRectMake(CGFloat(from * grid.size), CGFloat(y * grid.size), CGFloat((to - from) * grid.size), CGFloat(grid.size))
                CGContextAddRect(context, rect)
                CGContextFillRect(context, rect)
            }
        }
    }
    
    func makeCoordList(grid: PixelGrid) -> [(x: Int, y: Int)] {
        return reduce(0..<grid.height, []) { (memo: [(x: Int, y: Int)], y: Int) -> [(x: Int, y: Int)] in
            return memo + map(0..<grid.width) { (x: Int) -> (x: Int, y: Int) in
                return (x: x, y: y)
            }
        }
    }
    
    func generateAutonGrid(pixelGrid: PixelGrid) -> ([Int]) {
        return [Int](count: coordList!.count, repeatedValue: 0)
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
                if(autonGridWork![getOffset(x, y: y)] == 1) {
                    let randomFlop = (Int(rand()) % 2) == 0 ? -1 : 1
                    if isValidOffset(x, y: y + 1) && autonGridWork![getOffset(x, y: y + 1)] == 0 {
                        autonGridWork![getOffset(x, y: y)] = 0
                        autonGridWork![getOffset(x, y: y + 1)] = 1
                    } else if isValidOffset(x + randomFlop, y: y + 1) && (autonGridWork![getOffset(x + randomFlop, y: y + 1)] == 0) {
                        autonGridWork![getOffset(x, y: y)] = 0
                        autonGridWork![getOffset(x + randomFlop, y: y + 1)] = 1
                    }
                }
            }
        }
    }
    
    func calculateData() {
        if isBackgroundRunning == false {
            isBackgroundRunning = true
            
            if throttle {
                autonGridWork = generateAutonGrid(pixelGrid!)
                throttle = false
            }
            
            doBackgroundRun() {
                self.autonGrid = self.autonGridWork
                self.isBackgroundRunning = false
            }
        } else  {
            throttle = true
        }
    }
    
    func doBackgroundRun(fn: () -> ()) {
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            self.passAutonGrid(self.pixelGrid!)
            
            for i in 0...3 {
                self.autonGridWork![self.getOffset(self.pixelGrid!.width / 2 + ((Int(rand()) % 6) - 4), y: 0)] = 1
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                fn()
            })
        })
    }

}
