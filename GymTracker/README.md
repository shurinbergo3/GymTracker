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
*   **Apple Watch (BodyForgeWatch)** ⌚:
    *   Зеркалирование активной тренировки на часы: упражнение, прогресс по подходам, пульс, калории.
    *   Таймер отдыха идёт на часах синхронно с iPhone.
    *   Хаптик на запястье в момент окончания отдыха (без звука — не глушит музыку в наушниках).
    *   Передача состояния через `WatchConnectivity` (`WatchSyncBridge.swift`).
*   **Стильный UI**:
    *   Темная тема с неоновыми акцентами.
    *   Интуитивный дизайн в стиле карточек (Bento Grid).
*   **Облачная Синхронизация (Firebase)** ☁️:
    *   Полный бекап данных: История тренировок, Программы, Профиль, Замеры.
    *   Офлайн режим: Тренируйтесь без интернета, данные синхронизируются при появлении сети.
    *   Кросс-девайс: Доступ к вашим данным с любого устройства (после логина).

## 🛠 Технологии

Проект написан полностью на **Swift** с использованием передовых фреймворков Apple:

*   **SwiftUI**: Для построения реактивного интерфейса (iOS + watchOS).
*   **SwiftData**: Для локального хранения данных (Persistency).
*   **HealthKit**: Для чтения и записи биометрических данных.
*   **ActivityKit**: Для поддержки Live Activities и Dynamic Island.
*   **WatchConnectivity**: Мост iPhone ↔ Apple Watch (`WatchSyncBridge`).
*   **Swift Charts**: Для красивых и интерактивных графиков.
*   **Combine**: Для реактивной обработки событий.
*   **Firebase**:
    *   **Firestore**: Облачная NoSQL база данных для синхронизации.
    *   **Auth**: Безопасная аутентификация пользователей.

## 🚀 Установка и запуск

1.  **Клонируйте репозиторий**:
    ```bash
    git clone https://github.com/shurinbergo3/GymTracker.git
    cd GymTracker
    ```
2.  **Откройте проект в Xcode**:
    *   Запустите файл `GymTracker.xcodeproj` (или `.xcworkspace`, если используется).
3.  **Настройка подписи (Signing)**:
    *   Выберите вашу команду разработки в настройках таргетов `GymTracker`, `GymTrackerWidget` и `BodyForgeWatch Watch App` (если watch-таргет добавлен — см. [`docs/WATCHOS_SETUP.md`](docs/WATCHOS_SETUP.md)).
4.  **Соберите и запустите**:
    *   Выберите симулятор (рекомендуется iPhone 15 Pro/16 Pro для теста Dynamic Island) или реальное устройство.
    *   Для проверки часов — спарьте Apple Watch (или симулятор часов) и запустите схему `BodyForgeWatch Watch App`.
    *   Нажмите `Cmd + R`.

## 📱 Требования

*   iOS 17.0+
*   watchOS 10.0+ (опционально, для часовой версии)
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
├── GymTracker/                       # Ядро приложения (Source Code)
│   ├── Models/                       # Выделенные модели данных
│   ├── Services/                     # Сервисные классы (Analytics, Sleep, etc.)
│   │   └── WatchSyncBridge.swift     # iPhone → Watch мост (WatchConnectivity)
│   ├── [Root]                        # ~70 файлов в корне: Views, ViewModels, Managers
│   │   ├── *View.swift               # SwiftUI представления (Screens & Components)
│   │   ├── *ViewModel.swift          # Логика представлений
│   │   ├── *Manager.swift            # Singleton-менеджеры (Health, Sync, LiveActivity)
│   │   └── DesignSystem.swift        # Система стилей (цвета, шрифты)
│   └── Assets.xcassets               # Ресурсы (иконки, цвета)
├── GymTrackerWidget/                 # Target виджетов и Live Activities
├── BodyForgeWatch Watch App/         # watchOS-компаньон
│   ├── BodyForgeWatchApp.swift       # @main для watchOS
│   ├── WatchRootView.swift           # UI: idle / активная тренировка / отдых
│   └── WatchWorkoutModel.swift       # приёмник payload-ов от iPhone
├── docs/
│   └── WATCHOS_SETUP.md              # Инструкция по добавлению watch-таргета
├── GymTrackerTests/                  # Unit Tests
├── GymTrackerUITests/                # UI Tests
└── Localizable.xcstrings             # Локализация
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
*   **WatchConnectivity**: `WatchSyncBridge.swift` шлёт `updateApplicationContext` на часы; `BodyForgeWatch Watch App` рендерит активную тренировку, считает таймер отдыха и фитит хаптик в момент его окончания.
*   **Swift Charts**: Испольуется для визуализации прогресса (`WorkoutProgressChart.swift`).
*   **Cloud & Sync**:
    *   `SyncManager.swift`: Синхронизация данных (включая CloudKit/Firestore аспекты если есть).
    *   `FirestoreManager.swift`: Интеграция с Firebase Firestore.
    *   `AuthManager.swift`: Аутентификация (Google Sign-In).

### 🎨 Design System

Все основные UI-константы, цвета и модификаторы вынесены в `DesignSystem.swift`. Приложение использует "Bento Grid" стиль с темной темой и неоновыми акцентами.

