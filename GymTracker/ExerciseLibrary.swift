//
//  ExerciseLibrary.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import Foundation

// MARK: - Exercise Categories

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case chest = "Грудь"
    case back = "Спина"
    case legs = "Ноги"
    case shoulders = "Плечи"
    case arms = "Руки"
    case core = "Кор"
    case cardio = "Кардио"
    case complex = "Комплексные"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.arms.open"
        case .legs: return "figure.walk"
        case .shoulders: return "figure.arms.open"
        case .arms: return "figure.flexibility"
        case .core: return "figure.core.training"
        case .cardio: return "heart.fill"
        case .complex: return "figure.mixed.cardio"
        }
    }
}

enum MuscleGroup: String, CaseIterable {
    // Грудь
    case upperChest = "Верх груди"
    case middleChest = "Середина груди"
    case lowerChest = "Низ груди"
    
    // Спина
    case lats = "Широчайшие"
    case trapezius = "Трапеции"
    case lowerBack = "Поясница"
    case rearDelts = "Задние дельты"
    
    // Ноги
    case quadriceps = "Квадрицепсы"
    case hamstrings = "Бицепс бедра"
    case glutes = "Ягодицы"
    case calves = "Икры"
    
    // Плечи
    case frontDelts = "Передние дельты"
    case sideDelts = "Средние дельты"
    
    // Руки
    case biceps = "Бицепс"
    case triceps = "Трицепс"
    case forearms = "Предплечья"
    
    // Кор и полное тело
    case core = "Кор"
    case fullBody = "Все тело"
}

// MARK: - Library Exercise

struct LibraryExercise: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let muscleGroup: MuscleGroup
    let technique: String? // Описание техники выполнения
    
    init(name: String, category: ExerciseCategory, muscleGroup: MuscleGroup, technique: String? = nil) {
        self.name = name
        self.category = category
        self.muscleGroup = muscleGroup
        self.technique = technique
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LibraryExercise, rhs: LibraryExercise) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Exercise Library

struct ExerciseLibrary {
    static let allExercises: [LibraryExercise] = [
        // ГРУДЬ
        LibraryExercise(
            name: "Жим штанги лежа",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Лопатки сведены и прижаты. Штангу опускай на низ груди. Локти под углом 45 градусов к телу."
        ),
        LibraryExercise(
            name: "Жим гантелей лежа",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Лопатки сведены. Гантели опускай глубоко. Локти под углом 45 градусов."
        ),
        LibraryExercise(
            name: "Жим на наклонной скамье",
            category: .chest,
            muscleGroup: .upperChest,
            technique: "Скамья 30-45 градусов. Жми вверх, сводя гантели, но не ударяя их. Опускай глубоко, растягивая грудь."
        ),
        LibraryExercise(
            name: "Жим гантелей наклонный",
            category: .chest,
            muscleGroup: .upperChest,
            technique: "Скамья 30-45 градусов. Жми вверх, сводя гантели, но не ударяя их. Опускай глубоко, растягивая грудь."
        ),
        LibraryExercise(
            name: "Жим гантелей на наклонной",
            category: .chest,
            muscleGroup: .upperChest,
            technique: "Скамья 30-45 градусов. Жми вверх, сводя гантели, но не ударяя их. Опускай глубоко, растягивая грудь."
        ),
        LibraryExercise(
            name: "Разводка гантелей",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Локти слегка согнуты. Разводи гантели в стороны, чувствуя растяжение грудных."
        ),
        LibraryExercise(
            name: "Отжимания",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Тело в линию. Касайся грудью пола. Локти не разводи широко. Пресс напряжен."
        ),
        LibraryExercise(
            name: "Отжимания на брусьях",
            category: .chest,
            muscleGroup: .lowerChest,
            technique: "Наклон вперед — акцент на грудь, вертикально — трицепс. Опускайся до 90 градусов в локте."
        ),
        LibraryExercise(
            name: "Сведения (Flyes)",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Локти чуть согнуты. Своди руки перед собой, максимально сжимая грудные мышцы."
        ),
        LibraryExercise(
            name: "Сведение рук",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Локти на уровне плеч. Своди руки перед собой, сжимая грудные мышцы."
        ),
        LibraryExercise(
            name: "Жим в Хаммере",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Лопатки прижаты к спинке. Жми рукояти вперед с контролем."
        ),
        LibraryExercise(
            name: "Жим лежа (Силовой)",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Лопатки сведены и прижаты. Штангу опускай на низ груди. Локти под углом 45 градусов к телу."
        ),
        LibraryExercise(
            name: "Жим лежа (5/3/1)",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Лопатки сведены и прижаты. Штангу опускай на низ груди. Локти под углом 45 градусов к телу."
        ),
        LibraryExercise(
            name: "Жим лежа (Т2 3×10)",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Лопатки сведены и прижаты. Штангу опускай на низ груди. Локти под углом 45 градусов к телу."
        ),
        
        // СПИНА
        LibraryExercise(
            name: "Подтягивания",
            category: .back,
            muscleGroup: .lats,
            technique: "Хват шире плеч. Тянись грудью к перекладине. Локти своди к ребрам. Не раскачивайся."
        ),
        LibraryExercise(
            name: "Подтягивания с весом",
            category: .back,
            muscleGroup: .lats,
            technique: "Хват шире плеч. Тянись грудью к перекладине. Локти своди к ребрам. Не раскачивайся."
        ),
        LibraryExercise(
            name: "Подтягивания (Heavy)",
            category: .back,
            muscleGroup: .lats,
            technique: "Хват шире плеч. Тянись грудью к перекладине. Локти своди к ребрам. Не раскачивайся."
        ),
        LibraryExercise(
            name: "Тяга штанги в наклоне",
            category: .back,
            muscleGroup: .lats,
            technique: "Наклон корпуса 45 градусов. Спина прямая. Тяни гриф к низу живота, сводя лопатки."
        ),
        LibraryExercise(
            name: "Тяга в наклоне",
            category: .back,
            muscleGroup: .lats,
            technique: "Наклон корпуса 45 градусов. Спина прямая. Тяни гриф к низу живота, сводя лопатки."
        ),
        LibraryExercise(
            name: "Тяга верхнего блока",
            category: .back,
            muscleGroup: .lats,
            technique: "Сядь плотно. Тяни рукоять к верху груди. Локти направляй вниз и назад. Плечи не задирай к ушам."
        ),
        LibraryExercise(
            name: "Тяга гантелей в наклоне",
            category: .back,
            muscleGroup: .lats,
            technique: "Упор рукой и коленом в скамью. Тяни гантель к поясу (как будто заводишь пилу). Локоть идет вдоль корпуса."
        ),
        LibraryExercise(
            name: "Тяга одной рукой",
            category: .back,
            muscleGroup: .lats,
            technique: "Упор рукой и коленом в скамью. Тяни гантель к поясу (как будто заводишь пилу). Локоть идет вдоль корпуса."
        ),
        LibraryExercise(
            name: "Тяга горизонтального блока",
            category: .back,
            muscleGroup: .lats,
            technique: "Спина вертикально. Тяни рукоять к животу. Плечи отводи назад, грудь вперед. Растягивай широчайшие при возврате."
        ),
        LibraryExercise(
            name: "Тяга TRX/Блока",
            category: .back,
            muscleGroup: .lats,
            technique: "Спина вертикально. Тяни рукоять к животу. Своди лопатки в конечной точке."
        ),
        LibraryExercise(
            name: "Тяга блока узким хватом",
            category: .back,
            muscleGroup: .lats,
            technique: "Спина вертикально. Тяни рукоять к животу. Плечи отводи назад."
        ),
        LibraryExercise(
            name: "Тяга блока (Т3 3×15)",
            category: .back,
            muscleGroup: .lats,
            technique: "Сядь плотно. Тяни рукоять к верху груди. Локти направляй вниз и назад."
        ),
        LibraryExercise(
            name: "Шраги со штангой",
            category: .back,
            muscleGroup: .trapezius,
            technique: "Стоя с гантелями/штангой. Поднимай плечи к ушам. Руки прямые. Не вращай плечами."
        ),
        LibraryExercise(
            name: "Гиперэкстензия",
            category: .back,
            muscleGroup: .lowerBack,
            technique: "Спина прямая. Опускайся с контролем, поднимайся силой поясницы и ягодиц."
        ),
        LibraryExercise(
            name: "Лицевая тяга",
            category: .back,
            muscleGroup: .rearDelts,
            technique: "Блок на уровне глаз. Тяни канат к лицу, разводя руки в стороны (поза \"двойной бицепс\"). Локти выше плеч."
        ),
        LibraryExercise(
            name: "Тяга Т-грифа с упором",
            category: .back,
            muscleGroup: .lats,
            technique: "Грудью упрись в подушку. Тяни гриф к животу, сводя лопатки."
        ),
        LibraryExercise(
            name: "Тяга Т-грифа",
            category: .back,
            muscleGroup: .lats,
            technique: "Грудью упрись в подушку. Тяни гриф к животу, сводя лопатки."
        ),
        LibraryExercise(
            name: "Тяга Пендли",
            category: .back,
            muscleGroup: .lats,
            technique: "Гриф касается пола между повторами. Резко тяни к груди, взрывным движением."
        ),
        LibraryExercise(
            name: "Пуловер",
            category: .back,
            muscleGroup: .lats,
            technique: "Лежа поперек скамьи. Опускай гантель за голову, растягивая широчайшие."
        ),
        
        // НОГИ
        LibraryExercise(
            name: "Приседания со штангой",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Штанга на трапециях. Отводи таз назад, колени смотрят в стороны (по носкам). Дави пятками в пол."
        ),
        LibraryExercise(
            name: "Приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Штанга на трапециях. Отводи таз назад, колени смотрят в стороны (по носкам). Дави пятками в пол."
        ),
        LibraryExercise(
            name: "Приседания Low bar",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Штанга ниже на спине. Наклон корпуса больше. Отводи таз назад, дави пятками."
        ),
        LibraryExercise(
            name: "Приседания (5/3/1)",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Штанга на трапециях. Отводи таз назад, колени смотрят в стороны (по носкам). Дави пятками в пол."
        ),
        LibraryExercise(
            name: "Присед (Т1 5×3)",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Штанга на трапециях. Отводи таз назад, колени смотрят в стороны (по носкам). Дави пятками в пол."
        ),
        LibraryExercise(
            name: "Присед на спине",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Штанга на трапециях. Отводи таз назад, колени смотрят в стороны (по носкам). Дави пятками в пол."
        ),
        LibraryExercise(
            name: "Фронтальные приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Штанга на передних дельтах, локти высоко вверх. Корпус держи вертикально. Акцент на квадрицепс."
        ),
        LibraryExercise(
            name: "Гоблет-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Держи гантель у груди. Садись \"между ног\", локти касаются коленей. Спина прямая."
        ),
        LibraryExercise(
            name: "Гоблет присед",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Держи гантель у груди. Садись \"между ног\", локти касаются коленей. Спина прямая."
        ),
        LibraryExercise(
            name: "Кубковые приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Держи гантель у груди. Садись \"между ног\", локти касаются коленей. Спина прямая."
        ),
        LibraryExercise(
            name: "Жим ногами",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Спина прижата. Опускай платформу до угла 90 градусов в коленях. Не выпрямляй ноги полностью вверху."
        ),
        LibraryExercise(
            name: "Выпады с гантелями",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Шаг вперед/назад. Колено задней ноги почти касается пола. Углы в коленях 90 градусов."
        ),
        LibraryExercise(
            name: "Выпады",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Шаг вперед/назад. Колено задней ноги почти касается пола. Углы в коленях 90 градусов."
        ),
        LibraryExercise(
            name: "Выпады назад",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Шаг назад. Колено задней ноги почти касается пола. Углы в коленях 90 градусов."
        ),
        LibraryExercise(
            name: "Болгарские выпады",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Задняя нога на скамье. Опускайся вертикально вниз. Вес на пятке передней ноги. Корпус чуть вперед."
        ),
        LibraryExercise(
            name: "Румынская тяга",
            category: .legs,
            muscleGroup: .hamstrings,
            technique: "Ноги почти прямые. Веди штангу вниз по ногам, отводя таз максимально назад. Чувствуй растяжение бицепса бедра."
        ),
        LibraryExercise(
            name: "Румынская тяга гантели",
            category: .legs,
            muscleGroup: .hamstrings,
            technique: "Ноги почти прямые. Веди гантели вниз по ногам, отводя таз максимально назад. Чувствуй растяжение бицепса бедра."
        ),
        LibraryExercise(
            name: "Становая тяга",
            category: .complex,
            muscleGroup: .fullBody,
            technique: "Штанга над шнурками. Спина прямая. Поднимай за счет ног и спины одновременно. Вверху сожми ягодицы."
        ),
        LibraryExercise(
            name: "Становая тяга (5/3/1)",
            category: .complex,
            muscleGroup: .fullBody,
            technique: "Штанга над шнурками. Спина прямая. Поднимай за счет ног и спины одновременно. Вверху сожми ягодицы."
        ),
        LibraryExercise(
            name: "Становая (Т2)",
            category: .complex,
            muscleGroup: .fullBody,
            technique: "Штанга над шнурками. Спина прямая. Поднимай за счет ног и спины одновременно. Вверху сожми ягодицы."
        ),
        LibraryExercise(
            name: "Становая сумо",
            category: .legs,
            muscleGroup: .glutes,
            technique: "Широкая постановка ног, носки в стороны. Хват узкий. Спина вертикальнее, чем в классике."
        ),
        LibraryExercise(
            name: "Сгибания ног лежа",
            category: .legs,
            muscleGroup: .hamstrings,
            technique: "Лежа или сидя. Сгибай ноги, стараясь коснуться пятками ягодиц. Пауза в пиковом сокращении."
        ),
        LibraryExercise(
            name: "Сгибание ног лежа",
            category: .legs,
            muscleGroup: .hamstrings,
            technique: "Лежа. Сгибай ноги, стараясь коснуться пятками ягодиц. Пауза в пиковом сокращении."
        ),
        LibraryExercise(
            name: "Сгибание ног сидя",
            category: .legs,
            muscleGroup: .hamstrings,
            technique: "Сидя. Сгибай ноги, стараясь коснуться пятками ягодиц. Пауза в пиковом сокращении."
        ),
        LibraryExercise(
            name: "Подъемы на носки стоя",
            category: .legs,
            muscleGroup: .calves,
            technique: "Стоя или сидя. Опускай пятку максимально низко (растяжение), поднимайся максимально высоко (сокращение)."
        ),
        LibraryExercise(
            name: "Подъем на носки",
            category: .legs,
            muscleGroup: .calves,
            technique: "Стоя или сидя. Опускай пятку максимально низко (растяжение), поднимайся максимально высоко (сокращение)."
        ),
        LibraryExercise(
            name: "Ягодичный мост со штангой",
            category: .legs,
            muscleGroup: .glutes,
            technique: "Лопатки на скамье, штанга на сгибе бедра. Толкай таз вверх, в пике сжимай ягодицы. Не прогибай поясницу."
        ),
        LibraryExercise(
            name: "Ягодичный мост",
            category: .legs,
            muscleGroup: .glutes,
            technique: "Лопатки на скамье, штанга на сгибе бедра. Толкай таз вверх, в пике сжимай ягодицы. Не прогибай поясницу."
        ),
        LibraryExercise(
            name: "Ягодичный мост (Hip Thrust)",
            category: .legs,
            muscleGroup: .glutes,
            technique: "Лопатки на скамье, штанга на сгибе бедра. Толкай таз вверх, в пике сжимай ягодицы. Не прогибай поясницу."
        ),
        LibraryExercise(
            name: "Разгибание ног",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Сидя. Разгибай ноги полностью. В верхней точке задержись на секунду, напрягая квадрицепс."
        ),
        
        // ПЛЕЧИ
        LibraryExercise(
            name: "Жим штанги стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "Штанга на груди. Жми строго вертикально вверх, чуть отклоняя голову назад, чтобы пропустить гриф. Пресс и ягодицы зажаты."
        ),
        LibraryExercise(
            name: "Жим стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "Штанга на груди. Жми строго вертикально вверх, чуть отклоняя голову назад, чтобы пропустить гриф. Пресс и ягодицы зажаты."
        ),
        LibraryExercise(
            name: "Армейский жим",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "Штанга на груди. Жми строго вертикально вверх, чуть отклоняя голову назад, чтобы пропустить гриф. Пресс и ягодицы зажаты."
        ),
        LibraryExercise(
            name: "Армейский жим (5/3/1)",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "Штанга на груди. Жми строго вертикально вверх, чуть отклоняя голову назад, чтобы пропустить гриф. Пресс и ягодицы зажаты."
        ),
        LibraryExercise(
            name: "Армейский жим (Т1)",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "Штанга на груди. Жми строго вертикально вверх, чуть отклоняя голову назад, чтобы пропустить гриф. Пресс и ягодицы зажаты."
        ),
        LibraryExercise(
            name: "Жим гантелей сидя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "Спина прямая. Жми гантели вверх. Не ударяй их в верхней точке."
        ),
        LibraryExercise(
            name: "Жим гантелей стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "Пресс напряжен. Жми гантели вверх. Не прогибай поясницу."
        ),
        LibraryExercise(
            name: "Жим Арнольда",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "Начни ладонями к себе. При жиме разворачивай ладони наружу. Задействует все пучки дельт."
        ),
        LibraryExercise(
            name: "Махи гантелями в стороны",
            category: .shoulders,
            muscleGroup: .sideDelts,
            technique: "Локти чуть согнуты. Поднимай гантель через стороны до параллели с полом. Мизинец чуть выше большого пальца."
        ),
        LibraryExercise(
            name: "Махи в стороны",
            category: .shoulders,
            muscleGroup: .sideDelts,
            technique: "Локти чуть согнуты. Поднимай гантели через стороны до параллели с полом. Мизинец чуть выше большого пальца."
        ),
        LibraryExercise(
            name: "Махи сидя",
            category: .shoulders,
            muscleGroup: .sideDelts,
            technique: "Сидя. Локти чуть согнуты. Поднимай гантели через стороны до параллели с полом."
        ),
        LibraryExercise(
            name: "Махи на блоке",
            category: .shoulders,
            muscleGroup: .sideDelts,
            technique: "Стоя боком к блоку. Поднимай рукоять через сторону до параллели с полом."
        ),
        LibraryExercise(
            name: "Махи в наклоне",
            category: .shoulders,
            muscleGroup: .rearDelts,
            technique: "Корпус наклонен. Разводи гантели в стороны, локти чуть согнуты."
        ),
        LibraryExercise(
            name: "Обратные разведения",
            category: .shoulders,
            muscleGroup: .rearDelts,
            technique: "В тренажере. Разводи рукоятки назад, сжимая задние дельты."
        ),
        LibraryExercise(
            name: "Разведения (Т3)",
            category: .shoulders,
            muscleGroup: .sideDelts,
            technique: "Локти чуть согнуты. Разводи гантели в стороны до параллели с полом."
        ),
        LibraryExercise(
            name: "Тяга к подбородку",
            category: .shoulders,
            muscleGroup: .sideDelts,
            technique: "Локти выше кистей. Тяни штангу к подбородку. Не поднимай плечи к ушам."
        ),
        LibraryExercise(
            name: "Жим Смита",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "В тренажере Смита. Жми штангу вверх с контролем."
        ),
        LibraryExercise(
            name: "Жим из-за головы",
            category: .shoulders,
            muscleGroup: .frontDelts,
            technique: "Штангу опускай за голову. Только если подвижность плечевого сустава позволяет!"
        ),
        
        // РУКИ
        LibraryExercise(
            name: "Подъем штанги на бицепс",
            category: .arms,
            muscleGroup: .biceps,
            technique: "Локти прижаты к корпусу. Поднимай штангу к плечам. Не раскачивайся корпусом."
        ),
        LibraryExercise(
            name: "Молотковые сгибания",
            category: .arms,
            muscleGroup: .biceps,
            technique: "Ладони смотрят друг на друга. Сгибай руки с гантелями. Акцент на брахиалис и предплечье."
        ),
        LibraryExercise(
            name: "Молотки на бицепс",
            category: .arms,
            muscleGroup: .biceps,
            technique: "Ладони смотрят друг на друга. Сгибай руки с гантелями. Акцент на брахиалис и предплечье."
        ),
        LibraryExercise(
            name: "Сгибание на блоке спиной",
            category: .arms,
            muscleGroup: .biceps,
            technique: "Стоя спиной к блоку. Сгибай руки, чувствуя пиковое сокращение бицепса."
        ),
        LibraryExercise(
            name: "Bayesian Curl",
            category: .arms,
            muscleGroup: .biceps,
            technique: "Стоя спиной к блоку. Одной рукой. Максимальное растяжение и сокращение бицепса."
        ),
        LibraryExercise(
            name: "Сгибание Паук",
            category: .arms,
            muscleGroup: .biceps,
            technique: "Грудью на наклонной скамье. Руки висят вертикально вниз. Сгибай, чувствуя пиковое сокращение."
        ),
        LibraryExercise(
            name: "Французский жим",
            category: .arms,
            muscleGroup: .triceps,
            technique: "Лежа. Опускай штангу/гантели ко лбу или за голову. Локти зафиксированы в одной точке."
        ),
        LibraryExercise(
            name: "Разгибания на блоке",
            category: .arms,
            muscleGroup: .triceps,
            technique: "Локти прижаты к бокам. Жми рукоять вниз до полного выпрямления рук. Плечи не гуляют."
        ),
        LibraryExercise(
            name: "Разгибание на трицепс",
            category: .arms,
            muscleGroup: .triceps,
            technique: "Локти прижаты к бокам. Жми рукоять вниз до полного выпрямления рук. Плечи не гуляют."
        ),
        LibraryExercise(
            name: "Жим узким хватом",
            category: .arms,
            muscleGroup: .triceps,
            technique: "Хват на ширине плеч. Локти ближе к корпусу. Опускай к низу груди."
        ),
        
        // КОР
        LibraryExercise(
            name: "Планка",
            category: .core,
            muscleGroup: .core,
            technique: "Упор на локтях. Тело — прямая линия. Пресс и ягодицы максимально напряжены. Не проваливай поясницу."
        ),
        LibraryExercise(
            name: "Скручивания",
            category: .core,
            muscleGroup: .core,
            technique: "Лежа на спине. Поднимай плечи к коленям, скручивая корпус. Поясница прижата к полу."
        ),
        LibraryExercise(
            name: "Подъем ног в висе",
            category: .core,
            muscleGroup: .core,
            technique: "Вис на перекладине. Поднимай ноги к груди. Не раскачивайся."
        ),
        
        // КАРДИО & ФУНКЦИОНАЛ
        LibraryExercise(
            name: "Берпи",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "Упор лежа -> отжимание -> прыжок к рукам -> выпрыгивание вверх. Слитное движение."
        ),
        LibraryExercise(
            name: "Махи гирей",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "Это не присед, а движение тазом! Резко выталкивай гирю бедрами вперед до уровня глаз. Спина прямая."
        ),
        LibraryExercise(
            name: "Запрыгивания на тумбу",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "Прыгай на тумбу обеими ногами. Мягко приземляйся. Полностью выпрямись наверху."
        ),
        LibraryExercise(
            name: "Канаты",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "Создавай волны канатами. Корпус слегка наклонен. Колени мягкие."
        ),
        LibraryExercise(
            name: "Бег",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "Держи ровный темп. Дыши ритмично. Приземляйся на середину стопы."
        ),
        LibraryExercise(
            name: "Бег (Интервалы: 30/30, 45/45, 60/60)",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "Чередуй спринт и ходьбу. 30 сек спринт / 30 сек ходьба. Увеличивай интервалы."
        ),
        LibraryExercise(
            name: "Эллипс",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "40-60 минут в зоне 2 пульса. Активно работать руками (push-pull)."
        ),
        LibraryExercise(
            name: "Эллипс (40-60 мин, зона 2)",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "40-60 минут в зоне 2 пульса. Активно работать руками (push-pull)."
        ),
        LibraryExercise(
            name: "Степпер",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "Шаг через ступеньку, перекрестный шаг. Не держись за поручни!"
        ),
        LibraryExercise(
            name: "Степпер (Шаг через ступеньку, Перекрестный шаг)",
            category: .cardio,
            muscleGroup: .fullBody,
            technique: "Шаг через ступеньку, перекрестный шаг. Фокус на ягодицы. Не держись за поручни!"
        ),
        
        // КОМПЛЕКСНЫЕ
        LibraryExercise(
            name: "Взятие на грудь",
            category: .complex,
            muscleGroup: .fullBody,
            technique: "Взрывным движением подними штангу на грудь. Подсядь под нее."
        ),
        LibraryExercise(
            name: "Швунг жимовой",
            category: .complex,
            muscleGroup: .fullBody,
            technique: "Жим стоя, но с помощью ног. Подсядь и резко вытолкни штангу ногами, дожимая руками."
        ),
        LibraryExercise(
            name: "Жим швунг",
            category: .complex,
            muscleGroup: .fullBody,
            technique: "Жим стоя, но с помощью ног. Подсядь и резко вытолкни штангу ногами, дожимая руками."
        ),
        LibraryExercise(
            name: "Прогулка фермера",
            category: .complex,
            muscleGroup: .fullBody,
            technique: "Возьми тяжелые гантели/гири. Иди с прямой спиной. Укрепляет хват и кор."
        ),
        LibraryExercise(
            name: "Подсобка",
            category: .complex,
            muscleGroup: .fullBody,
            technique: "Вспомогательные упражнения для основных лифтов."
        ),
        LibraryExercise(
            name: "Подсобка (50 reps)",
            category: .complex,
            muscleGroup: .fullBody,
            technique: "Вспомогательные упражнения. Выполни 50 повторений на выбор."
        ),
    ]
    
    /// Упражнения, сгруппированные по категориям
    static var exercisesByCategory: [ExerciseCategory: [LibraryExercise]] {
        Dictionary(grouping: allExercises, by: { $0.category })
    }
    
    /// Поиск упражнений по названию
    static func search(_ query: String) -> [LibraryExercise] {
        guard !query.isEmpty else { return allExercises }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
