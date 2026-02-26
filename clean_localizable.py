#!/usr/bin/env python3
"""
Очистка устаревших ключей локализации из Localizable.xcstrings
Удаляет записи с "extractionState": "stale"
"""

import json
import sys
from pathlib import Path

def clean_localizable(file_path: Path) -> dict:
    """Удаляет устаревшие ключи локализации"""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if 'strings' not in data:
        print("❌ Неверный формат файла")
        return {}
    
    original_count = len(data['strings'])
    
    # Создаем новый словарь без стареющих ключей
    cleaned_strings = {}
    removed_keys = []
    
    for key, value in data['strings'].items():
        # Проверяем, есть ли extractionState: stale
        if isinstance(value, dict) and value.get('extractionState') == 'stale':
            removed_keys.append(key)
            continue
        
        cleaned_strings[key] = value
    
    data['strings'] = cleaned_strings
    new_count = len(data['strings'])
    
    print(f"✅ Исходное количество ключей: {original_count}")
    print(f"✅ Удалено устаревших ключей: {len(removed_keys)}")
    print(f"✅ Осталось ключей: {new_count}")
    
    if removed_keys:
        print(f"\n🗑️ Удаленные ключи:")
        for key in removed_keys[:20]:  # Показываем первые 20
            print(f"   - {key}")
        if len(removed_keys) > 20:
            print(f"   ... и еще {len(removed_keys) - 20}")
    
    return data

def main():
    file_path = Path("Localizable.xcstrings")
    
    if not file_path.exists():
        print(f"❌ Файл {file_path} не найден")
        sys.exit(1)
    
    print(f"🔍 Очистка файла: {file_path}")
    
    cleaned_data = clean_localizable(file_path)
    
    if not cleaned_data:
        sys.exit(1)
    
    # Создаем резервную копию
    backup_path = file_path.with_suffix('.xcstrings.backup')
    file_path.rename(backup_path)
    print(f"💾 Создана резервная копия: {backup_path}")
    
    # Сохраняем очищенный файл
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(cleaned_data, f, ensure_ascii=False, indent=2)
    
    print(f"✅ Файл успешно очищен и сохранен")

if __name__ == "__main__":
    main()
