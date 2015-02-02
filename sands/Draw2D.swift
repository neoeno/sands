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
    var autonGridWork : [Byte]?
    var autonGrid : [Byte]?
    var pixelGrid : PixelGrid?
    var colors = [UIColor.blackColor().CGColor, UIColor.yellowColor().CGColor, UIColor.redColor().CGColor]
    var isBackgroundRunning = false
    var context : CGContext?
    var throttle = 0
    var currentColor : Byte = 1
    
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
            pixelGrid = PixelGrid(width: 142*2, height: 80*2, size: 2)
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
    
    func drawGrid(context: CGContext, grid: PixelGrid, autonGrid: [Byte]) {
        CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)
        CGContextSetLineWidth(context, 0.5)
        for y in stride(from: grid.height - 1, through: 0, by: -1) {
            // We're going to try to draw contiguous areas with a single rectangle.
            // But only in rows, at the moment.
            var contiguousSince = 0
            var contiguousValue : Byte = 0
            var contiguous = false
            
            for x in stride(from: 0, to: grid.width, by: 1) {
                if contiguous {
                    if autonGrid[y * grid.width + x] != contiguousValue {
                        let from = contiguousSince
                        let to = x
                        let rect = CGRectMake(CGFloat(from * grid.size), CGFloat(y * grid.size), CGFloat((to - from) * grid.size), CGFloat(grid.size))
                        CGContextSetFillColorWithColor(context, colors[Int(contiguousValue)])
                        CGContextAddRect(context, rect)
                        CGContextFillRect(context, rect)
//                        CGContextStrokeRect(context, rect)
                        
                        if(autonGrid[y * grid.width + x] != 0) {
                            contiguous = true
                            contiguousSince = x
                            contiguousValue = autonGrid[y * grid.width + x]
                        } else {
                            contiguous = false
                            contiguousValue = 0
                        }
                    }
                } else {
                    if autonGrid[y * grid.width + x] != contiguousValue {
                        contiguous = true
                        contiguousSince = x
                        contiguousValue = autonGrid[y * grid.width + x]
                    }
                }
            }
            
            if contiguous {
                let from = contiguousSince
                let to = grid.width
                let rect = CGRectMake(CGFloat(from * grid.size), CGFloat(y * grid.size), CGFloat((to - from) * grid.size), CGFloat(grid.size))
                CGContextSetFillColorWithColor(context, colors[Int(contiguousValue)])
                CGContextAddRect(context, rect)
                CGContextFillRect(context, rect)
            }
        }
    }
    
    func generateAutonGrid(pixelGrid: PixelGrid) -> [Byte] {
        return [Byte](count: pixelGrid.width * pixelGrid.height, repeatedValue: 0)
    }
    
    func getOffset(x: Int, y: Int) -> Int {
        return pixelGrid!.width * y + x
    }
    
    func isValidOffset(x: Int, y: Int) -> Bool {
        return y < pixelGrid!.height && x < pixelGrid!.width
    }
    
    func passAutonGrid(pixelGrid: PixelGrid) {
        for y in stride(from: pixelGrid.height - 1, through: 0, by: -1) {
            for x in stride(from: 0, to: pixelGrid.width, by: 1) {
                let thisOffset = getOffset(x, y: y)
                let thisVal = autonGridWork![thisOffset]
                
                if(thisVal != 0) {
                    let randomFlop = (Int(rand()) % 2) == 0 ? -1 : 1
                    let belowOffset = getOffset(x, y: y + 1)
                    let diagOffset = getOffset(x + randomFlop, y: y + 1)
                    
                    if isValidOffset(x, y: y + 1) && autonGridWork![belowOffset] == 0 {
                        autonGridWork![belowOffset] = thisVal
                        autonGridWork![thisOffset] = 0
                    } else if isValidOffset(x + randomFlop, y: y + 1) && (autonGridWork![diagOffset] == 0) {
                        autonGridWork![diagOffset] = thisVal
                        autonGridWork![thisOffset] = 0
                    }
                }
            }
        }
    }
    
    func calculateData() {
        if isBackgroundRunning == false {
            isBackgroundRunning = true
            
            if throttle > 0 {
                currentColor = 2
                throttle = 0
            } else {
                currentColor = 1
            }
            
            doBackgroundRun() {
                self.autonGrid = self.autonGridWork
                self.isBackgroundRunning = false
            }
        } else  {
            throttle = 1
        }
    }
    
    func doBackgroundRun(fn: () -> ()) {
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            self.passAutonGrid(self.pixelGrid!)
            
            for i in 0...3 {
                self.autonGridWork![self.getOffset(self.pixelGrid!.width / 2 + ((Int(rand()) % 6) - 4), y: 0)] = self.currentColor
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                fn()
            })
        })
    }

}
