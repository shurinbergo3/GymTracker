#!/bin/bash

# Скрипт для применения изменений локализации

echo "🧹 Очистка кеша Xcode..."

# Удаляем DerivedData для проекта
rm -rf ~/Library/Developer/Xcode/DerivedData/Body_Forge-*

echo "✅ Кеш очищен"
echo ""
echo "📱 Теперь в Xcode выполните:"
echo "1. Product → Clean Build Folder (⇧⌘K)"
echo "2. Product → Build (⌘B)" 
echo "3. Удалите приложение с симулятора"
echo "4. Product → Run (⌘R)"
echo ""
echo "🌍 Проверьте что язык установлен на русский:"
echo "Settings → General → Language & Region → Russian"
