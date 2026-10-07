//
//  Note.swift
//  AiNoteTaker
//
//  Created by MacBook Pro on 9/21/26.
//
import Foundation

struct Note: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var reminderDate: Date
    var createdAt: Date = Date()
}
