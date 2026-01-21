//
//  ExerciseLibrary.swift
//  GymTracker
//
//  Created by Antigravity
//

import Foundation
import SwiftData

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
        case .arms: return "figure.strengthtraining.traditional"
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
    let defaultType: WorkoutType // Default workout type
    let technique: String? // Описание техники выполнения
    let videoUrl: String? // Ссылка на видео (YouTube)
    
    init(name: String, category: ExerciseCategory, muscleGroup: MuscleGroup, defaultType: WorkoutType = .strength, technique: String? = nil, videoUrl: String? = nil) {
        self.name = name
        self.category = category
        self.muscleGroup = muscleGroup
        self.defaultType = defaultType
        self.technique = technique
        self.videoUrl = videoUrl
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
        // MARK: - ГРУДЬ
        LibraryExercise(
            name: "Жим штанги лежа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Лягте на скамью, лопатки сведены и плотно прижаты. Хват чуть шире плеч. Опустите штангу на нижнюю часть груди (соски), локти под углом 45°. На выдохе мощно выжмите вверх без отрыва лопаток. Ноги жестко упираются в пол.",
            videoUrl: "https://www.youtube.com/results?search_query=bench+press+technique"
        ),
        LibraryExercise(
            name: "Жим гантелей лежа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Лягте на скамью. Гантели над грудью, лопатки сведены. Опускайте гантели по дуге вниз до растяжения грудных. Выжмите вверх, сводя их в верхней точке. Это упражнение дает большую амплитуду, чем штанга.",
            videoUrl: "https://www.youtube.com/results?search_query=dumbbell+bench+press+technique"
        ),
        LibraryExercise(
            name: "Жим на наклонной скамье",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Скамья 30-45°. Опускайте штангу на верх груди (ключицы). Локти держите под углом, не разводите широко. Акцент на верхний пучок грудных мышц.",
            videoUrl: "https://www.youtube.com/results?search_query=incline+bench+press+technique"
        ),
        LibraryExercise(
            name: "Жим гантелей наклонный",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Скамья 30-45°. Опускайте гантели к плечам, чувствуя растяжение верха груди. Жмите вверх, сводя руки. Предплечья вертикальны в нижней точке.",
            videoUrl: "https://www.youtube.com/results?search_query=incline+dumbbell+press+technique"
        ),
        LibraryExercise(
            name: "Кроссовер (верхние блоки)",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Встаньте по центру, корпус чуть вперед. Сводите руки перед собой вниз к поясу, акцентируя внимание на сжатии низа груди. Локти чуть согнуты и зафиксированы.",
            videoUrl: "https://www.youtube.com/results?search_query=cable+crossover+high+pulley"
        ),
        LibraryExercise(
            name: "Кроссовер (нижние блоки)",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Тяните рукояти снизу вверх и вперед перед лицом. Акцент на верх груди. В верхней точке сделайте пиковое сокращение.",
            videoUrl: "https://www.youtube.com/results?search_query=cable+crossover+low+pulley"
        ),
        LibraryExercise(
            name: "Разводка гантелей",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Лежа на скамье, разводите руки в стороны по широкой дуге до растяжения грудных. Локти зафиксированы под тупым углом. Движение 'обнимания бочки'.",
            videoUrl: "https://www.youtube.com/results?search_query=dumbbell+flyes+technique"
        ),
        LibraryExercise(
            name: "Отжимания от пола",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Тело в одну линию. Опускайтесь до касания грудью пола. Локти направлены назад под углом 45°, не в стороны. Полная амплитуда.",
            videoUrl: "https://www.youtube.com/results?search_query=pushups+technique"
        ),
        LibraryExercise(
            name: "Отжимания на брусьях",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Наклоните корпус вперед, ноги отведите назад. Опускайтесь до 90° в локтях. Локти чуть в стороны для акцента на грудь.",
            videoUrl: "https://www.youtube.com/results?search_query=dips+chest+focus"
        ),
        LibraryExercise(
            name: "Жим в Хаммере",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Сядьте плотно, лопатки прижаты. Жмите рукояти вперед. Тренажер задает траекторию, фокусируйтесь только на сокращении грудных.",
            videoUrl: "https://www.youtube.com/results?search_query=hammer+strength+chest+press"
        ),

        // MARK: - СПИНА
        LibraryExercise(
            name: "Подтягивания",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Хват шире плеч. Тянитесь грудью к перекладине, сводя лопатки. Локти вниз. Не сутультесь в верхней точке.",
            videoUrl: "https://www.youtube.com/results?search_query=pullups+technique"
        ),
        LibraryExercise(
            name: "Тяга штанги в наклоне",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Наклон корпуса 45°. Спина прямая. Тяните штангу к низу живота, сводя лопатки. Ведите локти вдоль корпуса.",
            videoUrl: "https://www.youtube.com/results?search_query=barbell+row+technique"
        ),
        LibraryExercise(
            name: "Тяга верхнего блока",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Сядьте, зафиксируйте ноги. Тяните рукоять к верху груди, прогибаясь в грудном отделе. Опускайте плечи вниз.",
            videoUrl: "https://www.youtube.com/results?search_query=lat+pulldown+technique"
        ),
        LibraryExercise(
            name: "Тяга гантели в наклоне",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Упор коленом и рукой в скамью. Спина параллельна полу. Тяните гантель к тазу (движение 'в карман'), локоть строго вверх.",
            videoUrl: "https://www.youtube.com/results?search_query=dumbbell+row+technique"
        ),
        LibraryExercise(
            name: "Тяга горизонтального блока",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Сидя, спина прямая. Тяните рукоять к животу, сводя лопатки. Плечи не поднимайте к ушам. При возврате чуть подайте корпус вперед для растяжения.",
            videoUrl: "https://www.youtube.com/results?search_query=seated+cable+row+technique"
        ),
        LibraryExercise(
            name: "Пуловер с гантелью",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Лежа лопатками на скамье. Опускайте гантель за голову на чуть согнутых руках, максимально растягивая широчайшие. Таз можно слегка опустить.",
            videoUrl: "https://www.youtube.com/results?search_query=dumbbell+pullover+technique"
        ),
        LibraryExercise(
            name: "Тяга Т-грифа",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Стоя над грифом, наклон корпуса. Тяните гриф к груди, сводя лопатки. Локти прижаты. Избегайте сильной раскачки.",
            videoUrl: "https://www.youtube.com/results?search_query=t-bar+row+technique"
        ),
        LibraryExercise(
            name: "Лицевая тяга (Face Pull)",
            category: .back,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Тяга каната к лицу (переносице). Локти выше плеч. В конце движения разведите руки ('двойной бицепс'). Для осанки и задней дельты.",
            videoUrl: "https://www.youtube.com/results?search_query=face+pull+technique"
        ),
        LibraryExercise(
            name: "Гиперэкстензия",
            category: .back,
            muscleGroup: .lowerBack,
            defaultType: .repsOnly,
            technique: "Упор на уровне бедер. Опускайтесь с прямой или скругленной спиной (вариации). Поднимайтесь до прямой линии с ногами. Не переразгибайтесь.",
            videoUrl: "https://www.youtube.com/results?search_query=hyperextension+technique"
        ),

        // MARK: - НОГИ
        LibraryExercise(
            name: "Приседания со штангой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Штанга на трапециях. Садитесь вниз, разводя колени в стороны. Спина прямая. Опускайтесь ниже параллели. Вставайте, давя пятками.",
            videoUrl: "https://www.youtube.com/results?search_query=barbell+squat+technique"
        ),
        LibraryExercise(
            name: "Фронтальные приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Штанга на передних дельтах, локти высоко. Спина вертикальна. Акцент на квадрицепсы.",
            videoUrl: "https://www.youtube.com/results?search_query=front+squat+technique"
        ),
        LibraryExercise(
            name: "Жим ногами",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Ноги на ширине плеч. Опускайте платформу до 90° в коленях. Не отрывайте поясницу от спинки! Колени не сводите внутрь.",
            videoUrl: "https://www.youtube.com/results?search_query=leg+press+technique"
        ),
        LibraryExercise(
            name: "Выпады с гантелями",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Широкий шаг. Заднее колено почти касается пола. Корпус вертикально. Угол в коленях 90°.",
            videoUrl: "https://www.youtube.com/results?search_query=dumbbell+lunges+technique"
        ),
        LibraryExercise(
            name: "Болгарские сплит-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Одна нога сзади на скамье. Приседайте на передней ноге. Корпус чуть вперед для ягодиц, прямо для квадрицепса. Адовое упражнение.",
            videoUrl: "https://www.youtube.com/results?search_query=bulgarian+split+squat+technique"
        ),
        LibraryExercise(
            name: "Румынская тяга (RDL)",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Ноги чуть согнуты. Наклон вперед за счет отведения таза назад. Гриф скользит по ногам. Спина идеально прямая. Чувствуйте растяжение бицепса бедра.",
            videoUrl: "https://www.youtube.com/results?search_query=romanian+deadlift+technique"
        ),

        LibraryExercise(
            name: "Сгибание ног в тренажере",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Лежа или сидя. Сгибайте ноги, прижимая таз к скамье. Не подбрасывайте вес инерцией.",
            videoUrl: "https://www.youtube.com/results?search_query=leg+curl+technique"
        ),
        LibraryExercise(
            name: "Разгибание ног сидя",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Сидя. Полностью разгибайте ноги, пауза в верхней точке. Изоляция квадрицепса.",
            videoUrl: "https://www.youtube.com/results?search_query=leg+extension+technique"
        ),
        LibraryExercise(
            name: "Ягодичный мост (Hip Thrust)",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Лопатки на скамье, штанга на бедрах. Поднимайте таз до полной линии тела. Пиковое сокращение ягодиц. Взгляд вперед.",
            videoUrl: "https://www.youtube.com/results?search_query=hip+thrust+technique"
        ),
        LibraryExercise(
            name: "Подъемы на носки",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Максимальная амплитуда: глубоко вниз (растяжение), высоко вверх (сокращение). Делайте паузы.",
            videoUrl: "https://www.youtube.com/results?search_query=calf+raises+technique"
        ),

        // MARK: - ПЛЕЧИ
        LibraryExercise(
            name: "Армейский жим",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Стоя. Жим штанги с груди над головой. Корпус напряжен, не прогибайтесь в пояснице. Вверху голова чуть вперед.",
            videoUrl: "https://www.youtube.com/results?search_query=overhead+press+technique"
        ),
        LibraryExercise(
            name: "Жим стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Движение штанги с груди вверх на прямые руки. Ноги на ширине плеч, колени чуть мягкие. В верхней точке руки полностью выпрямлены. Спина прямая.",
            videoUrl: "https://www.youtube.com/results?search_query=standing+military+press+technique"
        ),
        LibraryExercise(
            name: "Жим гантелей сидя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Спина прижата. Жмите гантели по дуге вверх. Локти не опускайте слишком низко (ниже параллели) для сохранения натяжения.",
            videoUrl: "https://www.youtube.com/results?search_query=seated+dumbbell+press+technique"
        ),
        LibraryExercise(
            name: "Махи гантелями в стороны",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Локти чуть согнуты. Поднимайте через стороны до параллели. 'Выливайте воду из кувшина'. Не раскачивайтесь.",
            videoUrl: "https://www.youtube.com/results?search_query=lateral+raises+technique"
        ),
        LibraryExercise(
            name: "Махи в наклоне",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Наклон корпуса вперед. Разводите руки в стороны. Локти смотрят в потолок. Работает задняя дельта.",
            videoUrl: "https://www.youtube.com/results?search_query=rear+delt+fly+technique"
        ),
        LibraryExercise(
            name: "Жим Арнольда",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт ладонями к себе. Жим с разворотом кистей. Вверху ладони вперед. Увеличивает амплитуду.",
            videoUrl: "https://www.youtube.com/results?search_query=arnold+press+technique"
        ),
        LibraryExercise(
            name: "Тяга к подбородку",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Широкий хват (комфортнее для кистей). Локти тяните вверх через стороны. Гриф до низа груди/подбородка.",
            videoUrl: "https://www.youtube.com/results?search_query=upright+row+technique"
        ),

        // MARK: - РУКИ
        LibraryExercise(
            name: "Подъем штанги на бицепс",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Стоя. Локти прижаты. Поднимайте штангу по дуге. Не читингуйте спиной. Опускайте под контролем.",
            videoUrl: "https://www.youtube.com/results?search_query=barbell+curl+technique"
        ),
        LibraryExercise(
            name: "Молотки",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Нейтральный хват. Сгибайте руки. Работает брахиалис (толщина руки) и предплечье.",
            videoUrl: "https://www.youtube.com/results?search_query=hammer+curls+technique"
        ),
        LibraryExercise(
            name: "Сгибания на скамье Скотта",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Руки зафиксированы на пюпитре. Исключает читинг. Полная изоляция бицепса.",
            videoUrl: "https://www.youtube.com/results?search_query=preacher+curl+technique"
        ),
        LibraryExercise(
            name: "Французский жим лежа",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Штанга. Сгибание рук в локтях, гриф ко лбу. Локти смотрят вверх и не гуляют в стороны.",
            videoUrl: "https://www.youtube.com/results?search_query=skullcrushers+technique"
        ),
        LibraryExercise(
            name: "Разгибание рук на блоке",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Стоя у блока. Локти прижаты к бокам. Разгибайте руки вниз. Плечи неподвижны.",
            videoUrl: "https://www.youtube.com/results?search_query=tricep+pushdown+technique"
        ),
        LibraryExercise(
            name: "Жим узким хватом",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Хват на ширине плеч. Локти скользят вдоль туловища. Основная нагрузка на трицепс.",
            videoUrl: "https://www.youtube.com/results?search_query=close+grip+bench+press+technique"
        ),

        // MARK: - КОР
        LibraryExercise(
            name: "Планка",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Упор лежа на локтях. Тело прямая струна. Пресс и ягодицы напряжены. Поясница не провисает.",
            videoUrl: "https://www.youtube.com/results?search_query=plank+technique"
        ),
        LibraryExercise(
            name: "Скручивания (Crunch)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Лежа. Отрываем только лопатки, поясница прижата. Выдох на подъеме. Скручивайтесь, а не поднимайтесь.",
            videoUrl: "https://www.youtube.com/results?search_query=crunch+technique"
        ),
        LibraryExercise(
            name: "Подъем ног в висе",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Вис на турнике. Поднимайте ноги, подкручивая таз вверх (показывайте попу зеркалу). Без раскачки.",
            videoUrl: "https://www.youtube.com/results?search_query=hanging+leg+raise+technique"
        ),
        LibraryExercise(
            name: "Русский твист",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Сидя на полу, отклонитесь назад, ноги на весу. Повороты корпуса влево-вправо. Косые мышцы.",
            videoUrl: "https://www.youtube.com/results?search_query=russian+twist+technique"
        ),

        // MARK: - НОВЫЕ СИЛОВЫЕ
        // -- Плечи --
        LibraryExercise(
            name: "Жим штанги из-за головы",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Опускайте штангу за голову до уровня ушей (не ниже, если нет гибкости). Жмите вверх. Аккуратно с плечевыми суставами!",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Протяжка (High Pull)",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Широкий хват. Тяните штангу вдоль тела к груди, поднимая локти максимально высоко в стороны.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Махи перед собой (Гантели)",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Попеременно или одновременно поднимайте гантели перед собой до уровня глаз. Не раскачивайте корпус.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Отведения руки на блоке",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Встаньте боком к блоку. Отводите руку в сторону до горизонтали. Постоянное напряжение в дельте.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Обратные разведения (Pec Deck)",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Сядьте лицом к спинке тренажера. Разводите рукояти назад. Локти на высоте плеч. Акцент на задний пучок.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим Арнольда стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Аналог жима сидя, но требует большей стабилизации корпуса. Не прогибайтесь в пояснице.",
            videoUrl: nil
        ),

        // -- Руки (Бицепс/Трицепс/Предплечья) --
        LibraryExercise(
            name: "Концентрированный подъем",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Сидя, уприте локоть во внутреннюю часть бедра. Сгибайте руку с гантелей. Полная изоляция, никакого читинга.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Молотки с канатом",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Нижний блок, канатная рукоять. Держите нейтральным хватом (ладони друг к другу). Тяните к плечам.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сгибания Зоттмана",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Поднимайте как обычный бицепс (ладони вверх), в верхней точке разворачивайте кисти (ладони вниз) и опускайте обратным хватом.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подъем штанги обратным хватом",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Хват сверху (ладони от себя). Поднимайте штангу на бицепс. Отлично развивает брахиалис и предплечья.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сгибание кистей со штангой",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Предплечья на скамье, кисти свисают. Сгибайте кисти вверх к себе. Максимальная амплитуда.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим Тейта",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Лежа с гантелями. Сгибайте руки в локтях внутрь (к груди), разводя локти в стороны. Разгибайте мощным усилием.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Разгибание руки из-за головы",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "С гантелью или на нижнем блоке. Локоть смотрит вверх. Опускайте вес за голову, растягивая трицепс.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Отжимания 'Алмаз'",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .repsOnly,
            technique: "Узкая постановка рук, указательные и большие пальцы образуют треугольник. Локти вдоль тела.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим узким хватом в Смите",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Локти прижаты к туловищу. Гриф опускается на низ груди. Изолированная работа трицепса и безопасно для баланса.",
            videoUrl: nil
        ),

        // -- Спина --
        LibraryExercise(
            name: "Тяга штанги обратным хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Как обычная тяга в наклоне, но хват ладонями от себя. Больше включает бицепс и низ широчайших.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Тяга одной рукой в упоре",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Упор рукой и коленом в скамью. Спина параллельно полу. Тяните гантель к тазу, максимально поднимая локоть.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Пуловер в блоке (Прямые руки)",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Стоя у верхнего блока. Прямыми (чуть согнутыми) руками опускайте рукоять к бедрам по дуге. Изоляция широчайших.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Шраги с гантелями",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Стоя с тяжелыми гантелями. Поднимайте плечи строго вверх к ушам. Задержитесь на секунду. Не вращайте плечами!",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Рычажная тяга (Hammer)",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Тяга в тренажере сидя. Грудь прижата к подушке. Тяните локти назад, сводя лопатки. Работает толщина спины.",
            videoUrl: nil
        ),

        // -- Грудь --
        LibraryExercise(
            name: "Жим Смита на наклонной",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Скамья 30-45 градусов. Опускайте гриф на ключицы. Смит дает изоляцию и безопасность.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сведения в кроссовере лежа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Лежа на скамье между блоками. Сводите рукояти над грудью, как при разводке гантелей, но с постоянным натяжением тросов.",
            videoUrl: nil
        ),

        // -- Ноги --
        LibraryExercise(
            name: "Гакк-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "В тренажере. Спина прижата. Приседайте глубоко. Отличное упражнение, снимающее нагрузку с поясницы.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сумо-тяга",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Широкая постановка ног, носки врозь. Хват узкий. Спина вертикальнее, чем в классике. Больше работают ноги и ягодицы.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Гоблет-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Держите гирю или гантель у груди. Приседайте, разводя колени. Учитесь держать спину прямо.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Приседания 'Пистолетик'",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Приседание на одной ноге, вторая выпрямлена вперед. Требует отличного баланса и силы ног.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Зашагивания на скамью",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "С гантелями в руках. Шагайте на возвышение всей стопой. Вставайте за счет ноги на скамье, не отталкивайтесь нижней.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Разведение ног (Тренажер)",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Сидя. Разводите ноги в стороны, задерживаясь в пиковой точке. Прорабатывает среднюю ягодичную.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сведение ног (Тренажер)",
            category: .legs,
            muscleGroup: .hamstrings, // Adductors actually
            defaultType: .strength,
            technique: "Сидя. Сводите ноги вместе. Работает внутренняя поверхность бедра (аддукторы).",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подъем на носки сидя",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Тренажер или штанга на коленях. Поднимайте пятки максимально высоко. Работает камбаловидная мышца.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Статика у стены (Стульчик)",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Прижмитесь спиной к стене и присядьте до угла 90 градусов. Держите позицию до отказа. Жжение гарантировано.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Тяга сумо с гирей",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Гиря между ног. Широкая стойка. Садитесь глубоко и вставайте, сжимая ягодицы наверху.",
            videoUrl: nil
        ),

        // -- Кор --
        LibraryExercise(
            name: "Колесо для пресса",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "С колен катите ролик вперед, растягиваясь почти до пола. Спину держите округлой, не прогибайтесь в пояснице!",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Вакуум",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Стоя или в наклоне. Сделайте полный выдох и втяните живот под ребра. Держите сколько сможете (15-30 сек).",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Молитва (Блок)",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Стоя на коленях у верхнего блока. Скручивайтесь вниз, прижимая рукоять к голове. Работайте прессом, не бедрами.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Уголок (L-Sit)",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "На брусьях или полу. Поднимите прямые ноги до угла 90 градусов и удерживайте. Стальной пресс обеспечен.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Складочка (V-Ups)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Лежа на спине. Одновременно поднимайте прямые руки и ноги, касаясь пальцами стоп в верхней точке.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Велосипед",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Лежа на спине, руки за головой. Поочередно тяните локоть к противоположному колену. Имитация педалирования.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подъем ног лежа",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Руки под ягодицы. Поднимайте прямые ноги до угла 90 градусов. Опускайте плавно, не касаясь пола.",
            videoUrl: nil
        ),

        // MARK: - КАРДИО & ЭНДУРАНС
        LibraryExercise(
            name: "Берпи",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Из положения стоя присядьте, упритесь руками в пол. Прыжком перейдите в упор лежа, отожмитесь, коснувшись грудью пола. Прыжком верните ноги к рукам и выпрыгните вверх с хлопком над головой. Держите темп.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Скакалка",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Держите локти ближе к корпусу, вращайте скакалку только кистями. Прыгайте на носках мягко, амортизируя коленями. Взгляд перед собой.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Бег (Интервалы)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Чередование периодов максимального ускорения (спринт) и активного отдыха (легкий бег или ходьба). Например: 30 сек спринт / 30 сек отдых. Эффективно для жиросжигания.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Гребля (Concept2)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Мощный толчок ногами, затем отклонение корпуса назад и тяга рук к солнечному сплетению. Возврат: выпрямить руки, корпус вперед, согнуть ноги. Спина прямая.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Байк (Assault Bike)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Работайте руками и ногами одновременно. Чем выше скорость, тем выше сопротивление. Следите за тем, чтобы колени не 'гуляли' в стороны.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Лыжный тренажер (SkiErg)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Имитация лыжного хода. Мощный мах руками вниз с одновременным подседом. Включайте пресс и широчайшие. Не работают только руки!",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Двойные прыжки на скакалке",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Высокий прыжок на носках, два оборота скакалки за один прыжок. Требует быстрой работы кистей и тайминга.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Заныривания на коробку (Box Jumps)",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Встаньте перед тумбой. Сделайте замах руками и запрыгните наверх, полностью выпрямив таз в верхней точке. Спускайтесь шагом, чтобы сберечь ахиллы.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Альпинист (Скалолаз)",
            category: .cardio,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Упор лежа. Поочередно подтягивайте колени к груди в быстром темпе, имитируя бег. Таз не задирайте. Пресс напряжен.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Джампинг Джек",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Прыжки 'звездочка'. Ноги врозь - хлопок над головой, ноги вместе - руки по швам. Держите легкий темп на носках.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Бег трусцой",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Равномерный бег в комфортном темпе. Пульс 120-140 ударов. Отлично для разминки или заминки.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Эллипсоид",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Кардио без ударной нагрузки на суставы. Держите спину прямо, работайте руками в такт ногам.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Степпер",
            category: .cardio,
            muscleGroup: .glutes,
            defaultType: .duration,
            technique: "Имитация ходьбы по лестнице. Не опирайтесь всем весом на поручни! Давите пяткой.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Бокс (Груша)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Работа по мешку. Держите стойку, руки у подбородка. Вкладывайте корпус в удар. Двигайтесь вокруг снаряда.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Ходьба в гору",
            category: .cardio,
            muscleGroup: .glutes,
            defaultType: .duration,
            technique: "Беговая дорожка с уклоном 10-15%. Быстрая ходьба без бега. Мощно прорабатывает заднюю поверхность бедра.",
            videoUrl: nil
        ),
        // -- Плечи --
        LibraryExercise(
            name: "Жим штанги из-за головы",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Опускайте штангу за голову до уровня ушей (не ниже, если нет гибкости). Жмите вверх. Аккуратно с плечевыми суставами!",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Протяжка (High Pull)",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Широкий хват. Тяните штангу вдоль тела к груди, поднимая локти максимально высоко в стороны.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Махи перед собой (Гантели)",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Попеременно или одновременно поднимайте гантели перед собой до уровня глаз. Не раскачивайте корпус.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Отведения руки на блоке",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Встаньте боком к блоку. Отводите руку в сторону до горизонтали. Постоянное напряжение в дельте.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Обратные разведения (Pec Deck)",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Сядьте лицом к спинке тренажера. Разводите рукояти назад. Локти на высоте плеч. Акцент на задний пучок.",
            videoUrl: nil
        ),

        // -- Руки (Бицепс/Трицепс) --
        LibraryExercise(
            name: "Концентрированный подъем",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Сидя, уприте локоть во внутреннюю часть бедра. Сгибайте руку с гантелей. Полная изоляция, никакого читинга.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Молотки с канатом",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Нижний блок, канатная рукоять. Держите нейтральным хватом (ладони друг к другу). Тяните к плечам.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сгибания Зоттмана",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Поднимайте как обычный бицепс (ладони вверх), в верхней точке разворачивайте кисти (ладони вниз) и опускайте обратным хватом.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим Тейта",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Лежа с гантелями. Сгибайте руки в локтях внутрь (к груди), разводя локти в стороны. Разгибайте мощным усилием.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Разгибание руки из-за головы",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "С гантелью или на нижнем блоке. Локоть смотрит вверх. Опускайте вес за голову, растягивая трицепс.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Отжимания 'Алмаз'",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .repsOnly,
            technique: "Узкая постановка рук, указательные и большие пальцы образуют треугольник. Локти вдоль тела.",
            videoUrl: nil
        ),

        // -- Спина --
        LibraryExercise(
            name: "Тяга штанги обратным хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Как обычная тяга в наклоне, но хват ладонями от себя. Больше включает бицепс и низ широчайших.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Тяга одной рукой в упоре",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Упор рукой и коленом в скамью. Спина параллельно полу. Тяните гантель к тазу, максимально поднимая локоть.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Пуловер в блоке (Прямые руки)",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Стоя у верхнего блока. Прямыми (чуть согнутыми) руками опускайте рукоять к бедрам по дуге. Изоляция широчайших.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Шраги с гантелями",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Стоя с тяжелыми гантелями. Поднимайте плечи строго вверх к ушам. Задержитесь на секунду. Не вращайте плечами!",
            videoUrl: nil
        ),
        
        // -- Ноги --
        LibraryExercise(
            name: "Гакк-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "В тренажере. Спина прижата. Приседайте глубоко. Отличное упражнение, снимающее нагрузку с поясницы.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сумо-тяга",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Широкая постановка ног, носки врозь. Хват узкий. Спина вертикальнее, чем в классике. Больше работают ноги и ягодицы.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Гоблет-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Держите гирю или гантель у груди. Приседайте, разводя колени. Учитесь держать спину прямо.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Приседания 'Пистолетик'",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Приседание на одной ноге, вторая выпрямлена вперед. Требует отличного баланса и силы ног.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Зашагивания на скамью",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "С гантелями в руках. Шагайте на возвышение всей стопой. Вставайте за счет ноги на скамье, не отталкивайтесь нижней.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Разведение ног (Тренажер)",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Сидя. Разводите ноги в стороны, задерживаясь в пиковой точке. Прорабатывает среднюю ягодичную.",
            videoUrl: nil
        ),

        // -- Кор --
        LibraryExercise(
            name: "Колесо для пресса",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "С колен катите ролик вперед, растягиваясь почти до пола. Спину держите округлой, не прогибайтесь в пояснице!",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Вакуум",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Стоя или в наклоне. Сделайте полный выдох и втяните живот под ребра. Держите сколько сможете (15-30 сек).",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Молитва (Блок)",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Стоя на коленях у верхнего блока. Скручивайтесь вниз, прижимая рукоять к голове. Работайте прессом, не бедрами.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Уголок (L-Sit)",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "На брусьях или полу. Поднимите прямые ноги до угла 90 градусов и удерживайте. Стальной пресс обеспечен.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Берпи",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Из положения стоя присядьте, упритесь руками в пол. Прыжком перейдите в упор лежа, отожмитесь, коснувшись грудью пола. Прыжком верните ноги к рукам и выпрыгните вверх с хлопком над головой. Держите темп.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Скакалка",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Держите локти ближе к корпусу, вращайте скакалку только кистями. Прыгайте на носках мягко, амортизируя коленями. Взгляд перед собой.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Бег (Интервалы)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Чередование периодов максимального ускорения (спринт) и активного отдыха (легкий бег или ходьба). Например: 30 сек спринт / 30 сек отдых. Эффективно для жиросжигания.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Гребля (Concept2)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Мощный толчок ногами, затем отклонение корпуса назад и тяга рук к солнечному сплетению. Возврат: выпрямить руки, корпус вперед, согнуть ноги. Спина прямая.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Байк (Assault Bike)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Работайте руками и ногами одновременно. Чем выше скорость, тем выше сопротивление. Следите за тем, чтобы колени не 'гуляли' в стороны.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Лыжный тренажер (SkiErg)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Имитация лыжного хода. Мощный мах руками вниз с одновременным подседом. Включайте пресс и широчайшие. Не работают только руки!",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Двойные прыжки на скакалке",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Высокий прыжок на носках, два оборота скакалки за один прыжок. Требует быстрой работы кистей и тайминга.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Заныривания на коробку (Box Jumps)",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Встаньте перед тумбой. Сделайте замах руками и запрыгните наверх, полностью выпрямив таз в верхней точке. Спускайтесь шагом, чтобы сберечь ахиллы.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Альпинист (Скалолаз)",
            category: .cardio,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Упор лежа. Поочередно подтягивайте колени к груди в быстром темпе, имитируя бег. Таз не задирайте. Пресс напряжен.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Джампинг Джек",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Прыжки 'звездочка'. Ноги врозь - хлопок над головой, ноги вместе - руки по швам. Держите легкий темп на носках.",
            videoUrl: nil
        ),

        // MARK: - КОМПЛЕКСНЫЕ (Тяжелая атлетика / Crossfit)
        LibraryExercise(
            name: "Становая тяга (Классика)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Штанга над серединой стопы. Хват чуть шире плеч. Спина прямая, плечи над грифом. Мощным движением ног оторвите штангу, выпрямляясь в тазу. Гриф скользит по ногам.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Рывок штанги (Snatch)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Широкий хват. Мощный подрыв штанги с пола за счет ног и спины, полное выпрямление ('тройное разгибание') и уход в глубокий сед, принимая штангу над головой. Требует гибкости плеч.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Взятие штанги на грудь (Clean)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Хват на ширине плеч. Подрыв штанги вверх, быстрый 'подворот' локтей вперед и прием штанги на передние дельты в седе или полу-седе. Локти смотрят вперед.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Трастеры (Thrusters)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Комбинация фронтального приседа и жима (швунга). Штанга на груди, глубокий сед. На вставании мощно вытолкните штангу над головой единым движением.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Махи гирей (Русские)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Мах гирей до уровня глаз за счет мощного разгибания таза. Спина прямая, не приседайте глубоко, работайте бедрами (hip hinge).",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Махи гирей (Американские)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Мах гирей в полную амплитуду над головой. Следите, чтобы поясница не прогибалась в верхней точке. Дно гири смотрит в потолок.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Кластеры (Clusters)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Взятие штанги на грудь в полный сед + Трастер. Каждый повтор начинается с пола. Одно из самых энергоемких упражнений.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Броски мяча (Wall Balls)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Глубокий присед с медболом у груди. На вставании мощный бросок мяча в мишень/стену. Ловите мяч, амортизируя ногами сразу в следующий присед.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Толчок штанги (Jerk)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Штанга на груди. Короткий подсед и выталкивание штанги вверх с одновременным уходом под нее (в ножницы или стойку). Руки выпрямляются мгновенно.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Рывок гири",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Подрыв гири с пола одной рукой и уход под нее. Гиря описывает дугу и мягко ложится на предплечье наверху. Спина прямая.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Прогулка фермера",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Возьмите тяжелые гантели или снаряды в руки. Идите мелкими шагами, корпус напряжен, плечи расправлены. Адский хват и стабилизация.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Турецкий подъем",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Подъем из положения лежа в положение стоя, удерживая гирю/гантель на вытянутой руке над головой. Требует поэтапного контроля каждого движения.",
            videoUrl: nil
        ),
        
        // MARK: - НОВЫЕ / ДОПОЛНИТЕЛЬНЫЕ
        LibraryExercise(
            name: "Шраги со штангой",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Поднимайте плечи к ушам. Руки прямые. Не вращайте плечами, только вверх-вниз.",
            videoUrl: "https://www.youtube.com/results?search_query=barbell+shrugs+technique"
        ),
        LibraryExercise(
            name: "Обратная бабочка",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Тренажер Pec-Deck. Сядьте лицом к спинке. Отводите руки назад до линии плеч. Локти чуть согнуты. Включает задние дельты.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подъем ног в упоре",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Упор локтями в брусья (станок). Поднимайте прямые или согнутые ноги к груди, подкручивая таз.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Гиперэкстензия (Обратная)",
            category: .back,
            muscleGroup: .glutes,
            defaultType: .repsOnly,
            technique: "Лежа животом на скамье, ноги свисают. Поднимайте прямые ноги вверх до горизонтали, сжимая ягодицы.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим Свенда",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Стоя, сжимаем блины или гантель перед собой на уровне груди ладонями. Выпрямляем руки вперед, постоянно сдавливая снаряд.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сгибание паука",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Лежа животом на наклонной скамье. Руки свисают вертикально вниз. Сгибание на бицепс, исключая помощь корпуса.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Разгибание из-за головы на блоке",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Нижний блок с канатом. Стоя спиной к блоку, тянем канат из-за головы вверх. Локти зафиксированы у ушей.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Тяга Кинга (King Deadlift)",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Стоя на одной ноге без веса. Приседайте, пытаясь коснуться коленом свободной ноги пола. Сложнейшая координация.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Боковые выпады",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Широкая стойка. Перенос веса на одну ногу, сгибая ее в колене. Вторая нога прямая. Спина ровная.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подъем таза на мяче",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .repsOnly,
            technique: "Лежа на спине, пятки на фитболе. Поднимаем таз и подкатываем мяч к себе, сгибая колени. Жжет бицепс бедра.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Медвежья проходка",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "На четвереньках, колени не касаются пола. Двигаемся вперед-назад разноименными конечностями. Спина параллельно полу.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Прыжки на скакалке (Крест-накрест)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Базовые прыжки с перекрещиванием рук перед собой. Развивает координацию и ловкость.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Выпрыгивания из приседа",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Полный присед и максимальное выпрыгивание вверх. Руки помогают инерцией. Мягкое приземление.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Отжимания с хлопком",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Взрывное отжимание, в верхней точке делаем хлопок руками. Требует скорости и силы.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подтягивания (Австралийские)",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Вис на низкой перекладине (или кольцах), тело под углом, пятки на полу. Тянемся грудью к перекладине.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Тяга Пендли",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Тяга штанги в наклоне, но каждый повтор начинается с 'мертвой точки' (с пола). Спина строго параллельна.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим Армейский сидя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Сидя в раме или на скамье. Жим штанги с груди. Исключает помощь ног.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Махи рукой лежа на боку",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Лежа на боку на скамье. Верхней рукой машем гантель вверх. Изоляция задней дельты.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сгибание запястий (За спиной)",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Штанга за спиной в опущенных руках. Сгибаем кисти вверх. Качает предплечья.",
            videoUrl: nil
        ),
        
        // -- Растяжка / МФР (Бонус) --
        LibraryExercise(
            name: "Ролл спины (МФР)",
            category: .core,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Прокатка спины на массажном роллере. Расслабляет фасции, снимает напряжение.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Отжимания узким хватом",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .repsOnly,
            technique: "Ладони близко друг к другу (ромбик). Локти вдоль тела. Акцент на трицепс.",
            videoUrl: "https://www.youtube.com/results?search_query=diamond+pushups+technique"
        ),
        LibraryExercise(
            name: "Обратные отжимания от скамьи",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .repsOnly,
            technique: "Руки сзади на скамье. Опускайте таз вниз, сгибая руки. Не уводите таз далеко от скамьи.",
            videoUrl: "https://www.youtube.com/results?search_query=bench+dips+technique"
        ),
        LibraryExercise(
            name: "Планка боковая",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            videoUrl: "https://www.youtube.com/results?search_query=side+plank+technique"
        ),
        
        // MARK: - ADDED MISSING EXERCISES FROM PROGRAMS
        
        // Shoulders - Плечи
        LibraryExercise(
            name: "Жим гантелей стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Встаньте прямо, ноги на ширине плеч. Гантели на уровне плеч, локти под 90°. На выдохе выжмите вверх, полностью выпрямляя руки. Напрягайте кор для стабилизации. опускайте медленно и подконтрольно.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим штанги стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Армейский жим. Штанга на уровне плеч, хват чуть шире плеч. Выжмите вверх, фиксируя корпус. Локти чуть вперед, не разводите wide.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим из-за головы",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Опускайте штангу за голову до уровня ушей. Жмите вверх, акцентируя средние дельты. Требует хорошей подвижности плеч.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим швунг",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Жим штанги с небольшим подседом. Используйте импульс ног для мощного выжима штанги вверх. Полезно для развития скоростно-силовых качеств.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Махи сидя",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Сидя, поднимайте гантели в стороны до уровня плеч. Локти чуть согнуты, ведите движение локтями. Исключает читинг корпусом.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Махи в стороны",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Стоя, поднимайте гантели в стороны до параллели с полом. Запястья чуть ниже локтей. Не раскачивайтесь.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Махи на блоке",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Тяните рукоять нижнего блока в сторону через тело. Постоянное натяжение троса обеспечивает качественную проработку.",
            videoUrl: nil
        ),
        
        // Back - Спина
        LibraryExercise(
            name: "Лицевая тяга",
            category: .back,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Канат на верхнем блоке. Тяните к лицу, разводя локти в стороны выше плеч. В конце ладони за уровнем лица. Сводите лопатки. Акцент на задние дельты и ротаторы плеча.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Обратные разведения",
            category: .back,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Наклон вперед, разводите руки в стороны. Акцент на задние дельты. Локти слегка согнуты.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Тяга блока узким хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Узкая V-рукоять. Тяните к низу живота, максимально сводя лопатки. Акцент на толщину спины.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Тяга одной рукой",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Одной рукой тяните гантель к поясу, другой упирайтесь в скамью. Сводите лопатку, чувствуя широчайшую.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подтягивания обратным хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Ладони к себе. Больше задействует бицепс и низ широчайших. Подбородок выше перекладины.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подтягивания с весом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Дополнительный вес на поясе или в жилете. Подтягивайтесь подбородком выше перекладины, сводя лопатки.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подтягивания (Heavy)",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Силовые подтягивания с большим весом. Малое количество повторений (3-5).",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Австралийские подтягивания",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Низкая перекладина, ноги на полу. Подтягивайтесь грудью к грифу. Хороший вариант для начинающих.",
            videoUrl: nil
        ),
        
        // Legs - Ноги
        LibraryExercise(
            name: "Румынская тяга",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Колени слегка согнуты. Наклоняйтесь вперед, отводя таз назад. Штанга скользит вдоль ног. Опускайте до середины голени, чувствуя растяжение бицепса бедра. Спина прямая!",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Румынская тяга гантели",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Вариант с гантелями. Позволяет больший диапазон движения. Техника как с штангой - таз назад, спина прямая.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Болгарские выпады",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Задняя нога на скамье. Опускайтесь до параллели переднего бедра с полом. Колено не выходит за носок. Мощный акцент на квадрицепс и ягодицы.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Выпады",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Шаг вперед, опуститесь до параллели. Колено не выходит за носок. Отталкивайтесь передней ногой.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Выпады назад",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Шаг назад. Опуститесь, отталкивайтесь назад. Меньше нагрузки на колени, чем при выпадах вперед.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сгибание ног лежа",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Лежа на животе, сгибайте ноги, подтягивая валик к ягодицам. Изолированная работа бицепса бедра.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сгибание ног сидя",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Сидя, сгибайте ноги под собой. Другой вариант изоляции бицепса бедра.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Разгибание ног",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Сидя, разгибайте ноги в коленях. Изоляция квадрицепса. Контролируемое опускание веса.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подъем на носки",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Поднимайтесь на носки максимально высоко. Задержитесь в верхней точке. Опускайтесь медленно. Для икроножных мышц.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Ягодичный мост",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Лежа на спине, стопы на полу. Поднимите таз вверх, максимально сжимая ягодицы. Задержитесь наверху.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Классические приседания. Спина прямая, приседайте до параллели или ниже. Колени по направлению носков.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Приседания (5/3/1)",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Приседания в рамках программы 5/3/1 Джима Вендлера. Силовой вариант с прогрессией.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Приседания Low bar",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Штанга ниже на спине. Больший наклон корпуса, больше работы ягодиц и бицепса бедра.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Приседания Пистолетик",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Приседание на одной ноге. Требует баланса и силы. Свободная нога выпрямлена вперед.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Присед на спине",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Классический присед со штангой на спине. Базовое упражнение для ног.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Присед (Т1 5×3)",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Приседания как основное (Tier 1) упражение. 5 подходов по 3 повторения с тяжелым весом.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Фронтальный присед",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Штанга спереди на плечах. Больше нагрузки на квадрицепс. Корпус более вертикален.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Гоблет присед",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Приседания с гантелью/гирей у груди. Учит правильной технике. Подходит для начинающих.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Гоблет приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Синоним гоблет приседа. Гантель у груди, приседайте глубоко.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Становая тяга",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Базовое упражнение. Спина прямая, тяните штангу вдоль ног. Разгибайте бедра и спину одновременно.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Становая тяга (5/3/1)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Становая в рамках 5/3/1. Силовая прогрессия.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Становая (Т2)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Становая как дополнительное (Tier 2) упражнение. Средние веса, больше повторений.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Становая сумо",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Широкая постановка ног, носки развернуты. Больше работы приводящих и ягодиц.",
            videoUrl: nil
        ),
        
        // Chest - Грудь
        LibraryExercise(
            name: "Жим лежа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Классический жим штанги лежа. Опускайте на грудь, выжмите вверх. Лопатки сведены.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим лежа (5/3/1)",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Жим лежа в программе 5/3/1. Силовая прогрессия.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим лежа (Силовой)",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Тяжелый жим с малым количеством повторений (1-5).",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим лежа (Т2 3×10)",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Жим как вспомогательное упражнение. 3 подхода по 10 повторений.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим гантелей на наклонной",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Скамья 30-45°. Жмите гантели вверх, сводя в верхней точке. Акцент на верх груди.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим Смита",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Жим в тренажере Смита. Фиксированная траектория. Безопаснее для работы без страхующего.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сведение рук",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Сведение гантелей или на тренажере. Изолирует грудные мышцы. Локти слегка согнуты.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сведения (Flyes)",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Разведения/сведения гантелей. Растягивает и сокращает грудные. Чувствуйте stretch.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Разведения (Т3)",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Разведения как изолирующее (Tier 3) упражнение. 3×15-20 повторений.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Пуловер",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Лежа, гантель за головой. Поднимайте над грудью прямыми руками. Растягивает грудные и широчайшие.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Отжимания",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Классические отжимания от пола. Тело - прямая линия, опускайтесь до касания грудью пола.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Отжимания на брусьях (с весом)",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .repsOnly,
            technique: "Отжимания с дополнительным весом. Наклон вперед для акцента на грудь.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Отжимания от перекладины",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Отжимания с руками на перекладине. Увеличенная амплитуда.",
            videoUrl: nil
        ),
        
        // Arms - Руки
        LibraryExercise(
            name: "Bayesian Curl",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Спиной к блоку, рука позади тела. Сгибайте руку на себя, максимально нагружая бицепс в растянутом положении. Наклоняйтесь вперед для пикового сокращения.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Молотки на бицепс",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Сгибайте руки с гантелями, большие пальцы вверх (молотковый хват). Акцент на бицепс и плечевую мышцу.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Сгибание Паук",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Spider curl. Живот на скамье, руки вниз. Сгибайте, локти неподвижны. Полная изоляция бицепса.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Разгибание на трицепс",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Разгибания на блоке или с гантелями. Локти зафиксированы, работает только трицепс.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Бицепс + Трицепс",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Суперсет бицепс + трицепс. Чередуйте упражнения на антагонисты без отдыха.",
            videoUrl: nil
        ),
        
        // Core
        LibraryExercise(
            name: "Подъем ног к перекладине (Toes to Bar)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "В висе поднимайте носки к перекладине. Контролируйте раскачку. Мощная работа пресса.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Уголок (L-sit) на брусьях",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "На брусьях держите ноги параллельно полу (уголок). Статическое удержание. Сильный пресс!",
            videoUrl: nil
        ),
        
        // Complex
        LibraryExercise(
            name: "Взятие на грудь",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Power clean. Взрывным движением поднимите штангу на грудь. Техничное упражнение для всего тела.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Выход силой на две руки",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Muscle up. Подтягивание с переходом в отжиманиеon верхом перекладины. Требует силы и техники.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Махи гирей",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Kettlebell swing. Махи гирей между ног и до уровня груди. Взрывная работа бедер и ягодиц.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Армейский жим (5/3/1)",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Армейский жим в рамках 5/3/1. Силовая прогрессия.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Армейский жим (Т1)",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Жим стоя как основное упражнение. Тяжелые веса, малые повторения.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подсобка",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Вспомогательные упражнения для укрепления слабых мест. Подбираются индивидуально.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Подсобка (50 reps)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Подсобные упражнения на 50 повторений. Большой объем для восстановления и гипертрофии.",
            videoUrl: nil
        ),
        
        // Cardio
        LibraryExercise(
            name: "Бег (Интервалы: 30/30, 45/45, 60/60)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Интервальный бег. Чередуйте спринт и восстановление по указанным интервалам.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Эллипс (40-60 мин, зона 2)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Низкоинтенсивное кардио в зоне 2 (60-70% от макс. пульса). Жиросжигание и восстановление.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Степпер (Шаг через ступеньку, Перекрестный шаг)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Варианты шагов на степпере для разнообразия и проработки мышц под разными углами.",
            videoUrl: nil
        ),
        
        // Back variations
        LibraryExercise(
            name: "Тяга TRX/Блока",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Горизонтальные тяги на TRX петлях или блоке. Сводите лопатки, тяните к груди.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Тяга блока (Т3 3×15)",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Тяга блока как изолирующее упражнение. 3 подхода по 15 повторений.",
            videoUrl: nil
        )
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
    
    // MARK: - Helper Methods
    
    /// Получение полного объекта упражнения
    static func getExercise(for name: String) -> LibraryExercise? {
        // 1. Точное совпадение
        if let exactMatch = allExercises.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return exactMatch
        }
        
        // 2. Очистка имени (удаляем все в скобках)
        let cleanName = name.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? name
        if let cleanMatch = allExercises.first(where: { $0.name.caseInsensitiveCompare(cleanName) == .orderedSame }) {
            return cleanMatch
        }
        
        // 3. Fallback: Содержит подстроку
        return allExercises.first(where: { name.localizedCaseInsensitiveContains($0.name) || $0.name.localizedCaseInsensitiveContains(name) })
    }
    
    /// Получение техники выполнения по названию (с нечетким поиском)
    static func getTechnique(for name: String) -> String? {
        getExercise(for: name)?.technique
    }
    
    /// Получение дефолтного типа тренировки для упражнения
    static func getDefaultType(for name: String) -> WorkoutType {
        getExercise(for: name)?.defaultType ?? .strength
    }
    
    /// Получение ссылки на видео
    static func getVideoUrl(for name: String) -> String? {
        getExercise(for: name)?.videoUrl
    }
    
    /// Миграция существующих упражнений для установки правильного типа
    static func migrateExerciseTypes(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ExerciseTemplate>()
            let templates = try context.fetch(descriptor)
            
            var migratedCount = 0
            for template in templates {
                // Устанавливаем тип если он не был явно задан
                if template._customWorkoutType == nil {
                    let defaultType = getDefaultType(for: template.name)
                    template._customWorkoutType = defaultType
                    migratedCount += 1
                }
            }
            
            if migratedCount > 0 {
                try context.save()
                #if DEBUG
                print("Migrated \(migratedCount) exercises to correct workout types")
                #endif
            }
        } catch {
            #if DEBUG
            print("Failed to migrate exercise types: \(error)")
            #endif
        }
    }
}


extension ExerciseCategory {
    // Adding Full Body case alias if needed or rely on existing complex
    static var fullBody: ExerciseCategory { .complex }
}
