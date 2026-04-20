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
        df.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
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
        print("DATESTRING: \(dateString)")
        guard let date = serverFormatter.date(from: dateString) else {
            return ""
        }
        let calendar = Calendar.current
        let now = Date()
        let components1 = calendar.dateComponents([.year, .month, .day], from: date)
        let components2 = calendar.dateComponents([.year, .month, .day], from: now)
        
        if components1.year == components2.year && components1.month == components2.month && components1.day == components2.day {
            return timeFormatter.string(from: date)
        } else {
            return dateFormatter.string(from: date)
        }
    }
    func formatDateMessage(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "" }
        
        // 1. Очищаем строку от лишних пробелов по краям
        let trimmedDate = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. Хак для старых iOS: превращаем "+00:00" в "+0000"
        // Это гарантирует, что маска "Z" или "ZZZ" сработает везде.
        var finalDateString = trimmedDate
        if trimmedDate.contains("+") || trimmedDate.contains("-") {
            let components = trimmedDate.components(separatedBy: ":")
            if components.count > 1 {
                let lastComponent = components.last!
                if lastComponent.count == 2 {
                    // Убираем только последнее двоеточие (которое в таймзоне)
                    if let lastIndex = finalDateString.lastIndex(of: ":") {
                        finalDateString.remove(at: lastIndex)
                    }
                }
            }
        }

        // 3. Форматтер для строки вида "yyyy-MM-dd HH:mm:ss+0000"
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        
        if let date = df.date(from: finalDateString) {
            return timeFormatter.string(from: date)
        }
        
        // 4. Если всё равно не вышло (на случай, если Python пришлет "T")
        let isoDf = DateFormatter()
        isoDf.locale = Locale(identifier: "en_US_POSIX")
        isoDf.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        // Пробуем еще раз с очищенной строкой
        let isoString = finalDateString.replacingOccurrences(of: " ", with: "T")
        if let date = isoDf.date(from: isoString) {
            return timeFormatter.string(from: date)
        }

        return "err"
    }
}
