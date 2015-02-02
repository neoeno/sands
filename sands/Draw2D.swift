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
    var autonGrid : [Byte]?
    var pixelGrid : PixelGrid?
    var colors = [UIColor.blackColor().CGColor, UIColor.yellowColor().CGColor, UIColor.redColor().CGColor]
    var isBackgroundRunning = false
    var context : CGContext?
    var throttle = 0
    var currentColor : Byte = 1
    var autonGridDiff : [Byte?]?
    
    override func didMoveToSuperview() {
        // If we have active timers, stop them
        if var calcTimer = self.calcTimer {
            // This stops the timer
            calcTimer.invalidate()
            self.calcTimer = nil
        }
        
        // If we're actually part of the view hierarchy, start the timers
        if self.superview != nil {
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
            autonGrid = generateAutonGrid(pixelGrid!)
            context = CGContextCreate(self.frame.size)
        }
        
        drawToScreen()
    }
    
    func drawToScreen() {
        let realContext = UIGraphicsGetCurrentContext()
        let image = CGBitmapContextCreateImage(context)
        CGContextDrawImage(realContext, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height), image)
    }
    
    func CGContextCreate(size: CGSize) -> CGContextRef {
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        let context = CGBitmapContextCreate(nil, UInt(size.width), UInt(size.height), 8, 0, colorSpace, bitmapInfo)
        
        return context
    }
    
    func drawGridDiff(context: CGContext, grid: PixelGrid, autonGridDiff: [Byte?]) {
        for y in stride(from: grid.height - 1, through: 0, by: -1) {
            // We're going to try to draw contiguous areas with a single rectangle.
            // But only in rows, at the moment.
            var contiguousSince = 0
            var contiguousValue : Byte? = 0
            
            for x in stride(from: 0, to: grid.width, by: 1) {
                if autonGridDiff[y * grid.width + x] != contiguousValue {
                    drawRectFromPixelToPixel(grid, y: y, xFrom: contiguousSince, xTo: x, value: contiguousValue)
                    
                    contiguousSince = x
                    contiguousValue = autonGridDiff[y * grid.width + x]
                }
            }
            
            drawRectFromPixelToPixel(grid, y: y, xFrom: contiguousSince, xTo: grid.width, value: contiguousValue)
        }
    }
    
    func drawRectFromPixelToPixel(grid: PixelGrid, y: Int, xFrom: Int, xTo: Int, value: Byte?) {
        if value == nil { return }
        
        let rect = CGRectMake(CGFloat(xFrom * grid.size), CGFloat(y * grid.size), CGFloat((xTo - xFrom) * grid.size), CGFloat(grid.size))
        
        CGContextSetFillColorWithColor(context!, colors[Int(value!)])
        CGContextAddRect(context!, rect)
        CGContextFillRect(context!, rect)
    }
    
    func queuePixelDraw(x: Int, y: Int) {
        if autonGridDiff == nil {
            autonGridDiff = generateAutonGridDiff(pixelGrid!)
        }
        
        autonGridDiff![getOffset(x, y: y)] = autonGrid![getOffset(x, y: y)]
    }
    
    func drawSinglePixel(x: Int, y: Int) {
        // Poss reuse drawGrid optimisation here if it's necessary.
        let grid = pixelGrid!
        let rect = CGRectMake(CGFloat(x * grid.size), CGFloat(y * grid.size), CGFloat(grid.size), CGFloat(grid.size))
        
        CGContextSetFillColorWithColor(context!, colors[Int(autonGrid![getOffset(x, y: y)])])
        CGContextAddRect(context!, rect)
        CGContextFillRect(context!, rect)
    }

    
    func generateAutonGrid(pixelGrid: PixelGrid) -> [Byte] {
        return [Byte](count: pixelGrid.width * pixelGrid.height, repeatedValue: 0)
    }
    
    func generateAutonGridDiff(pixelGrid: PixelGrid) -> [Byte?] {
        return [Byte?](count: pixelGrid.width * pixelGrid.height, repeatedValue: nil)
    }
    
    func resetAutonGridDiff() {
        for i in 0...(autonGridDiff!.count-1) {
            autonGridDiff![i] = nil
        }
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
                let thisVal = autonGrid![thisOffset]
                
                if(thisVal != 0) {
                    let randomFlop = (Int(rand()) % 2) == 0 ? -1 : 1
                    let belowOffset = getOffset(x, y: y + 1)
                    let diagOffset = getOffset(x + randomFlop, y: y + 1)
                    
                    if isValidOffset(x, y: y + 1) && autonGrid![belowOffset] == 0 {
                        autonGrid![belowOffset] = thisVal
                        autonGrid![thisOffset] = 0
                        self.queuePixelDraw(x, y: y + 1)
                        self.queuePixelDraw(x, y: y)
                    } else if isValidOffset(x + randomFlop, y: y + 1) && (autonGrid![diagOffset] == 0) {
                        autonGrid![diagOffset] = thisVal
                        autonGrid![thisOffset] = 0
                        self.queuePixelDraw(x + randomFlop, y: y + 1)
                        self.queuePixelDraw(x, y: y)
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
                self.setNeedsDisplay()
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
            
            for i in 0...2 {
                let x = self.pixelGrid!.width / 2 + ((Int(rand()) % 6) - 4)
                self.autonGrid![self.getOffset(x, y: 0)] = self.currentColor
                self.queuePixelDraw(x, y: 0)
            }
            
            self.drawGridDiff(self.context!, grid: self.pixelGrid!, autonGridDiff: self.autonGridDiff!)
            self.resetAutonGridDiff()
            
            dispatch_async(dispatch_get_main_queue(), {
                fn()
            })
        })
    }

}
