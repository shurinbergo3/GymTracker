# Body Forge (GymTracker)

**Body Forge** — это современное iOS-приложение для фитнеса, разработанное для тех, кто хочет серьезно подойти к своим тренировкам. Оно сочетает в себе мощный трекер прогресса, интеграцию с Apple Health и стильный "Bento Grid" интерфейс.

![App Screenshot Placeholder](https://via.placeholder.com/800x400?text=Body+Forge+App)

## ✨ Основные возможности

*   **Умный Трекинг**:
    *   Создавайте и редактируйте программы тренировок.
    *   Фиксируйте вес, повторения и время отдыха.
    *   Поддержка суперсетов и различных типов упражнений (Силовые, Кардио, Круговые).
*   **Интеграция с HealthKit** ❤️:
    *   Отображение пульса и калорий в реальном времени во время тренировки.
    *   Закрытие колец активности Apple Watch прямо из приложения.
    *   Синхронизация шагов и сна.
*   **Аналитика и Прогресс** 📈:
    *   Детальные графики роста силовых показателей.
    *   Сравнение текущей тренировки с предыдущей (индикаторы роста/спада).
    *   Отслеживание замеров тела с визуализацией прогресса.
*   **Live Activities & Dynamic Island** 🏝️:
    *   Таймер отдыха и статус тренировки всегда на виду, даже когда приложение свернуто.
*   **Стильный UI**:
    *   Темная тема с неоновыми акцентами.
    *   Интуитивный дизайн в стиле карточек (Bento Grid).

## 🛠 Технологии

Проект написан полностью на **Swift** с использованием передовых фреймворков Apple:

*   **SwiftUI**: Для построения реактивного интерфейса.
*   **SwiftData**: Для локального хранения данных (Persistency).
*   **HealthKit**: Для чтения и записи биометрических данных.
*   **ActivityKit**: Для поддержки Live Activities и Dynamic Island.
*   **Swift Charts**: Для красивых и интерактивных графиков.
*   **Combine**: Для реактивной обработки событий.

## 🚀 Установка и запуск

1.  **Клонируйте репозиторий**:
    ```bash
    git clone https://github.com/shurinbergo3/GymTracker.git
    cd GymTracker
    ```
2.  **Откройте проект в Xcode**:
    *   Запустите файл `GymTracker.xcodeproj` (или `.xcworkspace`, если используется).
3.  **Настройка подписи (Signing)**:
    *   Выберите вашу команду разработки в настройках таргета `GymTracker` и `GymTrackerWidget`.
4.  **Соберите и запустите**:
    *   Выберите симулятор (рекомендуется iPhone 15 Pro/16 Pro для теста Dynamic Island) или реальное устройство.
    *   Нажмите `Cmd + R`.

## 📱 Требования

*   iOS 17.0+
*   Xcode 15.0+

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробности см. в файле [LICENSE](LICENSE).


---
*Developed with ❤️ by Antigravity*

## 🤖 AI Context

> *Этот раздел предназначен для AI-ассистентов, чтобы ускорить погружение в архитектуру проекта.*

### 📂 Структура Проекта

Проект имеет относительно плоскую структуру внутри основной папки таргета.

```text
GymTracker/
├── GymTracker/                  # Ядро приложения (Source Code)
│   ├── Models/                  # Выделенные модели данных
│   ├── Services/                # Сервисные классы (Analytics, Sleep, etc.)
│   ├── [Root]                   # ~70 файлов в корне: Views, ViewModels, Managers
│   │   ├── *View.swift          # SwiftUI представления (Screens & Components)
│   │   ├── *ViewModel.swift     # Логика представлений
│   │   ├── *Manager.swift       # Singleton-менеджеры (Health, Sync, LiveActivity)
│   │   └── DesignSystem.swift   # Система стилей (цвета, шрифты)
│   └── Assets.xcassets          # Ресурсы (иконки, цвета)
├── GymTrackerWidget/            # Target виджетов и Live Activities
├── GymTrackerTests/             # Unit Tests
├── GymTrackerUITests/           # UI Tests
└── Localizable.xcstrings        # Локализация
```

### 🛠 Технический Стек

*   **Язык**: Swift 5.9+
*   **UI**: SwiftUI (основной), UIKit (минимум/отсутствует).
*   **Архитектура**: MVVM (Model-View-ViewModel).
*   **База Данных**: SwiftData (Persistence).
*   **Асинхронность**: Swift Concurrency (`async/await`, `Task`, `@MainActor`), Combine (частично).

### 🧩 Ключевые Фреймворки & Компоненты

*   **HealthKit**: `HealthManager.swift` — чтение/запись тренировок, пульса, калорий, колец активности.
*   **ActivityKit**: `LiveActivityManager.swift` и `GymTrackerWidget` — поддержка Live Activities и Dynamic Island.
*   **Swift Charts**: Испольуется для визуализации прогресса (`WorkoutProgressChart.swift`).
*   **Cloud & Sync**:
    *   `SyncManager.swift`: Синхронизация данных (включая CloudKit/Firestore аспекты если есть).
    *   `FirestoreManager.swift`: Интеграция с Firebase Firestore.
    *   `AuthManager.swift`: Аутентификация (Google Sign-In).

### 🎨 Design System

Все основные UI-константы, цвета и модификаторы вынесены в `DesignSystem.swift`. Приложение использует "Bento Grid" стиль с темной темой и неоновыми акцентами.

