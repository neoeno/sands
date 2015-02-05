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
    var colors = [UIColor.blackColor().CGColor, UIColor.yellowColor().CGColor, UIColor.redColor().CGColor]
    var isBackgroundRunning = false
    var context : CGContextRef?
    var throttle = 0
    lazy var sandGrid = SandGrid()
    
    override func didMoveToSuperview() {
        // If we have active timers, stop them
        if var calcTimer = self.calcTimer {
            // This stops the timer
            calcTimer.invalidate()
            self.calcTimer = nil
            
            UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
        }
        
        // If we're actually part of the view hierarchy, start the timers
        if self.superview != nil {
            self.calcTimer = NSTimer.scheduledTimerWithTimeInterval(
                0.04,
                target: self,
                selector: Selector("calculateData"),
                userInfo: nil,
                repeats: true)
            
            UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        }
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        if context == nil {
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
        let ctx = CGBitmapContextCreate(nil, UInt(size.width), UInt(size.height), 8, 0, colorSpace, bitmapInfo)
        
        return ctx
    }
    
    func drawGridDiff(grid: PixelGrid, sandGridDiff: [Byte?]) {
        for y in stride(from: grid.height - 1, through: 0, by: -1) {
            // We're going to try to draw contiguous areas with a single rectangle.
            // But only in rows, at the moment.
            var contiguousSince = 0
            var contiguousValue : Byte? = 0
            
            for x in stride(from: 0, to: grid.width, by: 1) {
                if sandGridDiff[y * grid.width + x] != contiguousValue {
                    drawRectFromPixelToPixel(grid, y: y, xFrom: contiguousSince, xTo: x, value: contiguousValue)
                    
                    contiguousSince = x
                    contiguousValue = sandGridDiff[y * grid.width + x]
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
    
    func calculateData() {
        if isBackgroundRunning == false {
            isBackgroundRunning = true
            
            if throttle > 0 {
                sandGrid.currentColor = 2
                throttle = 0
            } else {
                sandGrid.currentColor = 1
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
            self.drawGridDiff(self.sandGrid.pixelGrid, sandGridDiff: self.sandGrid.frameDiff())
            
            dispatch_async(dispatch_get_main_queue(), {
                fn()
            })
        })
    }

}
