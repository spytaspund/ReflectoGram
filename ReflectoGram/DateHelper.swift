//
//  DateHelper.swift
//  ReflectoGram
//
//  Created by spytaspund on 10.02.2026.
//

import Foundation

class DateHelper {
    static let shared = DateHelper()
    
    private let serverFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return df
    }()
    
    private let serverFormatterWithMS: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        return df
    }()
    
    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        return df
    }()
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .none
        df.dateStyle = .short
        return df
    }()
    
    func formatDate(_ dateString: String) -> String {
        var date = serverFormatter.date(from: dateString)
        
        if date == nil {
            date = serverFormatterWithMS.date(from: dateString)
        }
        
        guard let finalDate = date else { return "" }
        
        let calendar = Calendar.current
        let now = Date()
        let components1 = calendar.dateComponents([.year, .month, .day], from: finalDate)
        let components2 = calendar.dateComponents([.year, .month, .day], from: now)
        
        if components1.year == components2.year && components1.month == components2.month && components1.day == components2.day {
            return timeFormatter.string(from: finalDate)
        } else {
            return dateFormatter.string(from: finalDate)
        }
    }

    func formatDateMessage(_ dateString: String) -> String {
        let date = serverFormatter.date(from: dateString) ?? serverFormatterWithMS.date(from: dateString)
        if let d = date {
            return timeFormatter.string(from: d)
        }
        return "err"
    }
    
    func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
}
