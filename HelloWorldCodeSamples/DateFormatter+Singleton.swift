//
//  DateFormatter+Singleton.swift
//  HelloWorld
//
//  Created by Candance Smith on 10/20/16.
//  Copyright © 2016 candance. All rights reserved.
//

import Foundation

extension DateFormatter {
    
    @nonobjc static let dateFormatterFull: DateFormatter = {
        
        let dateFormatterFull = DateFormatter()
        dateFormatterFull.locale = Locale.current
        dateFormatterFull.dateStyle = .full
        return dateFormatterFull
        
    }()
    
    @nonobjc static let dateFormatterDayOfTheWeek: DateFormatter = {
        
        let dateFormatterDayOfTheWeek = DateFormatter()
        dateFormatterDayOfTheWeek.locale = Locale.current
        dateFormatterDayOfTheWeek.dateFormat = "EEEE"
        return dateFormatterDayOfTheWeek
        
    }()
    
    @nonobjc static let dateFormatterDate: DateFormatter = {
        
        let dateFormatterDate = DateFormatter()
        dateFormatterDate.locale = Locale.current
        dateFormatterDate.dateFormat = "d"
        return dateFormatterDate
        
    }()
    
    @nonobjc static let dateFormatterMonthYear: DateFormatter = {
        
        let dateFormatterMonthYear = DateFormatter()
        dateFormatterMonthYear.locale = Locale.current
        dateFormatterMonthYear.dateFormat = "MMMM yyyy"
        return dateFormatterMonthYear
        
    }()
    
    @nonobjc static func stringFromDate(_ dateFormatter: DateFormatter, date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    @nonobjc static func dateFromString(_ dateFormatter: DateFormatter, string: String) -> Date? {
       return dateFormatter.date(from: string)
    }
}
