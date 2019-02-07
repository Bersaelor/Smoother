//
//  SectionDataSource.swift
//  Sporttotal
//
//  Copyright © 2018 sporttotal.tv gmbh. All rights reserved.
//

import Foundation

/// Smoother averages out noisy signals
/// for more background check out https://en.wikipedia.org/wiki/Moving_average#Simple_moving_average
public class Smoother<X> where X: FloatingPoint {
    
    public enum Method {
        case movingAverage
        case weightedAverage
    }
    
    public let timeInterval: TimeInterval
    public let method: Method

    public init(timeInterval: TimeInterval, method: Method = .movingAverage) {
        self.timeInterval = timeInterval
        self.method = method
    }
    
    /// This method saves the new datapoint and returns the smoothed value
    ///
    /// - Parameter value: the input datapoint
    /// - Returns: the value smoothed by combining the new value with the values inside the timeInterval
    public func smooth(value: X) -> X {
        timeSeries.append((value, Date()))
        clearOldValues()
        return smoothedValue
    }
    
    var smoothedValue: X {
        guard !timeSeries.isEmpty else {
            print("WARNING: Accessing smoothed value before entering data")
            return 0
        }
        
        guard timeSeries.count > 1 else { return timeSeries.first?.0 ?? 0 }
        
        switch method {
        case .movingAverage: return calculateMovingAverage()
        case .weightedAverage: return calculateWeigthedAverage()
        }
    }
    
    // MARK: - Implementation Details
    
    private var timeSeries = ArraySlice<(X, Date)>()

    private func clearOldValues() {
        let now = Date()
        timeSeries = timeSeries.drop(while: { now.timeIntervalSince($0.1) > timeInterval })
    }
    
    /// Simple moving average
    ///
    /// - Returns: the calculated moving average
    private func calculateMovingAverage() -> X {
        let sum = timeSeries.reduce(0) { (sum, dataPoint) -> X in
            return sum + dataPoint.0
        }
        return sum * 1 / X(timeSeries.count)
    }
    
    /// Triangular weighted moving average
    /// if n is the number of points, n is also the weight for the newest point
    /// every point after is multiplied by weights n-1, n-2 ...
    ///
    /// - Returns: the calculated moving average
    private func calculateWeigthedAverage() -> X {
        let count = timeSeries.count
        
        let sum = timeSeries.reversed().enumerated().reduce(0) { (result, argument) -> X in
            let (offset, (value, _)) = argument
            let weight = X(count - offset)
            return result + weight * value
        }
        let fullWeight = X(count * (count + 1)) / 2
        return sum / fullWeight
    }
}
