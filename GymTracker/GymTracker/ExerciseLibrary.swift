//
//  ExerciseLibrary.swift
//  GymTracker
//
//  Created by Antigravity
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Exercise Categories

enum ExerciseCategory: CaseIterable, Identifiable {
    case chest
    case back
    case legs
    case shoulders
    case arms
    case core
    case cardio
    case complex
    case custom

    var id: String { rawValue }

    var rawValue: String {
        switch self {
        case .chest: return "Грудь".localized()
        case .back: return "Спина".localized()
        case .legs: return "Ноги".localized()
        case .shoulders: return "Плечи".localized()
        case .arms: return "Руки".localized()
        case .core: return "Кор".localized()
        case .cardio: return "Кардио".localized()
        case .complex: return "Комплексные".localized()
        case .custom: return "Пользовательские упражнения".localized()
        }
    }

    var icon: String {
        switch self {
        case .chest:     return "figure.arms.open"
        case .back:      return "figure.rower"
        case .legs:      return "figure.run"
        case .shoulders: return "figure.archery"
        case .arms:      return "dumbbell.fill"
        case .core:      return "figure.core.training"
        case .cardio:    return "heart.fill"
        case .complex:   return "figure.cross.training"
        case .custom:    return "person.fill"
        }
    }

    /// Primary brand color per category — used to add visual identity to lists/cards.
    var accentColor: Color {
        switch self {
        case .chest:     return Color(red: 1.00, green: 0.42, blue: 0.42) // coral
        case .back:      return Color(red: 0.30, green: 0.59, blue: 1.00) // sky blue
        case .legs:      return Color(red: 0.65, green: 0.43, blue: 0.95) // purple
        case .shoulders: return Color(red: 1.00, green: 0.66, blue: 0.30) // orange
        case .arms:      return Color(red: 0.31, green: 0.80, blue: 0.77) // teal
        case .core:      return Color(red: 1.00, green: 0.83, blue: 0.24) // amber
        case .cardio:    return Color(red: 1.00, green: 0.42, blue: 0.72) // pink
        case .complex:   return Color(red: 0.42, green: 0.83, blue: 0.50) // mint green
        case .custom:    return Color(red: 0.75, green: 1.00, blue: 0.00) // neon (brand)
        }
    }

    /// Secondary color used to build a vibrant gradient on category headers.
    var accentColorSecondary: Color {
        switch self {
        case .chest:     return Color(red: 1.00, green: 0.27, blue: 0.55)
        case .back:      return Color(red: 0.20, green: 0.83, blue: 1.00)
        case .legs:      return Color(red: 0.45, green: 0.30, blue: 1.00)
        case .shoulders: return Color(red: 1.00, green: 0.45, blue: 0.20)
        case .arms:      return Color(red: 0.20, green: 0.95, blue: 0.65)
        case .core:      return Color(red: 1.00, green: 0.60, blue: 0.10)
        case .cardio:    return Color(red: 1.00, green: 0.30, blue: 0.45)
        case .complex:   return Color(red: 0.20, green: 0.95, blue: 0.55)
        case .custom:    return Color(red: 0.55, green: 0.95, blue: 0.20)
        }
    }
}

enum MuscleGroup: CaseIterable {
    // Грудь
    case upperChest
    case middleChest
    case lowerChest

    // Спина
    case lats
    case trapezius
    case lowerBack
    case rearDelts

    // Ноги
    case quadriceps
    case hamstrings
    case glutes
    case calves

    // Плечи
    case frontDelts
    case sideDelts

    // Руки
    case biceps
    case triceps
    case forearms

    // Кор и полное тело
    case core
    case fullBody

    var rawValue: String {
        switch self {
        case .upperChest: return "Верх груди".localized()
        case .middleChest: return "Середина груди".localized()
        case .lowerChest: return "Низ груди".localized()
        case .lats: return "Широчайшие".localized()
        case .trapezius: return "Трапеции".localized()
        case .lowerBack: return "Поясница".localized()
        case .rearDelts: return "Задние дельты".localized()
        case .quadriceps: return "Квадрицепсы".localized()
        case .hamstrings: return "Бицепс бедра".localized()
        case .glutes: return "Ягодицы".localized()
        case .calves: return "Икры".localized()
        case .frontDelts: return "Передние дельты".localized()
        case .sideDelts: return "Средние дельты".localized()
        case .biceps: return "Бицепс".localized()
        case .triceps: return "Трицепс".localized()
        case .forearms: return "Предплечья".localized()
        case .core: return "Кор".localized()
        case .fullBody: return "Все тело".localized()
        }
    }
}

// MARK: - Library Exercise

struct LibraryExercise: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let muscleGroup: MuscleGroup
    let defaultType: WorkoutType
    let technique: String?
    let videoUrl: String?

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

// MARK: - Helper for YouTube search URLs

private func ytSearch(_ query: String) -> String {
    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
    return "https://www.youtube.com/results?search_query=\(encoded)"
}

// MARK: - Exercise Library

struct ExerciseLibrary {
    nonisolated static let allExercises: [LibraryExercise] = [

        // MARK: - ГРУДЬ

        LibraryExercise(
            name: "Жим штанги лежа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: лягте на скамью, лопатки сведены и опущены, грудь приподнята, ноги жёстко в пол. Хват чуть шире плеч, гриф над глазами.\n\nДвижение: опустите штангу на нижнюю часть груди (область сосков), локти под углом 45–60° к корпусу. Без отбива от груди мощно выжмите вверх по чуть J-образной траектории.\n\nКлючи: лопатки прижаты весь подход, кисти прямые (не загибайте назад). Без отрыва таза. Дыхание: вдох на опускании, выдох на жиме.",
            videoUrl: ytSearch("жим штанги лёжа техника")
        ),
        LibraryExercise(
            name: "Жим штанги на наклонной скамье",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: угол скамьи 30°. Хват чуть шире плеч, лопатки сведены, ягодицы прижаты.\n\nДвижение: опускайте штангу на верх груди (под ключицы), локти разводите на 45°. Жмите вверх без переразгибания локтей.\n\nКлючи: 30° оптимально для верха груди — выше угол смещает нагрузку в дельты. Не прогибайте поясницу до горизонтали.",
            videoUrl: ytSearch("incline barbell bench press technique")
        ),
        LibraryExercise(
            name: "Жим штанги на скамье с обратным наклоном",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Старт: скамья наклонена вниз на 15–30°, ноги зафиксированы валиками. Хват шире плеч.\n\nДвижение: опускайте штангу на нижний край груди, локти под 45°. Выжмите без замыкания локтей.\n\nКлючи: акцентирует нижнюю часть груди и снимает нагрузку с дельт. Используйте страховку — встать со штангой здесь сложнее.",
            videoUrl: ytSearch("decline barbell bench press technique")
        ),
        LibraryExercise(
            name: "Жим штанги обратным хватом",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: лежа на горизонтальной скамье, хват супинированный (ладони к лицу) чуть шире плеч. Попросите партнёра подать штангу.\n\nДвижение: опускайте штангу к низу груди / верху живота, локти прижаты к корпусу. Жмите по широкой дуге.\n\nКлючи: исследования показывают повышенную активацию верха груди. Работайте с умеренными весами — нагрузка на запястья высокая.",
            videoUrl: ytSearch("reverse grip bench press technique")
        ),
        LibraryExercise(
            name: "Жим гантелей лежа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: лежа на скамье, гантели у груди, ладони от себя, лопатки сведены.\n\nДвижение: опускайте гантели по дуге до уровня груди (предплечья вертикально). Жмите вверх, сводя гантели в верхней точке (без стука).\n\nКлючи: большая амплитуда и устранение силового дисбаланса. В нижней точке — лёгкое растяжение, без перегиба плеча назад.",
            videoUrl: ytSearch("dumbbell bench press technique")
        ),
        LibraryExercise(
            name: "Жим гантелей на наклонной скамье",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: скамья 30°. Гантели на бёдрах, толкните коленями вверх к плечам.\n\nДвижение: опускайте по дуге до уровня плеч (растяжение верха груди). Жмите вверх и слегка внутрь, сводя гантели.\n\nКлючи: предплечья вертикальны в нижней точке, локти не уходят за линию плеч.",
            videoUrl: ytSearch("incline dumbbell press technique")
        ),
        LibraryExercise(
            name: "Жим гантелей на скамье с обратным наклоном",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Старт: скамья с отрицательным наклоном 15–20°, ноги зафиксированы. Гантели у нижней части груди.\n\nДвижение: жмите гантели вверх, сводя в верхней точке. Опускайте подконтрольно до растяжения низа груди.\n\nКлючи: акцент на нижний пучок, минимальное участие плеч.",
            videoUrl: ytSearch("decline dumbbell press technique")
        ),
        LibraryExercise(
            name: "Жим в Хаммере",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: сядьте плотно, лопатки прижаты к спинке, грудь приподнята. Рукояти на уровне середины груди.\n\nДвижение: жмите рукояти вперёд, в верхней точке слегка сводите их (если конструкция позволяет). Возвращайте подконтрольно до растяжения.\n\nКлючи: тренажёр стабилизирует траекторию — фокусируйтесь на сокращении грудных, не на удержании веса.",
            videoUrl: ytSearch("hammer strength chest press")
        ),
        LibraryExercise(
            name: "Жим в тренажере сидя",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: отрегулируйте сиденье так, чтобы рукояти были на уровне середины груди. Лопатки прижаты к спинке.\n\nДвижение: жмите рукояти вперёд по фиксированной траектории, не разгибая локти полностью. Возвращайте до растяжения.\n\nКлючи: подходит для безопасной работы до отказа, для дроп-сетов и для новичков.",
            videoUrl: ytSearch("chest press machine technique")
        ),
        LibraryExercise(
            name: "Жим Смита лежа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: скамья по центру тренажёра Смита, гриф над нижней частью груди.\n\nДвижение: опускайте штангу к нижней части груди, локти под 45°. Жмите вверх без рывка.\n\nКлючи: фиксированная траектория позволяет работать ближе к отказу без страховщика. Не путать с обычным жимом — дисбалансы здесь не корректируются.",
            videoUrl: ytSearch("smith machine bench press technique")
        ),
        LibraryExercise(
            name: "Жим Смита на наклонной",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: установите скамью с углом 30° под гриф так, чтобы он опускался к верху груди.\n\nДвижение: опускайте к ключицам, локти под 45°. Жмите без замыкания.\n\nКлючи: безопасная альтернатива со свободным весом, отлично для прогрессии в верхе груди.",
            videoUrl: ytSearch("smith machine incline press")
        ),
        LibraryExercise(
            name: "Гильотинный жим",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: лежа, ноги на скамье или подставке (исключаем мост). Хват чуть шире обычного.\n\nДвижение: опускайте штангу прямо к шее (не к груди), локти разведены под 90°. Жмите вверх по той же линии.\n\nКлючи: опасно для плеч — начинайте с минимального веса. Обязательна страховка. Даёт максимальное растяжение грудных и убирает помощь трицепсов и широчайших.",
            videoUrl: ytSearch("guillotine press technique")
        ),
        LibraryExercise(
            name: "Жим Свенда",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: стоя или сидя, сожмите между ладонями два блина (или одну гантель ребром) перед грудью. Локти подняты до уровня плеч.\n\nДвижение: выпрямите руки вперёд, постоянно с максимальной силой сдавливая блины ладонями. Возвращайте к груди, не ослабляя давление.\n\nКлючи: изометрический финишер — даёт сильнейший пампинг и развивает нейромышечную связь. Без давления упражнение бесполезно.",
            videoUrl: ytSearch("svend press technique")
        ),
        LibraryExercise(
            name: "Сведение гантелей лежа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: лежа, гантели над грудью, ладони обращены друг к другу. Локти зафиксированы в лёгком сгибе (15–20°).\n\nДвижение: разведите руки по широкой дуге до уровня плеч (или чуть ниже) — почувствуйте растяжение. Сведите по той же дуге, не меняя угол в локте.\n\nКлючи: это не жим — двигаются только плечевые суставы. В верхней точке слегка сводите гантели вместе для пика.",
            videoUrl: ytSearch("dumbbell flyes technique")
        ),
        LibraryExercise(
            name: "Сведение гантелей на наклонной скамье",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: скамья 30°. Гантели над грудью, ладони друг к другу, локти слегка согнуты.\n\nДвижение: разводите по дуге до растяжения верха груди. Сводите вверху без полного замыкания.\n\nКлючи: акцентирует ключичную головку. Берите умеренный вес — здесь приоритет техника, а не масса.",
            videoUrl: ytSearch("incline dumbbell flyes technique")
        ),
        LibraryExercise(
            name: "Сведение рук в тренажере (Бабочка)",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: сядьте, спина прижата, предплечья на подушках (или хват рукоятей). Локти на уровне плеч.\n\nДвижение: сводите руки перед грудью до соприкосновения, удерживая 1 секунду. Разводите подконтрольно до растяжения.\n\nКлючи: идеальная изоляция — нет участия трицепса. Не дёргайте — медленный негатив.",
            videoUrl: ytSearch("pec deck machine technique")
        ),
        LibraryExercise(
            name: "Кроссовер с верхних блоков",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Старт: блоки сверху, рукояти в каждой руке, корпус слегка наклонён вперёд, шаг вперёд для устойчивости.\n\nДвижение: сводите руки по дуге вниз перед собой к уровню таза, скрещивая запястья в нижней точке. Возврат подконтрольный.\n\nКлючи: акцент на низ груди и внутреннюю линию. Локти зафиксированы в лёгком сгибе.",
            videoUrl: ytSearch("high cable crossover technique")
        ),
        LibraryExercise(
            name: "Кроссовер со средних блоков",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: блоки на уровне груди. Стойка по центру, шаг вперёд.\n\nДвижение: сводите руки перед собой на уровне груди до пересечения. Контроль на возврате.\n\nКлючи: нагрузка на среднюю часть груди под постоянным напряжением — отличная альтернатива сведениям.",
            videoUrl: ytSearch("mid cable crossover technique")
        ),
        LibraryExercise(
            name: "Кроссовер с нижних блоков",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: блоки внизу, корпус слегка наклонён вперёд.\n\nДвижение: ведите руки снизу-вверх к лицу, как будто обнимаете. В верхней точке руки на уровне глаз, лёгкое сведение.\n\nКлючи: целит верхний пучок груди и работает в разрезе, недоступном штанге.",
            videoUrl: ytSearch("low cable crossover technique")
        ),
        LibraryExercise(
            name: "Сведения в кроссовере лежа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: скамья между двух блоков, ручки в руках, ладони друг к другу.\n\nДвижение: сведите руки над грудью по дуге, разведите подконтрольно до глубокого растяжения.\n\nКлючи: постоянное напряжение во всей амплитуде — преимущество кроссовера над гантелями.",
            videoUrl: ytSearch("lying cable flyes technique")
        ),
        LibraryExercise(
            name: "Отжимания от пола",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Старт: упор лёжа, ладони чуть шире плеч, тело — прямая линия от макушки до пяток.\n\nДвижение: опуститесь до 1–2 см от пола, локти под 45°. Мощно отожмитесь, не теряя натяжение корпуса.\n\nКлючи: пресс и ягодицы напряжены. Без провисания таза. Шире хват — больше грудь, уже — больше трицепс.",
            videoUrl: ytSearch("push up technique")
        ),
        LibraryExercise(
            name: "Отжимания узким хватом (Алмаз)",
            category: .chest,
            muscleGroup: .triceps,
            defaultType: .repsOnly,
            technique: "Старт: упор лёжа, ладони сведены под грудью так, чтобы большие и указательные пальцы образовали ромб.\n\nДвижение: опускайтесь, локти движутся назад вдоль рёбер. Отжимайтесь, удерживая корпус ровным.\n\nКлючи: жёсткая нагрузка на трицепс и внутреннюю часть груди. При боли в плечах сместите ладони чуть шире.",
            videoUrl: ytSearch("diamond push up technique")
        ),
        LibraryExercise(
            name: "Отжимания широким хватом",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Старт: ладони на 1.5 ширины плеч, тело прямое.\n\nДвижение: опуститесь подконтрольно до уровня груди. Локти разводятся в стороны под 60–90°.\n\nКлючи: акцент на внешней части груди. Не уходите слишком широко — риск для плечевого сустава.",
            videoUrl: ytSearch("wide push up technique")
        ),
        LibraryExercise(
            name: "Отжимания с хлопком",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Старт: упор лёжа, классический хват.\n\nДвижение: взрывное отжимание вверх с отрывом ладоней от пола, хлопок и мягкое приземление с продолжением движения.\n\nКлючи: плиометрика — для развития мощности. Только когда уверенно делаете 25+ обычных отжиманий.",
            videoUrl: ytSearch("clap push up technique")
        ),
        LibraryExercise(
            name: "Отжимания с возвышения для ног",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .repsOnly,
            technique: "Старт: ноги на скамье / возвышении, ладони на полу чуть шире плеч.\n\nДвижение: опускайтесь до касания грудью, локти под 45°. Отжимайтесь, удерживая корпус.\n\nКлючи: чем выше ноги — тем больше нагрузки на верх груди и плечи. Имитирует наклонный жим.",
            videoUrl: ytSearch("decline push up technique")
        ),
        LibraryExercise(
            name: "Отжимания на брусьях",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .repsOnly,
            technique: "Старт: упор на прямых руках на брусьях, корпус чуть наклонён вперёд (для груди), ноги согнуты или скрещены.\n\nДвижение: опускайтесь, разводя локти под 30–45°, до уровня плеч ниже локтей. Отжимайтесь без переразгибания.\n\nКлючи: вертикальный корпус — больше нагрузки на трицепс. Контролируйте глубину — слишком глубоко чревато травмой плеча.",
            videoUrl: ytSearch("dips technique chest")
        ),
        LibraryExercise(
            name: "Пуловер с гантелью",
            category: .chest,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: лопатками поперёк скамьи, ноги в пол, гантель на вытянутых (слегка согнутых) руках над грудью.\n\nДвижение: опустите гантель за голову по дуге до растяжения широчайших и груди. Возвращайте по той же траектории.\n\nКлючи: бёдра можно слегка опустить вниз — увеличивает растяжение. Не разгибайте локти полностью.",
            videoUrl: ytSearch("dumbbell pullover technique")
        ),
        LibraryExercise(
            name: "Пуловер на верхнем блоке прямыми руками",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: стоя у вертикального блока, прямая или EZ-рукоять. Корпус слегка наклонён вперёд. Руки прямые, рукоять на уровне головы.\n\nДвижение: тяните рукоять вниз к бёдрам по широкой дуге за счёт широчайших, не сгибая локти.\n\nКлючи: чистая изоляция широчайших — нет работы бицепса. Концентрация на разгибании плеча.",
            videoUrl: ytSearch("straight arm pulldown technique")
        ),

        LibraryExercise(
            name: "Сведение в тренажере Хаммер",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: сядьте, спина прижата к спинке, рукояти на уровне середины груди. Локти слегка согнуты, упор предплечий в подушки или хват за рукояти.\n\nДвижение: сводите рукояти перед грудью по дуге до соприкосновения. Удержите 1 секунду — затем разведите подконтрольно до растяжения.\n\nКлючи: рычажная конструкция Hammer Strength даёт более естественную траекторию чем pec deck. Лопатки прижаты к спинке весь подход.",
            videoUrl: ytSearch("hammer strength pec fly")
        ),
        LibraryExercise(
            name: "Жим в Хаммере одной рукой",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: сядьте в тренажёр, одна рука на рукояти на уровне груди. Свободной рукой держитесь за сиденье.\n\nДвижение: жмите рукоять вперёд, не позволяя корпусу разворачиваться. Возврат подконтрольный до растяжения.\n\nКлючи: устраняет силовой дисбаланс между сторонами. Кор работает как стабилизатор — корпус неподвижен.",
            videoUrl: ytSearch("single arm hammer chest press")
        ),
        LibraryExercise(
            name: "Жим блина перед собой",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: стоя, блин (5–15 кг) зажат между ладонями на уровне груди. Локти на уровне плеч, пальцы в стороны.\n\nДвижение: с силой сдавливая блин, выпрямите руки вперёд. Возвращайте к груди, не ослабляя давление ладоней.\n\nКлючи: вариация Жима Свенда с одним блином. Сильнейший пампинг при минимальном весе. Без давления упражнение бесполезно.",
            videoUrl: ytSearch("plate squeeze press technique")
        ),
        LibraryExercise(
            name: "Жим штанги с пола",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: лёжа на полу, ноги согнуты или вытянуты. Штанга в руках над грудью, хват чуть шире плеч.\n\nДвижение: опускайте штангу до касания локтями пола (пауза 1 сек). Жмите вверх без отбива.\n\nКлючи: пол ограничивает амплитуду — щадит плечи и акцентирует локаут трицепсами. Хороший выбор при болях в плечах.",
            videoUrl: ytSearch("floor press technique")
        ),
        LibraryExercise(
            name: "Жим гантелей с пола",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: лёжа на полу, гантели у груди, локти на полу под 45°.\n\nДвижение: жмите гантели вверх, в верхней точке слегка сводите. Опускайте до касания локтями пола, пауза 1 сек.\n\nКлючи: альтернатива классическому жиму — нейтральнее для плеч. Нет помощи отскока — работа за счёт мышц.",
            videoUrl: ytSearch("dumbbell floor press technique")
        ),
        LibraryExercise(
            name: "Жим Лэндмайн стоя одной рукой",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: гриф в Лэндмайн-станции, конец у плеча. Противоположная нога впереди, свободная рука у пояса.\n\nДвижение: жмите гриф вперёд-вверх по диагонали до полного разгибания. Возврат подконтрольный.\n\nКлючи: гибрид жима и наклонного жима. Жёстко работает кор и верх груди. Не разворачивайте корпус — таз фиксирован.",
            videoUrl: ytSearch("single arm landmine press")
        ),
        LibraryExercise(
            name: "Жим в кроссовере одной рукой",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: блок на уровне груди, рукоять в одной руке. Стоя боком к блоку, шаг вперёд для устойчивости.\n\nДвижение: жмите рукоять вперёд по дуге, чуть к центру. Возврат с глубоким растяжением.\n\nКлючи: постоянное напряжение во всей амплитуде. Корпус неподвижен — работают только грудные.",
            videoUrl: ytSearch("single arm cable chest press")
        ),
        LibraryExercise(
            name: "Сведения сидя в кроссовере",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: сидя на лавке между двумя блоками на уровне плеч. Рукояти в руках, ладони друг к другу, локти слегка согнуты.\n\nДвижение: сводите рукояти перед грудью до соприкосновения. Разведите подконтрольно до полного растяжения.\n\nКлючи: альтернатива pec deck с большей свободой движения и постоянным напряжением блока.",
            videoUrl: ytSearch("seated cable fly")
        ),
        LibraryExercise(
            name: "Жим в раме с упоров (Pin press)",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: штанга на упорах силовой рамы на 5–10 см ниже груди. Установите рабочую высоту, лягте.\n\nДвижение: с упоров взрывной жим штанги вверх до полного разгибания. Опустите на упоры — пауза 1–2 сек, затем повтор.\n\nКлючи: уничтожает рефлекс растяжения — чистая концентрическая работа. Топливо для пробивания плато в жиме.",
            videoUrl: ytSearch("pin press bench technique")
        ),
        LibraryExercise(
            name: "Сведение со сжатием на блоке",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: блок на уровне середины груди. Рукояти в руках, локти слегка согнуты.\n\nДвижение: сводите руки перед собой до соприкосновения и удерживайте 2 секунды с максимальным напряжением. Возвращайте только на 80% амплитуды — не теряя натяжения.\n\nКлючи: пиковое сокращение — финишер для пампинга. Не разводите до полного растяжения, чтобы не терять напряжение.",
            videoUrl: ytSearch("cable chest squeeze fly")
        ),
        LibraryExercise(
            name: "Сжимающий жим гантелей",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: лёжа на скамье, гантели зажаты вместе над грудью, ладони друг к другу. Гантели плотно прижаты по всей длине.\n\nДвижение: жмите гантели вверх и вниз, удерживая постоянное давление между ними. Опустите до касания груди, не размыкая снаряды.\n\nКлючи: сильнейшая активация внутренней части груди и трицепсов через изометрическое сжатие. Используйте умеренный вес — техника важнее.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Жим гантели одной рукой лёжа",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: лёжа на скамье, гантель в одной руке у груди. Свободная рука вдоль корпуса или на животе для стабилизации.\n\nДвижение: жмите гантель вверх до полного разгибания, не разворачивая корпус. Опускайте подконтрольно до уровня груди.\n\nКлючи: устраняет силовой дисбаланс и заставляет кор работать как стабилизатор. Не позволяйте корпусу скручиваться — таз и плечи прижаты к скамье.",
            videoUrl: nil
        ),

        // MARK: - СПИНА

        LibraryExercise(
            name: "Становая тяга",
            category: .back,
            muscleGroup: .lowerBack,
            defaultType: .strength,
            technique: "Старт: гриф над серединой стопы, ноги на ширине таза. Хват чуть шире коленей. Спина нейтральная, грудь раскрыта, плечи чуть впереди грифа.\n\nДвижение: толкайте пол ногами, поднимая гриф вдоль голеней. Когда штанга проходит колени — мощно разгибайте таз. Опускайте по той же траектории.\n\nКлючи: штанга всегда касается ног. Никаких рывков. Поясница нейтральная всё движение. Дыхание: вдох до подъёма, удержание, выдох наверху.",
            videoUrl: ytSearch("conventional deadlift technique")
        ),
        LibraryExercise(
            name: "Становая тяга сумо",
            category: .back,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: широкая стойка, носки развёрнуты на 30–45°. Хват внутри ног, руки прямые. Таз ниже, корпус более вертикален.\n\nДвижение: толкайте пол, разводя колени в стороны (по линии стоп). Когда гриф проходит колени — разгибайте таз.\n\nКлючи: меньше нагрузки на поясницу, больше — на ягодицы и приводящие. Подходит при коротких руках или жёсткой пояснице.",
            videoUrl: ytSearch("sumo deadlift technique")
        ),
        LibraryExercise(
            name: "Румынская тяга",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: штанга в руках, стоя. Ноги на ширине таза, чуть согнуты в коленях.\n\nДвижение: уводите таз назад, опуская штангу по бёдрам до растяжения бицепса бедра (примерно середина голени). Возвращайтесь, разгибая таз.\n\nКлючи: спина нейтральная, грудь раскрыта. Колени почти не сгибаются — это шарнир в тазу, не присед. Штанга ведётся по ноге.",
            videoUrl: ytSearch("romanian deadlift technique")
        ),
        LibraryExercise(
            name: "Румынская тяга гантели",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: гантели в руках вдоль бёдер. Стойка на ширине таза.\n\nДвижение: таз назад, гантели по бёдрам вниз до растяжения бицепса бедра. Возврат — толкая бёдра вперёд.\n\nКлючи: гантели позволяют большую амплитуду и тщательный контроль. Идеально для гипертрофии задней цепи.",
            videoUrl: ytSearch("dumbbell romanian deadlift technique")
        ),
        LibraryExercise(
            name: "Одноногая румынская тяга",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: гантель в руке, противоположная нога стоит, рабочая чуть согнута.\n\nДвижение: опускайте гантель к полу, отводя свободную ногу назад в одну линию с корпусом. Возвращайтесь, активируя ягодицу.\n\nКлючи: жёсткая нагрузка на ягодицы и стабилизаторы. Бёдра параллельны полу, не разворачивайте таз.",
            videoUrl: ytSearch("single leg rdl technique")
        ),
        LibraryExercise(
            name: "Тяга штанги в наклоне",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: ноги на ширине плеч, лёгкий сгиб в коленях. Корпус наклонён до 45° (или ниже). Хват чуть шире плеч, штанга свисает.\n\nДвижение: тяните штангу к низу живота / верху таза, сводя лопатки. Локти ведутся вдоль корпуса.\n\nКлючи: спина нейтральная всё время. Без читинга корпусом — корпус остаётся фиксированным.",
            videoUrl: ytSearch("barbell row technique")
        ),
        LibraryExercise(
            name: "Тяга штанги в наклоне обратным хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: хват супинированный (ладони к себе) на ширине плеч, корпус наклонён до 45°.\n\nДвижение: тяните штангу к низу живота, локти прижаты к корпусу. Сводите лопатки в верхней точке.\n\nКлючи: больше акцент на нижние широчайшие и бицепс. Меньше нагрузка на поясницу при таком хвате.",
            videoUrl: ytSearch("yates row technique")
        ),
        LibraryExercise(
            name: "Тяга Пендли",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: каждое повторение начинается с пола. Корпус параллелен полу, спина нейтральная.\n\nДвижение: взрывная тяга штанги к нижней части груди / верху живота. Опустить полностью на пол, восстановить стойку.\n\nКлючи: строгая техника без раскачки — корпус неподвижен. Развивает мощную тягу для становой и силовых видов спорта.",
            videoUrl: ytSearch("pendlay row technique")
        ),
        LibraryExercise(
            name: "Тяга Т-грифа",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: над Т-грифом, ноги по бокам или одна сзади. Хват за рукояти, корпус 30–45°, спина нейтральная.\n\nДвижение: тяните рукояти к нижней части груди, сводя лопатки. Локти вдоль корпуса.\n\nКлючи: Т-гриф снимает нагрузку с поясницы по сравнению со штангой, позволяет работать с большим весом.",
            videoUrl: ytSearch("t bar row technique")
        ),
        LibraryExercise(
            name: "Тяга гантели в наклоне",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: одно колено и одноимённая рука на скамье, спина параллельна полу. Гантель в свободной руке.\n\nДвижение: тяните гантель к тазу (\"в карман\"), локоть ведёте строго вверх вдоль корпуса. Сводите лопатку.\n\nКлючи: не вращайте корпус. Опускайте до полного растяжения широчайшей. Гантель — большая амплитуда против штанги.",
            videoUrl: ytSearch("one arm dumbbell row technique")
        ),
        LibraryExercise(
            name: "Тяга гантели в стиле Кроча",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: тяжёлая гантель, упор свободной рукой в стойку. Корпус слегка скручен.\n\nДвижение: мощная тяга к тазу с лёгким читингом корпусом для разгона. Контролируйте опускание.\n\nКлючи: фишка Дориана Йейтса и Бранча Уоррена — для атлетов с большим стажем. 15–25 повторений в стиле \"кровь в мышцу\".",
            videoUrl: ytSearch("kroc row technique")
        ),
        LibraryExercise(
            name: "Тяга в Лэндмайн",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: один конец штанги в углу или в Лэндмайне. Стойка верхом над грифом, корпус наклонён.\n\nДвижение: тяните рукоять / гриф к нижней части груди, локти прижаты.\n\nКлючи: безопасная для поясницы тяга — фиксированная траектория. Отлично подходит при болях в спине.",
            videoUrl: ytSearch("landmine row technique")
        ),
        LibraryExercise(
            name: "Тяга Мэдоуз",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: штанга в Лэндмайне. Стойка перпендикулярно грифу, наклон вперёд, упор свободной рукой в колено. Хват пронированный за конец грифа.\n\nДвижение: тяните локоть вверх и назад, акцентируя нагрузку на верх широчайших и заднюю дельту.\n\nКлючи: авторство Джона Мэдоуза. Целит ту часть спины, что плохо прокачивается классическими тягами.",
            videoUrl: ytSearch("meadows row technique")
        ),
        LibraryExercise(
            name: "Тяга в тренажере с упором грудью",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: лягте грудью на наклонную скамью или сядьте в тренажёр Chest-Supported Row. Хват за рукояти.\n\nДвижение: тяните рукояти к корпусу, сводя лопатки в верхней точке. Локти вдоль корпуса.\n\nКлючи: полная изоляция спины — нет нагрузки на поясницу, читинг невозможен.",
            videoUrl: ytSearch("chest supported row technique")
        ),
        LibraryExercise(
            name: "Рычажная тяга (Hammer)",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: сядьте в Hammer Strength Row, грудь к подушке, хват нейтральный или пронированный.\n\nДвижение: тяните рукояти на себя, выводя локти назад. Сводите лопатки в верхней точке.\n\nКлючи: возможна работа одной рукой для устранения дисбалансов. Фиксированная траектория — фокус на ощущении мышц.",
            videoUrl: ytSearch("hammer strength row technique")
        ),
        LibraryExercise(
            name: "Подтягивания",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: вис на перекладине, хват пронированный (ладонями от себя) шире плеч. Лопатки слегка опущены.\n\nДвижение: подтянитесь грудью к перекладине, сводя лопатки и опуская локти вниз. Опуститесь подконтрольно до полного выпрямления рук.\n\nКлючи: без раскачки. Думайте \"локти в задние карманы\". Вверху — не сутультесь.",
            videoUrl: ytSearch("pull ups technique")
        ),
        LibraryExercise(
            name: "Подтягивания обратным хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: вис на перекладине, хват супинированный (ладонями к себе) на ширине плеч.\n\nДвижение: подтянитесь подбородком над перекладиной, локти прижаты к корпусу. Опускайтесь до полного выпрямления.\n\nКлючи: \"чин-апы\" — больше нагрузки на бицепс и нижние широчайшие. Идеальны для массонабора рук и спины.",
            videoUrl: ytSearch("chin ups technique")
        ),
        LibraryExercise(
            name: "Подтягивания узким хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: хват пронированный или нейтральный, ладони на ширине 10–20 см.\n\nДвижение: подтягивайтесь до подбородка над перекладиной, акцентируя нижние широчайшие и бицепс.\n\nКлючи: укороченная амплитуда сверху, увеличивает нагрузку на низ ширчайших. Хорошая вариация для мышечной разнообразности.",
            videoUrl: ytSearch("close grip pull ups technique")
        ),
        LibraryExercise(
            name: "Подтягивания нейтральным хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: ладони друг к другу на специальных параллельных рукоятях.\n\nДвижение: подтягивайтесь грудью к рукоятям, локти вниз вдоль корпуса.\n\nКлючи: самый щадящий для плечевого сустава вариант. Хорошее соотношение спина / бицепс.",
            videoUrl: ytSearch("neutral grip pull ups technique")
        ),
        LibraryExercise(
            name: "Подтягивания с дополнительным весом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: дополнительный вес на поясе или гантель между ног. Вис, хват шире плеч.\n\nДвижение: подтягивайтесь грудью к перекладине без рывков. Опускайтесь подконтрольно.\n\nКлючи: основа силового прогресса в подтягиваниях. 4–8 повторов в подходе.",
            videoUrl: ytSearch("weighted pull ups technique")
        ),
        LibraryExercise(
            name: "Австралийские подтягивания",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: гриф в раме / стойках на уровне таза. Лягте под него, хват шире плеч. Тело — прямая линия от пяток до плеч.\n\nДвижение: подтянитесь грудью к грифу, сводя лопатки. Опуститесь подконтрольно.\n\nКлючи: горизонтальная тяга с собственным весом. Чем ниже гриф — тем сложнее.",
            videoUrl: ytSearch("inverted row technique")
        ),
        LibraryExercise(
            name: "Тяга вертикального блока",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: сядьте, ноги под валиками. Хват шире плеч, прогиб в грудном отделе.\n\nДвижение: тяните рукоять к верху груди, опуская локти вниз и назад. Сводите лопатки.\n\nКлючи: не сутультесь. Не тяните за голову на классическом тренажёре — это травмоопасно.",
            videoUrl: ytSearch("lat pulldown technique")
        ),
        LibraryExercise(
            name: "Тяга вертикального блока обратным хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: хват супинированный на ширине плеч.\n\nДвижение: тяните рукоять к низу груди, локти прижаты к корпусу.\n\nКлючи: акцент на нижние широчайшие и бицепс. Хорошая альтернатива чин-апам, если их пока не освоили.",
            videoUrl: ytSearch("reverse grip lat pulldown technique")
        ),
        LibraryExercise(
            name: "Тяга вертикального блока узким хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: V-рукоять или узкий гриф. Хват ладонями друг к другу.\n\nДвижение: тяните рукоять к верху живота, локти вниз вдоль рёбер.\n\nКлючи: длинная амплитуда — отличная нагрузка на низ широчайших. Прогиб в грудном отделе.",
            videoUrl: ytSearch("close grip lat pulldown technique")
        ),
        LibraryExercise(
            name: "Тяга горизонтального блока",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: сядьте, ноги в упор, спина прямая, руки тянутся к рукояти.\n\nДвижение: тяните рукоять к низу живота, сводя лопатки и расправляя грудь. Локти вдоль корпуса.\n\nКлючи: на возврате слегка подайте корпус вперёд для растяжения широчайших. Не используйте поясницу для рывков.",
            videoUrl: ytSearch("seated cable row technique")
        ),
        LibraryExercise(
            name: "Тяга горизонтального блока узким хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: V-рукоять, ладони друг к другу, спина прямая.\n\nДвижение: тяните рукоять к пупку, локти прижаты к корпусу.\n\nКлючи: акцент на середину спины и широчайшие. Удерживайте 1 сек в верхней точке.",
            videoUrl: ytSearch("close grip seated row technique")
        ),
        LibraryExercise(
            name: "Тяга горизонтального блока одной рукой",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: рукоять D-образная, корпус прямой, ноги в упоре.\n\nДвижение: тяните рукоять к боку, поворачивая корпус для большей амплитуды. Сводите лопатку.\n\nКлючи: устраняет дисбаланс правой / левой стороны. Большая амплитуда против двуручной версии.",
            videoUrl: ytSearch("one arm cable row technique")
        ),
        LibraryExercise(
            name: "Тяга TRX",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: возьмитесь за петли TRX, отклонитесь назад с прямым телом. Угол определяет сложность.\n\nДвижение: подтянитесь к петлям, сводя лопатки. Локти вдоль корпуса. Опуститесь подконтрольно.\n\nКлючи: чем горизонтальнее тело — тем сложнее. Корпус всегда прямой.",
            videoUrl: ytSearch("trx row technique")
        ),
        LibraryExercise(
            name: "Гиперэкстензия",
            category: .back,
            muscleGroup: .lowerBack,
            defaultType: .repsOnly,
            technique: "Старт: упор валиков на уровне сгиба бёдер (не выше). Стопы зафиксированы.\n\nДвижение: опускайтесь до сгибания в тазу под 90°, поднимайтесь до прямой линии с ногами.\n\nКлючи: не переразгибайтесь — это травмоопасно. Можно выполнять с округлой спиной (для широчайших / трапеций) или с прямой (для разгибателей).",
            videoUrl: ytSearch("hyperextension technique")
        ),
        LibraryExercise(
            name: "Обратная гиперэкстензия",
            category: .back,
            muscleGroup: .glutes,
            defaultType: .repsOnly,
            technique: "Старт: лежа животом на скамье / тренажёре, ноги свисают.\n\nДвижение: поднимайте прямые ноги вверх до горизонтали, сжимая ягодицы. Опускайте подконтрольно.\n\nКлючи: декомпрессирует поясницу. Отличное упражнение для тяжелоатлетов в дни восстановления.",
            videoUrl: ytSearch("reverse hyperextension technique")
        ),
        LibraryExercise(
            name: "Good Morning",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: штанга на трапециях (как в приседе). Ноги на ширине таза, лёгкий сгиб в коленях.\n\nДвижение: тазом отойдите назад, наклоняя корпус вперёд до параллели полу (или ниже, если мобильность позволяет). Спина нейтральная.\n\nКлючи: укрепляет заднюю цепь. Начинайте с лёгкого веса — техника требует практики.",
            videoUrl: ytSearch("good morning exercise technique")
        ),
        LibraryExercise(
            name: "Шраги со штангой",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: штанга в опущенных руках перед собой. Хват чуть шире плеч.\n\nДвижение: поднимайте плечи к ушам максимально высоко, удерживая 1 сек. Опускайте подконтрольно.\n\nКлючи: только вертикальное движение. Без вращений плеч (это травмоопасно).",
            videoUrl: ytSearch("barbell shrug technique")
        ),
        LibraryExercise(
            name: "Шраги с гантелями",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: гантели в руках вдоль корпуса.\n\nДвижение: поднимайте плечи вверх максимально высоко. Удерживайте 1–2 сек в пике.\n\nКлючи: гантели позволяют большую амплитуду по сравнению со штангой.",
            videoUrl: ytSearch("dumbbell shrug technique")
        ),
        LibraryExercise(
            name: "Шраги в тренажере",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: специальный тренажёр или Hammer Shrug. Рукояти по бокам.\n\nДвижение: поднимайте плечи прямо вверх по фиксированной траектории.\n\nКлючи: чистая изоляция трапеций без участия предплечий и хвата.",
            videoUrl: ytSearch("machine shrug technique")
        ),

        LibraryExercise(
            name: "Тяга верхнего блока",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: сядьте в тренажёр, бёдра под валиками. Хват прямой штанги шире плеч сверху. Корпус слегка наклонён назад на 10–15°, грудь раскрыта.\n\nДвижение: тяните штангу к верхней части груди, сводя лопатки вниз и назад. Локти ведутся вниз и слегка назад, к карманам.\n\nКлючи: активируйте широчайшие до движения — представьте, что тянете локтями, а не кистями. Не качайте корпус — он фиксирован весь подход.",
            videoUrl: ytSearch("lat pulldown technique")
        ),
        LibraryExercise(
            name: "Тяга верхнего блока за голову",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: широкий хват сверху, корпус прямой и слегка наклонён вперёд. Бёдра под валиками.\n\nДвижение: тяните штангу за голову, до уровня основания шеи. Локти движутся в стороны и вниз.\n\nКлючи: вариант с риском для плеч — только при достаточной мобильности грудного отдела. Используйте умеренный вес.",
            videoUrl: ytSearch("behind the neck pulldown")
        ),
        LibraryExercise(
            name: "Тяга вертикального блока одной рукой",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: сидя или стоя на одном колене у блока. Одна рукоять в руке нейтральным хватом. Свободная рука опирается на бедро.\n\nДвижение: тяните рукоять к плечу, локоть назад вдоль корпуса. В нижней точке концентрируйтесь на сокращении широчайшей.\n\nКлючи: унилатеральная работа — больше амплитуда и лучшая активация. Без скручивания корпуса.",
            videoUrl: ytSearch("single arm lat pulldown")
        ),
        LibraryExercise(
            name: "Тяга нижнего блока одной рукой стоя",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: стоя в выпаде или с упором коленом. Рукоять в одной руке, корпус наклонён вперёд под 30°.\n\nДвижение: тяните рукоять к боку живота, локоть назад вдоль корпуса. Сводите лопатку.\n\nКлючи: горизонтальная тяга с акцентом на одну сторону. Корпус неподвижен — без скручивания.",
            videoUrl: ytSearch("single arm cable row standing")
        ),
        LibraryExercise(
            name: "Тяга гантели двумя руками в наклоне",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: одна гантель в обеих руках на торце. Стойка на ширине плеч, корпус наклонён до 45°. Спина нейтральная.\n\nДвижение: тяните гантель к низу живота, локти вдоль корпуса. Сводите лопатки в верхней точке.\n\nКлючи: симметричная нагрузка устраняет компенсации. Идеально для проработки нижних широчайших.",
            videoUrl: ytSearch("dumbbell two hand row")
        ),
        LibraryExercise(
            name: "Тяга гантелей лежа на наклонной",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: лёжа животом на наклонной скамье 30–45°. Гантели свисают вниз, ладони друг к другу.\n\nДвижение: тяните гантели к бёдрам, сводя лопатки. Локти ведутся вдоль корпуса вверх и назад.\n\nКлючи: исключает читинг корпусом — изолирует широчайшие. Не отрывайте грудь от скамьи.",
            videoUrl: ytSearch("chest supported dumbbell row")
        ),
        LibraryExercise(
            name: "Тяга гантелей в наклоне нейтральным хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: гантели в опущенных руках, ладони друг к другу. Корпус наклонён до 45°, спина нейтральная.\n\nДвижение: тяните гантели к корпусу, локти движутся вдоль рёбер вверх и назад.\n\nКлючи: нейтральный хват щадит плечи. Сильнее активирует середину спины и задние дельты.",
            videoUrl: ytSearch("neutral grip dumbbell row")
        ),
        LibraryExercise(
            name: "Австралийские подтягивания со штангой",
            category: .back,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: штанга в раме на уровне таза. Лягте под штангой, хват шире плеч сверху. Тело — прямая линия от плеч до пяток.\n\nДвижение: тяните грудь к штанге, сводя лопатки. Опускайтесь подконтрольно до полного выпрямления рук.\n\nКлючи: горизонтальная тяга весом тела — проработка средней части спины. Чем горизонтальнее тело, тем сложнее.",
            videoUrl: ytSearch("inverted row barbell")
        ),
        LibraryExercise(
            name: "Шраги обратные с гантелями",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: гантели в руках за спиной, ладони назад. Стойка на ширине плеч.\n\nДвижение: поднимите плечи строго вверх к ушам. Удержите 1 секунду — опустите подконтрольно.\n\nКлючи: акцент на нижнюю и среднюю трапеции. Не вращайте плечами по кругу.",
            videoUrl: ytSearch("behind back dumbbell shrug")
        ),
        LibraryExercise(
            name: "Шраги в Смите",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: штанга Смита на уровне бёдер, хват сверху на ширине плеч.\n\nДвижение: поднимите плечи строго вверх. Удержите 1 сек. Опустите.\n\nКлючи: фиксированная траектория позволяет работать с большим весом без потери техники. Отлично для прогрессии трапеций.",
            videoUrl: ytSearch("smith machine shrug")
        ),
        LibraryExercise(
            name: "Обратная гиперэкстензия со штангой",
            category: .back,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: лягте животом на скамью или GHD так, чтобы таз был на краю. Штанга между лодыжек или специальный тренажёр.\n\nДвижение: поднимайте ноги до параллели с полом за счёт ягодиц и поясницы. Опускайте подконтрольно.\n\nКлючи: разгружает поясницу и качает заднюю цепь. Без раскачки и инерции.",
            videoUrl: ytSearch("reverse hyperextension barbell")
        ),
        LibraryExercise(
            name: "Тяга в Лэндмайн узким хватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: гриф в Лэндмайн-станции, V-рукоять надета на конец грифа. Стоя над грифом, корпус наклонён до 45°.\n\nДвижение: тяните рукоять к низу живота, локти вдоль корпуса. Сводите лопатки.\n\nКлючи: естественная дуга движения. Меньше нагрузки на поясницу чем в классической штанговой тяге.",
            videoUrl: ytSearch("landmine row close grip")
        ),
        LibraryExercise(
            name: "Шраги Кирка",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: штанга в опущенных руках перед бёдрами, хват чуть шире плеч сверху.\n\nДвижение: гибрид тяги и шрага — поднимайте штангу вдоль корпуса, ведя локти высоко в стороны и одновременно поднимая плечи к ушам. В верхней точке штанга на уровне нижней части груди, плечи максимально вверх.\n\nКлючи: мощно прокачивает верх трапеций и среднюю часть спины. Любимое упражнение Кирка Карвоского — даёт ту самую \"толщину\" верха спины.",
            videoUrl: nil
        ),

        // MARK: - НОГИ

        LibraryExercise(
            name: "Приседания со штангой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: штанга на верхней части трапеций (high-bar) или на задних дельтах (low-bar). Стойка чуть шире плеч, носки развёрнуты на 15–30°.\n\nДвижение: вдох, удержание корпуса, опускайтесь, отводя таз и сгибая колени по линии стоп. Глубина — параллель или ниже. Поднимайтесь, толкая пол.\n\nКлючи: грудь раскрыта, спина нейтральная, колени на линии стоп. Пятки прижаты.",
            videoUrl: ytSearch("squat technique")
        ),
        LibraryExercise(
            name: "Приседания со штангой Low Bar",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: гриф ниже на спине — на задних дельтах, локти разведены. Стойка чуть шире.\n\nДвижение: больший наклон корпуса вперёд. Таз уводится назад в начале опускания.\n\nКлючи: классика пауэрлифтинга — позволяет поднимать больший вес. Активирует ягодицы и заднюю цепь.",
            videoUrl: ytSearch("low bar squat technique")
        ),
        LibraryExercise(
            name: "Фронтальные приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: штанга на передних дельтах, локти высоко вперёд (хват крестом или олимпийский). Грудь раскрыта.\n\nДвижение: опускайтесь с вертикальным корпусом до параллели или ниже. Поднимайтесь, толкая пол.\n\nКлючи: вертикальный корпус — главный признак правильной техники. Изолирует квадрицепсы и развивает мобильность.",
            videoUrl: ytSearch("front squat technique")
        ),
        LibraryExercise(
            name: "Приседания Зерчера",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: штанга в локтевых сгибах, плотно прижата к корпусу. Стойка как в обычном приседе.\n\nДвижение: опускайтесь с вертикальным корпусом до параллели. Толкайте пол при подъёме.\n\nКлючи: жёстко прокачивает квадрицепсы, верх спины и кор. Используйте подушку или одежду на сгибах локтей.",
            videoUrl: ytSearch("zercher squat technique")
        ),
        LibraryExercise(
            name: "Приседания с безопасным грифом",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: SSB (Safety Squat Bar) на трапециях, рукояти в руках перед собой.\n\nДвижение: опускание как в обычном приседе, но корпус наклоняется чуть больше.\n\nКлючи: щадит плечи и кисти. Идеально при болях в плечах или травмах. Гриф толкает корпус вперёд — нужно сильнее напрягать спину.",
            videoUrl: ytSearch("safety squat bar technique")
        ),
        LibraryExercise(
            name: "Приседания в Смите",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: гриф Смита на трапециях. Ноги поставьте чуть впереди — для нагрузки на квадрицепсы.\n\nДвижение: опускайтесь до параллели. Поднимайтесь, толкая пятками.\n\nКлючи: фиксированная траектория позволяет работать в отказ без риска. Подходит для гипертрофии квадрицепсов.",
            videoUrl: ytSearch("smith machine squat technique")
        ),
        LibraryExercise(
            name: "Гакк-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: спиной в платформу гакк-машины, плечи под валики. Ноги чуть выше центра платформы.\n\nДвижение: опускайтесь до 90° в коленях. Поднимайтесь, не разгибая колени до конца.\n\nКлючи: стопы выше — больше ягодиц, ниже — больше квадрицепсов. Можно делать в обратном положении (грудью к платформе) для акцента на ягодицы.",
            videoUrl: ytSearch("hack squat technique")
        ),
        LibraryExercise(
            name: "Сисси-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: стоя, держитесь свободной рукой за стойку. Ноги вместе.\n\nДвижение: отклоняйтесь корпусом назад, поднимаясь на носки и сгибая колени. Колени уходят вперёд за носки.\n\nКлючи: жёсткая нагрузка на низ квадрицепса. Используйте сиси-станок или контролируйте опорой. Не для людей с больными коленями.",
            videoUrl: ytSearch("sissy squat technique")
        ),
        LibraryExercise(
            name: "Гоблет-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: гантель / гиря у груди, локти под снарядом. Стойка чуть шире плеч.\n\nДвижение: опускайтесь между бёдер до параллели или ниже. Поднимайтесь, толкая пол.\n\nКлючи: лучшее упражнение для обучения приседу — корпус всегда вертикален. Локти направляйте в колени для контроля.",
            videoUrl: ytSearch("goblet squat technique")
        ),
        LibraryExercise(
            name: "Болгарские сплит-приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: задняя нога на скамье (носок упирается). Передняя в шаге, гантели в руках или штанга на спине.\n\nДвижение: опускайтесь, сгибая переднее колено до 90°. Заднее колено почти касается пола. Поднимайтесь через переднюю ногу.\n\nКлючи: нагружает квадрицепс и ягодицу одной ноги. Колено не уходит за носок.",
            videoUrl: ytSearch("bulgarian split squat technique")
        ),
        LibraryExercise(
            name: "Зашагивания на скамью",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: гантели в руках, перед скамьёй высотой ниже колена.\n\nДвижение: поставьте ногу на скамью, поднимитесь полностью на неё. Опуститесь подконтрольно. Не толкайтесь нижней ногой.\n\nКлючи: работа от ягодицы и квадрицепса верхней ноги. Без \"отскока\".",
            videoUrl: ytSearch("step up technique")
        ),
        LibraryExercise(
            name: "Выпады с гантелями",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: гантели в руках, ноги на ширине таза.\n\nДвижение: шаг вперёд, опуститесь до 90° в колене. Заднее колено почти касается пола. Возврат через переднюю ногу.\n\nКлючи: корпус прямой. Колено не уходит за носок. Передняя нога делает работу.",
            videoUrl: ytSearch("dumbbell lunge technique")
        ),
        LibraryExercise(
            name: "Выпады назад с гантелями",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: гантели в руках, ноги на ширине таза.\n\nДвижение: шаг назад, опуститесь до 90° в переднем колене. Возврат через переднюю ногу.\n\nКлючи: безопаснее для коленей, чем выпады вперёд. Больший акцент на ягодицы.",
            videoUrl: ytSearch("reverse lunge technique")
        ),
        LibraryExercise(
            name: "Выпады в ходьбе",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: гантели в руках, открытое пространство перед собой.\n\nДвижение: шагайте вперёд, делая выпады по очереди. Между шагами — мгновенная пауза для контроля.\n\nКлючи: высокая метаболическая нагрузка. Идеально для финиша тренировки ног.",
            videoUrl: ytSearch("walking lunge technique")
        ),
        LibraryExercise(
            name: "Боковые выпады",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: широкая стойка, гантель у груди.\n\nДвижение: перенесите вес на одну ногу, отводя таз назад и сгибая колено. Вторая нога остаётся прямой. Возврат в центр.\n\nКлючи: тренирует ягодицы и приводящие. Стопа рабочей ноги полностью на полу.",
            videoUrl: ytSearch("lateral lunge technique")
        ),
        LibraryExercise(
            name: "Приседания Пистолетик",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: на одной ноге, вторая выпрямлена вперёд параллельно полу. Руки балансируют.\n\nДвижение: опускайтесь до полного приседа на одной ноге, удерживая вторую. Поднимайтесь без касания пола.\n\nКлючи: требует мобильности и силы. Учитесь с поддержкой за TRX или стойку. Прогрессируйте через приседы на скамью.",
            videoUrl: ytSearch("pistol squat technique")
        ),
        LibraryExercise(
            name: "Приседания Креветка",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: на одной ноге, вторая согнута в колене и удерживается рукой за спиной.\n\nДвижение: опускайтесь до касания пола задним коленом. Поднимайтесь.\n\nКлючи: альтернатива пистолетику — мобильность нужна меньше. Прогрессирует через варианты с разным удержанием руки.",
            videoUrl: ytSearch("shrimp squat technique")
        ),
        LibraryExercise(
            name: "Приседания Дракона",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: на одной ноге, вторая поднята и проходит под рабочей ногой во время приседа.\n\nДвижение: опускайтесь, проводя свободную ногу под рабочей. Сложнейший контроль.\n\nКлючи: один из самых сложных вариантов одноногих приседов. Требует феноменального баланса.",
            videoUrl: ytSearch("dragon squat technique")
        ),
        LibraryExercise(
            name: "Тяга Кинга",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: стоя на одной ноге, свободная согнута в колене.\n\nДвижение: опускайтесь, пытаясь коснуться пола свободным коленом. Поднимайтесь через переднюю ногу.\n\nКлючи: вариация одноногого приседа. Сложная координация — начинайте без веса.",
            videoUrl: ytSearch("king deadlift technique")
        ),
        LibraryExercise(
            name: "Жим ногами",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: спина и таз плотно прижаты к спинке, стопы на платформе на ширине плеч.\n\nДвижение: опускайте платформу до 90° в коленях (или ниже, если поясница не отрывается). Жмите без замыкания коленей.\n\nКлючи: стопы выше — акцент на ягодицы, ниже — на квадрицепсы. Не отрывайте таз от спинки.",
            videoUrl: ytSearch("leg press technique")
        ),
        LibraryExercise(
            name: "Жим ногами под наклоном 45°",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: классический Leg Press 45°. Стопы на ширине плеч, носки слегка наружу.\n\nДвижение: опускайте платформу глубоко без отрыва таза. Жмите вверх без замыкания коленей.\n\nКлючи: позволяет работать с очень большим весом. Безопаснее приседа для гипертрофии квадрицепса.",
            videoUrl: ytSearch("45 leg press technique")
        ),
        LibraryExercise(
            name: "Разгибание ног в тренажере",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: сядьте, валик на нижней части голени, спина прижата.\n\nДвижение: разгибайте ноги до полного выпрямления, удерживая 1 сек в пике. Опускайте подконтрольно.\n\nКлючи: единственное упражнение, прицельно изолирующее квадрицепс. Не дёргайте.",
            videoUrl: ytSearch("leg extension technique")
        ),
        LibraryExercise(
            name: "Сгибание ног лежа",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: лёжа животом на скамье тренажёра, валик на нижней части голени.\n\nДвижение: сгибайте ноги, приводя пятки к ягодицам. Удерживайте 1 сек в пике.\n\nКлючи: акцент на коротких головках бицепса бедра. Не отрывайте таз от скамьи.",
            videoUrl: ytSearch("lying leg curl technique")
        ),
        LibraryExercise(
            name: "Сгибание ног сидя",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: сядьте в тренажёр, бёдра под валиком, голени на нижнем валике.\n\nДвижение: сгибайте ноги в коленях, приводя голени под скамью.\n\nКлючи: положение с растяжением бицепса бедра — даёт лучшую гипертрофию по последним исследованиям.",
            videoUrl: ytSearch("seated leg curl technique")
        ),
        LibraryExercise(
            name: "Сгибание ног стоя",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: стоя в тренажёре, одна нога зацеплена за валик.\n\nДвижение: сгибайте ногу, приводя пятку к ягодице. Меняйте ногу.\n\nКлючи: унилатеральная нагрузка — устраняет дисбаланс. Хорошая альтернатива при отсутствии тренажёра лёжа.",
            videoUrl: ytSearch("standing leg curl technique")
        ),
        LibraryExercise(
            name: "Нордическое сгибание",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .repsOnly,
            technique: "Старт: на коленях, стопы зафиксированы партнёром или тренажёром. Корпус прямой.\n\nДвижение: медленно опускайтесь вперёд, удерживая корпус прямым только за счёт бицепса бедра. У пола опускайтесь на руки.\n\nКлючи: одно из лучших упражнений против травм бицепса бедра. Очень тяжёлое — начинайте с малых амплитуд.",
            videoUrl: ytSearch("nordic curl technique")
        ),
        LibraryExercise(
            name: "Обратный Нордик",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: на коленях, корпус вертикален, стопы свободно.\n\nДвижение: отклоняйтесь назад, удерживая прямую линию от колен до плеч за счёт квадрицепсов. Возврат вперёд.\n\nКлючи: сильно нагружает прямую мышцу бедра. Не для слабых коленей.",
            videoUrl: ytSearch("reverse nordic curl technique")
        ),
        LibraryExercise(
            name: "Ягодичный мост (Hip Thrust)",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: лопатки на скамье, штанга на тазу (с подушкой), стопы на ширине таза в 30 см от таза.\n\nДвижение: разгибайте таз вверх до прямой линии корпус-бёдра. Сжимайте ягодицы в верхней точке.\n\nКлючи: подбородок к груди — без переразгибания шеи. Бёдра параллельны полу в верхней точке.",
            videoUrl: ytSearch("hip thrust technique")
        ),
        LibraryExercise(
            name: "Ягодичный мост одной ногой",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: как обычный Hip Thrust, но одна нога поднята вверх или скрещена.\n\nДвижение: разгибайте таз одной ногой, удерживая горизонтальное положение.\n\nКлючи: устраняет дисбаланс ягодиц. Без веса или с гантелью на тазу.",
            videoUrl: ytSearch("single leg hip thrust technique")
        ),
        LibraryExercise(
            name: "Подъем таза на мяче",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .repsOnly,
            technique: "Старт: лёжа на спине, пятки на фитболе, руки вдоль тела.\n\nДвижение: поднимите таз, затем подкатите мяч к ягодицам, согнув колени. Разогните, оттолкнув мяч обратно.\n\nКлючи: одновременно тренирует ягодицы и бицепс бедра. Кор стабилизирует.",
            videoUrl: ytSearch("hamstring curl ball technique")
        ),
        LibraryExercise(
            name: "Подъемы на носки стоя",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: в тренажёре или со штангой, носки на платформе, пятки свисают.\n\nДвижение: поднимайтесь максимально высоко на носки. Удерживайте 1 сек. Опускайтесь до растяжения икр.\n\nКлючи: полная амплитуда — главное условие роста. Многосуставные мышцы икр любят высокие повторы (15–20).",
            videoUrl: ytSearch("standing calf raise technique")
        ),
        LibraryExercise(
            name: "Подъемы на носки сидя",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: сидя в тренажёре, валик на нижней части бедра, носки на платформе.\n\nДвижение: поднимайтесь на носки, сжимая икроножные.\n\nКлючи: акцент на камбаловидную мышцу — это даёт ширину икрам. Высокие повторы.",
            videoUrl: ytSearch("seated calf raise technique")
        ),
        LibraryExercise(
            name: "Подъемы на носки в жиме ногами",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: в Leg Press, носки на нижнем краю платформы, пятки свисают. Не разгибайте колени до замыкания.\n\nДвижение: толкайте платформу носками, поднимаясь на пальцы. Опускайтесь до полного растяжения.\n\nКлючи: позволяет максимальную нагрузку на икры. Безопасно для поясницы.",
            videoUrl: ytSearch("leg press calf raise technique")
        ),
        LibraryExercise(
            name: "Отведение ноги в кроссовере",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: манжета на лодыжке, лицом к нижнему блоку. Держитесь за стойку.\n\nДвижение: отведите ногу назад максимально высоко, сжимая ягодицу. Возврат подконтрольно.\n\nКлючи: чистая изоляция большой ягодичной. Нога прямая.",
            videoUrl: ytSearch("cable kickback technique")
        ),
        LibraryExercise(
            name: "Отведение ноги назад в тренажере",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: в тренажёре Glute Kickback, упор на руки. Платформа под рабочей ногой.\n\nДвижение: разгибайте ногу назад против сопротивления, удерживая 1 сек.\n\nКлючи: фиксированная траектория — фокус на ощущении ягодицы.",
            videoUrl: ytSearch("glute kickback machine technique")
        ),
        LibraryExercise(
            name: "Сведение ног в тренажере",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: сядьте в тренажёр, валики с внутренней стороны бёдер.\n\nДвижение: сведите бёдра вместе. Удерживайте 1 сек, разводите подконтрольно.\n\nКлючи: тренирует приводящие мышцы. Не делайте резких рывков.",
            videoUrl: ytSearch("hip adduction machine technique")
        ),
        LibraryExercise(
            name: "Разведение ног в тренажере",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: сядьте, валики с внешней стороны бёдер. Корпус слегка наклонён вперёд для акцента на ягодицы.\n\nДвижение: разведите бёдра против сопротивления. Удерживайте 1 сек.\n\nКлючи: акцентирует среднюю ягодичную, отвечающую за \"капы\" ягодиц.",
            videoUrl: ytSearch("hip abduction machine technique")
        ),
        LibraryExercise(
            name: "Статика у стены (Стульчик)",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: спиной к стене, бёдра параллельны полу, колени под 90°.\n\nДвижение: удерживайте позицию заданное время. Дыхание ровное.\n\nКлючи: изометрическая нагрузка — отлично для выносливости квадрицепсов и реабилитации.",
            videoUrl: ytSearch("wall sit technique")
        ),

        LibraryExercise(
            name: "Hip Thrust в тренажере",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: сядьте в тренажёр для ягодичного моста, валик на бёдрах. Ноги на платформе на ширине таза.\n\nДвижение: толкайте таз вверх, выпрямляя бёдра в одну линию с корпусом. Сожмите ягодицы в верхней точке. Опустите подконтрольно.\n\nКлючи: фиксированная траектория позволяет работать в отказ безопасно. Подходит для прогрессии больших весов.",
            videoUrl: ytSearch("hip thrust machine")
        ),
        LibraryExercise(
            name: "Hip Thrust одной ногой со штангой",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: лопатки на скамье, штанга на тазу. Одна нога в полу, другая поднята или скрещена.\n\nДвижение: толкайте таз вверх через рабочую ногу до полного разгибания бедра. Сожмите ягодицу в верхней точке.\n\nКлючи: устраняет дисбаланс между ягодицами. Используйте лёгкий вес — это сложнее обычного моста.",
            videoUrl: ytSearch("single leg hip thrust barbell")
        ),
        LibraryExercise(
            name: "Выпады назад со штангой",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: штанга на трапециях, ноги на ширине таза.\n\nДвижение: шагните одной ногой назад, опуститесь до 90° в переднем колене. Возврат через переднюю ногу.\n\nКлючи: легче для коленей чем выпады вперёд. Сильнее активирует ягодицы. Колено не уходит за носок.",
            videoUrl: ytSearch("barbell reverse lunge")
        ),
        LibraryExercise(
            name: "Казацкие приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: широкая стойка, носки слегка развёрнуты. Гиря или гантель у груди (по желанию).\n\nДвижение: приседайте на одну ногу, перенося вес. Вторая нога прямая, носок смотрит вверх. Поднимитесь и перейдите на другую сторону.\n\nКлючи: развивает мобильность тазобедренного и силу одной ноги. Контроль глубины — постепенно увеличивайте амплитуду.",
            videoUrl: ytSearch("cossack squat technique")
        ),
        LibraryExercise(
            name: "Приседания с пятками на возвышении",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: пятки на блинах 2.5–5 см или специальной платформе. Штанга на трапециях. Стойка чуть уже плеч.\n\nДвижение: глубокий присед с вертикальным корпусом до полной амплитуды. Поднимайтесь, толкая пол.\n\nКлючи: имитирует фронтальный присед — изолирует квадрицепсы. Идеально для бодибилдеров с тугими голеностопами.",
            videoUrl: ytSearch("cyclist squat heels elevated")
        ),
        LibraryExercise(
            name: "Сплит-присед с передней ногой на возвышении",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: передняя нога на блине 5–10 см, задняя в шаге сзади. Гантели в руках.\n\nДвижение: опускайтесь, сгибая переднее колено в полной амплитуде. Заднее колено почти касается пола.\n\nКлючи: больше амплитуда чем в обычном сплит-приседе — лучшая растяжка квадрицепса. Для ATG-нагрузки.",
            videoUrl: ytSearch("front foot elevated split squat")
        ),
        LibraryExercise(
            name: "Боковое зашагивание на скамью",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: гантели в руках, скамья сбоку. Стойка боком к скамье.\n\nДвижение: боком ставьте ближнюю ногу на скамью, поднимайтесь полностью. Спускайтесь подконтрольно.\n\nКлючи: акцент на средней ягодичной — мышца, отвечающая за стабилизацию таза. Без отскока.",
            videoUrl: ytSearch("lateral step up technique")
        ),
        LibraryExercise(
            name: "Обратные гакк-приседания",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: лицом к платформе гакк-машины, грудь и плечи прижаты к подушкам. Ноги на ширине таза.\n\nДвижение: опускайтесь до 90° в коленях. Поднимайтесь, толкая пятками.\n\nКлючи: акцент на ягодицы и бицепсы бедра, минимум на квадрицепсы. Альтернатива хип-трасту.",
            videoUrl: ytSearch("reverse hack squat technique")
        ),
        LibraryExercise(
            name: "Жим ногами одной ногой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: сядьте в тренажёр, одна нога на платформе по центру. Другая в стороне или у груди.\n\nДвижение: жмите платформу до почти полного разгибания (не блокируйте колено). Опускайте подконтрольно.\n\nКлючи: устраняет дисбаланс. Стопа выше — больше ягодиц, ниже — больше квадрицепсов.",
            videoUrl: ytSearch("single leg press technique")
        ),
        LibraryExercise(
            name: "Glute Ham Raise (GHR)",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .repsOnly,
            technique: "Старт: тренажёр GHR. Подушки под бёдрами, голени между валиками. Корпус параллелен полу.\n\nДвижение: опускайтесь, разгибая колени, до горизонтали или ниже. Поднимайтесь за счёт сгибания коленей.\n\nКлючи: лучшее упражнение для бицепса бедра в коленном сгибании. При слабости — помогайте руками или резиной.",
            videoUrl: ytSearch("glute ham raise technique")
        ),
        LibraryExercise(
            name: "Тяга Кинга на одной ноге",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: рабочая нога стоит, свободная согнута и поднята назад. Гантели в руках.\n\nДвижение: уводите свободную ногу назад, опускаясь как в одноногой румынской тяге, но с касанием пола свободным коленом. Возврат.\n\nКлючи: гибрид RDL и обратного выпада. Без поддержки задней ноги — больше работы для ягодицы рабочей ноги.",
            videoUrl: ytSearch("king deadlift single leg")
        ),
        LibraryExercise(
            name: "Glute Pull-Through на блоке",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: спиной к нижнему блоку, канат между ног, ладони друг к другу. Шаг вперёд для натяжения.\n\nДвижение: уводите таз назад с лёгким сгибом коленей. Канат проходит между ног. Возврат — толкая бёдра вперёд и сжимая ягодицы.\n\nКлючи: отличная альтернатива хип-трасту без скамьи. Концентрация на разгибании бедра.",
            videoUrl: ytSearch("cable pull through glute")
        ),
        LibraryExercise(
            name: "Приседания Пистолетик с поддержкой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: одна нога на полу, другая вытянута вперёд. Держитесь за TRX, столб или стену.\n\nДвижение: опускайтесь на одну ногу до глубокого приседа. Поднимайтесь, помогая руками минимально.\n\nКлючи: обучающая прогрессия к чистому пистолетику. Постепенно уменьшайте опору.",
            videoUrl: ytSearch("assisted pistol squat technique")
        ),
        LibraryExercise(
            name: "Ягодичный мост с резиной",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: лопатки на скамье, штанга или вес на тазу. Резинка вокруг колен, ноги на ширине таза.\n\nДвижение: толкайте таз вверх, активно разводя колени против резинки. Сжимайте ягодицы 1 сек в верхней точке.\n\nКлючи: резинка добавляет работу средней ягодичной. Колени не сходятся внутрь.",
            videoUrl: ytSearch("banded hip thrust technique")
        ),
        LibraryExercise(
            name: "ATG сплит-присед",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: задняя нога на скамье, передняя в большом шаге. Гантели в руках.\n\nДвижение: опускайтесь до полного контакта задней голени с икрой. Колено передней ноги уходит далеко за носок.\n\nКлючи: ATG (Ass-To-Grass) — полная амплитуда для здоровья колена и силы квадрицепса. Для подготовленных.",
            videoUrl: ytSearch("atg split squat full depth")
        ),
        LibraryExercise(
            name: "Приседания на коробку",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: штанга на трапециях. За спиной коробка / скамья / тумба высотой ниже параллели бедра.\n\nДвижение: уводите таз назад и опускайтесь, садясь на коробку с лёгкой паузой 1 сек. Не расслабляйте корпус. Поднимайтесь, толкая пол через пятки.\n\nКлючи: коробка задаёт фиксированную глубину и развивает взрывную силу из мёртвой точки. Классика пауэрлифтинга для гипертрофии ягодиц и задней цепи.",
            videoUrl: nil
        ),

        // MARK: - ПЛЕЧИ

        LibraryExercise(
            name: "Армейский жим",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: штанга на передних дельтах, хват чуть шире плеч. Стойка узкая, ягодицы и пресс напряжены.\n\nДвижение: жмите штангу строго вверх. Когда гриф проходит лоб, голову подайте чуть вперёд. Удерживайте корпус прямым.\n\nКлючи: без раскачки и подседа. Локти под грифом. Дыхание: вдох-удержание-выдох наверху.",
            videoUrl: ytSearch("overhead press technique")
        ),
        LibraryExercise(
            name: "Жим штанги стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: штанга на дельтах, хват шире плеч на 5–10 см. Корпус вертикален.\n\nДвижение: вертикальный жим над головой. В верхней точке трапеции активно тянутся вверх (full lockout).\n\nКлючи: классика силового тренинга. Без читинга — для этого есть швунг.",
            videoUrl: ytSearch("standing barbell press technique")
        ),
        LibraryExercise(
            name: "Жим гантелей сидя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: сидя на скамье со спинкой, гантели на уровне ушей, ладони от себя.\n\nДвижение: жмите гантели вверх и слегка внутрь, не сводя их. Опускайте до уровня ушей.\n\nКлючи: больше амплитуда чем со штангой. Лопатки прижаты к спинке.",
            videoUrl: ytSearch("seated dumbbell press technique")
        ),
        LibraryExercise(
            name: "Жим гантелей стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: гантели на уровне плеч, ладони от себя. Стойка узкая.\n\nДвижение: жмите гантели вверх над головой. Корпус не отклоняется назад.\n\nКлючи: больше работы для кора. Меньше веса по сравнению со штангой, но безопаснее для плеч.",
            videoUrl: ytSearch("standing dumbbell press technique")
        ),
        LibraryExercise(
            name: "Жим Арнольда",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: гантели у груди, ладони к себе.\n\nДвижение: разворачивайте кисти наружу во время жима — в верхней точке ладони от себя. Возврат с обратным разворотом.\n\nКлючи: ротационное движение прорабатывает все три пучка дельты. Любимое упражнение Арнольда.",
            videoUrl: ytSearch("arnold press technique")
        ),
        LibraryExercise(
            name: "Жим из-за головы",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: штанга за головой на трапециях, хват шире плеч. Только при хорошей мобильности плеч.\n\nДвижение: жмите штангу вверх, опускайте за голову до уровня ушей.\n\nКлючи: травмоопасно при плохой мобильности — рассмотрите альтернативы. Используйте малый-средний вес.",
            videoUrl: ytSearch("behind neck press technique")
        ),
        LibraryExercise(
            name: "Жим Z",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: сидя на полу, ноги прямо вперёд. Штанга на дельтах.\n\nДвижение: чистый жим вверх над головой без помощи ног. Опускайте до дельт.\n\nКлючи: исключает помощь ног и кора — самый строгий вертикальный жим. Развивает чистую силу плеч.",
            videoUrl: ytSearch("z press technique")
        ),
        LibraryExercise(
            name: "Жим швунг",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: штанга на дельтах. Стойка узкая.\n\nДвижение: короткий подсед коленями, взрывное разгибание + жим штанги над головой одним движением.\n\nКлючи: позволяет поднять больший вес. Импульс от ног — ключевой момент.",
            videoUrl: ytSearch("push press technique")
        ),
        LibraryExercise(
            name: "Жим Лэндмайн",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: один конец штанги в Лэндмайне. Другой конец на уровне плеча.\n\nДвижение: жмите штангу вверх и вперёд. Корпус слегка отклоняется.\n\nКлючи: щадящая для плеч альтернатива вертикальному жиму. Можно делать одной рукой.",
            videoUrl: ytSearch("landmine press technique")
        ),
        LibraryExercise(
            name: "Махи гантелями в стороны",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: гантели в опущенных руках, локти слегка согнуты. Корпус слегка наклонён вперёд.\n\nДвижение: поднимайте гантели через стороны до уровня плеч, локти выше кистей (\"выливаем кувшин\"). Опускайте подконтрольно.\n\nКлючи: средние дельты любят высокие повторы. Без читинга корпусом. Используйте средний вес.",
            videoUrl: ytSearch("lateral raise technique")
        ),
        LibraryExercise(
            name: "Махи в стороны на блоке",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: блок внизу, рукоять в дальней руке. Стойка боком.\n\nДвижение: поднимайте руку через сторону до уровня плеча. Возврат подконтрольно.\n\nКлючи: постоянное напряжение в нижней точке (где гантели не нагружены). Плавная сила во всей амплитуде.",
            videoUrl: ytSearch("cable lateral raise technique")
        ),
        LibraryExercise(
            name: "Махи сидя",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: сидя на скамье, гантели в руках вдоль корпуса.\n\nДвижение: поднимайте гантели через стороны до уровня плеч.\n\nКлючи: исключает читинг корпусом. Чистая изоляция средних дельт.",
            videoUrl: ytSearch("seated lateral raise technique")
        ),
        LibraryExercise(
            name: "Махи лежа на боку",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: лёжа на боку на скамье или полу, гантель в верхней руке.\n\nДвижение: поднимайте гантель строго вверх до вертикали. Опускайте подконтрольно.\n\nКлючи: уникальное упражнение — нагрузка максимальна в нижней точке (где обычные махи слабы).",
            videoUrl: ytSearch("lying lateral raise technique")
        ),
        LibraryExercise(
            name: "Махи в наклоне",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: корпус наклонён до 45° или ниже. Гантели в опущенных руках, локти слегка согнуты.\n\nДвижение: разводите гантели в стороны до уровня плеч. Локти ведутся вверх.\n\nКлючи: думайте \"свести лопатки\". Не используйте инерцию. Задние дельты любят повторы 12–20.",
            videoUrl: ytSearch("bent over rear delt fly technique")
        ),
        LibraryExercise(
            name: "Махи в наклоне на блоке",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: между двух блоков, рукояти в крест-накрест. Корпус слегка наклонён.\n\nДвижение: разводите руки в стороны через дугу до уровня плеч.\n\nКлючи: постоянное напряжение во всей амплитуде. Лучшее упражнение для задних дельт по электромиографии.",
            videoUrl: ytSearch("cable rear delt fly technique")
        ),
        LibraryExercise(
            name: "Махи перед собой с гантелями",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: гантели в опущенных руках перед бёдрами.\n\nДвижение: поочерёдно или одновременно поднимайте гантели прямо перед собой до уровня плеч.\n\nКлючи: фронтальные дельты получают много нагрузки в жимах — это упражнение скорее добивающее. 10–15 повторов.",
            videoUrl: ytSearch("front raise technique")
        ),
        LibraryExercise(
            name: "Махи перед собой со штангой",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: штанга в опущенных руках, хват на ширине плеч.\n\nДвижение: поднимайте штангу перед собой до уровня плеч.\n\nКлючи: больший вес чем с гантелями. Без раскачки.",
            videoUrl: ytSearch("barbell front raise technique")
        ),
        LibraryExercise(
            name: "Махи перед собой на блоке",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: спиной к нижнему блоку, рукоять между ног.\n\nДвижение: поднимайте рукоять перед собой до уровня плеч.\n\nКлючи: блок даёт постоянное напряжение. Хорошо после жима для добивания.",
            videoUrl: ytSearch("cable front raise technique")
        ),
        LibraryExercise(
            name: "Обратные разведения в тренажере",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: Pec-Deck в обратном положении (грудью к спинке). Хват за рукояти, локти слегка согнуты.\n\nДвижение: разводите руки назад до линии плеч. Удерживайте 1 сек.\n\nКлючи: одна из лучших изоляций задних дельт. Пик сокращения важен.",
            videoUrl: ytSearch("reverse pec deck technique")
        ),
        LibraryExercise(
            name: "Лицевая тяга",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: канат на верхнем блоке, хват сверху ладонями вниз. Стойка прямая, шаг назад.\n\nДвижение: тяните канат к лицу (между бровями), локти выше плеч. В конце — \"двойной бицепс\" с разворотом кистей наружу.\n\nКлючи: упражнение для здоровья плеч и осанки. Делайте в каждой тренировке верха.",
            videoUrl: ytSearch("face pull technique")
        ),
        LibraryExercise(
            name: "Лицевая тяга на кольцах",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .repsOnly,
            technique: "Старт: кольца на уровне головы, корпус наклонён, ноги впереди.\n\nДвижение: тяните корпус к рукам, разводя локти и сводя лопатки.\n\nКлючи: отлично для гимнастов и ОФП. Угол наклона определяет нагрузку.",
            videoUrl: ytSearch("ring face pull technique")
        ),
        LibraryExercise(
            name: "Кубинский жим",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: лёгкие гантели у бёдер.\n\nДвижение: поднимите как тягу к подбородку → разверните гантели наружу (наружная ротация плеча) → жмите вверх → возврат в обратном порядке.\n\nКлючи: укрепляет вращательную манжету. Только лёгкий вес.",
            videoUrl: ytSearch("cuban press technique")
        ),
        LibraryExercise(
            name: "Тяга к подбородку",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: штанга в опущенных руках, хват чуть шире плеч (комфортнее для запястий).\n\nДвижение: тяните штангу к низу груди / подбородку, локти выше кистей.\n\nКлючи: широкий хват — больше дельт, меньше травматичности. Узкий хват чреват импинджментом.",
            videoUrl: ytSearch("upright row technique")
        ),

        LibraryExercise(
            name: "Жим Лэндмайн стоя одной рукой над головой",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: гриф в Лэндмайн-станции, конец у плеча. Стоя, противоположная нога впереди.\n\nДвижение: жмите гриф вверх по диагонали до полного разгибания. Возврат подконтрольный.\n\nКлючи: гибрид жима над головой и лёгкая на плечо траектория. Кор работает как стабилизатор.",
            videoUrl: ytSearch("landmine shoulder press single arm")
        ),
        LibraryExercise(
            name: "Жим гантелей нейтральным хватом сидя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: сидя на скамье 80–90°, гантели у плеч ладонями друг к другу.\n\nДвижение: жмите гантели вверх, удерживая нейтральный хват весь подход. В верхней точке слегка сводите.\n\nКлючи: нейтральный хват щадит плечи — отличный выбор при болях. Активирует передние и средние пучки.",
            videoUrl: ytSearch("neutral grip dumbbell shoulder press")
        ),
        LibraryExercise(
            name: "Тяга к подбородку с гантелями",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: гантели в опущенных руках перед бёдрами, ладони к корпусу.\n\nДвижение: тяните гантели вдоль корпуса вверх, ведя локти в стороны и вверх. До уровня груди или ниже.\n\nКлючи: гантели позволяют большую амплитуду чем штанга и мягче для плеч. Локти не выше плеч.",
            videoUrl: ytSearch("dumbbell upright row")
        ),
        LibraryExercise(
            name: "Y-подъемы лежа на наклонной",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: лёжа животом на наклонной скамье 30°. Лёгкие гантели в опущенных руках, ладони друг к другу.\n\nДвижение: поднимайте руки в форме буквы Y до уровня плеч. Большие пальцы вверх.\n\nКлючи: целит нижние трапеции и задние дельты — критически важные для здоровья плеча. Используйте лёгкий вес.",
            videoUrl: ytSearch("y raise prone incline")
        ),
        LibraryExercise(
            name: "Powell Raise",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: лёжа боком на скамье, верхняя рука с гантелью свисает вниз. Локоть согнут под 90°.\n\nДвижение: поворачивайте гантель вверх дугой, удерживая локоть на одном уровне. Возврат подконтрольный.\n\nКлючи: гибрид внешней ротации и махов в стороны — для здоровья ротаторной манжеты.",
            videoUrl: ytSearch("powell raise technique")
        ),
        LibraryExercise(
            name: "Махи на блоке за спиной",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: стоя боком к нижнему блоку. Рукоять в дальней руке за спиной (рука перед бёдрами противоположной стороны).\n\nДвижение: поднимайте руку в сторону до уровня плеча по дуге.\n\nКлючи: новый угол нагрузки — больше акцент на средние дельты. Постоянное напряжение блока.",
            videoUrl: ytSearch("behind back cable lateral raise")
        ),
        LibraryExercise(
            name: "Подъем блина перед собой",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: блин (10–20 кг) в обеих руках по бокам, хват на 3 и 9 часов.\n\nДвижение: поднимайте блин перед собой до уровня плеч. Опускайте подконтрольно.\n\nКлючи: альтернатива гантелям/штанге. Меньше нагрузки на запястья, лучшее ощущение нагрузки на дельты.",
            videoUrl: ytSearch("plate front raise technique")
        ),
        LibraryExercise(
            name: "Bus Driver (вращение блина)",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .repsOnly,
            technique: "Старт: блин в руках, поднят перед собой на уровне плеч.\n\nДвижение: вращайте блин 90° по часовой стрелке, затем 90° против. Удерживая блин на уровне плеч весь подход.\n\nКлючи: изометрия + вращение — финишер для передних дельт. Используйте небольшой вес.",
            videoUrl: ytSearch("bus driver plate exercise")
        ),
        LibraryExercise(
            name: "Кубинская ротация с гантелями",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: стоя, гантели в опущенных руках, ладони к корпусу.\n\nДвижение: поднимите гантели через стороны на уровень локтей плеч (как тяга к подбородку). Не меняя положение локтей, разверните гантели вверх по дуге. Жим над головой (опционально). Возврат по той же траектории.\n\nКлючи: для здоровья плеч и активации внешних ротаторов. Лёгкий вес — техника важнее.",
            videoUrl: ytSearch("cuban rotation dumbbell")
        ),
        LibraryExercise(
            name: "Тяга к подбородку с канатом на блоке",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: канат на нижнем блоке, хват за концы.\n\nДвижение: тяните канат вверх вдоль корпуса, ведя локти в стороны и вверх. В верхней точке слегка раздвиньте концы.\n\nКлючи: блок даёт постоянное напряжение, канат позволяет естественную траекторию.",
            videoUrl: ytSearch("cable rope upright row")
        ),
        LibraryExercise(
            name: "Египетские махи (Egyptian Lateral Raise)",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: стойка боком к нижнему блоку. Свободной рукой держитесь за стойку и отклоняйтесь от блока, корпус под углом 15–25°. Рукоять в дальней руке поперёк корпуса.\n\nДвижение: поднимайте руку через сторону до уровня плеча или чуть выше, удерживая корпус наклонённым. Опускайте подконтрольно с глубокой растяжкой.\n\nКлючи: наклон корпуса смещает нагрузку в нижнюю фазу амплитуды, где средняя дельта обычно недогружена. Любимое упражнение Майка Израетеля для гипертрофии плеч.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Y-подъёмы на блоке",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: между двух нижних блоков, рукояти в руках перекрёстно (правая в левой, левая в правой). Корпус прямой.\n\nДвижение: разводите руки вверх и в стороны по диагонали, образуя букву Y. В верхней точке большие пальцы смотрят назад. Возврат подконтрольный.\n\nКлючи: целит нижние трапеции и задние дельты — критически важные для здоровой осанки и плеч. Лёгкий вес, медленный темп, концентрация на сокращении.",
            videoUrl: nil
        ),

        // MARK: - РУКИ — БИЦЕПС

        LibraryExercise(
            name: "Подъем штанги на бицепс",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: штанга в опущенных руках, хват на ширине плеч снизу.\n\nДвижение: сгибайте руки, локти прижаты к корпусу. Поднимайте до уровня груди. Опускайте полностью.\n\nКлючи: без раскачки корпусом. Локти не уходят вперёд.",
            videoUrl: ytSearch("barbell curl technique")
        ),
        LibraryExercise(
            name: "Подъем EZ-штанги на бицепс",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: EZ-штанга в опущенных руках, хват в изогнутой части снизу.\n\nДвижение: сгибайте руки до уровня груди.\n\nКлючи: щадит запястья по сравнению с прямой штангой. Чуть меньше нагрузки на бицепс, но сохраняется длительная работа.",
            videoUrl: ytSearch("ez bar curl technique")
        ),
        LibraryExercise(
            name: "Подъем штанги обратным хватом",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: штанга в опущенных руках, хват сверху на ширине плеч.\n\nДвижение: сгибайте руки, удерживая запястья прямыми.\n\nКлючи: акцент на брахиалис и предплечья. Используйте умеренный вес — кисти будут уставать.",
            videoUrl: ytSearch("reverse curl technique")
        ),
        LibraryExercise(
            name: "Подъем гантелей на бицепс сидя",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: сидя на скамье под наклоном 60–75° или прямой. Гантели в опущенных руках.\n\nДвижение: сгибайте руки с супинацией (разворот ладоней вверх).\n\nКлючи: исключает читинг корпусом. Полная амплитуда.",
            videoUrl: ytSearch("seated dumbbell curl technique")
        ),
        LibraryExercise(
            name: "Подъем гантелей на бицепс стоя",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: гантели в руках, ладони к корпусу.\n\nДвижение: сгибайте руки, разворачивая ладони вверх к концу движения (супинация).\n\nКлючи: супинация — ключ к максимальному сокращению. Локти прижаты.",
            videoUrl: ytSearch("alternating dumbbell curl technique")
        ),
        LibraryExercise(
            name: "Подъем гантелей на наклонной скамье",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: сидя на наклонной скамье 45–60°. Гантели свисают с супинированным хватом.\n\nДвижение: сгибайте руки, удерживая локти за линией корпуса.\n\nКлючи: максимальное растяжение длинной головки бицепса — лучший стимул для гипертрофии по последним исследованиям.",
            videoUrl: ytSearch("incline dumbbell curl technique")
        ),
        LibraryExercise(
            name: "Молотки",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: гантели в руках, нейтральный хват (ладони друг к другу).\n\nДвижение: сгибайте руки, удерживая нейтральный хват. Не разворачивайте кисти.\n\nКлючи: целит брахиалис (под бицепсом — даёт толщину руки) и плечелучевую.",
            videoUrl: ytSearch("hammer curl technique")
        ),
        LibraryExercise(
            name: "Молотки с канатом",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: канат на нижнем блоке, хват за концы каната нейтральный.\n\nДвижение: сгибайте руки до уровня груди. В верхней точке слегка раздвиньте концы каната.\n\nКлючи: блок даёт постоянное напряжение и в верхней, и в нижней точке.",
            videoUrl: ytSearch("hammer curl rope technique")
        ),
        LibraryExercise(
            name: "Сгибания на скамье Скотта",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: руки лежат на пюпитре скамьи Скотта, EZ-штанга или гантели в руках.\n\nДвижение: сгибайте руки до уровня груди. Опускайте до полного выпрямления (но не блокируйте локти).\n\nКлючи: исключает читинг. Больший упор на короткую головку бицепса.",
            videoUrl: ytSearch("preacher curl technique")
        ),
        LibraryExercise(
            name: "Сгибание паука",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: лёжа животом на наклонной скамье или скамье Скотта вертикальной стороной. Руки свисают вертикально.\n\nДвижение: сгибайте руки, удерживая локти неподвижными.\n\nКлючи: максимальная изоляция короткой головки. Никакого читинга.",
            videoUrl: ytSearch("spider curl technique")
        ),
        LibraryExercise(
            name: "Сгибания Зоттмана",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: гантели в руках, ладони от себя.\n\nДвижение: подъем как обычное сгибание. Вверху — разверните кисти ладонями от себя. Опускайте обратным хватом.\n\nКлючи: в одном повторе работает и бицепс (на подъёме), и предплечья (на опускании).",
            videoUrl: ytSearch("zottman curl technique")
        ),
        LibraryExercise(
            name: "Байезианские сгибания",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: спиной к нижнему блоку. Рукоять в одной руке, рука отведена назад за линию корпуса.\n\nДвижение: сгибайте руку в полной амплитуде, удерживая локоть позади корпуса.\n\nКлючи: упражнение работает в положении максимального растяжения длинной головки — даёт сильнейший стимул роста.",
            videoUrl: ytSearch("bayesian cable curl technique")
        ),
        LibraryExercise(
            name: "Концентрированные сгибания",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: сидя на скамье, локоть упирается во внутреннюю сторону бедра. Гантель в руке.\n\nДвижение: сгибайте руку, удерживая локоть на бедре.\n\nКлючи: пиковое сокращение наверху — максимальная активация бицепса по электромиографии.",
            videoUrl: ytSearch("concentration curl technique")
        ),
        LibraryExercise(
            name: "Сгибания в кроссовере",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: рукоять (прямая или EZ) на нижнем блоке.\n\nДвижение: сгибайте руки до уровня груди. Локти прижаты к корпусу.\n\nКлючи: постоянное напряжение во всей амплитуде. Идеально для добивающего сета.",
            videoUrl: ytSearch("cable curl technique")
        ),
        LibraryExercise(
            name: "Сгибания в тренажере",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: сядьте в тренажёр для бицепса, руки на пюпитре.\n\nДвижение: сгибайте руки против сопротивления. Контролируйте опускание.\n\nКлючи: безопасный путь к отказу. Хорош для дроп-сетов.",
            videoUrl: ytSearch("machine bicep curl technique")
        ),

        LibraryExercise(
            name: "Перекрёстный подъем гантелей на бицепс",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: стоя, гантели в опущенных руках, ладони к корпусу (нейтральный хват).\n\nДвижение: согните руку, ведя гантель по диагонали к противоположному плечу (поперёк корпуса). Удерживайте локоть прижатым к боку. Опустите подконтрольно. Чередуйте руки.\n\nКлючи: изоляция плечелучевой мышцы и брахиалиса. Сильнее работает короткая головка бицепса. Без раскачки корпусом.",
            videoUrl: ytSearch("cross body hammer curl")
        ),
        LibraryExercise(
            name: "Drag Curl со штангой",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: штанга в опущенных руках, хват на ширине плеч снизу.\n\nДвижение: сгибайте руки, удерживая штангу как можно ближе к корпусу — гриф буквально \"скользит\" вверх по бёдрам и животу. Локти уходят назад.\n\nКлючи: убирает работу передних дельт — изолирует бицепс. Работа с меньшим весом, но с большей активацией.",
            videoUrl: ytSearch("drag curl barbell")
        ),
        LibraryExercise(
            name: "Обратные сгибания на скамье Скотта",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: руки на пюпитре скамьи Скотта, EZ-штанга в руках хватом сверху.\n\nДвижение: сгибайте руки до уровня груди. Опускайте подконтрольно до полного выпрямления.\n\nКлючи: изоляция брахиалиса и плечелучевой. Используйте лёгкий вес — кисти быстро устанут.",
            videoUrl: ytSearch("reverse preacher curl")
        ),
        LibraryExercise(
            name: "Подъем штанги широким хватом",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: штанга в руках, хват шире плеч снизу.\n\nДвижение: сгибайте руки до уровня груди, локти прижаты.\n\nКлючи: широкий хват акцентирует короткую головку бицепса (внутренняя часть). Альтернатива классическому хвату для разнообразия.",
            videoUrl: ytSearch("wide grip barbell curl")
        ),
        LibraryExercise(
            name: "Обратные сгибания на блоке",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: прямая рукоять на нижнем блоке. Хват сверху на ширине плеч.\n\nДвижение: сгибайте руки до уровня груди. Опускайте подконтрольно.\n\nКлючи: постоянное напряжение блока + хват сверху = акцент на брахиалис и предплечья.",
            videoUrl: ytSearch("reverse cable curl")
        ),
        LibraryExercise(
            name: "Сгибания Скотта на блоке",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: скамья Скотта перед нижним блоком. EZ-рукоять в руках хватом снизу.\n\nДвижение: сгибайте руки до уровня груди, удерживая локти на пюпитре. Опускайте до почти полного выпрямления.\n\nКлючи: изоляция короткой головки + постоянное напряжение блока. Идеально для пампинга.",
            videoUrl: ytSearch("preacher cable curl")
        ),
        LibraryExercise(
            name: "Cheat Curl (читинг)",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: штанга в руках с весом на 10–20% больше рабочего, хват на ширине плеч снизу.\n\nДвижение: лёгким импульсом коленями выведите штангу до уровня груди. Опускайте СТРОГО подконтрольно за 3–4 секунды.\n\nКлючи: техника продвинутых для пробивания плато. Акцент на эксцентрической фазе. Не перебарщивайте с импульсом.",
            videoUrl: ytSearch("cheat curl technique")
        ),
        LibraryExercise(
            name: "21-ки (21s) на бицепс",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: штанга в руках хватом снизу.\n\nДвижение: 7 повторений нижней половины амплитуды (от старта до 90°). Без отдыха — 7 повторений верхней половины (от 90° до груди). Без отдыха — 7 полных повторений.\n\nКлючи: 21 повторение в подходе для шокирующего пампинга. Используйте вес на 40–50% от 1ПМ.",
            videoUrl: ytSearch("21s biceps curl")
        ),

        // MARK: - РУКИ — ТРИЦЕПС

        LibraryExercise(
            name: "Жим узким хватом",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: лёжа на скамье, штанга в руках, хват на ширине плеч (не уже!).\n\nДвижение: опускайте штангу к нижней части груди, локти прижаты к корпусу. Жмите вверх.\n\nКлючи: ширина хвата как ширина плеч — оптимум для трицепса. Уже хват чреват травмой запястья.",
            videoUrl: ytSearch("close grip bench press technique")
        ),
        LibraryExercise(
            name: "Жим узким хватом в Смите",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: скамья по центру тренажёра Смита, хват на ширине плеч.\n\nДвижение: опускайте к нижней части груди, локти прижаты. Жмите по фиксированной траектории.\n\nКлючи: безопасная альтернатива со свободным весом. Можно работать в отказ.",
            videoUrl: ytSearch("smith close grip bench technique")
        ),
        LibraryExercise(
            name: "Французский жим",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: лёжа на скамье, EZ-штанга на вытянутых руках над грудью.\n\nДвижение: сгибайте руки в локтях, опуская штангу за голову (не ко лбу!). Локти направлены вверх.\n\nКлючи: опускание за голову даёт максимальное растяжение длинной головки трицепса. Не разводите локти.",
            videoUrl: ytSearch("skull crusher technique")
        ),
        LibraryExercise(
            name: "Французский жим сидя со штангой",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: сидя на скамье, EZ-штанга над головой на прямых руках.\n\nДвижение: опускайте штангу за голову, локти направлены вверх и слегка вперёд.\n\nКлючи: позиция растянутой длинной головки даёт лучший стимул. Контроль опускания.",
            videoUrl: ytSearch("seated overhead tricep extension technique")
        ),
        LibraryExercise(
            name: "Французский жим с гантелью стоя",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: стоя, одна гантель в обеих руках над головой.\n\nДвижение: опускайте гантель за голову, удерживая локти у ушей.\n\nКлючи: универсальная вариация — можно делать дома. Локти не разводите.",
            videoUrl: ytSearch("overhead dumbbell extension technique")
        ),
        LibraryExercise(
            name: "Французский жим из-за головы с гантелью",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: гантель в одной руке над головой, локоть у уха.\n\nДвижение: опускайте гантель за голову, удерживая локоть неподвижным.\n\nКлючи: унилатерально — устраняет дисбаланс. Полная амплитуда.",
            videoUrl: ytSearch("one arm overhead extension technique")
        ),
        LibraryExercise(
            name: "Тейт-пресс",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: лёжа на скамье, гантели на вытянутых руках над грудью, ладони к ногам.\n\nДвижение: опускайте гантели к груди, разводя локти в стороны. Сгибание происходит только в локте.\n\nКлючи: акцент на медиальную и латеральную головки. Без помощи длинной головки.",
            videoUrl: ytSearch("tate press technique")
        ),
        LibraryExercise(
            name: "Разгибание рук на блоке",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: стоя у вертикального блока, рукоять (прямая, V или канат) в руках. Локти прижаты к корпусу.\n\nДвижение: разгибайте руки строго вниз. В нижней точке слегка задерживайте.\n\nКлючи: плечи неподвижны — двигаются только локти. Без раскачки корпусом.",
            videoUrl: ytSearch("tricep pushdown technique")
        ),
        LibraryExercise(
            name: "Разгибание рук на блоке с канатом",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: канат на верхнем блоке, хват за концы.\n\nДвижение: разгибайте руки вниз. В нижней точке разведите концы каната в стороны для пикового сокращения.\n\nКлючи: разведение концов даёт лучшую активацию латеральной головки.",
            videoUrl: ytSearch("rope pushdown technique")
        ),
        LibraryExercise(
            name: "Разгибание рук на блоке обратным хватом",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: рукоять на верхнем блоке, хват супинированный (ладонями к себе).\n\nДвижение: разгибайте руки вниз, удерживая локти прижатыми.\n\nКлючи: акцент на медиальную головку трицепса. Меньший вес чем с обычным хватом.",
            videoUrl: ytSearch("reverse grip pushdown technique")
        ),
        LibraryExercise(
            name: "Разгибания на блоке из-за головы",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: спиной к нижнему блоку, рукоять (канат или EZ) над головой. Шаг вперёд.\n\nДвижение: разгибайте руки, удерживая локти неподвижными у головы.\n\nКлючи: позиция растянутой длинной головки + постоянное напряжение блока = двойной стимул.",
            videoUrl: ytSearch("overhead cable extension technique")
        ),
        LibraryExercise(
            name: "Разгибание руки в наклоне с гантелью",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: упор коленом и рукой в скамью, гантель в свободной руке. Локоть прижат к корпусу, плечо параллельно полу.\n\nДвижение: разгибайте руку назад до полного выпрямления. Удерживайте 1 сек.\n\nКлючи: пиковое сокращение в верхней точке. Не двигайте плечо — только локоть.",
            videoUrl: ytSearch("tricep kickback technique")
        ),
        LibraryExercise(
            name: "Обратные отжимания от скамьи",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .repsOnly,
            technique: "Старт: руки на скамье позади, ноги впереди прямые или согнутые.\n\nДвижение: опускайте таз вниз, сгибая руки. Локти строго назад. Поднимайтесь, не разводя локти.\n\nКлючи: не опускайтесь слишком глубоко (риск для плечевых). Не уводите таз далеко от скамьи.",
            videoUrl: ytSearch("bench dip technique")
        ),
        LibraryExercise(
            name: "Отжимания на брусьях узким хватом",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .repsOnly,
            technique: "Старт: упор на узких брусьях. Корпус вертикален, ноги согнуты.\n\nДвижение: опускайтесь, локти прижаты вдоль корпуса. Поднимайтесь до полного разгибания.\n\nКлючи: вертикальный корпус — главное условие нагрузки на трицепс. Лучшее упражнение для массонабора рук.",
            videoUrl: ytSearch("dips for triceps technique")
        ),

        LibraryExercise(
            name: "Разгибание на трицепс",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: стоя у вертикального блока, прямая или V-рукоять в руках. Локти прижаты к корпусу, корпус слегка наклонён вперёд.\n\nДвижение: разгибайте руки вниз до полного выпрямления. В нижней точке слегка задерживайтесь для пикового сокращения. Возврат подконтрольный до 90°.\n\nКлючи: универсальная вариация для всех уровней. Плечи неподвижны — двигаются только локти. Без раскачки корпусом.",
            videoUrl: ytSearch("tricep extension cable")
        ),
        LibraryExercise(
            name: "JM-press",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: лёжа на скамье, штанга в руках, хват на ширине плеч.\n\nДвижение: гибрид жима узким хватом и французского. Опускайте штангу к верхней части груди, локти под 45°. На середине пути сгибайте локти больше, чтобы штанга шла к шее. Жмите по обратной траектории.\n\nКлючи: изобретено пауэрлифтером JM Blakley. Позволяет работать с большими весами для трицепса. Только для опытных.",
            videoUrl: ytSearch("jm press technique")
        ),
        LibraryExercise(
            name: "Французский жим с пола",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: лёжа на полу, EZ-штанга на вытянутых руках над грудью.\n\nДвижение: опускайте штангу за голову, локти направлены вверх. Касание локтями пола — пауза 1 сек. Жмите вверх.\n\nКлючи: пол ограничивает амплитуду — щадит локти. Хорош для прогрессии при болях.",
            videoUrl: ytSearch("floor skull crusher")
        ),
        LibraryExercise(
            name: "Однорукое разгибание на блоке",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: рукоять (D-handle) на верхнем блоке, в одной руке. Свободная рука у пояса.\n\nДвижение: разгибайте руку строго вниз до полного выпрямления. Удержите 1 сек.\n\nКлючи: унилатеральная работа — устраняет дисбаланс. Концентрация на пиковом сокращении.",
            videoUrl: ytSearch("single arm pushdown technique")
        ),
        LibraryExercise(
            name: "Cross-body разгибание трицепса с гантелью",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: лёжа на скамье, гантель в одной руке над грудью. Свободная рука держит локоть рабочей.\n\nДвижение: опускайте гантель к противоположному плечу, удерживая локоть фиксированным. Разгибайте до полного выпрямления.\n\nКлючи: новый угол растяжения длинной головки. Используйте лёгкий вес.",
            videoUrl: ytSearch("cross body tricep extension")
        ),
        LibraryExercise(
            name: "California Press",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: лёжа на скамье, гантели в руках на уровне груди, ладони друг к другу.\n\nДвижение: опускайте гантели к нижней части груди (как сгибание). На середине пути выводите гантели вперёд и жмите как французский жим. Возврат по той же траектории.\n\nКлючи: гибрид жима и французского. Сильно нагружает все три головки трицепса.",
            videoUrl: ytSearch("california press technique")
        ),
        LibraryExercise(
            name: "Разгибание трицепса в тренажере",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: сядьте в тренажёр, спина прижата, предплечья на подушках. Хват за рукояти.\n\nДвижение: разгибайте руки против сопротивления. Удержите 1 сек в нижней точке.\n\nКлючи: стабильная траектория позволяет работать в отказ. Идеально для дроп-сетов.",
            videoUrl: ytSearch("tricep extension machine")
        ),
        LibraryExercise(
            name: "Отжимания на брусьях в гравитроне",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: коленями на платформу гравитрона, упор на брусьях. Корпус вертикален.\n\nДвижение: опускайтесь, локти вдоль корпуса. Поднимайтесь до полного разгибания.\n\nКлючи: ассистированная версия отжиманий на брусьях. Идеально для прогрессии или объёмной работы. Постепенно уменьшайте помощь.",
            videoUrl: ytSearch("assisted dip machine")
        ),
        LibraryExercise(
            name: "Сгибания на бицепс на блоке одной рукой",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: стоя боком к нижнему блоку, рукоять в дальней руке. Локоть прижат к корпусу.\n\nДвижение: сгибайте руку, разворачивая ладонь к плечу (супинация). В верхней точке пиковое напряжение 1 секунду. Опускайте подконтрольно до полного выпрямления.\n\nКлючи: унилатеральная работа устраняет дисбаланс между руками. Постоянное напряжение блока во всей амплитуде.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Французский жим EZ-штанги лёжа",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: лёжа на скамье, EZ-штанга на вытянутых руках, чуть наклонена к голове (под углом 75–80°). Хват в изогнутой части сверху.\n\nДвижение: сгибайте локти, опуская штангу ко лбу или чуть за голову. Локти удерживайте неподвижными. Разгибайте до старта.\n\nКлючи: Skullcrusher — классика для длинной головки трицепса. EZ-гриф щадит запястья. Локти не разводите в стороны.",
            videoUrl: nil
        ),

        // MARK: - РУКИ — ПРЕДПЛЕЧЬЯ

        LibraryExercise(
            name: "Сгибание кистей со штангой",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: сидя, предплечья на коленях, кисти свисают со штангой ладонями вверх.\n\nДвижение: сгибайте кисти максимально вверх. В нижней точке слегка раскрывайте ладони.\n\nКлючи: высокие повторы (15–25). Полная амплитуда.",
            videoUrl: ytSearch("wrist curl technique")
        ),
        LibraryExercise(
            name: "Сгибание кистей за спиной",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: стоя, штанга за спиной в опущенных руках хватом снизу.\n\nДвижение: сгибайте кисти, поднимая штангу.\n\nКлючи: уникальный угол нагрузки — отлично прорабатывает предплечья.",
            videoUrl: ytSearch("behind back wrist curl technique")
        ),
        LibraryExercise(
            name: "Разгибание кистей со штангой",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: предплечья на коленях, кисти свисают ладонями вниз.\n\nДвижение: разгибайте кисти максимально вверх.\n\nКлючи: тренирует разгибатели кисти — критично для здоровья локтей и борьбы с эпикондилитом.",
            videoUrl: ytSearch("reverse wrist curl technique")
        ),
        LibraryExercise(
            name: "Удержание блина",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .duration,
            technique: "Старт: блин (5–20 кг) в опущенной руке, удерживается за гладкую плоскость пальцами.\n\nДвижение: удерживайте максимально долго.\n\nКлючи: развивает хват и предплечья. Меняйте руки.",
            videoUrl: ytSearch("plate pinch grip technique")
        ),

        LibraryExercise(
            name: "Сжатие гриппера",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .repsOnly,
            technique: "Старт: гриппер в одной руке, ручки в ладони и пальцах.\n\nДвижение: сжимайте гриппер до полного смыкания ручек. Удержите 1–2 сек. Контролируйте раскрытие.\n\nКлючи: основное упражнение для силы хвата. Прогрессия — переход на более жёсткие модели (Captains of Crush и аналоги).",
            videoUrl: ytSearch("gripper hand training")
        ),
        LibraryExercise(
            name: "Wrist Roller (катушка с весом)",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .repsOnly,
            technique: "Старт: специальная палка с верёвкой и весом. Держите палку на вытянутых руках перед собой.\n\nДвижение: вращая палку поочерёдно кистями, поднимайте вес до палки. Затем подконтрольно опускайте.\n\nКлючи: сильнейший пампинг предплечий. Развивает выносливость хвата.",
            videoUrl: ytSearch("wrist roller forearm")
        ),
        LibraryExercise(
            name: "Щепотный хват блина",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: блин в опущенной руке, держите за гладкий край пальцами и большим пальцем (как щепотка).\n\nДвижение: удерживайте на время или ходите с блинами в обеих руках.\n\nКлючи: развивает силу пальцев — критично для борцов, скалолазов, силачей. Постепенно увеличивайте вес.",
            videoUrl: ytSearch("plate pinch grip hold")
        ),
        LibraryExercise(
            name: "Сгибание кистей за спиной со штангой",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: штанга за спиной в опущенных руках. Хват сверху на ширине плеч.\n\nДвижение: сгибайте кисти, поднимая штангу как можно выше за спиной.\n\nКлючи: уникальный угол нагрузки на сгибатели предплечья. Лёгкий вес — приоритет техника.",
            videoUrl: ytSearch("behind back wrist curl")
        ),
        LibraryExercise(
            name: "Hammer Hold (удержание молотка)",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: гантель в руке за один край (вертикально). Тяжёлая сторона направлена вниз.\n\nДвижение: удерживайте гантель в этом положении 30–60 сек.\n\nКлючи: тренирует силу хвата и стабилизаторы запястья. Меняйте стороны.",
            videoUrl: ytSearch("hammer hold forearm")
        ),

        // MARK: - КОР

        LibraryExercise(
            name: "Планка",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: упор лёжа на предплечьях, тело — прямая линия. Локти под плечами.\n\nДвижение: удерживайте позицию, напрягая пресс, ягодицы, ноги.\n\nКлючи: без провисания таза или поднимания. Дыхание ровное. Качество важнее времени.",
            videoUrl: ytSearch("plank technique")
        ),
        LibraryExercise(
            name: "Боковая планка",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: упор на предплечье на боку, ноги вытянуты, верхняя нога на нижней.\n\nДвижение: удерживайте корпус прямой линией. Таз поднят.\n\nКлючи: тренирует косые мышцы. Меняйте стороны.",
            videoUrl: ytSearch("side plank technique")
        ),
        LibraryExercise(
            name: "Копенгагенская планка",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: лёжа на боку, верхняя нога на скамье (на уровне колена или щиколотки). Упор на предплечье.\n\nДвижение: поднимите таз до прямой линии тела за счёт верхней ноги.\n\nКлючи: жёсткая нагрузка на приводящие и косые. Профилактика травм паха.",
            videoUrl: ytSearch("copenhagen plank technique")
        ),
        LibraryExercise(
            name: "Подъем ног в висе",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: вис на перекладине, лопатки активны.\n\nДвижение: поднимайте прямые или согнутые ноги до уровня таза, подкручивая таз вверх в верхней точке.\n\nКлючи: подкрут таза = работа пресса. Без раскачки — контролируемый темп.",
            videoUrl: ytSearch("hanging leg raise technique")
        ),
        LibraryExercise(
            name: "Подъем ног в упоре",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: упор предплечьями на брусьях, ноги свисают.\n\nДвижение: поднимайте ноги к груди, подкручивая таз.\n\nКлючи: легче чем в висе — отлично для прогрессии.",
            videoUrl: ytSearch("captains chair leg raise technique")
        ),
        LibraryExercise(
            name: "Подъем ног лежа",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: лёжа на спине, руки вдоль корпуса или под ягодицами.\n\nДвижение: поднимайте прямые ноги до вертикали. Опускайте подконтрольно, не касаясь пола.\n\nКлючи: поясница прижата к полу. Если не удаётся — согните колени.",
            videoUrl: ytSearch("lying leg raise technique")
        ),
        LibraryExercise(
            name: "Подъем ног к перекладине (Toes to Bar)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: вис на перекладине.\n\nДвижение: поднимайте ноги до касания перекладины носками. Контролируемое опускание.\n\nКлючи: продвинутая версия — требует мобильности и силы пресса. Можно делать в стиле \"кип\" для CrossFit.",
            videoUrl: ytSearch("toes to bar technique")
        ),
        LibraryExercise(
            name: "Скручивания",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: лёжа на спине, колени согнуты, стопы на полу. Руки у висков.\n\nДвижение: подкрутите таз, поднимая лопатки от пола (не более чем на 30°). Сожмите пресс.\n\nКлючи: это не подъем туловища — нужно подкрутить таз. Поясница не отрывается.",
            videoUrl: ytSearch("crunch technique")
        ),
        LibraryExercise(
            name: "Обратные скручивания",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: лёжа на спине, колени к груди, руки вдоль корпуса.\n\nДвижение: подкрутите таз, поднимая ягодицы и приближая колени к груди.\n\nКлючи: акцент на нижнюю часть пресса. Без раскачки.",
            videoUrl: ytSearch("reverse crunch technique")
        ),
        LibraryExercise(
            name: "Скручивания на блоке",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: на коленях перед верхним блоком, канат за головой. Бёдра вертикальны.\n\nДвижение: подкручивайте корпус вниз, приближая локти к коленям. Бёдра не двигаются.\n\nКлючи: позволяет работать с прогрессией веса. Округлите спину при сокращении.",
            videoUrl: ytSearch("cable crunch technique")
        ),
        LibraryExercise(
            name: "Скручивания в тренажере",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: сядьте в тренажёр Ab Crunch, руки за рукоятями.\n\nДвижение: скручивайте корпус вниз против сопротивления.\n\nКлючи: безопасный путь к гипертрофии пресса с прогрессирующей нагрузкой.",
            videoUrl: ytSearch("ab crunch machine technique")
        ),
        LibraryExercise(
            name: "Складочка (V-Ups)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: лёжа на спине, ноги прямые, руки вытянуты за голову.\n\nДвижение: одновременно поднимите ноги и корпус, тянитесь руками к стопам.\n\nКлючи: единое движение — образуется V-форма. Сохраняйте баланс.",
            videoUrl: ytSearch("v ups technique")
        ),
        LibraryExercise(
            name: "Велосипед",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: лёжа, руки у висков, ноги подняты под 90°.\n\nДвижение: поочерёдно тянитесь локтем к противоположному колену, имитируя велосипед.\n\nКлючи: работает прямая и косые мышцы. Контроль, не скорость.",
            videoUrl: ytSearch("bicycle crunch technique")
        ),
        LibraryExercise(
            name: "Русский твист",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: сидя, корпус откинут до 45°, ноги приподняты. Гантель / медбол в руках.\n\nДвижение: поворачивайте корпус из стороны в сторону, касаясь снаряда пола.\n\nКлючи: работает за счёт корпуса, не рук. Ноги не дёргаются.",
            videoUrl: ytSearch("russian twist technique")
        ),
        LibraryExercise(
            name: "Ролик для пресса",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: на коленях, ролик в руках перед собой.\n\nДвижение: катите ролик вперёд, удерживая прямой корпус. До максимально низкого положения. Возврат за счёт пресса.\n\nКлючи: одно из самых тяжёлых упражнений для пресса. Без провисания таза.",
            videoUrl: ytSearch("ab wheel technique")
        ),
        LibraryExercise(
            name: "Уголок (L-Sit)",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: сидя на полу или на параллетках, руки прямые, упор в пол.\n\nДвижение: оторвите ягодицы и ноги от пола. Удерживайте L-форму.\n\nКлючи: гимнастический навык. Прогрессия от согнутых колен к прямым ногам.",
            videoUrl: ytSearch("l sit technique")
        ),
        LibraryExercise(
            name: "Уголок на брусьях",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: упор на брусьях, руки прямые.\n\nДвижение: поднимите прямые ноги до уровня таза. Удерживайте.\n\nКлючи: тяжелее L-Sit на полу. Требует сильного хвата и пресса.",
            videoUrl: ytSearch("l sit dip bar technique")
        ),
        LibraryExercise(
            name: "Вакуум",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: стоя или на коленях, наклонитесь чуть вперёд.\n\nДвижение: полный выдох → втяните живот максимально внутрь и вверх. Удерживайте 15–30 сек.\n\nКлючи: тренирует поперечную мышцу — даёт визуально плоский живот. Делайте утром натощак.",
            videoUrl: ytSearch("stomach vacuum technique")
        ),
        LibraryExercise(
            name: "Прогулка фермера",
            category: .core,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: тяжёлые гантели или гири в опущенных руках. Корпус напряжён, плечи расправлены.\n\nДвижение: идите мелкими шагами заданное расстояние или время.\n\nКлючи: тренирует хват, кор, трапеции, ноги. Не сутультесь — гордая осанка.",
            videoUrl: ytSearch("farmers walk technique")
        ),
        LibraryExercise(
            name: "Анти-ротация на блоке",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: боком к блоку, рукоять прижата к груди. Стойка стабильна.\n\nДвижение: вытяните руки вперёд, не позволяя корпусу повернуться к блоку. Удерживайте 2 сек. Возврат.\n\nКлючи: тренирует анти-ротационную силу кора — критично для здоровой поясницы.",
            videoUrl: ytSearch("pallof press technique")
        ),
        LibraryExercise(
            name: "Прогулка медведя",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: на четвереньках, колени над землёй на 5 см. Спина прямая.\n\nДвижение: шагайте вперёд, продвигая противоположную руку и ногу одновременно. Колени не касаются пола.\n\nКлючи: жёсткая стабилизация кора. Не виляйте тазом.",
            videoUrl: ytSearch("bear crawl technique")
        ),
        LibraryExercise(
            name: "Удержание угла",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: лёжа на спине, ноги прямые, руки за голову.\n\nДвижение: одновременно оторвите от пола ноги и плечи, удерживая прямой корпус.\n\nКлючи: изометрическая нагрузка на пресс. Дыхание ровное.",
            videoUrl: ytSearch("hollow hold technique")
        ),
        LibraryExercise(
            name: "Перекрестные скручивания",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: лёжа, руки за голову, ноги согнуты.\n\nДвижение: тянитесь правым локтем к левому колену и наоборот.\n\nКлючи: работают косые мышцы. Без рывков шеей.",
            videoUrl: ytSearch("cross body crunch technique")
        ),
        LibraryExercise(
            name: "Dead Bug (Жук)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: лёжа на спине, руки вверх, ноги под 90°.\n\nДвижение: одновременно опустите противоположные руку и ногу, не отрывая поясницу. Возврат.\n\nКлючи: одно из самых функциональных упражнений для кора. Поясница прижата.",
            videoUrl: ytSearch("dead bug technique")
        ),
        LibraryExercise(
            name: "Bird Dog (Птица-собака)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: на четвереньках, руки под плечами, колени под тазом.\n\nДвижение: вытяните противоположные руку и ногу до прямой линии. Удерживайте 2 сек.\n\nКлючи: тренирует кор и поясницу. Не разворачивайте таз.",
            videoUrl: ytSearch("bird dog technique")
        ),
        LibraryExercise(
            name: "Hollow Body Hold",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: лёжа на спине, поясница прижата.\n\nДвижение: оторвите ноги и плечи, образуя \"полую\" дугу. Руки вытянуты за голову.\n\nКлючи: гимнастическая база. Поясница ВСЕГДА прижата к полу.",
            videoUrl: ytSearch("hollow body hold technique")
        ),

        LibraryExercise(
            name: "Рубка дров на блоке (Woodchopper)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: блок наверху, рукоять в обеих руках над одним плечом. Стоя боком к блоку.\n\nДвижение: тяните рукоять по диагонали вниз к противоположному бедру, разворачивая корпус. Возврат подконтрольный.\n\nКлючи: тренирует ротацию корпуса — важно для борьбы, бокса, гольфа. Руки прямые, движение от кора.",
            videoUrl: ytSearch("cable woodchopper exercise")
        ),
        LibraryExercise(
            name: "Обратная рубка дров на блоке",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: блок внизу, рукоять в обеих руках у бедра. Стоя боком к блоку.\n\nДвижение: тяните рукоять по диагонали вверх над противоположным плечом, разворачивая корпус.\n\nКлючи: ротация снизу вверх — нагружает косые с другого угла. Руки прямые.",
            videoUrl: ytSearch("reverse woodchopper cable")
        ),
        LibraryExercise(
            name: "Pallof Press со штангой",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: гриф в Лэндмайн-станции, конец у груди в обеих руках. Стоя боком к станции, ноги на ширине плеч.\n\nДвижение: выпрямите руки от груди, удерживая гриф по центру. Сопротивляйтесь силе, тянущей гриф в сторону. Удерживайте 2–3 сек, верните к груди.\n\nКлючи: анти-ротация — учит кор сопротивляться скручиванию. Корпус НЕ должен поворачиваться.",
            videoUrl: ytSearch("pallof press landmine")
        ),
        LibraryExercise(
            name: "Прогулка фермера одной рукой",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: одна тяжёлая гантель в одной руке у бедра. Свободная рука сбоку.\n\nДвижение: ходите 20–40 м, удерживая корпус ровным. Не наклоняйтесь в сторону веса.\n\nКлючи: жёстко работают косые мышцы и квадратная поясницы. Отличное упражнение для антибокового сгибания.",
            videoUrl: ytSearch("single arm farmer carry")
        ),
        LibraryExercise(
            name: "Suitcase Carry (прогулка с чемоданом)",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: тяжёлая гантель или гиря в одной руке.\n\nДвижение: ходите медленно, поддерживая идеально ровную осанку. Свободная рука сбоку.\n\nКлючи: то же что и фермерская прогулка одной рукой, но с акцентом на медленный темп и идеальную осанку. Отличный антиротационный стимул.",
            videoUrl: ytSearch("suitcase carry exercise")
        ),
        LibraryExercise(
            name: "Stir the Pot (помешивание на фитболе)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: упор предплечьями на фитбол, тело в планке.\n\nДвижение: \"размешивайте\" предплечьями круги по часовой стрелке 10 раз, затем против. Удерживая корпус неподвижным.\n\nКлючи: жёстко работает поперечная мышца живота. Корпус не качается — двигаются только руки.",
            videoUrl: ytSearch("stir the pot ab exercise")
        ),
        LibraryExercise(
            name: "V-Sit Hold (удержание уголка)",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: сидя на полу, ноги вытянуты, корпус под углом 45°.\n\nДвижение: оторвите ноги от пола, образуя V. Удерживайте позицию.\n\nКлючи: жёсткое удержание прямой мышцы живота. Дыхание спокойное, корпус не прогибается.",
            videoUrl: ytSearch("v sit hold technique")
        ),
        LibraryExercise(
            name: "Боковые наклоны с гантелей",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: гантель в одной руке, свободная рука у головы. Стойка на ширине плеч.\n\nДвижение: наклоняйте корпус в сторону гантели до растяжения. Поднимайтесь, сжимая косые противоположной стороны.\n\nКлючи: акцент на латеральную флексию косых. Не наклоняйтесь вперёд или назад — только в стороны.",
            videoUrl: ytSearch("dumbbell side bend technique")
        ),
        LibraryExercise(
            name: "Русский твист с блином",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: сидя на полу, ноги согнуты или висят. Блин в обеих руках, корпус откинут на 45°.\n\nДвижение: вращайте корпус в стороны, касаясь блином пола рядом с бёдрами. Чередуйте стороны.\n\nКлючи: ноги в воздухе — больше сложность. Двигается корпус, а не только руки.",
            videoUrl: ytSearch("plate russian twist")
        ),
        LibraryExercise(
            name: "Дворники в висе (Windshield Wipers)",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: вис на перекладине, ноги подняты в L-sit или выше.\n\nДвижение: вращайте ноги в стороны как стрелки часов или дворники. Корпус неподвижен.\n\nКлючи: продвинутое упражнение для силы кора и хвата. Только при освоенных подъёмах ног в висе.",
            videoUrl: ytSearch("hanging windshield wipers")
        ),
        LibraryExercise(
            name: "Скручивания на блоке (Cable Crunch)",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: на коленях лицом или спиной к верхнему блоку. Канат удерживается у висков. Бёдра вертикальны.\n\nДвижение: скручивайте корпус, опуская локти к коленям. Концентрация на сжатии пресса, не на тяге руками. Возврат подконтрольный до растяжения.\n\nКлючи: позволяет прогрессивную нагрузку на пресс — главный фактор гипертрофии. Не разгибайте поясницу — движение только за счёт скручивания.",
            videoUrl: nil
        ),
        LibraryExercise(
            name: "Pallof Press",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: стойка боком к блоку на уровне груди. Рукоять прижата к грудине обеими руками. Стопы на ширине плеч.\n\nДвижение: вытягивайте рукоять вперёд до полного выпрямления рук, сопротивляясь скручиванию корпуса. Удерживайте 1–2 сек. Возврат к груди.\n\nКлючи: антиротационное упражнение — тренирует кор как стабилизатор. Корпус не двигается — это весь смысл.",
            videoUrl: nil
        ),

        // MARK: - КАРДИО

        LibraryExercise(
            name: "Бег трусцой",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Зона 2 (60–70% макс. пульса). Расслабленный темп — можно говорить полными предложениями.\n\nКлючи: лёгкий приземление на середину стопы, корпус слегка наклонён вперёд. Идеально для жиросжигания и восстановления.",
            videoUrl: ytSearch("jogging form technique")
        ),
        LibraryExercise(
            name: "Бег интервалы",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "HIIT-схемы: 30/30, 45/45, 60/60. Спринт + восстановление.\n\nКлючи: на спринтах работа в зоне 4–5 (90%+ макс. пульса). Между интервалами — лёгкая трусца. Запускает EPOC — догорание калорий после.",
            videoUrl: ytSearch("interval running technique")
        ),
        LibraryExercise(
            name: "Скакалка",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: скакалка отрегулирована — рукояти под мышками при наступании на середину.\n\nДвижение: прыгайте на носках, едва отрывая ноги. Кисти крутят, плечи расслаблены.\n\nКлючи: лучшее портативное кардио. Тренирует икры и координацию.",
            videoUrl: ytSearch("jump rope technique")
        ),
        LibraryExercise(
            name: "Двойные прыжки на скакалке",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: уверенно делаете 100+ обычных прыжков.\n\nДвижение: один прыжок выше + два оборота скакалки за это время.\n\nКлючи: культовое CrossFit упражнение. Кисти крутят быстрее, прыжок выше.",
            videoUrl: ytSearch("double under technique")
        ),
        LibraryExercise(
            name: "Прыжки на скакалке крест-накрест",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: после освоения базовых прыжков.\n\nДвижение: на каждом прыжке скрещивайте руки перед собой, прыгая через образовавшуюся петлю.\n\nКлючи: координационное упражнение. Хорошо разнообразит тренировку.",
            videoUrl: ytSearch("criss cross jump rope technique")
        ),
        LibraryExercise(
            name: "Гребля (Concept2)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Цикл: ноги (60% усилия) → корпус (20%) → руки (20%). Возврат в обратном порядке.\n\nКлючи: толкайте ногами, не тяните руками. Спина прямая. Гребок мощный, возврат подконтрольный.",
            videoUrl: ytSearch("rowing machine technique")
        ),
        LibraryExercise(
            name: "Байк (Assault Bike)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Сядьте, ноги и руки одновременно работают.\n\nДвижение: толкайте педали и тяните рукояти максимально мощно.\n\nКлючи: жёсткая аэробно-силовая нагрузка. \"Самокат смерти\" — обожаемый CrossFit-инструмент.",
            videoUrl: ytSearch("assault bike technique")
        ),
        LibraryExercise(
            name: "Лыжный тренажер (SkiErg)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: рукояти вверху, корпус слегка наклонён, ноги чуть согнуты.\n\nДвижение: тяните рукояти вниз и за спину, наклоняя корпус. Используйте кор и ноги.\n\nКлючи: имитация классических лыж. Высокая нагрузка на спину и кор.",
            videoUrl: ytSearch("skierg technique")
        ),
        LibraryExercise(
            name: "Эллипсоид",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Стопы на платформах, рукояти в руках.\n\nДвижение: толкайте ноги назад, помогая руками. Корпус прямой.\n\nКлючи: щадящее кардио — нет ударной нагрузки. Зона 2, 30–60 минут.",
            videoUrl: ytSearch("elliptical technique")
        ),
        LibraryExercise(
            name: "Степпер",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Шагайте на месте, удерживая корпус вертикально. Не наклоняйтесь на рукояти.\n\nКлючи: жжёт ягодицы и квадрицепсы. Идеально для кардио в дни верха тела.",
            videoUrl: ytSearch("stair stepper technique")
        ),
        LibraryExercise(
            name: "Бокс (груша)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Раунды по 2–3 минуты. Базовые удары: джеб, кросс, хук, апперкот.\n\nКлючи: техника важнее силы. Кисти всегда в перчатках. Возвращайте руки в защиту после каждого удара.",
            videoUrl: ytSearch("boxing bag technique")
        ),
        LibraryExercise(
            name: "Ходьба в гору",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Беговая дорожка с наклоном 10–15% или живой подъём. Темп быстрая ходьба.\n\nКлючи: жгучее кардио без ударной нагрузки. Работают ягодицы и икры. Не держитесь за поручни.",
            videoUrl: ytSearch("incline walking technique")
        ),
        LibraryExercise(
            name: "Берпи",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Цикл: присед → выброс ног в планку → отжимание → подтягивание ног к груди → выпрыгивание с хлопком над головой.\n\nКлючи: легендарное упражнение CrossFit. Темп умеренный, не жертвуйте техникой.",
            videoUrl: ytSearch("burpee technique")
        ),
        LibraryExercise(
            name: "Заныривания на коробку (Box Jumps)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: перед коробкой высотой 50–75 см.\n\nДвижение: глубокий присед → взрывное выпрыгивание на коробку. Спрыгивание мягкое.\n\nКлючи: безопаснее ставить ногу на коробку при спуске (не спрыгивать), чтобы беречь ахилл.",
            videoUrl: ytSearch("box jump technique")
        ),
        LibraryExercise(
            name: "Альпинист",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: упор лёжа.\n\nДвижение: поочерёдно подтягивайте колени к груди в быстром темпе.\n\nКлючи: тренирует кор и кардио. Бёдра не поднимаются вверх.",
            videoUrl: ytSearch("mountain climber technique")
        ),
        LibraryExercise(
            name: "Джампинг Джек",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: стоя, ноги вместе, руки вдоль тела.\n\nДвижение: прыжком развести ноги в стороны и поднять руки над головой. Прыжком вернуться.\n\nКлючи: классическое разогревочное упражнение. Высокий темп.",
            videoUrl: ytSearch("jumping jack technique")
        ),
        LibraryExercise(
            name: "Выпрыгивания из приседа",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: стоя, ноги на ширине плеч.\n\nДвижение: глубокий присед → взрывное выпрыгивание вверх → мягкое приземление.\n\nКлючи: плиометрика для развития мощности ног.",
            videoUrl: ytSearch("squat jump technique")
        ),
        LibraryExercise(
            name: "Прыжки в длину",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: стоя, руки отведены назад.\n\nДвижение: мах руками вперёд + взрывное выпрыгивание вперёд. Мягкое приземление.\n\nКлючи: тренирует мощность задней цепи. Измеряйте длину для прогрессии.",
            videoUrl: ytSearch("broad jump technique")
        ),
        LibraryExercise(
            name: "Спринты",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Дистанция 50–200 м. Максимальная скорость.\n\nКлючи: между спринтами — полное восстановление (2–3 мин). Для развития мощности и анаэробной системы.",
            videoUrl: ytSearch("sprint training technique")
        ),
        LibraryExercise(
            name: "Табата",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Протокол: 20 сек работы / 10 сек отдыха x 8 раундов = 4 минуты.\n\nКлючи: жёсткий HIIT — упражнение на пределе. Работает с любым движением (берпи, спринт, гири).",
            videoUrl: ytSearch("tabata protocol technique")
        ),
        LibraryExercise(
            name: "Подъем по лестнице",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Живой подъезд / стадион. Темп быстрый, без бега.\n\nКлючи: фантастическое кардио для ягодиц и икр. Безопасно для коленей.",
            videoUrl: ytSearch("stair climbing cardio")
        ),

        LibraryExercise(
            name: "Inchworm (Червяк)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: стоя, ноги вместе.\n\nДвижение: наклонитесь, поставьте руки на пол. Перебирая руками, дойдите до планки. Перебирая ступнями, подойдите к рукам. Встаньте.\n\nКлючи: разогревает всё тело — мобильность + плечи + кор. Идеально как первый блок разминки.",
            videoUrl: ytSearch("inchworm exercise warmup")
        ),
        LibraryExercise(
            name: "Бег с высоким подъёмом коленей",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: стоя на месте, локти на 90°.\n\nДвижение: бегите на месте, поднимая колени до уровня таза. Активно работайте руками.\n\nКлючи: высокая интенсивность для разогрева или интервалов. Стопы — на носки.",
            videoUrl: ytSearch("high knees exercise")
        ),
        LibraryExercise(
            name: "Прыжки в стороны (Lateral Jumps)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: стоя, ноги вместе. Можно поставить полосу или шнурок для ориентира.\n\nДвижение: прыгайте боком через линию двумя ногами. Без пауз.\n\nКлючи: плиометрика для лёгких и боковой стабильности. Мягкое приземление через колени.",
            videoUrl: ytSearch("lateral jumps exercise")
        ),
        LibraryExercise(
            name: "Burpee Broad Jump",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: стоя, ноги на ширине плеч.\n\nДвижение: классический берпи (отжимание + подъём). Из стойки прыгайте в длину вперёд. Развернитесь и повторите в обратную сторону.\n\nКлючи: жёсткое кардио + плиометрика. Для функциональной подготовки.",
            videoUrl: ytSearch("burpee broad jump")
        ),
        LibraryExercise(
            name: "Skater Hops (Прыжки конькобежца)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: стоя на одной ноге, корпус слегка наклонён вперёд.\n\nДвижение: оттолкнитесь и прыгните боком на другую ногу. Свободная нога уходит назад накрест. Без пауз чередуйте.\n\nКлючи: плиометрика + латеральная сила. Имитирует движение конькобежца. Мягкое приземление.",
            videoUrl: ytSearch("skater hops exercise")
        ),

        // MARK: - КОМПЛЕКСНЫЕ (Тяжелая атлетика / Crossfit / Calisthenics)

        LibraryExercise(
            name: "Рывок штанги (Snatch)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: широкий хват, штанга над серединой стопы. Таз ниже плеч.\n\nДвижение: подрыв с пола → \"тройное разгибание\" (стопы, колени, таз) → подсед под штангу → приём над головой в полном приседе.\n\nКлючи: один из самых технически сложных движений. Изучайте под тренером. Требует мобильности.",
            videoUrl: ytSearch("snatch technique")
        ),
        LibraryExercise(
            name: "Силовой рывок",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: как в обычном рывке.\n\nДвижение: приём штанги над головой без полного подседа (выше параллели).\n\nКлючи: проще классики, отлично для развития мощности задней цепи.",
            videoUrl: ytSearch("power snatch technique")
        ),
        LibraryExercise(
            name: "Взятие штанги на грудь (Clean)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: хват на ширине плеч, штанга над серединой стопы.\n\nДвижение: подрыв → подсед → приём штанги на передние дельты. Локти высоко вперёд.\n\nКлючи: ключ — быстрый \"подворот\" локтей. База тяжёлой атлетики.",
            videoUrl: ytSearch("clean technique")
        ),
        LibraryExercise(
            name: "Силовое взятие на грудь",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: как в обычном Clean.\n\nДвижение: приём штанги на грудь без полного подседа.\n\nКлючи: развивает взрывную мощность. Используется в CrossFit-комплексах.",
            videoUrl: ytSearch("power clean technique")
        ),
        LibraryExercise(
            name: "Толчок штанги (Jerk)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: штанга на дельтах после взятия на грудь.\n\nДвижение: короткий подсед → взрывное разгибание → выталкивание штанги вверх с уходом под неё в ножницы.\n\nКлючи: ноги дают импульс, руки только фиксируют. Финал — корпус прямой под штангой.",
            videoUrl: ytSearch("split jerk technique")
        ),
        LibraryExercise(
            name: "Швунг толчковый",
            category: .complex,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: штанга на дельтах.\n\nДвижение: подсед → разгибание → выталкивание штанги вверх с подсаживанием под неё.\n\nКлючи: между швунгом и толчком — без ножниц.",
            videoUrl: ytSearch("push jerk technique")
        ),
        LibraryExercise(
            name: "Трастеры (Thrusters)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: штанга на передних дельтах (как фронт-присед).\n\nДвижение: фронтальный присед → на вставании толкайте штангу вверх над головой.\n\nКлючи: одно движение от пола до верха. Один из самых жёстких CrossFit-комплексов.",
            videoUrl: ytSearch("thruster technique")
        ),
        LibraryExercise(
            name: "Махи гирей русские",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: гиря между ног, ноги шире плеч.\n\nДвижение: hip hinge → взрывное разгибание таза → гиря летит до уровня глаз. Возврат с замахом между ног.\n\nКлючи: работа от бёдер, не от рук. Спина нейтральная.",
            videoUrl: ytSearch("russian kettlebell swing technique")
        ),
        LibraryExercise(
            name: "Махи гирей американские",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: как в русском махе.\n\nДвижение: гиря летит над головой в полную амплитуду. Дно гири смотрит в потолок.\n\nКлючи: требует мобильности плеч. В верхней точке корпус прямой — не прогибайтесь в пояснице.",
            videoUrl: ytSearch("american kettlebell swing technique")
        ),
        LibraryExercise(
            name: "Кластеры (Clusters)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: каждый повтор начинается с пола.\n\nДвижение: взятие на грудь → фронтальный присед → выталкивание над головой → возврат на пол.\n\nКлючи: жёсткое CrossFit-движение. Энергоёмкое.",
            videoUrl: ytSearch("clusters crossfit technique")
        ),
        LibraryExercise(
            name: "Броски мяча (Wall Balls)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: медбол у груди, перед мишенью на стене (3 м).\n\nДвижение: глубокий присед → выпрыгивание → бросок мяча в мишень. Ловите и сразу в присед.\n\nКлючи: непрерывный темп. Жёсткая ритмическая нагрузка.",
            videoUrl: ytSearch("wall ball technique")
        ),
        LibraryExercise(
            name: "Рывок гири",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: гиря между ног, одна рука на ручке.\n\nДвижение: подрыв → гиря летит вверх → \"подворот\" кисти → приём над головой на вытянутой руке.\n\nКлючи: гиря должна мягко \"приземлиться\" на предплечье. Меняйте руки.",
            videoUrl: ytSearch("kettlebell snatch technique")
        ),
        LibraryExercise(
            name: "Толчок гирь длинным циклом",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: две гири в опущенных руках.\n\nДвижение: взятие на грудь → толчок над головой → опускание на грудь → опускание между ног → повтор.\n\nКлючи: гиревой спорт высшей сложности. Развивает невероятную выносливость.",
            videoUrl: ytSearch("long cycle clean and jerk technique")
        ),
        LibraryExercise(
            name: "Турецкий подъем",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: лёжа на спине, гиря на вытянутой руке над собой.\n\nДвижение: пошаговый подъем в стойку, удерживая руку с гирей вертикально. Возврат тем же путём.\n\nКлючи: культовое упражнение для подвижности и стабильности всего тела. Изучайте по этапам.",
            videoUrl: ytSearch("turkish get up technique")
        ),
        LibraryExercise(
            name: "Подъем мешка на плечо",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: тяжёлый сэндбэг или мешок на полу.\n\nДвижение: становая → поднять на плечо одним движением → опустить на пол.\n\nКлючи: классика силового экстрима. Используйте поясной ремень.",
            videoUrl: ytSearch("sandbag shoulder technique")
        ),
        LibraryExercise(
            name: "Кипинг подтягивания",
            category: .complex,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: вис на перекладине.\n\nДвижение: используйте импульс корпуса (\"кип\") для выполнения большого числа подтягиваний.\n\nКлючи: CrossFit-стандарт. Не путайте со строгими подтягиваниями.",
            videoUrl: ytSearch("kipping pull up technique")
        ),
        LibraryExercise(
            name: "Бабочка-подтягивания",
            category: .complex,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: после освоения кипа.\n\nДвижение: непрерывная циклическая работа корпусом для подтягиваний без задержек в верхней / нижней точке.\n\nКлючи: высочайший темп подтягиваний для CrossFit. Очень нагрузочно для плеч.",
            videoUrl: ytSearch("butterfly pull up technique")
        ),
        LibraryExercise(
            name: "Хождение на руках",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: стойка на руках у стены или в свободной среде.\n\nДвижение: переставляйте руки, продвигаясь вперёд / в стороны.\n\nКлючи: требует освоенной стойки на руках. Развивает плечи, кор, координацию.",
            videoUrl: ytSearch("handstand walk technique")
        ),
        LibraryExercise(
            name: "Жим в стойке на руках",
            category: .complex,
            muscleGroup: .frontDelts,
            defaultType: .repsOnly,
            technique: "Старт: стойка на руках у стены.\n\nДвижение: опускайтесь на голову, отжимайтесь до полного выпрямления.\n\nКлючи: гимнастический эквивалент жима над головой. Нужны сильные плечи и кор.",
            videoUrl: ytSearch("handstand push up technique")
        ),
        LibraryExercise(
            name: "Burpee Box Jump Over",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Цикл: берпи → выпрыгивание на коробку → перепрыгивание на другую сторону → берпи.\n\nКлючи: одно из самых тяжёлых движений в CrossFit. Темп умеренный.",
            videoUrl: ytSearch("burpee box jump over technique")
        ),
        LibraryExercise(
            name: "Толкание салазок",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: руки на рукоятях салазок, корпус наклонён вперёд.\n\nДвижение: толкайте салазки на расстояние, мощно отталкиваясь ногами.\n\nКлючи: безударный спринт. Жжёт ноги и кардио.",
            videoUrl: ytSearch("sled push technique")
        ),
        LibraryExercise(
            name: "Тяга салазок",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: лямка на поясе или верёвка в руках. Салазки сзади.\n\nДвижение: идите вперёд, либо тяните руками к корпусу.\n\nКлючи: тренирует тягу и ноги. Прекрасное восстановительное упражнение для тяжелоатлетов.",
            videoUrl: ytSearch("sled pull technique")
        ),
        LibraryExercise(
            name: "Атласовый камень",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: каменный шар (50–150 кг) на полу.\n\nДвижение: подними на платформу или плечо.\n\nКлючи: соревновательное упражнение силового экстрима. Используйте липкие лосьоны и ремни.",
            videoUrl: ytSearch("atlas stone technique")
        ),
        LibraryExercise(
            name: "Переворот покрышки",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: покрышка лежит. Хват снизу под покрышкой.\n\nДвижение: используйте всё тело для подъёма. Толкните плечом для перевода через верх.\n\nКлючи: техника близка к становой и трастерам. Огромная нагрузка на всё тело.",
            videoUrl: ytSearch("tire flip technique")
        ),
        LibraryExercise(
            name: "Канаты (Battle Ropes)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: концы канатов в руках, лёгкий присед, корпус наклонён вперёд.\n\nДвижение: интенсивные удары канатами вверх-вниз или волной.\n\nКлючи: высокоинтенсивное кардио для верха тела. Раунды по 30–60 сек.",
            videoUrl: ytSearch("battle ropes technique")
        ),

        LibraryExercise(
            name: "Devil Press",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: стойка над двумя гантелями.\n\nДвижение: бёрпи с упором на гантели → встать с гантелями в руках → одним движением (рывком) забросить обе гантели над головой. Опустить и повторить.\n\nКлючи: одно из самых тяжёлых упражнений в кроссфите. Тренирует всё тело + лёгкие.",
            videoUrl: ytSearch("devil press crossfit")
        ),
        LibraryExercise(
            name: "Man Maker",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: гантели в руках в планке.\n\nДвижение: тяга гантели к корпусу одной рукой, затем другой → отжимание → встать с гантелями → присед с гантелями у плеч → жим над головой. Это одно повторение.\n\nКлючи: метаболически невероятно тяжёлое. Используйте умеренные веса — техника важнее.",
            videoUrl: ytSearch("man maker exercise")
        ),
        LibraryExercise(
            name: "Sumo Deadlift High Pull",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: широкая стойка сумо, гиря или штанга между ног, хват внутри ног.\n\nДвижение: становая сумо → продолжая инерцию, тянуть штангу к подбородку, ведя локти в стороны.\n\nКлючи: соединяет тазовое разгибание и работу плеч. Используется в кроссфите для метаболической работы.",
            videoUrl: ytSearch("sumo deadlift high pull")
        ),
        LibraryExercise(
            name: "Подъем сэндбэга на плечо",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: сэндбэг на полу. Стойка над мешком.\n\nДвижение: становой движение → когда мешок дойдёт до бёдер, забросьте его на одно плечо. Опустите и повторите на другую сторону.\n\nКлючи: реалистичная функциональная сила. Атлас и силовые виды спорта.",
            videoUrl: ytSearch("sandbag shoulder clean")
        ),
        LibraryExercise(
            name: "Рывок гантели",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: гантель на полу между ног. Полуприсед, ладонь к корпусу.\n\nДвижение: взрывное разгибание ног и таза → рука тянет гантель вверх по дуге → подсед под гантель → выпрямление с гантелью над головой.\n\nКлючи: классика кроссфита. Чередуйте руки. Локоть высокий в фазе подъёма.",
            videoUrl: ytSearch("dumbbell snatch crossfit")
        ),
        LibraryExercise(
            name: "Тяга в планке с гантелями (Renegade Row)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: упор на гантели в планке. Ноги шире плеч для стабильности.\n\nДвижение: тяните одну гантель к боку корпуса, удерживая таз ровно (без скручивания). Опустите и повторите другой рукой.\n\nКлючи: антиротация + тяга. Жёстко работает кор и широчайшие.",
            videoUrl: ytSearch("renegade row dumbbell")
        ),
        LibraryExercise(
            name: "Трастер с гантелями",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: гантели у плеч, ладони друг к другу.\n\nДвижение: фронтальный присед → инерцией подъёма из приседа выжмите гантели над головой. Возврат гантелей к плечам — опуститесь в присед. Повторите.\n\nКлючи: ноги + плечи в одном движении. Лучшее для метаболической работы. Темп высокий.",
            videoUrl: ytSearch("dumbbell thruster")
        ),

        // MARK: - КАЛИСТЕНИКА И ГИМНАСТИКА (Complex)

        LibraryExercise(
            name: "Выход силой",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: вис на перекладине.\n\nДвижение: взрывное подтягивание + переворот корпуса с выходом в упор на прямые руки.\n\nКлючи: гимнастический навык. Прогрессия через подтягивания с большим импульсом.",
            videoUrl: ytSearch("muscle up technique")
        ),
        LibraryExercise(
            name: "Передний вис (Front Lever)",
            category: .complex,
            muscleGroup: .lats,
            defaultType: .duration,
            technique: "Старт: вис на перекладине.\n\nДвижение: поднимите тело параллельно полу лицом вверх, удерживая прямую линию от плеч до пят.\n\nКлючи: продвинутый гимнастический навык. Прогрессия от подтянутых колен.",
            videoUrl: ytSearch("front lever technique")
        ),
        LibraryExercise(
            name: "Задний вис (Back Lever)",
            category: .complex,
            muscleGroup: .frontDelts,
            defaultType: .duration,
            technique: "Старт: вис на перекладине.\n\nДвижение: переверните корпус и удерживайте параллельно полу лицом вниз.\n\nКлючи: жёсткое испытание для бицепса и плеч. Прогрессия очень постепенная.",
            videoUrl: ytSearch("back lever technique")
        ),
        LibraryExercise(
            name: "Горизонт (Planche)",
            category: .complex,
            muscleGroup: .frontDelts,
            defaultType: .duration,
            technique: "Старт: упор на руках на полу или параллетках.\n\nДвижение: оторвите ноги от пола, удерживая прямое тело параллельно полу.\n\nКлючи: высочайшая гимнастическая сложность. Прогрессия годами через лягушку, тук, страддл.",
            videoUrl: ytSearch("planche technique")
        ),
        LibraryExercise(
            name: "Флаг человека",
            category: .complex,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: вертикальный шест, хват двумя руками друг над другом.\n\nДвижение: выведите тело в горизонталь параллельно полу.\n\nКлючи: иконическое движение калистеники. Требует силы кора, хвата и плеч.",
            videoUrl: ytSearch("human flag technique")
        ),
        LibraryExercise(
            name: "Болгарские отжимания",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: упор на двух гирях / упорах с разведением рук в стороны.\n\nДвижение: отжимание с большим разведением рук — нагрузка на грудь и плечи.\n\nКлючи: культовое упражнение русских силовых традиций.",
            videoUrl: ytSearch("bulgarian push up technique")
        ),
        LibraryExercise(
            name: "Отжимания на кольцах",
            category: .complex,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Старт: упор на гимнастических кольцах с прямыми руками.\n\nДвижение: опуститесь, стабилизируя кольца. Поднимитесь, разворачивая кисти наружу.\n\nКлючи: жёсткая нагрузка на стабилизаторы. Прогрессия от отжиманий на низких кольцах.",
            videoUrl: ytSearch("ring push up technique")
        ),
        LibraryExercise(
            name: "Лэндмайн-приседания",
            category: .complex,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: один конец штанги в Лэндмайне, другой у груди.\n\nДвижение: фронтальный присед с штангой у груди.\n\nКлючи: безопасная альтернатива фронтальному приседу. Подходит для людей с проблемами в плечах.",
            videoUrl: ytSearch("landmine squat technique")
        ),
        LibraryExercise(
            name: "Махи 360",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: гиря в руках.\n\nДвижение: круговой мах гирей вокруг головы и корпуса.\n\nКлючи: тренирует кор и хват. Контролируемое движение, не на скорость.",
            videoUrl: ytSearch("kettlebell halo technique")
        ),
        LibraryExercise(
            name: "Ротационный выброс",
            category: .complex,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: медбол в руках, стойка боком к стене.\n\nДвижение: разворотом корпуса бросьте мяч в стену с максимальной силой.\n\nКлючи: тренирует ротационную мощность — для борьбы, бокса, гольфа.",
            videoUrl: ytSearch("rotational med ball throw technique")
        ),
        LibraryExercise(
            name: "Выпады с жимом над головой",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: гантели на плечах.\n\nДвижение: выпад вперёд + жим гантелей над головой одновременно.\n\nКлючи: требует координации и стабильности. Нагружает всё тело.",
            videoUrl: ytSearch("lunge with press technique")
        ),
        LibraryExercise(
            name: "Прогулка медведя с тягой",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: на четвереньках с гантелями. Колени над землёй.\n\nДвижение: тяните гантель к корпусу, шагните противоположной рукой и ногой.\n\nКлючи: жёсткая стабилизация + тяга. Кор работает максимально.",
            videoUrl: ytSearch("bear crawl renegade row technique")
        ),
        LibraryExercise(
            name: "Отжимания Spider-Man",
            category: .complex,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Старт: упор лёжа, ладони на ширине плеч.\n\nДвижение: опускаясь, подтяните одно колено к одноимённому локтю. Поднимаясь, верните ногу. Чередуйте стороны.\n\nКлючи: классические отжимания + работа кора и тазобедренного. Имитирует движение Человека-Паука.",
            videoUrl: ytSearch("spider man push up")
        ),
        LibraryExercise(
            name: "Отжимания Лучник",
            category: .complex,
            muscleGroup: .middleChest,
            defaultType: .repsOnly,
            technique: "Старт: широкий упор лёжа, руки в полтора-два раза шире плеч.\n\nДвижение: опускайтесь к одной руке, удерживая вторую прямой и натянутой. Поднимайтесь и переходите на другую сторону.\n\nКлючи: прогрессия к отжиманиям на одной руке. Жёсткая работа одной стороны груди и трицепса.",
            videoUrl: ytSearch("archer push up")
        ),
        LibraryExercise(
            name: "Pseudo Planche отжимания",
            category: .complex,
            muscleGroup: .frontDelts,
            defaultType: .repsOnly,
            technique: "Старт: упор лёжа, ладони у пояса (а не у плеч), пальцы развёрнуты назад. Корпус наклонён вперёд.\n\nДвижение: опускайтесь, удерживая корпус наклонённым вперёд. Поднимайтесь, держа смещённый центр тяжести.\n\nКлючи: подготовка к Planche (горизонту). Жёсткая нагрузка на передние дельты и кор.",
            videoUrl: ytSearch("pseudo planche push up")
        ),
        LibraryExercise(
            name: "Подтягивания Лучник",
            category: .complex,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: широкий хват на перекладине, руки шире плеч.\n\nДвижение: подтягивайтесь к одной руке, удерживая вторую прямой и натянутой. Чередуйте стороны.\n\nКлючи: прогрессия к подтягиваниям на одной руке. Сильно нагружает одну широчайшую.",
            videoUrl: ytSearch("archer pull up")
        ),
        LibraryExercise(
            name: "L-Sit на полу",
            category: .complex,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: сидя на полу, ладони рядом с бёдрами. Ноги вытянуты.\n\nДвижение: оторвите таз от пола, удерживая ноги горизонтально. Удерживайте позицию.\n\nКлючи: жёсткая работа пресса, сгибателей бедра и трицепсов. Прогрессия — поднимать в висе или на брусьях.",
            videoUrl: ytSearch("l sit hold floor")
        ),
        LibraryExercise(
            name: "Pike отжимания",
            category: .complex,
            muscleGroup: .frontDelts,
            defaultType: .repsOnly,
            technique: "Старт: упор лёжа, поднимите таз вверх — тело образует перевёрнутую V (как поза \"собака мордой вниз\" в йоге).\n\nДвижение: опускайте голову к полу между руками. Жмите вверх до полного разгибания.\n\nКлючи: прогрессия к жиму в стойке на руках. Жёсткая нагрузка на передние дельты.",
            videoUrl: ytSearch("pike push up technique")
        ),
        LibraryExercise(
            name: "Hindu отжимания",
            category: .complex,
            muscleGroup: .frontDelts,
            defaultType: .repsOnly,
            technique: "Старт: тело в перевёрнутой V, ноги шире плеч.\n\nДвижение: опускайте корпус по дуге, проводя грудью почти по полу. В конечной точке поднимите голову и выпрямите руки (поза кобры). Возврат по обратной дуге.\n\nКлючи: индийский борцовский стиль. Развивает мобильность плеч и силу.",
            videoUrl: ytSearch("hindu push up")
        ),
        LibraryExercise(
            name: "Pseudo Planche удержание",
            category: .complex,
            muscleGroup: .frontDelts,
            defaultType: .duration,
            technique: "Старт: упор лёжа, ладони у пояса, пальцы развёрнуты назад.\n\nДвижение: наклоните корпус вперёд, перенесите вес на руки. Удерживайте позицию 10–30 сек.\n\nКлючи: изометрический шаг к чистому Planche. Силовая база для горизонта.",
            videoUrl: ytSearch("pseudo planche hold")
        ),
        LibraryExercise(
            name: "Негативные подтягивания",
            category: .complex,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: с прыжка или подставки в верхнюю точку подтягивания (подбородок над перекладиной).\n\nДвижение: опускайтесь подконтрольно за 4–6 секунд до полного выпрямления рук. Используйте подставку или прыжок для возврата.\n\nКлючи: эксцентрическая работа — сильнейший стимул для мышц. Идеально, если ещё не освоили подтягивания.",
            videoUrl: ytSearch("negative pull up")
        ),
        LibraryExercise(
            name: "Лопаточные подтягивания (Scapular Pull-ups)",
            category: .complex,
            muscleGroup: .lats,
            defaultType: .repsOnly,
            technique: "Старт: вис на перекладине, плечи расслаблены — лопатки подняты к ушам.\n\nДвижение: НЕ сгибая руки, опустите лопатки вниз и сведите. Тело слегка поднимется. Удержите 1 сек, расслабьтесь.\n\nКлючи: фундамент здорового подтягивания. Учит активировать широчайшие до движения. Обязательно для новичков.",
            videoUrl: ytSearch("scapular pull ups")
        ),

        // MARK: - МОБИЛЬНОСТЬ

        LibraryExercise(
            name: "Cat-Cow (Кошка-Корова)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: упор на четвереньки, ладони под плечами, колени под тазом. Спина нейтральная.\n\nДвижение: на выдохе округляйте спину куполом, опуская подбородок к груди (Кошка). На вдохе прогибайтесь, поднимая голову и таз вверх (Корова). Плавно чередуйте 8–10 циклов.\n\nКлючи: классическое упражнение для подвижности грудного отдела. Дыхание ведёт движение — не торопитесь. Идеальное начало утра или тренировки.",
            videoUrl: ytSearch("cat cow stretch tutorial")
        ),
        LibraryExercise(
            name: "World's Greatest Stretch",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: глубокий выпад правой ногой вперёд, левая нога прямая, ладони на полу по бокам стопы.\n\nДвижение: 1) опустите правый локоть к подъёму стопы, потянитесь. 2) разверните корпус вправо, поднимая правую руку к потолку. 3) вернитесь, выпрямите переднюю ногу — растяжение задней поверхности. 4) шаг назад в планку, поменяйте ногу.\n\nКлючи: одно растяжение для всего тела — бёдра, грудной отдел, подколенные. По 4–6 повторов на ногу. Лучшая разминка перед силовой.",
            videoUrl: ytSearch("worlds greatest stretch tutorial")
        ),
        LibraryExercise(
            name: "Hip 90/90",
            category: .complex,
            muscleGroup: .glutes,
            defaultType: .duration,
            technique: "Старт: сидя на полу, передняя нога согнута на 90° перед собой (голень параллельно корпусу), задняя — на 90° сбоку (бедро в линию с тазом).\n\nДвижение: наклоняйте корпус вперёд над передней ногой — растяжка ягодичной. Затем разверните корпус и опустите заднее колено к полу — растяжка приводящих. Сделайте 5–8 кругов, поменяйте стороны.\n\nКлючи: золотой стандарт для подвижности тазобедренных суставов. Спина прямая. Не толкайте через боль — работайте в комфортном диапазоне.",
            videoUrl: ytSearch("90 90 hip stretch mobility")
        ),
        LibraryExercise(
            name: "Cossack Squat",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: широкая стойка, носки развёрнуты на 30–45°, руки перед собой для баланса.\n\nДвижение: переносите вес на одну ногу, сгибая её в глубокий боковой присед. Вторая нога остаётся прямой, носок смотрит вверх. Пятка опорной ноги прижата к полу. Перекатитесь через центр в зеркальное положение.\n\nКлючи: лучшее упражнение для подвижности тазобедренных + сила в боковой плоскости. Колено идёт по линии стопы. Если глубоко не получается — держитесь за опору.",
            videoUrl: ytSearch("cossack squat technique")
        ),
        LibraryExercise(
            name: "Thoracic Bridge",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: упор сзади, ладони и стопы на полу, бёдра опущены.\n\nДвижение: поднимите таз и одну руку вверх, разворачиваясь грудным отделом. Тянитесь свободной рукой за голову до раскрытия груди. Поменяйте сторону.\n\nКлючи: открывает грудной отдел и плечи — критично для тех, кто много сидит. Не задерживайте дыхание. По 5–6 повторов на сторону.",
            videoUrl: ytSearch("thoracic bridge mobility")
        ),
        LibraryExercise(
            name: "Down Dog → Up Dog",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: упор лёжа.\n\nДвижение: толкните таз вверх и назад, выпрямите ноги, голова между рук — Собака мордой вниз. Удержите 2 сек. Перекатитесь вперёд через планку, опустите таз вниз, выпрямите руки и поднимите грудь — Собака мордой вверх. Чередуйте 6–8 циклов.\n\nКлючи: динамичная растяжка цепи спины-груди. Прорабатывает плечи, подколенные сухожилия, грудной отдел. Дыхание синхронно с движением.",
            videoUrl: ytSearch("downward dog upward dog flow")
        ),

        // MARK: - ЙОГА (восстановление)

        LibraryExercise(
            name: "Sun Salutation A (Сурья Намаскар)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Цикл из 9 поз, выполняемых на одном дыхании-движении: Тадасана → наклон вперёд → полу-наклон → планка → чатуранга → Собака мордой вверх → Собака мордой вниз → шаг к рукам → возврат.\n\nКлючи: классическое приветствие солнцу — 5–10 циклов прогревают всё тело. Каждое движение — один вдох или выдох. Идеальная разминка для йоги или утра.",
            videoUrl: ytSearch("sun salutation A tutorial")
        ),
        LibraryExercise(
            name: "Downward Dog (Собака мордой вниз)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: упор лёжа.\n\nДвижение: поднимите таз вверх, выпрямляя ноги в букву \"V\" перевёрнутую. Ладони и стопы на полу, голова свободно висит между рук, уши на уровне предплечий. Удерживайте 30–60 сек.\n\nКлючи: растягивает подколенные, икры, плечи. Если жёстко — слегка согните колени. Распределяйте вес между ладонями и пятками равномерно.",
            videoUrl: ytSearch("downward dog pose tutorial")
        ),
        LibraryExercise(
            name: "Warrior II (Воин II)",
            category: .complex,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: широкая стойка. Передняя стопа смотрит вперёд, задняя — на 90° в сторону. Руки в стороны параллельно полу.\n\nДвижение: согните переднее колено до 90°, бедро параллельно полу. Колено над лодыжкой. Корпус строго вертикально. Взгляд через переднюю руку. Удерживайте 30–60 сек, поменяйте сторону.\n\nКлючи: укрепляет ноги, открывает таз. Заднее колено НЕ опускается. Плечи опущены.",
            videoUrl: ytSearch("warrior 2 yoga pose")
        ),
        LibraryExercise(
            name: "Pigeon Pose (Голубь)",
            category: .complex,
            muscleGroup: .glutes,
            defaultType: .duration,
            technique: "Старт: из планки или Собаки мордой вниз.\n\nДвижение: подведите правое колено за правую кисть, голень под углом. Левая нога вытянута назад. Опуститесь корпусом вперёд на предплечья. Удерживайте 1–2 минуты, поменяйте сторону.\n\nКлючи: глубокая растяжка ягодичной и сгибателя бедра. Если таз перекошен — подложите подушку под бедро. Дышите в напряжённую зону.",
            videoUrl: ytSearch("pigeon pose yoga")
        ),
        LibraryExercise(
            name: "Cobra (Кобра)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: лёжа на животе, ладони под плечами, локти прижаты.\n\nДвижение: на вдохе мягко выпрямите руки, поднимая грудь. Таз остаётся на полу. Плечи опущены, шея вытянута. Удерживайте 20–30 сек.\n\nКлючи: контр-поза для всех, кто сутулится. Не выдавливайтесь руками — работайте мышцами спины. Без боли в пояснице.",
            videoUrl: ytSearch("cobra pose yoga")
        ),
        LibraryExercise(
            name: "Seated Forward Fold (Наклон сидя)",
            category: .complex,
            muscleGroup: .hamstrings,
            defaultType: .duration,
            technique: "Старт: сидя на полу, ноги вытянуты вперёд, стопы согнуты на себя.\n\nДвижение: на выдохе наклоняйтесь вперёд от тазобедренных суставов (не от поясницы). Тянитесь грудью к коленям, руками к стопам. Удерживайте 1–2 минуты.\n\nКлючи: растяжка задней цепи. Спину НЕ горбьте — наклон от таза. Согнутые колени — нормально, если жёстко.",
            videoUrl: ytSearch("seated forward fold pose")
        ),
        LibraryExercise(
            name: "Child's Pose (Поза ребёнка)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: на коленях, большие пальцы стоп вместе, колени развёрнуты.\n\nДвижение: опустите таз на пятки, корпус лбом на пол, руки вытянуты вперёд. Дышите глубоко в спину. Удерживайте 1–3 минуты.\n\nКлючи: главная поза восстановления. Расслабляет поясницу и плечи. Используйте между интенсивными позами или для завершения сессии.",
            videoUrl: ytSearch("child pose yoga")
        ),
        LibraryExercise(
            name: "Savasana (Шавасана)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: лёжа на спине, ноги слегка расставлены, ладони вверх.\n\nДвижение: полностью расслабьте каждую часть тела — от стоп до макушки. Дыхание естественное. Удерживайте 5–10 минут.\n\nКлючи: финальная поза любой йога-сессии. Активная медитация. Отпустите все мысли — это не сон, а осознанное расслабление.",
            videoUrl: ytSearch("savasana tutorial")
        ),

        // MARK: - КОР (плиометрика и кондиции)

        LibraryExercise(
            name: "Russian Twist",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: сидя, корпус откинут на 45°, ноги согнуты или подняты от пола. Руки перед грудью или с весом.\n\nДвижение: вращайте корпус вправо, касаясь руками пола рядом с бедром. Возврат через центр и поворот влево. Чередуйте.\n\nКлючи: классика для косых мышц. Поднимите ноги для усложнения. Двигается корпус, а не только руки. Темп умеренный.",
            videoUrl: ytSearch("russian twist technique")
        ),
        LibraryExercise(
            name: "V-ups",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: лёжа на спине, руки за головой, ноги вместе.\n\nДвижение: одновременно поднимите прямые ноги и корпус, тянясь руками к стопам — формируется буква V. Подконтрольный возврат.\n\nКлючи: жёсткое упражнение на верх и низ пресса одновременно. Поясница не отрывается резко. Если тяжело — упрощённая версия с согнутыми коленями.",
            videoUrl: ytSearch("v-ups technique")
        ),
        LibraryExercise(
            name: "Toes to Bar",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: вис на перекладине прямым хватом, плечи активны.\n\nДвижение: с напряжением кора и широчайших поднимите прямые ноги до касания носками перекладины. Подконтрольный возврат без раскачки.\n\nКлючи: продвинутое CrossFit упражнение. Сначала освойте подъёмы ног в висе. Слегка наклоняйте корпус назад в верхней точке.",
            videoUrl: ytSearch("toes to bar crossfit")
        ),
        LibraryExercise(
            name: "Bird Dog",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: на четвереньках, руки под плечами, колени под тазом. Спина нейтральная.\n\nДвижение: одновременно вытяните противоположные руку и ногу до прямой линии. Удерживайте 2 сек, возврат. Чередуйте стороны.\n\nКлючи: учит координации и стабилизации поясницы. Таз не разворачивается. Без раскачивания.",
            videoUrl: ytSearch("bird dog exercise")
        ),
        LibraryExercise(
            name: "Dead Bug",
            category: .core,
            muscleGroup: .core,
            defaultType: .repsOnly,
            technique: "Старт: лёжа на спине, руки вертикально вверх, ноги под 90°. Поясница прижата.\n\nДвижение: одновременно опустите противоположные руку и ногу до пола. Поясница НЕ отрывается. Возврат и смена сторон.\n\nКлючи: топ для глубоких мышц кора. Если поясница отрывается — уменьшите амплитуду. Дыхание ровное.",
            videoUrl: ytSearch("dead bug exercise")
        ),

        // MARK: - ЯГОДИЦЫ (доп. движения)

        LibraryExercise(
            name: "Frog Pump (Лягушка)",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .repsOnly,
            technique: "Старт: лёжа на спине, согнутые ноги, стопы вместе подошвами, колени развёрнуты в стороны (как лягушка).\n\nДвижение: толкая стопами друг к другу, поднимите таз вверх до сжатия ягодиц. Удерживайте 1 сек, опустите.\n\nКлючи: изолированно бьёт по ягодицам. Делайте на 20–30 повторов с резинкой над коленями для огня. Идеальный финишер.",
            videoUrl: ytSearch("frog pump glutes")
        ),
        LibraryExercise(
            name: "Hip Thrust (с резинкой)",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .repsOnly,
            technique: "Старт: лопатки на скамье, стопы на полу, резинка над коленями. Таз внизу.\n\nДвижение: с напряжённой резинкой (колени развёрнуты в стороны) поднимайте таз до прямой линии плечи-колени. Сжатие ягодиц 1 сек.\n\nКлючи: резинка активирует среднюю ягодичную (отвечает за форму). Колени НЕ сходятся. 15–25 повторов.",
            videoUrl: ytSearch("banded hip thrust")
        ),
        LibraryExercise(
            name: "Step Up на платформу",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .repsOnly,
            technique: "Старт: перед платформой 40–60 см. Гантели в руках или штанга на плечах.\n\nДвижение: поставьте всю стопу на платформу, выжмите всё тело вверх через пятку опорной ноги (НЕ толкайтесь нижней). Подконтрольный спуск.\n\nКлючи: чем выше платформа, тем больше нагрузка на ягодицы. 8–12 повторов на ногу. Корпус слегка наклонён вперёд.",
            videoUrl: ytSearch("step up exercise glutes")
        ),
        LibraryExercise(
            name: "Отведение ноги (Cable Kickback)",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: манжета на лодыжке, тросик у нижнего блока. Стоя лицом к блоку, наклон корпуса вперёд, держась за раму.\n\nДвижение: отводите прямую ногу назад до сжатия ягодицы. Без прогиба в пояснице. Подконтрольный возврат.\n\nКлючи: изоляция большой ягодичной. Рабочая нога слегка согнута в верхней точке для пика сжатия. 12–15 повторов.",
            videoUrl: ytSearch("cable kickback glutes")
        ),
        LibraryExercise(
            name: "Отведение ноги на блоке",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: манжета на лодыжке, нижний блок. Стойте боком к блоку, держась за раму свободной рукой.\n\nДвижение: отводите рабочую ногу в сторону по дуге до сжатия средней ягодичной. Подконтрольный возврат через центр.\n\nКлючи: бьёт среднюю ягодичную (форма таза). Корпус неподвижен. Без раскачивания.",
            videoUrl: ytSearch("cable hip abduction")
        ),

        // MARK: - КОНДИЦИИ (плиометрика)

        LibraryExercise(
            name: "Воздушные приседания",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: стопы на ширине плеч, носки слегка в стороны, руки перед грудью.\n\nДвижение: опуститесь в присед до параллели или ниже, колени по линии стоп. Через пятки выпрямитесь.\n\nКлючи: база для всех приседаний. Идеально для разминки или WOD. Спина прямая, грудь раскрыта.",
            videoUrl: ytSearch("air squat technique")
        ),
        LibraryExercise(
            name: "Приседания с прыжком",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .repsOnly,
            technique: "Старт: стойка приседаний.\n\nДвижение: глубокий присед → взрывное выпрыгивание вверх с отрывом стоп от пола. Мягкое приземление в присед сразу — без паузы переход в следующий повтор.\n\nКлючи: плиометрика для мощности ног. Колени мягкие при приземлении. 10–20 повторов.",
            videoUrl: ytSearch("jump squat technique")
        ),
        LibraryExercise(
            name: "Прыжки на скакалке",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .duration,
            technique: "Старт: скакалка отрегулирована — рукояти под мышками при наступании на середину. Локти прижаты.\n\nДвижение: прыгайте на носках, едва отрывая стопы от пола. Кисти крутят, плечи расслаблены.\n\nКлючи: лучшее портативное кардио. Развивает икры и координацию. Темп: 120–180 прыжков/мин.",
            videoUrl: ytSearch("jump rope technique")
        ),
        LibraryExercise(
            name: "Burpees (Берпи)",
            category: .cardio,
            muscleGroup: .fullBody,
            defaultType: .repsOnly,
            technique: "Старт: стоя.\n\nДвижение: присед → выброс ног в планку → отжимание (опционально) → прыжок ног к рукам → выпрыгивание с хлопком над головой.\n\nКлючи: легендарное упражнение CrossFit. Темп умеренный — техника важнее скорости. Спина не круглится при выбросе.",
            videoUrl: ytSearch("burpee technique")
        ),
        LibraryExercise(
            name: "Mountain Climbers (Скалолаз)",
            category: .core,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: упор лёжа, корпус прямой.\n\nДвижение: поочерёдно подтягивайте колени к груди в быстром темпе, как при беге на месте в горизонтали. Таз не поднимается.\n\nКлючи: тренирует кор + кардио. Плечи строго над запястьями. Темп высокий, но без потери техники.",
            videoUrl: ytSearch("mountain climber technique")
        ),
        LibraryExercise(
            name: "Махи гирей",
            category: .complex,
            muscleGroup: .glutes,
            defaultType: .repsOnly,
            technique: "Старт: гиря между стоп, ноги на ширине плеч, спина прямая, таз чуть выше колен.\n\nДвижение: занос гири между ног (как футбольный пас назад) → взрывное разгибание таза, гиря по дуге выходит до уровня плеч (русский стиль) или над головой (американский). Возврат от таза, не от рук.\n\nКлючи: движение от таза, руки только направляют. Спина нейтральна весь подход. Икона функциональной силы. 10–20 повторов.",
            videoUrl: ytSearch("kettlebell swing technique")
        ),

        // MARK: - АЛИАСЫ для совместимости с программами

        LibraryExercise(
            name: "Уголок (L-sit) на брусьях",
            category: .complex,
            muscleGroup: .core,
            defaultType: .duration,
            technique: "Старт: упор на брусьях, плечи опущены вниз от ушей.\n\nДвижение: поднимите прямые ноги до параллели с полом, образуя букву \"L\". Удерживайте 5–30 сек.\n\nКлючи: продвинутое статическое движение для кора и плеч. Если жёстко — начните с подтянутых к груди коленей (Tuck L-sit).",
            videoUrl: ytSearch("l-sit parallel bars")
        ),
    ]

    // MARK: - Lookup helpers

    static var exercisesByCategory: [ExerciseCategory: [LibraryExercise]] {
        Dictionary(grouping: allExercises, by: { $0.category })
    }

    static func search(_ query: String) -> [LibraryExercise] {
        guard !query.isEmpty else { return allExercises }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    // MARK: - Helper Methods

    nonisolated static func getExercise(for name: String) -> LibraryExercise? {
        // 1. Exact match
        if let exact = allExercises.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return exact
        }
        // 2. Strip parenthetical suffix and try exact again
        let cleanName = name.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? name
        if let cleanMatch = allExercises.first(where: { $0.name.caseInsensitiveCompare(cleanName) == .orderedSame }) {
            return cleanMatch
        }
        // 2b. Extract content INSIDE parens and try exact match against that.
        //     Handles bilingual seed names like "Burpees (Берпи)" → "Берпи",
        //     "Mountain Climbers (Скалолаз)" → "Скалолаз".
        if let openIdx = name.firstIndex(of: "("),
           let closeIdx = name.firstIndex(of: ")"),
           openIdx < closeIdx {
            let inner = String(name[name.index(after: openIdx)..<closeIdx])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !inner.isEmpty,
               let innerMatch = allExercises.first(where: { $0.name.caseInsensitiveCompare(inner) == .orderedSame }) {
                return innerMatch
            }
        }
        // 3. Substring match (either direction)
        if let substringMatch = allExercises.first(where: { name.localizedCaseInsensitiveContains($0.name) || $0.name.localizedCaseInsensitiveContains(name) }) {
            return substringMatch
        }
        // 4. Token-based fallback — require every meaningful query token to appear in the candidate name.
        //    Handles seeder names like "Жим лежа" → "Жим штанги лежа", "Жим стоя" → "Жим штанги стоя".
        let stopWords: Set<String> = ["на", "со", "с", "в", "из", "и", "для", "до", "по", "к", "за"]
        let queryTokens = cleanName
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !stopWords.contains($0) && $0.count > 1 }
        guard queryTokens.count >= 2 else { return nil }

        var bestMatch: (exercise: LibraryExercise, score: Int)?
        for candidate in allExercises {
            let candidateLower = candidate.name.lowercased()
            let matched = queryTokens.filter { candidateLower.contains($0) }.count
            // Require all query tokens present
            guard matched == queryTokens.count else { continue }
            // Prefer the candidate with the fewest extra tokens (closest match)
            let candidateTokenCount = candidate.name
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .count
            let score = -abs(candidateTokenCount - queryTokens.count)
            if bestMatch == nil || score > bestMatch!.score {
                bestMatch = (candidate, score)
            }
        }
        return bestMatch?.exercise
    }

    static func getTechnique(for name: String) -> String? {
        getExercise(for: name)?.technique
    }

    nonisolated static func getDefaultType(for name: String) -> WorkoutType {
        getExercise(for: name)?.defaultType ?? .strength
    }

    static func getVideoUrl(for name: String) -> String? {
        getExercise(for: name)?.videoUrl
    }

    /// Background-safe migration that fills missing default workout types on existing templates.
    static func migrateExerciseTypes(container: ModelContainer) async {
        await Task.detached(priority: .utility) {
            let context = ModelContext(container)
            context.autosaveEnabled = false

            let descriptor = FetchDescriptor<ExerciseTemplate>()
            guard let templates = try? context.fetch(descriptor) else {
                #if DEBUG
                print("⚠️ Migration: Failed to fetch templates")
                #endif
                return
            }

            var migratedCount = 0
            for template in templates {
                if template._customWorkoutType == nil {
                    template._customWorkoutType = getDefaultType(for: template.name)
                    migratedCount += 1
                }
            }

            if migratedCount > 0 {
                do {
                    try context.save()
                    #if DEBUG
                    print("✅ Background Migration: Updated \(migratedCount) exercises")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Migration: Failed to save: \(error)")
                    #endif
                }
            }
        }.value
    }
}

extension ExerciseCategory {
    static var fullBody: ExerciseCategory { .complex }
}
