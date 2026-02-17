//
//  ProgramCleanupUtility.swift
//  GymTracker
//
//  Created by Antigravity
//  Utility to clean up duplicate programs
//

import Foundation
import SwiftData

/// Утилита для одноразовой очистки дублей программ
struct ProgramCleanupUtility {
    
    /// Удаляет все дубли программ, оставляя только первый экземпляр каждой
    static func removeDuplicatePrograms(context: ModelContext) {
        let descriptor = FetchDescriptor<Program>()
        
        do {
            let allPrograms = try context.fetch(descriptor)
            
            var seenNames = Set<String>()
            var duplicatesToDelete: [Program] = []
            
            // Проходим по всем программам
            for program in allPrograms {
                if seenNames.contains(program.name) {
                    // Это дубль - добавляем в список на удаление
                    duplicatesToDelete.append(program)
                } else {
                    // Первый экземпляр - запоминаем имя
                    seenNames.insert(program.name)
                }
            }
            
            // Удаляем все дубли
            for program in duplicatesToDelete {
                context.delete(program)
            }
            
            // Сохраняем изменения
            try context.save()
            
            #if DEBUG
            print("✅ Removed \(duplicatesToDelete.count) duplicate programs")
            print("✅ Kept \(seenNames.count) unique programs")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ Failed to remove duplicates: \(error)")
            #endif
        }
    }
}
