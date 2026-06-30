//
//  ExerciseLibraryGenerated.swift
//  GymTracker
//
//  Метаданные (GIF-демонстрации ExerciseDB, оборудование, вспомогательные мышцы)
//  и расширенный набор упражнений. Файл генерируется скриптом - не редактировать вручную.
//

import Foundation
import SwiftUI

enum Equipment: String, CaseIterable, Identifiable, Codable {
    case barbell, dumbbell, machine, cable, bodyweight, kettlebell, bands, ezbar, medicineBall, exerciseBall, foamRoll, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .barbell: return "Штанга".localized()
        case .dumbbell: return "Гантели".localized()
        case .machine: return "Тренажёр".localized()
        case .cable: return "Блок".localized()
        case .bodyweight: return "Свой вес".localized()
        case .kettlebell: return "Гиря".localized()
        case .bands: return "Резина".localized()
        case .ezbar: return "EZ-гриф".localized()
        case .medicineBall: return "Медбол".localized()
        case .exerciseBall: return "Фитбол".localized()
        case .foamRoll: return "Ролик".localized()
        case .other: return "Другое".localized()
        }
    }
    var icon: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .machine: return "gearshape.2.fill"
        case .cable: return "cable.connector"
        case .bodyweight: return "figure.strengthtraining.functional"
        case .kettlebell: return "scalemass.fill"
        case .bands: return "waveform.path"
        case .ezbar: return "dumbbell.fill"
        case .medicineBall: return "basketball.fill"
        case .exerciseBall: return "circle.circle.fill"
        case .foamRoll: return "cylinder.fill"
        case .other: return "questionmark.circle"
        }
    }
}

struct ExerciseMedia {
    let gifAsset: String?
    let equipment: Equipment?
    let secondaryMuscles: [MuscleGroup]
}

extension LibraryExercise {
    var media: ExerciseMedia? { ExerciseLibrary.exerciseMedia[name] }
    var gifAsset: String? { media?.gifAsset }
    var equipment: Equipment? { media?.equipment }
    var secondaryMuscles: [MuscleGroup] { media?.secondaryMuscles ?? [] }
}

extension ExerciseLibrary {
    nonisolated static let exerciseMedia: [String: ExerciseMedia] = [
        "21-ки (21s) на бицепс": ExerciseMedia(gifAsset: "exgif_NbVPDMW", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "ATG сплит-присед": ExerciseMedia(gifAsset: "exgif_9E25EOx", equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Burpee Box Jump Over": ExerciseMedia(gifAsset: "exgif_dK9394r", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Burpee Broad Jump": ExerciseMedia(gifAsset: "exgif_dK9394r", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Burpees (Берпи)": ExerciseMedia(gifAsset: "exgif_dK9394r", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Cat-Cow (Кошка-Корова)": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.trapezius]),
        "Cheat Curl (читинг)": ExerciseMedia(gifAsset: "exgif_25GPyDY", equipment: .some(.barbell), secondaryMuscles: [.forearms]),
        "Child's Pose (Поза ребёнка)": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.glutes, .trapezius]),
        "Cossack Squat": ExerciseMedia(gifAsset: "exgif_GWoKnIm", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Dead Bug": ExerciseMedia(gifAsset: "exgif_iny3m5y", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Dead Bug (Жук)": ExerciseMedia(gifAsset: "exgif_iny3m5y", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Drag Curl со штангой": ExerciseMedia(gifAsset: "exgif_IENzBdA", equipment: .some(.barbell), secondaryMuscles: [.forearms]),
        "Glute Ham Raise (GHR)": ExerciseMedia(gifAsset: "exgif_Vvwjz6N", equipment: .some(.bodyweight), secondaryMuscles: [.glutes]),
        "Glute Pull-Through на блоке": ExerciseMedia(gifAsset: "exgif_OM46QHm", equipment: .some(.cable), secondaryMuscles: [.hamstrings]),
        "Good Morning": ExerciseMedia(gifAsset: "exgif_XlZ4lAC", equipment: .some(.barbell), secondaryMuscles: [.core, .glutes, .lowerBack]),
        "Good Morning сидя": ExerciseMedia(gifAsset: "exgif_d960PgE", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
        "Hammer Hold (удержание молотка)": ExerciseMedia(gifAsset: "exgif_REXmfVC", equipment: .some(.machine), secondaryMuscles: [.forearms]),
        "Hindu отжимания": ExerciseMedia(gifAsset: "exgif_epOSYUZ", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Hip Thrust (с резинкой)": ExerciseMedia(gifAsset: "exgif_E4R8Hz1", equipment: .some(.bands), secondaryMuscles: [.hamstrings]),
        "Inchworm (Червяк)": ExerciseMedia(gifAsset: "exgif_ZgsNQ6d", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "JM-press": ExerciseMedia(gifAsset: "exgif_ZsiqXYa", equipment: .some(.barbell), secondaryMuscles: [.middleChest, .sideDelts]),
        "L-Sit на полу": ExerciseMedia(gifAsset: "exgif_UpWmA5E", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Mountain Climbers (Скалолаз)": ExerciseMedia(gifAsset: "exgif_RJgzwny", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Pallof Press": ExerciseMedia(gifAsset: "exgif_9pa4H5m", equipment: .some(.bands), secondaryMuscles: [.glutes]),
        "Pallof Press с ротацией": ExerciseMedia(gifAsset: "exgif_G7PXMlT", equipment: .some(.bands), secondaryMuscles: [.glutes]),
        "Pallof Press со штангой": ExerciseMedia(gifAsset: "exgif_9pa4H5m", equipment: .some(.bands), secondaryMuscles: [.glutes]),
        "Pseudo Planche удержание": ExerciseMedia(gifAsset: "exgif_LYJodFS", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Russian Twist": ExerciseMedia(gifAsset: "exgif_XVDdcoj", equipment: .some(.bodyweight), secondaryMuscles: [.lowerBack]),
        "Seated Forward Fold (Наклон сидя)": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.calves]),
        "Skater Hops (Прыжки конькобежца)": ExerciseMedia(gifAsset: "exgif_zfNHMN9", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .glutes, .calves]),
        "Step Up на платформу": ExerciseMedia(gifAsset: "exgif_d5bTEPV", equipment: .some(.bands), secondaryMuscles: [.hamstrings, .calves]),
        "Sumo Deadlift High Pull": ExerciseMedia(gifAsset: "exgif_8ARQ9Hw", equipment: .some(.kettlebell), secondaryMuscles: [.glutes, .hamstrings]),
        "Toes to Bar": ExerciseMedia(gifAsset: "exgif_4Ml7QFO", equipment: .some(.bodyweight), secondaryMuscles: []),
        "V-Sit Hold (удержание уголка)": ExerciseMedia(gifAsset: "exgif_ZuXu4Eq", equipment: .some(.bodyweight), secondaryMuscles: []),
        "World's Greatest Stretch": ExerciseMedia(gifAsset: "exgif_DFGXwZr", equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .calves]),
        "Wrist Roller (катушка с весом)": ExerciseMedia(gifAsset: "exgif_bd5b860", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .triceps]),
        "Y-подъемы лежа на наклонной": ExerciseMedia(gifAsset: "exgif_PbzNu7c", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Австралийские подтягивания": ExerciseMedia(gifAsset: "exgif_bZGHsAZ", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Австралийские подтягивания со штангой": ExerciseMedia(gifAsset: "exgif_bZGHsAZ", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Альпинист": ExerciseMedia(gifAsset: "exgif_RJgzwny", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Анти-ротация на блоке": ExerciseMedia(gifAsset: "exgif_9pa4H5m", equipment: .some(.bands), secondaryMuscles: [.glutes]),
        "Армейский жим": ExerciseMedia(gifAsset: "exgif_Kyd9Rz5", equipment: .some(.barbell), secondaryMuscles: [.triceps, .trapezius]),
        "Армейский жим штанги сидя": ExerciseMedia(gifAsset: "exgif_ngPpyRS", equipment: .some(.barbell), secondaryMuscles: [.triceps, .trapezius]),
        "Атласовый камень": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.core, .glutes, .biceps, .calves, .forearms, .hamstrings, .trapezius, .quadriceps]),
        "Бабочка-подтягивания": ExerciseMedia(gifAsset: "exgif_lBDjFxJ", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Байезианские сгибания": ExerciseMedia(gifAsset: "exgif_G08RZcQ", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Бег интервалы": ExerciseMedia(gifAsset: "exgif_oLrKqDH", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Бег с высоким подъёмом коленей": ExerciseMedia(gifAsset: "exgif_ealLwvX", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .glutes, .calves]),
        "Бег трусцой": ExerciseMedia(gifAsset: "exgif_oLrKqDH", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Берпи": ExerciseMedia(gifAsset: "exgif_dK9394r", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Боковая планка": ExerciseMedia(gifAsset: "exgif_5VXmnV5", equipment: .some(.bodyweight), secondaryMuscles: [.sideDelts]),
        "Боковая растяжка корпуса сидя": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Боковая растяжка корпуса стоя": ExerciseMedia(gifAsset: "exgif_1jXLYEw", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Боковая растяжка шеи": ExerciseMedia(gifAsset: "exgif_x2chWLO", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Боковая складка лёжа": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Боковые выпады": ExerciseMedia(gifAsset: "exgif_py1HSzx", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Боковые запрыгивания на коробку": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.glutes, .calves, .hamstrings, .quadriceps]),
        "Боковые наклоны на верхнем блоке": ExerciseMedia(gifAsset: "exgif_wPypxFY", equipment: .some(.cable), secondaryMuscles: []),
        "Боковые наклоны с гантелей": ExerciseMedia(gifAsset: "exgif_IpONWYv", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Боковые перепрыгивания через коробку": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.glutes, .calves, .hamstrings]),
        "Бокс (груша)": ExerciseMedia(gifAsset: "exgif_hoXt6wv", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .triceps, .forearms]),
        "Болгарские сплит-приседания": ExerciseMedia(gifAsset: "exgif_QpXqiq8", equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Болгарские сплит-приседания в Смите": ExerciseMedia(gifAsset: "exgif_wWFspEi", equipment: .some(.machine), secondaryMuscles: [.glutes, .hamstrings]),
        "Бросок мяча из-за головы": ExerciseMedia(gifAsset: "exgif_PsVS1QP", equipment: .some(.medicineBall), secondaryMuscles: [.core, .middleChest, .sideDelts]),
        "Бросок мяча из-за головы стоя": ExerciseMedia(gifAsset: "exgif_PsVS1QP", equipment: .some(.medicineBall), secondaryMuscles: [.middleChest, .lats]),
        "Бросок мяча об пол": ExerciseMedia(gifAsset: "exgif_oHg8eop", equipment: .some(.medicineBall), secondaryMuscles: []),
        "Бросок мяча об пол одной рукой": ExerciseMedia(gifAsset: "exgif_jCrtE9b", equipment: .some(.medicineBall), secondaryMuscles: [.lats, .sideDelts]),
        "Бросок мяча от груди": ExerciseMedia(gifAsset: "exgif_aDoFKrE", equipment: .some(.medicineBall), secondaryMuscles: [.triceps]),
        "Бросок мяча от груди (одиночный)": ExerciseMedia(gifAsset: "exgif_jeHtrlO", equipment: .some(.medicineBall), secondaryMuscles: [.triceps]),
        "Бросок мяча от груди лежа": ExerciseMedia(gifAsset: "exgif_Al3tP0D", equipment: .some(.medicineBall), secondaryMuscles: [.middleChest, .sideDelts]),
        "Бросок мяча снизу-назад": ExerciseMedia(gifAsset: nil, equipment: .some(.medicineBall), secondaryMuscles: [.core, .hamstrings, .quadriceps]),
        "Бросок мяча через голову назад": ExerciseMedia(gifAsset: nil, equipment: .some(.medicineBall), secondaryMuscles: []),
        "Быстрые скиппинги": ExerciseMedia(gifAsset: "exgif_e1e76I2", equipment: .some(.cable), secondaryMuscles: [.calves, .hamstrings, .glutes]),
        "Вакуум": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Велосипед": ExerciseMedia(gifAsset: "exgif_1ZFqTDN", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Велотренажёр": ExerciseMedia(gifAsset: "exgif_a8VDgLw", equipment: .some(.machine), secondaryMuscles: [.hamstrings, .calves]),
        "Взятие гантелей на грудь": ExerciseMedia(gifAsset: "exgif_7Hg55JG", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings, .calves]),
        "Взятие гири дном вверх с виса": ExerciseMedia(gifAsset: "exgif_4KJEpzb", equipment: .some(.kettlebell), secondaryMuscles: [.forearms]),
        "Взятие гири на грудь одной рукой": ExerciseMedia(gifAsset: nil, equipment: .some(.kettlebell), secondaryMuscles: [.glutes, .lowerBack, .sideDelts, .trapezius]),
        "Взятие гири с пола (Dead Clean)": ExerciseMedia(gifAsset: "exgif_LHWF7us", equipment: .some(.kettlebell), secondaryMuscles: [.glutes, .calves]),
        "Взятие гирь на грудь с виса попеременно": ExerciseMedia(gifAsset: "exgif_I4tibZG", equipment: .some(.kettlebell), secondaryMuscles: [.trapezius]),
        "Взятие двух гирь на грудь": ExerciseMedia(gifAsset: "exgif_7Ba7bQ2", equipment: .some(.kettlebell), secondaryMuscles: [.trapezius, .forearms]),
        "Взятие на грудь в разножку": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.calves, .forearms, .glutes, .hamstrings, .lowerBack, .sideDelts, .trapezius]),
        "Взятие на грудь и жим": ExerciseMedia(gifAsset: "exgif_SGY8Zui", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .glutes, .triceps]),
        "Взятие на грудь и толчок": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.core, .glutes, .hamstrings, .lowerBack, .quadriceps, .trapezius, .triceps]),
        "Взятие на грудь с виса": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.calves, .forearms, .glutes, .hamstrings, .lowerBack, .sideDelts, .trapezius]),
        "Взятие на грудь с плинтов": ExerciseMedia(gifAsset: "exgif_SiWCcTN", equipment: .some(.barbell), secondaryMuscles: [.glutes, .calves]),
        "Взятие штанги на грудь (Clean)": ExerciseMedia(gifAsset: "exgif_SiWCcTN", equipment: .some(.barbell), secondaryMuscles: [.glutes, .calves]),
        "Внешняя ротация плеча с гантелью": ExerciseMedia(gifAsset: "exgif_bmBf7LN", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Внутренняя ротация плеча на блоке": ExerciseMedia(gifAsset: "exgif_YPoVrBi", equipment: .some(.cable), secondaryMuscles: [.triceps]),
        "Внутренняя ротация плеча с резиной": ExerciseMedia(gifAsset: nil, equipment: .some(.bands), secondaryMuscles: []),
        "Воздушные приседания": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .hamstrings]),
        "Восьмёрка с гирей": ExerciseMedia(gifAsset: "exgif_L4ay0PW", equipment: .some(.kettlebell), secondaryMuscles: [.forearms]),
        "Вращение рук с палкой за спиной": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.biceps, .middleChest]),
        "Выпады в ходьбе": ExerciseMedia(gifAsset: "exgif_IZVHb27", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Выпады в ходьбе со штангой": ExerciseMedia(gifAsset: "exgif_t8iSghb", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Выпады назад с гантелями": ExerciseMedia(gifAsset: "exgif_SSsBDwB", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings, .calves]),
        "Выпады назад со штангой": ExerciseMedia(gifAsset: "exgif_VaP75jl", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Выпады с гантелями": ExerciseMedia(gifAsset: "exgif_RRWFUcw", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings, .calves]),
        "Выпады с проносом гири": ExerciseMedia(gifAsset: "exgif_WKMQzCD", equipment: .some(.kettlebell), secondaryMuscles: [.hamstrings, .calves]),
        "Выпады со штангой": ExerciseMedia(gifAsset: "exgif_t8iSghb", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Выпрыгивание из положения на коленях": ExerciseMedia(gifAsset: "exgif_UgDm3oy", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Выпрыгивания в выпаде": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.calves, .glutes, .hamstrings]),
        "Выпрыгивания из приседа": ExerciseMedia(gifAsset: "exgif_LIlE5Tn", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Выход силой": ExerciseMedia(gifAsset: "exgif_yJUHKTn", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .triceps]),
        "Гакк-приседания": ExerciseMedia(gifAsset: "exgif_Qa55kX1", equipment: .some(.other), secondaryMuscles: [.hamstrings, .calves]),
        "Гакк-приседания со штангой за спиной": ExerciseMedia(gifAsset: "exgif_5VCj6iH", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Гильотинный жим": ExerciseMedia(gifAsset: "exgif_GXoaSgn", equipment: .some(.barbell), secondaryMuscles: [.triceps]),
        "Гиперэкстензия": ExerciseMedia(gifAsset: "exgif_zhMwOwE", equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .hamstrings]),
        "Гиперэкстензия на фитболе с весом": ExerciseMedia(gifAsset: "exgif_8urJS9b", equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .hamstrings]),
        "Гоблет-приседания": ExerciseMedia(gifAsset: "exgif_yn8yg1r", equipment: .some(.dumbbell), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Горизонт (Planche)": ExerciseMedia(gifAsset: "exgif_YZ4961r", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Горизонтальный велотренажёр": ExerciseMedia(gifAsset: nil, equipment: .some(.machine), secondaryMuscles: [.calves, .glutes, .hamstrings]),
        "Гребля (Concept2)": ExerciseMedia(gifAsset: nil, equipment: .some(.machine), secondaryMuscles: [.biceps, .calves, .glutes, .hamstrings, .lowerBack, .trapezius]),
        "Грудинные подтягивания Жиронды": ExerciseMedia(gifAsset: "exgif_IL0JUxR", equipment: .some(.bodyweight), secondaryMuscles: [.biceps]),
        "Двойные прыжки на скакалке": ExerciseMedia(gifAsset: "exgif_e1e76I2", equipment: .some(.cable), secondaryMuscles: [.calves, .hamstrings, .glutes]),
        "Джампинг Джек": ExerciseMedia(gifAsset: "exgif_1g5bPpA", equipment: .some(.bodyweight), secondaryMuscles: [.calves]),
        "Диагональные прыжки в шаге": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .calves, .hamstrings]),
        "Динамическая растяжка груди": ExerciseMedia(gifAsset: "exgif_3uj0Ozg", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Динамическая растяжка спины (махи руками)": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Египетские махи (Egyptian Lateral Raise)": ExerciseMedia(gifAsset: "exgif_wEulIzp", equipment: .some(.cable), secondaryMuscles: [.trapezius, .triceps]),
        "Жим Арнольда": ExerciseMedia(gifAsset: "exgif_Xy4jlWA", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Жим Арнольда с гирей": ExerciseMedia(gifAsset: "exgif_UM8mgyG", equipment: .some(.kettlebell), secondaryMuscles: [.triceps, .trapezius]),
        "Жим Брэдфорда": ExerciseMedia(gifAsset: "exgif_dCPESfR", equipment: .some(.barbell), secondaryMuscles: [.triceps, .trapezius]),
        "Жим Лэндмайн стоя одной рукой над головой": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.middleChest, .triceps]),
        "Жим Свенда": ExerciseMedia(gifAsset: "exgif_I1OBLnn", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Жим Смита лежа": ExerciseMedia(gifAsset: "exgif_trqKQv2", equipment: .some(.machine), secondaryMuscles: [.triceps]),
        "Жим Смита на наклонной": ExerciseMedia(gifAsset: "exgif_5v7KYld", equipment: .some(.machine), secondaryMuscles: [.triceps]),
        "Жим Смита на скамье с обратным наклоном": ExerciseMedia(gifAsset: "exgif_ETZfAbZ", equipment: .some(.machine), secondaryMuscles: [.triceps]),
        "Жим в Смите с обратным наклоном": ExerciseMedia(gifAsset: "exgif_ETZfAbZ", equipment: .some(.machine), secondaryMuscles: [.triceps]),
        "Жим в Хаммере": ExerciseMedia(gifAsset: "exgif_T0yTjgW", equipment: .some(.machine), secondaryMuscles: [.triceps]),
        "Жим в Хаммере на наклоне вверх": ExerciseMedia(gifAsset: "exgif_jHAnWmT", equipment: .some(.machine), secondaryMuscles: [.triceps]),
        "Жим в Хаммере на наклоне вниз": ExerciseMedia(gifAsset: "exgif_vsVoPHt", equipment: .some(.machine), secondaryMuscles: [.triceps]),
        "Жим в Хаммере одной рукой": ExerciseMedia(gifAsset: "exgif_T0yTjgW", equipment: .some(.machine), secondaryMuscles: [.triceps]),
        "Жим в кроссовере на наклонной сидя": ExerciseMedia(gifAsset: "exgif_Vh0GsK4", equipment: .some(.cable), secondaryMuscles: [.triceps]),
        "Жим в кроссовере попеременно": ExerciseMedia(gifAsset: "exgif_KHPZL0b", equipment: .some(.cable), secondaryMuscles: [.triceps, .trapezius]),
        "Жим в раме с упоров (Pin press)": ExerciseMedia(gifAsset: "exgif_bndCa3Q", equipment: .some(.barbell), secondaryMuscles: [.middleChest, .forearms, .lats, .trapezius, .sideDelts]),
        "Жим в стойке на руках": ExerciseMedia(gifAsset: "exgif_rQxwMxO", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Жим в тренажере сидя": ExerciseMedia(gifAsset: "exgif_DOoWcnA", equipment: .some(.machine), secondaryMuscles: [.triceps]),
        "Жим гантелей лежа": ExerciseMedia(gifAsset: "exgif_SpYC0Kp", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Жим гантелей лежа нейтральным хватом": ExerciseMedia(gifAsset: "exgif_pP8wP2P", equipment: .some(.dumbbell), secondaryMuscles: [.sideDelts, .triceps]),
        "Жим гантелей на наклонной скамье": ExerciseMedia(gifAsset: "exgif_ns0SIbU", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Жим гантелей на скамье с обратным наклоном": ExerciseMedia(gifAsset: "exgif_DwhEmmE", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Жим гантелей нейтральным хватом на наклонной": ExerciseMedia(gifAsset: "exgif_PG1kcIb", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Жим гантелей с пола": ExerciseMedia(gifAsset: nil, equipment: .some(.dumbbell), secondaryMuscles: [.middleChest, .sideDelts]),
        "Жим гантелей сидя": ExerciseMedia(gifAsset: "exgif_znQUdHY", equipment: .some(.dumbbell), secondaryMuscles: [.triceps, .trapezius]),
        "Жим гантелей стоя": ExerciseMedia(gifAsset: "exgif_A6wtbuL", equipment: .some(.dumbbell), secondaryMuscles: [.triceps, .trapezius]),
        "Жим гантели над головой одной рукой": ExerciseMedia(gifAsset: "exgif_84RyJf8", equipment: .some(.dumbbell), secondaryMuscles: [.triceps, .trapezius]),
        "Жим гантели одной рукой лёжа": ExerciseMedia(gifAsset: "exgif_zGSIWQi", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Жим гири одной рукой": ExerciseMedia(gifAsset: "exgif_yCvYdi7", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Жим гири с пола одной рукой": ExerciseMedia(gifAsset: "exgif_rg59QCH", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Жим гири с пола с переносом ноги": ExerciseMedia(gifAsset: nil, equipment: .some(.kettlebell), secondaryMuscles: [.sideDelts, .triceps]),
        "Жим гири сидя на полу": ExerciseMedia(gifAsset: "exgif_BkxB8LW", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Жим двух гирь стоя": ExerciseMedia(gifAsset: "exgif_blBXysN", equipment: .some(.kettlebell), secondaryMuscles: [.triceps, .trapezius]),
        "Жим из-за головы": ExerciseMedia(gifAsset: "exgif_xDh0lJr", equipment: .some(.barbell), secondaryMuscles: [.triceps, .trapezius]),
        "Жим лёжа с досок (board press)": ExerciseMedia(gifAsset: "exgif_EIeI8Vf", equipment: .some(.barbell), secondaryMuscles: [.triceps]),
        "Жим лёжа с резиновыми лентами": ExerciseMedia(gifAsset: "exgif_khlHMqs", equipment: .some(.bands), secondaryMuscles: [.triceps]),
        "Жим лёжа с цепями": ExerciseMedia(gifAsset: "exgif_EIeI8Vf", equipment: .some(.barbell), secondaryMuscles: [.triceps]),
        "Жим на плечи в кроссовере сидя": ExerciseMedia(gifAsset: "exgif_PzQanLE", equipment: .some(.cable), secondaryMuscles: [.triceps, .trapezius]),
        "Жим на плечи с резиной": ExerciseMedia(gifAsset: "exgif_peAeMR3", equipment: .some(.bands), secondaryMuscles: [.triceps, .trapezius]),
        "Жим над головой в Смите": ExerciseMedia(gifAsset: "exgif_903mzG8", equipment: .some(.machine), secondaryMuscles: [.triceps, .trapezius]),
        "Жим над головой в кроссовере": ExerciseMedia(gifAsset: "exgif_PzQanLE", equipment: .some(.cable), secondaryMuscles: [.triceps, .trapezius]),
        "Жим ногами": ExerciseMedia(gifAsset: "exgif_10Z2DXU", equipment: .some(.other), secondaryMuscles: [.hamstrings, .calves]),
        "Жим ногами одной ногой": ExerciseMedia(gifAsset: "exgif_WWD6FzI", equipment: .some(.other), secondaryMuscles: [.hamstrings, .calves]),
        "Жим ногами под наклоном 45°": ExerciseMedia(gifAsset: "exgif_10Z2DXU", equipment: .some(.other), secondaryMuscles: [.hamstrings, .calves]),
        "Жим от груди в кроссовере стоя": ExerciseMedia(gifAsset: nil, equipment: .some(.cable), secondaryMuscles: [.sideDelts, .triceps]),
        "Жим с наклоном с гирей (bent press)": ExerciseMedia(gifAsset: "exgif_kjE55n5", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Жим узким хватом": ExerciseMedia(gifAsset: "exgif_J6Dx1Mu", equipment: .some(.barbell), secondaryMuscles: [.middleChest, .sideDelts]),
        "Жим узким хватом в Смите": ExerciseMedia(gifAsset: "exgif_WcHl7ru", equipment: .some(.machine), secondaryMuscles: [.middleChest, .sideDelts]),
        "Жим узким хватом с французским на наклоне вниз": ExerciseMedia(gifAsset: "exgif_LMGXZn8", equipment: .some(.barbell), secondaryMuscles: [.middleChest, .sideDelts]),
        "Жим швунг": ExerciseMedia(gifAsset: "exgif_FS63wTN", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Жим штанги лежа": ExerciseMedia(gifAsset: "exgif_EIeI8Vf", equipment: .some(.barbell), secondaryMuscles: [.triceps]),
        "Жим штанги на наклонной скамье": ExerciseMedia(gifAsset: "exgif_3TZduzM", equipment: .some(.barbell), secondaryMuscles: [.triceps]),
        "Жим штанги на скамье с обратным наклоном": ExerciseMedia(gifAsset: "exgif_GrO65fd", equipment: .some(.barbell), secondaryMuscles: [.triceps]),
        "Жим штанги обратным хватом": ExerciseMedia(gifAsset: "exgif_945zpRg", equipment: .some(.barbell), secondaryMuscles: [.triceps]),
        "Жим штанги с пола": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.middleChest, .sideDelts]),
        "Жим штанги стоя": ExerciseMedia(gifAsset: "exgif_wdRZISl", equipment: .some(.barbell), secondaryMuscles: [.triceps, .trapezius]),
        "Жим штанги широким хватом": ExerciseMedia(gifAsset: "exgif_JsKq9so", equipment: .some(.barbell), secondaryMuscles: [.triceps]),
        "Задний вис (Back Lever)": ExerciseMedia(gifAsset: "exgif_GaSzzuh", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Заныривания на коробку (Box Jumps)": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.glutes, .calves, .quadriceps]),
        "Зашагивание с подъемом колена": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .quadriceps]),
        "Зашагивания на платформу со штангой": ExerciseMedia(gifAsset: "exgif_Kxquu2E", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Зашагивания на скамью": ExerciseMedia(gifAsset: "exgif_aXtJhlg", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings, .calves]),
        "Изометрия шеи вперёд-назад": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Казацкие приседания": ExerciseMedia(gifAsset: "exgif_GWoKnIm", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Канаты (Battle Ropes)": ExerciseMedia(gifAsset: "exgif_RJa4tCo", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Касания пяток лёжа": ExerciseMedia(gifAsset: "exgif_qaZVsGk", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Кипинг подтягивания": ExerciseMedia(gifAsset: "exgif_lBDjFxJ", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Концентрированные сгибания": ExerciseMedia(gifAsset: "exgif_gvsWLQw", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Косые скручивания": ExerciseMedia(gifAsset: "exgif_cJgSTmh", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Косые скручивания на наклонной скамье": ExerciseMedia(gifAsset: "exgif_9Ap7miY", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Кроссовер с верхних блоков": ExerciseMedia(gifAsset: "exgif_j7XMAyn", equipment: .some(.cable), secondaryMuscles: [.triceps]),
        "Кроссовер с нижних блоков": ExerciseMedia(gifAsset: "exgif_FVmZVhk", equipment: .some(.cable), secondaryMuscles: [.triceps]),
        "Кроссовер с резиной": ExerciseMedia(gifAsset: "exgif_0CXGHya", equipment: .some(.cable), secondaryMuscles: [.triceps]),
        "Кроссовер со средних блоков": ExerciseMedia(gifAsset: "exgif_Pr9Rhf4", equipment: .some(.cable), secondaryMuscles: [.triceps]),
        "Круговые движения бедром стоя": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.glutes]),
        "Круговые движения руками": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.trapezius]),
        "Круговые разведения гантелей лёжа": ExerciseMedia(gifAsset: "exgif_RSOsp5d", equipment: .some(.dumbbell), secondaryMuscles: [.triceps, .forearms]),
        "Кубинская ротация с гантелями": ExerciseMedia(gifAsset: "exgif_QfAKy1G", equipment: .some(.dumbbell), secondaryMuscles: [.triceps, .trapezius]),
        "Кубинский жим": ExerciseMedia(gifAsset: "exgif_QfAKy1G", equipment: .some(.dumbbell), secondaryMuscles: [.triceps, .trapezius]),
        "Лазание по канату": ExerciseMedia(gifAsset: "exgif_yaAxcQr", equipment: .some(.cable), secondaryMuscles: [.forearms, .biceps]),
        "Лицевая тяга": ExerciseMedia(gifAsset: "exgif_wqNPGCg", equipment: .some(.cable), secondaryMuscles: [.biceps]),
        "Лопаточные подтягивания (Scapular Pull-ups)": ExerciseMedia(gifAsset: "exgif_uTBt1HV", equipment: .some(.bodyweight), secondaryMuscles: [.biceps]),
        "Лыжный тренажер (SkiErg)": ExerciseMedia(gifAsset: "exgif_vpQaQkH", equipment: nil, secondaryMuscles: [.forearms]),
        "Лэндмайн 180 (ротация)": ExerciseMedia(gifAsset: "exgif_QYysSLV", equipment: .some(.barbell), secondaryMuscles: [.glutes, .lowerBack, .sideDelts]),
        "Лэндмайн-джаммер": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.core, .calves, .middleChest, .hamstrings, .quadriceps, .triceps]),
        "Махи в наклоне": ExerciseMedia(gifAsset: "exgif_8DiFDVA", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Махи в наклоне на блоке": ExerciseMedia(gifAsset: "exgif_aqvSOQE", equipment: .some(.cable), secondaryMuscles: []),
        "Махи в стороны лёжа на наклонной": ExerciseMedia(gifAsset: "exgif_aTNKZiC", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Махи в стороны на блоке": ExerciseMedia(gifAsset: "exgif_goJ6ezq", equipment: .some(.cable), secondaryMuscles: [.trapezius, .triceps]),
        "Махи в стороны с переводом перед собой": ExerciseMedia(gifAsset: "exgif_xMjBKwn", equipment: .some(.dumbbell), secondaryMuscles: [.biceps]),
        "Махи в стороны с резиной": ExerciseMedia(gifAsset: nil, equipment: .some(.bands), secondaryMuscles: []),
        "Махи гантелями в стороны": ExerciseMedia(gifAsset: "exgif_DsgkuIt", equipment: .some(.dumbbell), secondaryMuscles: [.trapezius]),
        "Махи гирей": ExerciseMedia(gifAsset: "exgif_UHJlbu3", equipment: .some(.kettlebell), secondaryMuscles: [.hamstrings]),
        "Махи гирей американские": ExerciseMedia(gifAsset: "exgif_UHJlbu3", equipment: .some(.kettlebell), secondaryMuscles: [.hamstrings]),
        "Махи гирей русские": ExerciseMedia(gifAsset: "exgif_UHJlbu3", equipment: .some(.kettlebell), secondaryMuscles: [.hamstrings]),
        "Махи лежа на боку": ExerciseMedia(gifAsset: "exgif_53Ttlck", equipment: .some(.dumbbell), secondaryMuscles: [.trapezius]),
        "Махи на блоке за спиной": ExerciseMedia(gifAsset: "exgif_goJ6ezq", equipment: .some(.cable), secondaryMuscles: [.trapezius, .triceps]),
        "Махи на задние дельты лёжа на скамье": ExerciseMedia(gifAsset: "exgif_Ion0XWz", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Махи ногой вперёд (динамическая растяжка)": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Махи перед собой на блоке": ExerciseMedia(gifAsset: "exgif_u2X71Np", equipment: .some(.cable), secondaryMuscles: [.triceps, .forearms]),
        "Махи перед собой с гантелями": ExerciseMedia(gifAsset: "exgif_3eGE2JC", equipment: .some(.dumbbell), secondaryMuscles: [.biceps]),
        "Махи перед собой со штангой": ExerciseMedia(gifAsset: "exgif_b2Uoz54", equipment: .some(.barbell), secondaryMuscles: [.biceps, .triceps]),
        "Махи сидя": ExerciseMedia(gifAsset: "exgif_hxyTtWj", equipment: .some(.dumbbell), secondaryMuscles: [.trapezius]),
        "Мельница с гирей": ExerciseMedia(gifAsset: "exgif_9Tkqa9O", equipment: .some(.kettlebell), secondaryMuscles: [.glutes, .hamstrings, .sideDelts, .triceps]),
        "Мельница с гирей (продвинутая)": ExerciseMedia(gifAsset: "exgif_Kal9cQQ", equipment: .some(.kettlebell), secondaryMuscles: [.glutes, .hamstrings, .sideDelts]),
        "Мельница с двумя гирями": ExerciseMedia(gifAsset: "exgif_OaE7CpD", equipment: .some(.kettlebell), secondaryMuscles: [.hamstrings]),
        "Молотки": ExerciseMedia(gifAsset: "exgif_slDvUAU", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Молотки с канатом": ExerciseMedia(gifAsset: "exgif_HPlPoQA", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Молотковые сгибания на наклонной скамье": ExerciseMedia(gifAsset: "exgif_ByX0WxV", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Молотковые сгибания на скамье Скотта": ExerciseMedia(gifAsset: "exgif_fy7Tgy4", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Мускульный рывок": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.glutes, .lowerBack, .quadriceps, .sideDelts, .triceps]),
        "Наклоны к носкам стоя": ExerciseMedia(gifAsset: "exgif_BbfB8Gb", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Негативные подтягивания": ExerciseMedia(gifAsset: "exgif_lBDjFxJ", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Ножницы лёжа": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Нордическое сгибание": ExerciseMedia(gifAsset: "exgif_ms7tjSG", equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .calves]),
        "Обратная гиперэкстензия": ExerciseMedia(gifAsset: "exgif_Krmb3cB", equipment: .some(.machine), secondaryMuscles: [.hamstrings]),
        "Обратная гиперэкстензия со штангой": ExerciseMedia(gifAsset: "exgif_OrETs32", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Обратная рубка дров на блоке": ExerciseMedia(gifAsset: nil, equipment: .some(.cable), secondaryMuscles: [.sideDelts]),
        "Обратные отжимания от скамьи": ExerciseMedia(gifAsset: "exgif_9RT8oQW", equipment: .some(.bodyweight), secondaryMuscles: [.middleChest, .sideDelts]),
        "Обратные отжимания от скамьи с весом": ExerciseMedia(gifAsset: "exgif_MU9HnE7", equipment: .some(.bodyweight), secondaryMuscles: [.middleChest, .sideDelts]),
        "Обратные разведения в тренажере": ExerciseMedia(gifAsset: "exgif_myfUsKf", equipment: .some(.machine), secondaryMuscles: []),
        "Обратные сгибания на блоке": ExerciseMedia(gifAsset: "exgif_eOG0r6v", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Обратные сгибания на скамье Скотта": ExerciseMedia(gifAsset: "exgif_4LIG9xr", equipment: .some(.barbell), secondaryMuscles: [.forearms]),
        "Обратные сгибания с гантелями": ExerciseMedia(gifAsset: "exgif_0IgNjSM", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Обратные скручивания": ExerciseMedia(gifAsset: "exgif_nCU1Ekp", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Обратные скручивания на TRX": ExerciseMedia(gifAsset: "exgif_R1WYG5D", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Обратные скручивания на наклонной скамье": ExerciseMedia(gifAsset: "exgif_nCU1Ekp", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Одноногая румынская тяга": ExerciseMedia(gifAsset: "exgif_gKozT8X", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings]),
        "Однорукое разгибание на блоке": ExerciseMedia(gifAsset: "exgif_qRZ5S1N", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Отведение ноги (Cable Kickback)": ExerciseMedia(gifAsset: nil, equipment: .some(.cable), secondaryMuscles: [.hamstrings]),
        "Отведение ноги в кроссовере": ExerciseMedia(gifAsset: "exgif_Kpajagk", equipment: .some(.cable), secondaryMuscles: [.hamstrings]),
        "Отведение ноги назад в тренажере": ExerciseMedia(gifAsset: "exgif_OPqShYN", equipment: .some(.machine), secondaryMuscles: [.hamstrings]),
        "Отжимание с переходом в боковую планку": ExerciseMedia(gifAsset: "exgif_KhHJ338", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания Spider-Man": ExerciseMedia(gifAsset: "exgif_P9GFBME", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Отжимания Лучник": ExerciseMedia(gifAsset: "exgif_A9qxk2F", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания на TRX": ExerciseMedia(gifAsset: "exgif_IaGQCrC", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания на брусьях": ExerciseMedia(gifAsset: "exgif_9WTm7dq", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания на брусьях в гравитроне": ExerciseMedia(gifAsset: "exgif_J60bN17", equipment: .some(.machine), secondaryMuscles: [.middleChest, .sideDelts]),
        "Отжимания на брусьях узким хватом": ExerciseMedia(gifAsset: "exgif_X6C6i5Y", equipment: .some(.bodyweight), secondaryMuscles: [.middleChest, .sideDelts]),
        "Отжимания на кольцах (дипы)": ExerciseMedia(gifAsset: "exgif_ezTvXcr", equipment: .some(.bodyweight), secondaryMuscles: [.middleChest, .sideDelts]),
        "Отжимания на одной руке": ExerciseMedia(gifAsset: "exgif_MUic5zN", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания от возвышения": ExerciseMedia(gifAsset: "exgif_B1EVP9F", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания от пола": ExerciseMedia(gifAsset: "exgif_I4hDWkc", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания по кругу (часы)": ExerciseMedia(gifAsset: "exgif_CMAxnsG", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания с возвышения для ног": ExerciseMedia(gifAsset: "exgif_i5cEhka", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания с ногами на фитболе": ExerciseMedia(gifAsset: "exgif_4cWjYEN", equipment: .some(.exerciseBall), secondaryMuscles: [.sideDelts, .triceps]),
        "Отжимания с хлопком": ExerciseMedia(gifAsset: "exgif_wigSg76", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Отжимания узким хватом (Алмаз)": ExerciseMedia(gifAsset: "exgif_soIB2rj", equipment: .some(.bodyweight), secondaryMuscles: [.middleChest, .sideDelts]),
        "Отжимания широким хватом": ExerciseMedia(gifAsset: "exgif_JmMVpR3", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Переворот покрышки": ExerciseMedia(gifAsset: "exgif_oZjMu1t", equipment: .some(.other), secondaryMuscles: [.hamstrings]),
        "Передний вис (Front Lever)": ExerciseMedia(gifAsset: "exgif_PkCN2lv", equipment: .some(.bodyweight), secondaryMuscles: [.lats, .forearms]),
        "Перекрестные скручивания": ExerciseMedia(gifAsset: "exgif_rbu5UUb", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Перекрёстный подъем гантелей на бицепс": ExerciseMedia(gifAsset: "exgif_Qyk5J3p", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Планка": ExerciseMedia(gifAsset: "exgif_CosupLu", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Плиометрические отжимания через гирю": ExerciseMedia(gifAsset: "exgif_ktf3nvW", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Подтягивание колена к груди лёжа": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .lowerBack]),
        "Подтягивание коленей к груди сидя": ExerciseMedia(gifAsset: "exgif_OyoZ3Pu", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подтягивание коленей лёжа": ExerciseMedia(gifAsset: "exgif_OyoZ3Pu", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подтягивание коленей на фитболе": ExerciseMedia(gifAsset: "exgif_UQr48Oi", equipment: .some(.exerciseBall), secondaryMuscles: []),
        "Подтягивание ног на скамье": ExerciseMedia(gifAsset: "exgif_OyoZ3Pu", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подтягивания": ExerciseMedia(gifAsset: "exgif_lBDjFxJ", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Подтягивания Лучник": ExerciseMedia(gifAsset: "exgif_72BC5Za", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Подтягивания из стороны в сторону": ExerciseMedia(gifAsset: "exgif_isAAZWA", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Подтягивания нейтральным хватом": ExerciseMedia(gifAsset: "exgif_0V2YQjW", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Подтягивания обратным хватом": ExerciseMedia(gifAsset: "exgif_T2mxWqc", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Подтягивания разнохватом": ExerciseMedia(gifAsset: "exgif_T8UpLkb", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Подтягивания с дополнительным весом": ExerciseMedia(gifAsset: "exgif_HMzLjXx", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Подтягивания с подъёмом коленей": ExerciseMedia(gifAsset: "exgif_bmwlYvD", equipment: .some(.bodyweight), secondaryMuscles: [.forearms, .biceps]),
        "Подтягивания с резиной": ExerciseMedia(gifAsset: "exgif_r1XNRYB", equipment: .some(.bands), secondaryMuscles: [.biceps, .forearms]),
        "Подъем EZ-штанги на бицепс": ExerciseMedia(gifAsset: "exgif_6TG6x2w", equipment: .some(.ezbar), secondaryMuscles: [.forearms]),
        "Подъем блина перед собой": ExerciseMedia(gifAsset: "exgif_e4aFmFY", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Подъем бревна над головой": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.core, .middleChest, .glutes, .hamstrings, .lowerBack, .trapezius, .quadriceps, .triceps]),
        "Подъем гантелей на бицепс сидя": ExerciseMedia(gifAsset: "exgif_TiaZTxx", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Подъем гантелей на бицепс стоя": ExerciseMedia(gifAsset: "exgif_BU15nH4", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Подъем гантелей на наклонной скамье": ExerciseMedia(gifAsset: "exgif_ae9UoXQ", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Подъем мешка на плечо": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.core, .biceps, .calves, .forearms, .glutes, .hamstrings, .lowerBack, .trapezius, .sideDelts]),
        "Подъем на носок на одной ноге с гантелью": ExerciseMedia(gifAsset: "exgif_fKZgDEO", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Подъем ног в висе": ExerciseMedia(gifAsset: "exgif_I3tsCnC", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подъем ног в упоре": ExerciseMedia(gifAsset: "exgif_weoDEpH", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подъем ног к перекладине (Toes to Bar)": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подъем ног лежа": ExerciseMedia(gifAsset: "exgif_WhuFnR7", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подъем по лестнице": ExerciseMedia(gifAsset: "exgif_j9Q5crt", equipment: .some(.machine), secondaryMuscles: [.hamstrings, .glutes, .calves]),
        "Подъем сэндбэга на плечо": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.core, .biceps, .calves, .forearms, .glutes, .hamstrings, .lowerBack, .trapezius, .sideDelts]),
        "Подъем таза на мяче": ExerciseMedia(gifAsset: "exgif_GOJKFfO", equipment: .some(.exerciseBall), secondaryMuscles: [.hamstrings, .calves]),
        "Подъем штанги на бицепс": ExerciseMedia(gifAsset: "exgif_25GPyDY", equipment: .some(.barbell), secondaryMuscles: [.forearms]),
        "Подъем штанги обратным хватом": ExerciseMedia(gifAsset: "exgif_xNrS20v", equipment: .some(.barbell), secondaryMuscles: [.forearms]),
        "Подъем штанги широким хватом": ExerciseMedia(gifAsset: "exgif_NdIb5Z1", equipment: .some(.barbell), secondaryMuscles: [.forearms]),
        "Подъемы гантелей в плоскости лопатки (скапция)": ExerciseMedia(gifAsset: nil, equipment: .some(.dumbbell), secondaryMuscles: [.trapezius]),
        "Подъемы на носки в жиме ногами": ExerciseMedia(gifAsset: "exgif_ykHcWme", equipment: .some(.other), secondaryMuscles: [.hamstrings]),
        "Подъемы на носки в наклоне (ослик)": ExerciseMedia(gifAsset: "exgif_u5ESqzH", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .glutes]),
        "Подъемы на носки с гантелями стоя": ExerciseMedia(gifAsset: "exgif_dPmaUaU", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Подъемы на носки с резиной": ExerciseMedia(gifAsset: "exgif_9JprnPh", equipment: .some(.bands), secondaryMuscles: []),
        "Подъемы на носки сидя": ExerciseMedia(gifAsset: "exgif_bOOdeyc", equipment: .some(.machine), secondaryMuscles: []),
        "Подъемы на носки со штангой стоя": ExerciseMedia(gifAsset: "exgif_8ozhUIZ", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .glutes]),
        "Подъемы на носки стоя": ExerciseMedia(gifAsset: "exgif_bJYHBIN", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подъём корпуса (Sit-Up)": ExerciseMedia(gifAsset: "exgif_Bn6TXyO", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подъём корпуса на 3/4": ExerciseMedia(gifAsset: "exgif_2gPfomN", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Подъём корпуса с жимом штанги": ExerciseMedia(gifAsset: "exgif_wnEscH8", equipment: .some(.barbell), secondaryMuscles: [.middleChest, .sideDelts, .triceps]),
        "Подъёмы на носки в Смите": ExerciseMedia(gifAsset: "exgif_6MaEjVA", equipment: .some(.machine), secondaryMuscles: [.hamstrings, .glutes]),
        "Подъёмы перед собой на наклонной скамье": ExerciseMedia(gifAsset: nil, equipment: .some(.dumbbell), secondaryMuscles: []),
        "Попеременный жим гантелей (See-Saw)": ExerciseMedia(gifAsset: "exgif_izMnLqz", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Попеременный жим гирь (Качели)": ExerciseMedia(gifAsset: "exgif_UDm6cGl", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Приседания Джефферсона": ExerciseMedia(gifAsset: "exgif_pkSoCW9", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания Зерчера": ExerciseMedia(gifAsset: "exgif_LSTChY9", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания Пистолетик": ExerciseMedia(gifAsset: "exgif_nqs5HGV", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания Пистолетик с поддержкой": ExerciseMedia(gifAsset: "exgif_nqs5HGV", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания в Смите": ExerciseMedia(gifAsset: "exgif_jFtipLl", equipment: .some(.machine), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания на коленях со штангой": ExerciseMedia(gifAsset: "exgif_oR7O9LW", equipment: .some(.barbell), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Приседания на коробку": ExerciseMedia(gifAsset: "exgif_W9pFVv1", equipment: .some(.barbell), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Приседания на коробку с резиной": ExerciseMedia(gifAsset: "exgif_TUZLh71", equipment: .some(.bands), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания на коробку с цепями": ExerciseMedia(gifAsset: "exgif_W9pFVv1", equipment: .some(.barbell), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Приседания плие с гантелью": ExerciseMedia(gifAsset: "exgif_HsvHqgf", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания с гантелями": ExerciseMedia(gifAsset: "exgif_HsvHqgf", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания с гирей над головой одной рукой": ExerciseMedia(gifAsset: nil, equipment: .some(.kettlebell), secondaryMuscles: [.calves, .glutes, .hamstrings, .sideDelts]),
        "Приседания с прыжком": ExerciseMedia(gifAsset: "exgif_LIlE5Tn", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания с широкой постановкой ног": ExerciseMedia(gifAsset: "exgif_s7HX1BY", equipment: .some(.barbell), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Приседания со штангой": ExerciseMedia(gifAsset: "exgif_qXTaZnJ", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания со штангой Low Bar": ExerciseMedia(gifAsset: "exgif_bTpEUcm", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Приседания со штангой на скамью (box squat)": ExerciseMedia(gifAsset: "exgif_W9pFVv1", equipment: .some(.barbell), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Приседания со штангой над головой": ExerciseMedia(gifAsset: "exgif_gfk9kD4", equipment: .some(.barbell), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Прогулка медведя": ExerciseMedia(gifAsset: "exgif_0Yz8WdV", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Прогулка медведя с тягой": ExerciseMedia(gifAsset: "exgif_0Yz8WdV", equipment: .some(.bodyweight), secondaryMuscles: [.triceps]),
        "Прогулка с ярмом": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.core, .glutes, .calves, .hamstrings, .lowerBack]),
        "Прогулка фермера": ExerciseMedia(gifAsset: "exgif_qPEzJjA", equipment: .some(.dumbbell), secondaryMuscles: [.calves, .forearms]),
        "Протяжка в взятии (Clean Pull)": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.forearms, .glutes, .hamstrings, .lowerBack, .trapezius]),
        "Протяжка салазок с жимом": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.calves, .glutes, .hamstrings, .quadriceps, .sideDelts, .triceps]),
        "Прыжки в длину": ExerciseMedia(gifAsset: "exgif_uZKq7lo", equipment: .some(.bodyweight), secondaryMuscles: [.calves, .hamstrings, .glutes]),
        "Прыжки в стороны (Lateral Jumps)": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .calves, .hamstrings, .quadriceps]),
        "Прыжки на скакалке": ExerciseMedia(gifAsset: "exgif_e1e76I2", equipment: .some(.cable), secondaryMuscles: [.calves, .hamstrings, .glutes]),
        "Прыжки на скакалке крест-накрест": ExerciseMedia(gifAsset: "exgif_e1e76I2", equipment: .some(.cable), secondaryMuscles: [.calves, .hamstrings, .glutes]),
        "Прыжковые выпады со сменой ног": ExerciseMedia(gifAsset: "exgif_Eh2v5Iu", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Прыжок в глубину": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.calves, .glutes, .hamstrings]),
        "Прыжок в глубину с запрыгиванием": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .calves, .hamstrings]),
        "Пуловер на блоке прямыми руками на наклонной": ExerciseMedia(gifAsset: "exgif_1PK5Uo3", equipment: .some(.cable), secondaryMuscles: [.triceps]),
        "Пуловер на верхнем блоке прямыми руками": ExerciseMedia(gifAsset: "exgif_x69MAlq", equipment: .some(.cable), secondaryMuscles: [.biceps]),
        "Пуловер с гантелью": ExerciseMedia(gifAsset: "exgif_9XjtHvS", equipment: .some(.dumbbell), secondaryMuscles: [.triceps]),
        "Пуловер со штангой": ExerciseMedia(gifAsset: "exgif_cA9FuWG", equipment: .some(.barbell), secondaryMuscles: [.triceps]),
        "Разведение ног в тренажере": ExerciseMedia(gifAsset: "exgif_CHpahtl", equipment: .some(.machine), secondaryMuscles: [.glutes, .hamstrings]),
        "Разведение резины перед собой": ExerciseMedia(gifAsset: nil, equipment: .some(.bands), secondaryMuscles: [.trapezius]),
        "Разведения с резиной на задние дельты": ExerciseMedia(gifAsset: "exgif_sTfvVsG", equipment: .some(.bands), secondaryMuscles: [.trapezius]),
        "Разгибание кистей со штангой": ExerciseMedia(gifAsset: "exgif_LsZkfU6", equipment: .some(.barbell), secondaryMuscles: [.biceps]),
        "Разгибание на трицепс": ExerciseMedia(gifAsset: "exgif_Hx1WC8I", equipment: .some(.cable), secondaryMuscles: []),
        "Разгибание на трицепс из-за головы с канатом": ExerciseMedia(gifAsset: "exgif_2IxROQ1", equipment: .some(.cable), secondaryMuscles: []),
        "Разгибание на трицепс с резиной из-за головы": ExerciseMedia(gifAsset: nil, equipment: .some(.bands), secondaryMuscles: []),
        "Разгибание ног в тренажере": ExerciseMedia(gifAsset: "exgif_my33uHU", equipment: .some(.machine), secondaryMuscles: [.hamstrings]),
        "Разгибание одной рукой из-за головы на нижнем блоке": ExerciseMedia(gifAsset: "exgif_sYCcnon", equipment: .some(.cable), secondaryMuscles: [.middleChest, .sideDelts]),
        "Разгибание рук на блоке": ExerciseMedia(gifAsset: "exgif_3ZflifB", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Разгибание рук на блоке обратным хватом": ExerciseMedia(gifAsset: "exgif_VjYliFZ", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Разгибание рук на блоке с канатом": ExerciseMedia(gifAsset: "exgif_dU605di", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Разгибание руки в наклоне с гантелью": ExerciseMedia(gifAsset: "exgif_bQy2Eni", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Разгибание трицепса в тренажере": ExerciseMedia(gifAsset: "exgif_Ser9eQp", equipment: .some(.machine), secondaryMuscles: []),
        "Разгибания на блоке из-за головы": ExerciseMedia(gifAsset: "exgif_1xHyxys", equipment: .some(.cable), secondaryMuscles: []),
        "Раскатка штанги стоя": ExerciseMedia(gifAsset: "exgif_xnInPfE", equipment: .some(.barbell), secondaryMuscles: [.lowerBack, .sideDelts]),
        "Растяжка ИТ-тракта и ягодиц": ExerciseMedia(gifAsset: "exgif_DeDThfG", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Растяжка бегуна": ExerciseMedia(gifAsset: "exgif_0mB6wHO", equipment: .some(.bodyweight), secondaryMuscles: [.calves]),
        "Растяжка бедра 90/90": ExerciseMedia(gifAsset: "exgif_99rWm7w", equipment: .some(.bodyweight), secondaryMuscles: [.glutes]),
        "Растяжка бицепса стоя": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.middleChest, .sideDelts]),
        "Растяжка боков лёжа на боку": ExerciseMedia(gifAsset: "exgif_jDOKRM5", equipment: .some(.bodyweight), secondaryMuscles: [.glutes]),
        "Растяжка в широком седе": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .calves]),
        "Растяжка верха спины": ExerciseMedia(gifAsset: "exgif_GSDioYu", equipment: .some(.bodyweight), secondaryMuscles: [.trapezius]),
        "Растяжка груди и передних дельт с палкой": ExerciseMedia(gifAsset: "exgif_Uto7l43", equipment: .some(.bodyweight), secondaryMuscles: [.sideDelts]),
        "Растяжка груди на фитболе": ExerciseMedia(gifAsset: "exgif_ykA5tU7", equipment: .some(.exerciseBall), secondaryMuscles: [.triceps]),
        "Растяжка задней поверхности бедра и голени": ExerciseMedia(gifAsset: "exgif_xTjr103", equipment: .some(.cable), secondaryMuscles: [.calves]),
        "Растяжка задней поверхности бедра лёжа": ExerciseMedia(gifAsset: "exgif_sU5BrfP", equipment: .some(.bodyweight), secondaryMuscles: [.glutes]),
        "Растяжка задней поверхности бедра с ремнём": ExerciseMedia(gifAsset: "exgif_99rWm7w", equipment: .some(.bodyweight), secondaryMuscles: [.glutes]),
        "Растяжка задней поверхности и икр с ремнём": ExerciseMedia(gifAsset: nil, equipment: .some(.bands), secondaryMuscles: [.calves]),
        "Растяжка икр сидя": ExerciseMedia(gifAsset: "exgif_17bqEXD", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Растяжка икр у стены": ExerciseMedia(gifAsset: "exgif_m0tCHqc", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Растяжка икроножной мышцы": ExerciseMedia(gifAsset: "exgif_qOKcgVP", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .glutes]),
        "Растяжка камбаловидной мышцы и ахилла": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Растяжка квадрицепса и сгибателей бедра": ExerciseMedia(gifAsset: "exgif_tFGKm99", equipment: .some(.cable), secondaryMuscles: [.hamstrings, .glutes]),
        "Растяжка квадрицепса лёжа": ExerciseMedia(gifAsset: "exgif_BWnJR72", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Растяжка квадрицепса лёжа на боку": ExerciseMedia(gifAsset: nil, equipment: .some(.bands), secondaryMuscles: []),
        "Растяжка квадрицепса на четвереньках": ExerciseMedia(gifAsset: "exgif_qBcKorM", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .glutes]),
        "Растяжка квадрицепса с опорой": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Растяжка паха лёжа": ExerciseMedia(gifAsset: nil, equipment: .some(.bands), secondaryMuscles: []),
        "Растяжка плеча перед собой": ExerciseMedia(gifAsset: "exgif_Uto7l43", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Растяжка предплечий на коленях": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Растяжка приводящих лёжа на боку": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Растяжка сгибателей бедра в выпаде": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.quadriceps]),
        "Растяжка сгибателей бедра стоя": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: []),
        "Растяжка ягодиц лёжа (колено через тело)": ExerciseMedia(gifAsset: "exgif_6sYyrRX", equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .lowerBack]),
        "Растяжка ягодиц лёжа (фигура 4)": ExerciseMedia(gifAsset: "exgif_DeDThfG", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Ролик для пресса": ExerciseMedia(gifAsset: "exgif_NAgVB3t", equipment: .some(.foamRoll), secondaryMuscles: [.sideDelts]),
        "Рубка дров на блоке (Woodchopper)": ExerciseMedia(gifAsset: nil, equipment: .some(.cable), secondaryMuscles: [.sideDelts]),
        "Румынская тяга": ExerciseMedia(gifAsset: "exgif_wQ2c4XD", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
        "Румынская тяга в Смите": ExerciseMedia(gifAsset: "exgif_UfePqpx", equipment: .some(.machine), secondaryMuscles: [.hamstrings]),
        "Румынская тяга гантели": ExerciseMedia(gifAsset: "exgif_rR0LJzx", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings]),
        "Румынская тяга с дефицита": ExerciseMedia(gifAsset: "exgif_rR0LJzx", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings]),
        "Русский твист": ExerciseMedia(gifAsset: "exgif_XVDdcoj", equipment: .some(.bodyweight), secondaryMuscles: [.lowerBack]),
        "Русский твист с блином": ExerciseMedia(gifAsset: "exgif_fZFZ704", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Рывковая протяжка": ExerciseMedia(gifAsset: "exgif_dG5Smob", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .glutes, .calves]),
        "Рывок в разножку": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.calves, .forearms, .glutes, .hamstrings, .lowerBack, .quadriceps, .sideDelts, .trapezius, .triceps]),
        "Рывок гантели": ExerciseMedia(gifAsset: "exgif_6pTkI99", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings]),
        "Рывок гири": ExerciseMedia(gifAsset: "exgif_aXcUyKb", equipment: .some(.kettlebell), secondaryMuscles: [.forearms]),
        "Рывок с виса": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.core, .calves, .forearms, .glutes, .lowerBack, .quadriceps, .sideDelts, .trapezius]),
        "Рывок с плинтов": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.calves, .forearms, .glutes, .hamstrings, .lowerBack, .sideDelts, .trapezius, .triceps]),
        "Рывок штанги (Snatch)": ExerciseMedia(gifAsset: "exgif_dG5Smob", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .glutes, .calves]),
        "Рычажная тяга (Hammer)": ExerciseMedia(gifAsset: "exgif_7I6LNUG", equipment: .some(.machine), secondaryMuscles: [.biceps, .forearms]),
        "Сведение в тренажере Хаммер": ExerciseMedia(gifAsset: "exgif_v3xmPAR", equipment: .some(.machine), secondaryMuscles: []),
        "Сведение гантелей лежа": ExerciseMedia(gifAsset: "exgif_yz9nUhF", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Сведение гантелей на наклонной скамье": ExerciseMedia(gifAsset: "exgif_ESOd5Pl", equipment: .some(.dumbbell), secondaryMuscles: [.sideDelts]),
        "Сведение гантелей на скамье с обратным наклоном": ExerciseMedia(gifAsset: "exgif_xXm4nYq", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Сведение лопаток лёжа на наклонной": ExerciseMedia(gifAsset: nil, equipment: .some(.dumbbell), secondaryMuscles: []),
        "Сведение ног в тренажере": ExerciseMedia(gifAsset: "exgif_oHsrypV", equipment: .some(.machine), secondaryMuscles: [.hamstrings, .glutes]),
        "Сведение ноги в кроссовере": ExerciseMedia(gifAsset: "exgif_hBGWILP", equipment: .some(.cable), secondaryMuscles: [.glutes]),
        "Сведение ноги с резиной": ExerciseMedia(gifAsset: "exgif_7WaDzyL", equipment: .some(.bodyweight), secondaryMuscles: [.glutes]),
        "Сведение рук в тренажере (Бабочка)": ExerciseMedia(gifAsset: "exgif_v3xmPAR", equipment: .some(.machine), secondaryMuscles: []),
        "Сведения в кроссовере лежа": ExerciseMedia(gifAsset: "exgif_lJJ7Yq8", equipment: .some(.cable), secondaryMuscles: [.triceps]),
        "Сведения в кроссовере на наклонной скамье": ExerciseMedia(gifAsset: "exgif_tBWXbIT", equipment: .some(.cable), secondaryMuscles: [.triceps]),
        "Сгибание кистей за спиной": ExerciseMedia(gifAsset: "exgif_2qTvJAZ", equipment: .some(.barbell), secondaryMuscles: [.biceps]),
        "Сгибание кистей за спиной со штангой": ExerciseMedia(gifAsset: "exgif_2qTvJAZ", equipment: .some(.barbell), secondaryMuscles: [.biceps]),
        "Сгибание кистей на блоке": ExerciseMedia(gifAsset: "exgif_LrV4s90", equipment: .some(.cable), secondaryMuscles: [.biceps]),
        "Сгибание кистей со штангой": ExerciseMedia(gifAsset: "exgif_82LxxkW", equipment: .some(.barbell), secondaryMuscles: [.biceps]),
        "Сгибание на скамье Скотта одной рукой": ExerciseMedia(gifAsset: nil, equipment: .some(.dumbbell), secondaryMuscles: []),
        "Сгибание ног лежа": ExerciseMedia(gifAsset: "exgif_17lJ1kr", equipment: .some(.machine), secondaryMuscles: [.calves]),
        "Сгибание ног с резиной сидя": ExerciseMedia(gifAsset: nil, equipment: .some(.bands), secondaryMuscles: []),
        "Сгибание ног сидя": ExerciseMedia(gifAsset: "exgif_Zg3XY7P", equipment: .some(.machine), secondaryMuscles: [.calves]),
        "Сгибание ног со скольжением": ExerciseMedia(gifAsset: "exgif_LNE3wfo", equipment: .some(.bodyweight), secondaryMuscles: [.glutes]),
        "Сгибание ног стоя": ExerciseMedia(gifAsset: "exgif_C5jncD2", equipment: .some(.bodyweight), secondaryMuscles: [.glutes]),
        "Сгибание пальцев со штангой": ExerciseMedia(gifAsset: "exgif_awG04cF", equipment: .some(.barbell), secondaryMuscles: []),
        "Сгибание паука": ExerciseMedia(gifAsset: "exgif_Ye5Qxb0", equipment: .some(.ezbar), secondaryMuscles: [.forearms]),
        "Сгибания Зоттмана": ExerciseMedia(gifAsset: "exgif_kXaIn5A", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Сгибания Скотта на блоке": ExerciseMedia(gifAsset: "exgif_P2lNrGL", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Сгибания в кроссовере": ExerciseMedia(gifAsset: "exgif_G08RZcQ", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Сгибания в тренажере": ExerciseMedia(gifAsset: "exgif_q6y3OhV", equipment: .some(.machine), secondaryMuscles: [.forearms]),
        "Сгибания на бицепс в кроссовере над головой": ExerciseMedia(gifAsset: "exgif_wDUqY2u", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Сгибания на бицепс в тренажере Скотта": ExerciseMedia(gifAsset: "exgif_b6hQYMb", equipment: .some(.machine), secondaryMuscles: [.forearms]),
        "Сгибания на бицепс гантелей лёжа": ExerciseMedia(gifAsset: "exgif_KUaZst7", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Сгибания на бицепс лёжа на блоке": ExerciseMedia(gifAsset: "exgif_otqIxU4", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Сгибания на бицепс на блоке одной рукой": ExerciseMedia(gifAsset: "exgif_YTur5nR", equipment: .some(.cable), secondaryMuscles: [.forearms]),
        "Сгибания на бицепс на верхних блоках": ExerciseMedia(gifAsset: nil, equipment: .some(.cable), secondaryMuscles: []),
        "Сгибания на скамье Скотта": ExerciseMedia(gifAsset: "exgif_qOgPVf6", equipment: .some(.barbell), secondaryMuscles: [.forearms]),
        "Сгибания на скамье Скотта с гантелями": ExerciseMedia(gifAsset: "exgif_jivWf8n", equipment: .some(.dumbbell), secondaryMuscles: [.forearms]),
        "Сжатие гриппера": ExerciseMedia(gifAsset: "exgif_mKwcrHn", equipment: .some(.machine), secondaryMuscles: [.biceps, .triceps]),
        "Сжимающий жим гантелей": ExerciseMedia(gifAsset: "exgif_7jGOBF3", equipment: .some(.dumbbell), secondaryMuscles: [.middleChest, .sideDelts]),
        "Силовое взятие на грудь": ExerciseMedia(gifAsset: "exgif_SiWCcTN", equipment: .some(.barbell), secondaryMuscles: [.glutes, .calves]),
        "Силовой рывок": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.calves, .glutes, .lowerBack, .quadriceps, .sideDelts, .trapezius, .triceps]),
        "Силовой рывок с плинтов": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.calves, .forearms, .glutes, .hamstrings, .lowerBack, .sideDelts, .trapezius, .triceps]),
        "Сисси-приседания": ExerciseMedia(gifAsset: "exgif_xdYPUtE", equipment: .some(.bodyweight), secondaryMuscles: [.calves, .glutes]),
        "Скакалка": ExerciseMedia(gifAsset: "exgif_e1e76I2", equipment: .some(.cable), secondaryMuscles: [.calves, .hamstrings, .glutes]),
        "Складочка (V-Ups)": ExerciseMedia(gifAsset: "exgif_mbkgB44", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Скоростные приседания на коробку с резиной": ExerciseMedia(gifAsset: "exgif_euI1BwR", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Скрутка ног лёжа (Железный крест)": ExerciseMedia(gifAsset: "exgif_pZwUsKB", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Скручивание позвоночника сидя": ExerciseMedia(gifAsset: "exgif_S1JXDAG", equipment: .some(.bands), secondaryMuscles: [.lats, .lowerBack, .trapezius]),
        "Скручивания": ExerciseMedia(gifAsset: "exgif_TFqbd8t", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Скручивания в тренажере": ExerciseMedia(gifAsset: "exgif_Wgaz7pm", equipment: .some(.machine), secondaryMuscles: []),
        "Скручивания на блоке": ExerciseMedia(gifAsset: "exgif_WW95auq", equipment: .some(.cable), secondaryMuscles: []),
        "Скручивания на блоке (Cable Crunch)": ExerciseMedia(gifAsset: "exgif_WW95auq", equipment: .some(.cable), secondaryMuscles: []),
        "Скручивания на блоке стоя": ExerciseMedia(gifAsset: "exgif_jpgqxiS", equipment: .some(.cable), secondaryMuscles: []),
        "Скручивания на наклонной скамье вниз": ExerciseMedia(gifAsset: "exgif_9Ap7miY", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Скручивания на фитболе": ExerciseMedia(gifAsset: "exgif_Gn5FwYT", equipment: .some(.exerciseBall), secondaryMuscles: []),
        "Скручивания с отягощением": ExerciseMedia(gifAsset: "exgif_s8nrDXF", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Сплит-присед на TRX": ExerciseMedia(gifAsset: "exgif_QpXqiq8", equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Сплит-прыжки": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.calves, .glutes, .quadriceps]),
        "Спринты": ExerciseMedia(gifAsset: "exgif_Qoujh3Q", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Становая на прямых ногах": ExerciseMedia(gifAsset: "exgif_hrVQWvE", equipment: .some(.barbell), secondaryMuscles: [.glutes]),
        "Становая тяга": ExerciseMedia(gifAsset: "exgif_ila4NZS", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
        "Становая тяга в рычажном тренажере": ExerciseMedia(gifAsset: "exgif_GUT8I22", equipment: .some(.machine), secondaryMuscles: [.hamstrings]),
        "Становая тяга в стиле взятия": ExerciseMedia(gifAsset: "exgif_ila4NZS", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
        "Становая тяга с дефицита": ExerciseMedia(gifAsset: "exgif_ila4NZS", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
        "Становая тяга с трэп-грифом": ExerciseMedia(gifAsset: "exgif_jQGwmxN", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
        "Становая тяга сумо": ExerciseMedia(gifAsset: "exgif_KgI0tqW", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
        "Статика у стены (Стульчик)": ExerciseMedia(gifAsset: "exgif_sVQCCeG", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings, .calves]),
        "Степпер": ExerciseMedia(gifAsset: "exgif_j9Q5crt", equipment: .some(.machine), secondaryMuscles: [.hamstrings, .glutes, .calves]),
        "Сумо-тяга гири к подбородку": ExerciseMedia(gifAsset: "exgif_8ARQ9Hw", equipment: .some(.kettlebell), secondaryMuscles: [.glutes, .hamstrings]),
        "Супермен": ExerciseMedia(gifAsset: nil, equipment: .some(.bodyweight), secondaryMuscles: [.glutes, .hamstrings]),
        "Тейт-пресс": ExerciseMedia(gifAsset: "exgif_s5PdDyY", equipment: .some(.dumbbell), secondaryMuscles: [.middleChest, .sideDelts]),
        "Толкание салазок": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.calves, .middleChest, .glutes, .hamstrings, .triceps]),
        "Толчок гири одной рукой": ExerciseMedia(gifAsset: "exgif_vzAxBtt", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Толчок гирь длинным циклом": ExerciseMedia(gifAsset: "exgif_vzAxBtt", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Толчок двух гирь": ExerciseMedia(gifAsset: "exgif_tznL2Ad", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Толчок из приседа": ExerciseMedia(gifAsset: "exgif_IMRsOCn", equipment: .some(.barbell), secondaryMuscles: [.glutes, .hamstrings, .calves]),
        "Толчок штанги (Jerk)": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.glutes, .hamstrings, .sideDelts, .triceps]),
        "Трастеры (Thrusters)": ExerciseMedia(gifAsset: "exgif_f7Y9eDZ", equipment: .some(.barbell), secondaryMuscles: [.glutes, .hamstrings]),
        "Турецкий подъем": ExerciseMedia(gifAsset: "exgif_Ha7SZ3y", equipment: .some(.kettlebell), secondaryMuscles: [.hamstrings]),
        "Тяга TRX": ExerciseMedia(gifAsset: "exgif_jdiExfW", equipment: .some(.bodyweight), secondaryMuscles: [.biceps, .forearms]),
        "Тяга Кинга на одной ноге": ExerciseMedia(gifAsset: "exgif_gKozT8X", equipment: .some(.dumbbell), secondaryMuscles: [.hamstrings]),
        "Тяга Пендли": ExerciseMedia(gifAsset: "exgif_r0z6xzQ", equipment: .some(.barbell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга Т-грифа": ExerciseMedia(gifAsset: "exgif_aaXr7ld", equipment: .some(.machine), secondaryMuscles: [.biceps, .forearms]),
        "Тяга Т-грифа лёжа в тренажере": ExerciseMedia(gifAsset: "exgif_aaXr7ld", equipment: .some(.machine), secondaryMuscles: [.biceps, .forearms]),
        "Тяга Т-грифа одной рукой": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.biceps, .lats, .lowerBack, .trapezius]),
        "Тяга в наклоне в Смите": ExerciseMedia(gifAsset: "exgif_ZX9UZmj", equipment: .some(.machine), secondaryMuscles: [.biceps, .forearms]),
        "Тяга в рывковом хвате": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.forearms, .glutes, .hamstrings, .lowerBack, .quadriceps, .trapezius]),
        "Тяга в тренажере с упором грудью": ExerciseMedia(gifAsset: "exgif_7I6LNUG", equipment: .some(.machine), secondaryMuscles: [.biceps, .forearms]),
        "Тяга вертикального блока": ExerciseMedia(gifAsset: "exgif_RVwzP10", equipment: .some(.cable), secondaryMuscles: [.biceps, .forearms]),
        "Тяга вертикального блока обратным хватом": ExerciseMedia(gifAsset: "exgif_xBYcQHj", equipment: .some(.cable), secondaryMuscles: [.biceps, .forearms]),
        "Тяга вертикального блока одной рукой": ExerciseMedia(gifAsset: "exgif_U5INZY6", equipment: .some(.cable), secondaryMuscles: [.biceps, .forearms]),
        "Тяга вертикального блока узким хватом": ExerciseMedia(gifAsset: "exgif_4c9BhzB", equipment: .some(.cable), secondaryMuscles: [.biceps, .forearms]),
        "Тяга верхнего блока": ExerciseMedia(gifAsset: "exgif_RVwzP10", equipment: .some(.cable), secondaryMuscles: [.biceps, .forearms]),
        "Тяга верхнего блока за голову": ExerciseMedia(gifAsset: "exgif_CmEr4pM", equipment: .some(.cable), secondaryMuscles: [.biceps]),
        "Тяга верхнего блока нейтральным хватом (V-рукоять)": ExerciseMedia(gifAsset: "exgif_4c9BhzB", equipment: .some(.cable), secondaryMuscles: [.biceps, .forearms]),
        "Тяга гантелей в наклоне нейтральным хватом": ExerciseMedia(gifAsset: "exgif_BJ0Hz5L", equipment: .some(.dumbbell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга гантелей лежа на наклонной": ExerciseMedia(gifAsset: "exgif_7vG5o25", equipment: .some(.dumbbell), secondaryMuscles: [.biceps]),
        "Тяга гантели в наклоне": ExerciseMedia(gifAsset: "exgif_C0MA9bC", equipment: .some(.dumbbell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга гантели в стиле Кроча": ExerciseMedia(gifAsset: "exgif_C0MA9bC", equipment: .some(.dumbbell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга гантели двумя руками в наклоне": ExerciseMedia(gifAsset: "exgif_BJ0Hz5L", equipment: .some(.dumbbell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга гири в наклоне одной рукой": ExerciseMedia(gifAsset: "exgif_g9AsZ8P", equipment: .some(.kettlebell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга гирь в наклоне попеременно": ExerciseMedia(gifAsset: "exgif_Ca76jUE", equipment: .some(.kettlebell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга горизонтального блока": ExerciseMedia(gifAsset: "exgif_fUBheHs", equipment: .some(.cable), secondaryMuscles: [.biceps, .forearms]),
        "Тяга горизонтального блока одной рукой": ExerciseMedia(gifAsset: "exgif_vpp9Ku2", equipment: .some(.cable), secondaryMuscles: [.biceps, .forearms]),
        "Тяга двух гирь в наклоне": ExerciseMedia(gifAsset: "exgif_wf24o8S", equipment: .some(.kettlebell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга к подбородку": ExerciseMedia(gifAsset: "exgif_cALKspW", equipment: .some(.cable), secondaryMuscles: [.trapezius, .biceps]),
        "Тяга к подбородку в Смите": ExerciseMedia(gifAsset: "exgif_1DN3iz4", equipment: .some(.machine), secondaryMuscles: [.trapezius, .biceps]),
        "Тяга к подбородку на блоке": ExerciseMedia(gifAsset: "exgif_cALKspW", equipment: .some(.cable), secondaryMuscles: [.trapezius, .biceps]),
        "Тяга к подбородку с гантелями": ExerciseMedia(gifAsset: "exgif_ainizkb", equipment: .some(.dumbbell), secondaryMuscles: [.trapezius, .biceps]),
        "Тяга к подбородку с канатом на блоке": ExerciseMedia(gifAsset: "exgif_cALKspW", equipment: .some(.cable), secondaryMuscles: [.trapezius, .biceps]),
        "Тяга к подбородку с резиной": ExerciseMedia(gifAsset: nil, equipment: .some(.bands), secondaryMuscles: [.sideDelts]),
        "Тяга нижнего блока к шее": ExerciseMedia(gifAsset: nil, equipment: .some(.cable), secondaryMuscles: [.biceps, .trapezius]),
        "Тяга нижнего блока одной рукой стоя": ExerciseMedia(gifAsset: "exgif_4f8RXP8", equipment: .some(.cable), secondaryMuscles: [.biceps]),
        "Тяга с плинтов (Rack Pull)": ExerciseMedia(gifAsset: "exgif_za9Ni4z", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
        "Тяга салазок": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.calves, .glutes, .hamstrings]),
        "Тяга салазок к себе": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.biceps, .lats]),
        "Тяга салазок над головой спиной вперёд": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: [.calves, .trapezius, .quadriceps]),
        "Тяга штанги в наклоне": ExerciseMedia(gifAsset: "exgif_eZyBC3j", equipment: .some(.barbell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга штанги в наклоне обратным хватом": ExerciseMedia(gifAsset: "exgif_SzX3uzM", equipment: .some(.barbell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга штанги лёжа на скамье": ExerciseMedia(gifAsset: "exgif_R5swFnc", equipment: .some(.barbell), secondaryMuscles: [.biceps, .forearms]),
        "Тяга штанги на задние дельты": ExerciseMedia(gifAsset: "exgif_S9zHIvU", equipment: .some(.barbell), secondaryMuscles: [.biceps]),
        "Уголок (L-Sit)": ExerciseMedia(gifAsset: "exgif_UpWmA5E", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Уголок (L-sit) на брусьях": ExerciseMedia(gifAsset: "exgif_UpWmA5E", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Уголок на брусьях": ExerciseMedia(gifAsset: "exgif_UpWmA5E", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Удары кувалдой по покрышке": ExerciseMedia(gifAsset: "exgif_REXmfVC", equipment: .some(.machine), secondaryMuscles: [.forearms]),
        "Удержание блина": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: []),
        "Уход в сед в рывке (Snatch Balance)": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.calves, .glutes, .hamstrings, .sideDelts, .triceps]),
        "Флаг человека": ExerciseMedia(gifAsset: "exgif_pQ0Mx1Z", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Флаттер-кики (попеременные махи ногами)": ExerciseMedia(gifAsset: "exgif_UVo2Qs2", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Фоллаут на TRX": ExerciseMedia(gifAsset: "exgif_X3TCNEU", equipment: .some(.bodyweight), secondaryMuscles: [.middleChest, .lowerBack, .sideDelts]),
        "Французский жим": ExerciseMedia(gifAsset: "exgif_h8LFzo9", equipment: .some(.barbell), secondaryMuscles: [.forearms]),
        "Французский жим EZ-штанги лёжа": ExerciseMedia(gifAsset: "exgif_6CKUx7o", equipment: .some(.ezbar), secondaryMuscles: [.forearms]),
        "Французский жим EZ-штанги на обратном наклоне": ExerciseMedia(gifAsset: "exgif_CQHoDm0", equipment: .some(.ezbar), secondaryMuscles: []),
        "Французский жим гантелей лёжа": ExerciseMedia(gifAsset: "exgif_mpKZGWz", equipment: .some(.dumbbell), secondaryMuscles: [.middleChest, .sideDelts]),
        "Французский жим гантелями на обратном наклоне": ExerciseMedia(gifAsset: "exgif_OTgkHwR", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Французский жим из-за головы с гантелью": ExerciseMedia(gifAsset: "exgif_BCUR88E", equipment: .some(.dumbbell), secondaryMuscles: [.middleChest, .sideDelts]),
        "Французский жим лёжа на блоке": ExerciseMedia(gifAsset: "exgif_uxJcFUU", equipment: .some(.cable), secondaryMuscles: []),
        "Французский жим на блоке на наклонной скамье": ExerciseMedia(gifAsset: "exgif_Hx1WC8I", equipment: .some(.cable), secondaryMuscles: []),
        "Французский жим на наклонной скамье": ExerciseMedia(gifAsset: "exgif_KyLtiLT", equipment: .some(.ezbar), secondaryMuscles: [.forearms]),
        "Французский жим с гантелью стоя": ExerciseMedia(gifAsset: "exgif_PdmaD0N", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Французский жим с пола": ExerciseMedia(gifAsset: "exgif_h8LFzo9", equipment: .some(.barbell), secondaryMuscles: []),
        "Французский жим сидя со штангой": ExerciseMedia(gifAsset: "exgif_5uFK1xr", equipment: .some(.barbell), secondaryMuscles: []),
        "Фронтальные приседания": ExerciseMedia(gifAsset: "exgif_zG0zs85", equipment: .some(.barbell), secondaryMuscles: [.hamstrings, .calves]),
        "Фронтальные приседания с двумя гирями": ExerciseMedia(gifAsset: "exgif_DB0n8AG", equipment: .some(.kettlebell), secondaryMuscles: [.hamstrings, .calves]),
        "Ходьба в гору": ExerciseMedia(gifAsset: "exgif_rjiM4L3", equipment: .some(.machine), secondaryMuscles: [.hamstrings, .calves]),
        "Ходьба монстра с резиной": ExerciseMedia(gifAsset: "exgif_O95afRA", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Хождение на руках": ExerciseMedia(gifAsset: "exgif_XooAdhl", equipment: .some(.bodyweight), secondaryMuscles: []),
        "Швунг гири одной рукой": ExerciseMedia(gifAsset: "exgif_osdXT3K", equipment: .some(.kettlebell), secondaryMuscles: [.triceps]),
        "Швунг толчковый": ExerciseMedia(gifAsset: nil, equipment: .some(.barbell), secondaryMuscles: [.core, .calves, .glutes, .hamstrings, .sideDelts, .triceps]),
        "Шраги Кирка": ExerciseMedia(gifAsset: "exgif_dG7tG5y", equipment: .some(.barbell), secondaryMuscles: []),
        "Шраги в Смите": ExerciseMedia(gifAsset: "exgif_OUQ0ZyW", equipment: .some(.machine), secondaryMuscles: [.sideDelts]),
        "Шраги в тренажере": ExerciseMedia(gifAsset: "exgif_ZZKbeMw", equipment: .some(.machine), secondaryMuscles: [.forearms]),
        "Шраги обратные с гантелями": ExerciseMedia(gifAsset: "exgif_NJzBsGJ", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Шраги рывковым хватом": ExerciseMedia(gifAsset: "exgif_dG7tG5y", equipment: .some(.barbell), secondaryMuscles: [.forearms, .sideDelts]),
        "Шраги с гантелями": ExerciseMedia(gifAsset: "exgif_NJzBsGJ", equipment: .some(.dumbbell), secondaryMuscles: []),
        "Шраги со штангой": ExerciseMedia(gifAsset: "exgif_dG7tG5y", equipment: .some(.barbell), secondaryMuscles: []),
        "Щепотный хват блина": ExerciseMedia(gifAsset: nil, equipment: .some(.other), secondaryMuscles: []),
        "Эллипсоид": ExerciseMedia(gifAsset: "exgif_rjtuP6X", equipment: .some(.machine), secondaryMuscles: [.hamstrings, .glutes, .calves]),
        "Ягодичный мост (Hip Thrust)": ExerciseMedia(gifAsset: "exgif_qKBpF7I", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
        "Ягодичный мост на одной ноге": ExerciseMedia(gifAsset: "exgif_rmEukuS", equipment: .some(.bodyweight), secondaryMuscles: [.hamstrings]),
        "Ягодичный мост на фитболе": ExerciseMedia(gifAsset: nil, equipment: .some(.exerciseBall), secondaryMuscles: [.hamstrings]),
        "Ягодичный мост с резиной": ExerciseMedia(gifAsset: "exgif_Pjbc0Kt", equipment: .some(.bands), secondaryMuscles: [.hamstrings]),
        "Ягодичный мост со штангой": ExerciseMedia(gifAsset: "exgif_qKBpF7I", equipment: .some(.barbell), secondaryMuscles: [.hamstrings]),
    ]
}

extension ExerciseLibrary {
    nonisolated static let generatedNewExercises: [LibraryExercise] = [
        LibraryExercise(
            name: "Подъём корпуса на 3/4",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, колени согни, стопы зафиксируй на полу. Руки за головой или у висков, поясница прижата.\n\nДвижение: На выдохе сгибай корпус и тянись грудью к коленям, пока туловище не встанет перпендикулярно полу. Опускайся обратно, но только на три четверти - спину до конца не клади.\n\nКлючи: Работай прессом, а не шеей - руками голову не дёргай. Неполное опускание держит мышцы под нагрузкой всё время. Темп ровный, без рывков и инерции.",
            videoUrl: "https://www.youtube.com/results?search_query=3/4%20Sit-Up%20technique"
        ),
        LibraryExercise(
            name: "Растяжка бедра 90/90",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, одну ногу вытяни прямо на полу. Вторую согни в тазобедренном и коленном суставах под прямым углом, при желании придержи руками под бедром.\n\nДвижение: Из этого положения выпрямляй согнутую ногу вверх, тянись пяткой в потолок. На пике задержись на секунду и плавно верни ногу обратно.\n\nКлючи: Растяжение должно ощущаться по задней поверхности бедра, но без боли. Бедро держи под прямым углом, не уводи его. Сделай 10-20 повторов и поменяй ногу.",
            videoUrl: "https://www.youtube.com/results?search_query=90/90%20Hamstring%20technique"
        ),
        LibraryExercise(
            name: "Мельница с гирей (продвинутая)",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Закинь гирю на плечо и выжми её над головой одной рукой, рука зафиксирована. Стопы разверни примерно на 45° в сторону от руки с гирей, свободную руку убери за спину.\n\nДвижение: Не сводя глаз с гири, отводи таз в сторону поднятой руки и наклоняйся вниз как можно ниже, скользя свободной рукой по ноге. Секунду задержись и плавно поднимись обратно.\n\nКлючи: Гиря всё время строго над головой, локоть прямой. Сгибание идёт за счёт таза, а не круглой спины. Движение медленное и контролируемое - это про стабильность, не про скорость.",
            videoUrl: "https://www.youtube.com/results?search_query=Advanced%20Kettlebell%20Windmill%20technique"
        ),
        LibraryExercise(
            name: "Растяжка квадрицепса на четвереньках",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Встань на четвереньки. Перенеси вес, подними одну ногу от пола и поймай стопу или лодыжку рукой с той же стороны.\n\nДвижение: Притягивай пятку к ягодице, держа колено максимально согнутым, чтобы растянуть квадрицепс и сгибатели бедра. Одновременно подавай таз вперёд и вниз, усиливая растяжение.\n\nКлючи: Тяни плавно, без рывков - почувствуй переднюю поверхность бедра. Спину держи нейтральной, не проваливай поясницу. Задержись на 10-20 секунд и поменяй сторону.",
            videoUrl: "https://www.youtube.com/results?search_query=All%20Fours%20Quad%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Касания пяток лёжа",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, колени согни, стопы на полу примерно на 45-60 см друг от друга. Руки вытяни вдоль тела.\n\nДвижение: На выдохе скрути корпус вбок и вверх на 8-10 см, дотягиваясь правой ладонью до правой пятки, на секунду задержись. На вдохе вернись назад и повтори в другую сторону. Касание обеих пяток - это одно повторение.\n\nКлючи: Работают косые мышцы живота, тянись именно вбок, а не вперёд. Поясницу от пола не отрывай. Движение короткое и чёткое, без раскачки.",
            videoUrl: "https://www.youtube.com/results?search_query=Alternate%20Heel%20Touchers%20technique"
        ),
        LibraryExercise(
            name: "Диагональные прыжки в шаге",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: Встань в удобную стойку, одна стопа чуть впереди другой, колени слегка согнуты.\n\nДвижение: Оттолкнись передней ногой и мощно выноси противоположное колено вперёд и вверх как можно выше, прыгая по диагонали в сторону. Старайся преодолеть максимум расстояния, мягко приземлись и сразу отталкивайся другой ногой.\n\nКлючи: Это про взрывную силу и баланс - акцент на высоте колена и дальности прыжка. Приземляйся мягко, гася удар. Линия на полу поможет контролировать дистанцию из стороны в сторону.",
            videoUrl: "https://www.youtube.com/results?search_query=Alternate%20Leg%20Diagonal%20Bound%20technique"
        ),
        LibraryExercise(
            name: "Жим в кроссовере попеременно",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Опусти ручки блоков в самый низ, выбери умеренный вес. Возьми ручки и держи их на уровне плеч, ладони смотрят вперёд.\n\nДвижение: Держа голову и грудь приподнятыми, выжми одну руку строго над головой, разгибая локоть. На секунду задержись наверху, верни руку к плечу и повтори другой рукой.\n\nКлючи: Жми точно вверх, не уводя руку в сторону. Корпус держи стабильным - не помогай себе наклоном и инерцией. Трос даёт нагрузку и на подъёме, и на опускании, так что опускай руку контролируемо.",
            videoUrl: "https://www.youtube.com/results?search_query=Alternating%20Cable%20Shoulder%20Press%20technique"
        ),
        LibraryExercise(
            name: "Взятие гирь на грудь с виса попеременно",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Поставь две гири между стоп. Отведи таз назад, спину держи ровной, взгляд направь вперёд и возьмись за рукоятки.\n\nДвижение: Взрывным разгибанием ног и таза подними одну гирю к плечу, проворачивая кисть под рукоятку, вторая гиря остаётся в висе. Опусти гирю обратно в вис и тут же возьми на плечо вторую. Чередуй стороны.\n\nКлючи: Сила идёт от ног и таза, а не от рук - руки лишь направляют гирю. Спину держи ровной всю фазу подъёма. Кисть проворачивай вовремя, чтобы гиря мягко легла на предплечье, а не била по нему.",
            videoUrl: "https://www.youtube.com/results?search_query=Alternating%20Hang%20Clean%20technique"
        ),
        LibraryExercise(
            name: "Тяга гирь в наклоне попеременно",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Поставь две гири перед стопами. Слегка согни колени, отведи таз назад и наклонись со прямой спиной, взявшись за обе рукоятки.\n\nДвижение: Подними одну гирю с пола, удерживая вторую внизу. Сводя лопатку рабочей стороны, согни локоть и подтяни гирю к животу или нижним рёбрам. Опусти и повтори другой рукой.\n\nКлючи: Тяни лопаткой и спиной, а не бицепсом - локоть идёт назад вдоль корпуса. Спину держи ровной и неподвижной весь подход, не скручивай корпус за гирей. Опускай гирю контролируемо, не бросай.",
            videoUrl: "https://www.youtube.com/results?search_query=Alternating%20Kettlebell%20Row%20technique"
        ),
        LibraryExercise(
            name: "Растяжка ягодиц лёжа (фигура 4)",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, согни колени, стопы на полу. Положи лодыжку одной ноги на колено второй, образуя фигуру 4.\n\nДвижение: Обхвати руками бедро или колено нижней ноги и подтяни обе ноги к груди. Шею и плечи держи расслабленными, не напрягай верх тела.\n\nКлючи: Растяжение должно ощущаться в ягодице верхней ноги. Тяни плавно, дыши спокойно, не задерживай дыхание. Задержись на 10-20 секунд и поменяй сторону.",
            videoUrl: "https://www.youtube.com/results?search_query=Ankle%20On%20The%20Knee%20technique"
        ),
        LibraryExercise(
            name: "Круговые движения руками",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Встань прямо и разведи руки в стороны параллельно полу, под прямым углом к корпусу. Это исходное положение.\n\nДвижение: Медленно описывай прямыми руками круги диаметром примерно 30 см, дыши ровно. Покрути так около десяти секунд, затем смени направление на противоположное.\n\nКлючи: Отличная разминка для плеч перед тренировкой. Руки держи прямыми и параллельными полу, не роняй их. Круги контролируемые - тут важна амплитуда, а не скорость.",
            videoUrl: "https://www.youtube.com/results?search_query=Arm%20Circles%20technique"
        ),
        LibraryExercise(
            name: "Круговые разведения гантелей лёжа",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: Ляг на горизонтальную скамью, в каждой руке гантель, ладони смотрят в потолок. Руки выпрямлены вдоль бёдер, параллельны полу, локти чуть согнуты.\n\nДвижение: На вдохе веди гантели полукругом от бёдер к точке над головой, держа руки параллельно полу всё время. На выдохе тем же полукругом верни их в исходное положение.\n\nКлючи: Локти всё время мягко согнуты - выпрямленные в замок суставы легко травмировать. Двигай руками медленно по дуге, без рывков. Вес бери лёгкий: упражнение про растяжку груди, а не про силу.",
            videoUrl: "https://www.youtube.com/results?search_query=Around%20The%20Worlds%20technique"
        ),
        LibraryExercise(
            name: "Разведения с резиной на задние дельты",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: Закрепи резину вокруг неподвижной стойки, например стойки для приседаний. Возьми ручки и отойди назад, чтобы резина натянулась. Вытяни руки прямо перед собой параллельно полу, стопы на ширине плеч.\n\nДвижение: На выдохе разводи прямые руки в стороны и назад, держа их параллельными полу, пока они не окажутся разведены в линию. На вдохе плавно вернись в исходное.\n\nКлючи: Веди движение задними дельтами, сводя лопатки, а не за счёт рук. Руки держи почти прямыми, корпус не раскачивай. На пике на секунду задержись, чтобы прожать заднюю дельту.",
            videoUrl: "https://www.youtube.com/results?search_query=Resistance%20Band%20Rear%20Delt%20Flyes%20technique"
        ),
        LibraryExercise(
            name: "Бросок мяча через голову назад",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Лучше делать с партнёром, иначе бросай в стену или поднимай мяч сам. Встань спиной к партнёру и держи мяч между ног, ноги чуть шире плеч.\n\nДвижение: Присядь, отводя таз назад, затем мощно разогнись и взрывным движением выбрось мяч над головой назад через себя. Партнёр откатывает мяч обратно, и ты повторяешь.\n\nКлючи: Сила идёт от разгибания ног и таза, руки лишь сопровождают мяч. Бросай на полном выпрямлении тела, вкладывайся резко. Спину держи ровной, не округляй поясницу в приседе.",
            videoUrl: "https://www.youtube.com/results?search_query=Backward%20Medicine%20Ball%20Throw%20technique"
        ),
        LibraryExercise(
            name: "Подтягивания с резиной",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Накинь петлю резины на середину перекладины. Опусти свободный конец вниз и вставь в петлю одно согнутое колено, проверь, что нога не выскользнет. Возьмись за перекладину средним или широким хватом.\n\nДвижение: Сводя лопатки и сгибая локти, подтягивай себя вверх, пока подбородок не окажется над перекладиной. Локти веди вниз вдоль корпуса. После короткой паузы плавно опустись в вис.\n\nКлючи: Резина помогает в нижней, самой тяжёлой точке - отличный способ освоить подтягивания. Тяни спиной, не раскачивайся и не дёргайся рывком. Более толстая резина даёт больше помощи, бери под свой уровень.",
            videoUrl: "https://www.youtube.com/results?search_query=Band%20Assisted%20Pull-Up%20technique"
        ),
        LibraryExercise(
            name: "Сведение ноги с резиной",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Закрепи ленту за стойку, встань боком к ней и накинь петлю на лодыжку дальней ноги. Стой прямо, при необходимости держись за опору свободной рукой.\n\nДвижение: На выдохе отводи ногу в сторону на максимум, держа колено прямым. Плавно верни в исходное и повтори, потом смени сторону.\n\nКлючи: Работают средняя ягодичная и отводящие мышцы бедра. Не раскачивай корпус и не сгибай колено - тогда нагрузка не уйдёт. Контролируй обратное движение, не отпускай резину рывком.",
            videoUrl: "https://www.youtube.com/results?search_query=Band%20Hip%20Abduction%20technique"
        ),
        LibraryExercise(
            name: "Разведение резины перед собой",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: Возьми ленту обеими руками и вытяни прямые руки перед собой на уровне плеч. Плечи опусти и слегка сведи лопатки.\n\nДвижение: Разводи руки в стороны, как при обратной разводке, доводя ленту до груди. Локти держи почти прямыми. На пике задержись и плавно вернись в исходное.\n\nКлючи: Цель - задние дельты и средняя часть спины. Не тяни плечи к ушам и не сгибай локти - иначе подключаются бицепсы. Веди движение лопатками, дыши ровно.",
            videoUrl: "https://www.youtube.com/results?search_query=Band%20Pull-Apart%20technique"
        ),
        LibraryExercise(
            name: "Раскатка штанги стоя",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Прими упор лёжа, но вместо ладоней держись за гриф штанги с небольшим весом (по 2-5 кг на сторону). Спина в лёгком прогибе, пресс собран.\n\nДвижение: На вдохе раскатывай штангу вперёд, опуская корпус почти к полу. На выдохе тяни гриф к ступням, поднимая таз и скручивая пресс. Вернись назад под контролем.\n\nКлючи: Руки держи перпендикулярно полу, иначе нагрузка уйдёт в плечи и спину. Держи живот в тонусе и не проваливай поясницу - это защитит спину.",
            videoUrl: "https://www.youtube.com/results?search_query=Barbell%20Ab%20Rollout%20technique"
        ),
        LibraryExercise(
            name: "Ягодичный мост со штангой",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Сядь на пол, прокати штангу над бёдрами и ляг на спину. Стопы поставь близко к тазу, гриф лежит на тазобедренном сгибе - подложи мягкую накладку.\n\nДвижение: Упрись пятками в пол и выталкивай таз вверх через гриф, пока бёдра и корпус не выстроятся в линию. В верхней точке сожми ягодицы и плавно опустись.\n\nКлючи: Вес держи на верхней части спины и пятках. В верхней точке доводи таз до конца и сжимай ягодицы - так работают именно они, а не поясница. Подбородок слегка прижат.",
            videoUrl: "https://www.youtube.com/results?search_query=Barbell%20Glute%20Bridge%20technique"
        ),
        LibraryExercise(
            name: "Гакк-приседания со штангой за спиной",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Встань прямо, гриф держи за спиной на вытянутых руках, ладони назад, стопы на ширине плеч. При желании используй лямки для хвата.\n\nДвижение: На вдохе медленно приседай, пока бёдра не станут параллельны полу, взгляд и грудь вверх, спина прямая. На выдохе вставай, толкая через пятки и напрягая бёдра.\n\nКлючи: Гриф идёт вдоль ягодиц и задней части ног - акцент на квадрицепсы. Держи корпус вертикально и не наклоняйся вперёд. Колени двигаются по линии стоп.",
            videoUrl: "https://www.youtube.com/results?search_query=Barbell%20Hack%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Выпады со штангой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: В силовой раме сними штангу со стоек на верх спины (чуть ниже шеи), держи гриф руками по бокам. Отойди от стоек, стопы на ширине таза.\n\nДвижение: На вдохе шагни вперёд правой ногой и опустись, сгибая бёдра, корпус держи вертикально. На выдохе оттолкнись пяткой и вернись назад. Повтори, затем смени ногу.\n\nКлючи: Колено передней ноги не должно выходить за носок - это бережёт сустав. Держи равновесие и не заваливай корпус вперёд. Опускайся подконтрольно, без провала вниз.",
            videoUrl: "https://www.youtube.com/results?search_query=Barbell%20Lunge%20technique"
        ),
        LibraryExercise(
            name: "Тяга штанги на задние дельты",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: Возьми штангу широким верхним хватом (шире плеч), ладони к телу. Слегка согни колени и наклонись с прямой спиной, пока корпус не станет параллелен полу, руки висят свободно.\n\nДвижение: На выдохе разведи локти в стороны и тяни гриф к верху груди, сжимая задние дельты. На вдохе медленно опусти. Корпус и руки в нижней точке образуют букву Т.\n\nКлючи: Это как жим лёжа наоборот - локти идут в стороны. Не тяни бицепсами, руки лишь как крючки. Не раскачивай корпус, фокус на задних дельтах.",
            videoUrl: "https://www.youtube.com/results?search_query=Barbell%20Rear%20Delt%20Row%20technique"
        ),
        LibraryExercise(
            name: "Приседания со штангой на скамью (box squat)",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Поставь скамью или тумбу за собой. Сними штангу со стоек на верх спины, отойди и встань так, чтобы при приседе сесть на край скамьи. Стопы чуть шире плеч, носки наружу.\n\nДвижение: На вдохе медленно опускайся, отводя таз назад и сохраняя прямую спину, пока слегка не коснёшься скамьи. На выдохе вставай через пятки, разгибая колени и таз.\n\nКлючи: Скамья учит уводить таз назад и держать глубину. Колени по линии носков, не дальше. Голову держи поднятой - взгляд вниз сбивает баланс. Не плюхайся на скамью.",
            videoUrl: "https://www.youtube.com/results?search_query=Barbell%20Box%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Зашагивания на платформу со штангой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Встань прямо со штангой на верхней части спины (чуть ниже шеи) перед устойчивой платформой высотой примерно до колена.\n\nДвижение: Поставь правую стопу на платформу и на выдохе вытолкнись через пятку, разгибая бедро и колено, подними тело наверх и приставь левую ногу. На вдохе шагни вниз левой ногой и вернись в исходное. Повтори, затем смени ногу.\n\nКлючи: Толкай именно пяткой опорной ноги, не отталкивайся нижней. Держи корпус вертикально и не заваливайся. Колено идёт по линии стопы, спускайся плавно.",
            videoUrl: "https://www.youtube.com/results?search_query=Barbell%20Step-Up%20technique"
        ),
        LibraryExercise(
            name: "Выпады в ходьбе со штангой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Встань прямо, стопы на ширине плеч, штанга лежит на верхней части спины.\n\nДвижение: Шагни вперёд одной ногой, сгибая колени и опуская таз, пока заднее колено почти не коснётся пола. Корпус держи вертикально, переднее колено над стопой. Оттолкнись пяткой передней ноги, выпрямись и шагни вперёд задней ногой - выпад на другую сторону.\n\nКлючи: Идёшь вперёд непрерывно, не приставляя ноги. Не выноси переднее колено за носок и не роняй корпус. Держи мышцы кора в тонусе для равновесия.",
            videoUrl: "https://www.youtube.com/results?search_query=Barbell%20Walking%20Lunge%20technique"
        ),
        LibraryExercise(
            name: "Жим лёжа с резиновыми лентами",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Закрепи ленту под ножкой скамьи у изголовья, возьми обе рукоятки и ляг. Выпрями руки перед собой на ширине плеч и разверни кисти ладонями от себя.\n\nДвижение: Медленно опускай рукоятки, пока локти не согнутся примерно до 90°, держа полный контроль. На выдохе выжимай вверх грудными, в верхней точке сожми грудь и задержись на секунду.\n\nКлючи: Лента даёт нарастающее сопротивление - вверху тяжелее всего. Опускай вдвое дольше, чем поднимаешь. Лопатки сведены, локти не разваливай в стороны.",
            videoUrl: "https://www.youtube.com/results?search_query=Banded%20Bench%20Press%20technique"
        ),
        LibraryExercise(
            name: "Жим лёжа с цепями",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Повесь цепи на грифы штанги, отрегулировав длину. Ляг на скамью, прижми стопы под себя и прогни спину. Сведи лопатки и вдави трапеции в скамью - тело в жёстком напряжении.\n\nДвижение: Сними штангу со стоек, не выводя плечи вперёд. Опусти гриф к низу груди, держа кисть и локоть на одной линии. На паузе у груди мощно выжимай вверх, к локауту локти подбираешь к корпусу.\n\nКлючи: Цепи частично ложатся на пол внизу и тяжелеют вверху - вверху максимальная нагрузка. Старайся как бы разорвать гриф и держи всё тело собранным.",
            videoUrl: "https://www.youtube.com/results?search_query=Bench%20Press%20with%20Chains%20technique"
        ),
        LibraryExercise(
            name: "Пуловер со штангой",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Ляг на горизонтальную скамью, возьми штангу хватом на ширине плеч и держи её над грудью с чуть согнутыми руками.\n\nДвижение: Сохраняя сгиб в локтях, на вдохе медленно опускай штангу по дуге за голову, пока не почувствуешь растяжение в груди. На выдохе верни штангу по той же дуге в исходное и задержи на секунду.\n\nКлючи: Угол в локтях держи постоянным - это не жим, а дуга. Опускай ровно до комфортного растяжения, без боли в плечах. Грудная клетка раскрыта, дыши на растяжении.",
            videoUrl: "https://www.youtube.com/results?search_query=Bent-Arm%20Barbell%20Pullover%20technique"
        ),
        LibraryExercise(
            name: "Тяга Т-грифа одной рукой",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Загрузи один конец грифа, другой упри в угол или прижми тяжёлым предметом, чтобы не скользил. Наклонись почти параллельно полу, колени слегка согнуты. Возьмись за гриф у блинов одной рукой, другую положи на колено.\n\nДвижение: На выдохе тяни гриф вверх, держа локоть прижатым, пока блины не коснутся низа груди, и сожми спину. На вдохе медленно опусти, растягивая широчайшие.\n\nКлючи: Локоть вдоль корпуса - так лучше включаются широчайшие. Не раскачивай корпус, двигается только рука. Не клади блины на пол между повторами.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Landmine%20Row%20technique"
        ),
        LibraryExercise(
            name: "Жим с наклоном с гирей (bent press)",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Закинь гирю на плечо: разгибая ноги и таз, подними её к плечу с разворотом кисти. Это исходное положение.\n\nДвижение: Наклоняйся в сторону, противоположную гире, пока свободная рука не достанет до пола, глаза - на гирю. Одновременно выжимай гирю вверх, разгибая локоть и держа руку перпендикулярно полу. Затем выпрямись, гиря над головой, и верни её на плечо.\n\nКлючи: Это силовое движение со смещением корпуса, а не чистый жим - вес идёт вверх за счёт наклона. Не своди глаз с гири и держи руку строго вертикально. Начинай с лёгкого веса.",
            videoUrl: "https://www.youtube.com/results?search_query=Kettlebell%20Bent%20Press%20technique"
        ),
        LibraryExercise(
            name: "Жим лёжа с досок (board press)",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Ложись на скамью, сведи лопатки и упрись ногами в пол, создав плотный прогиб. На грудь положи 1-5 досок - их держит партнёр или фиксируешь подручными средствами. Сними штангу хватом чуть шире плеч или на ширине плеч под трицепс.\n\nДвижение: Опусти штангу до касания досок, держа предплечья вертикально, и без паузы взрывно выжми вверх до полного выпрямления рук.\n\nКлючи: Локти держи прижатыми до самого верха. Доски сокращают амплитуду и позволяют грузить больше - это про дожим и силу трицепса. Не теряй напряжение в спине, не роняй штангу на доски.",
            videoUrl: "https://www.youtube.com/results?search_query=Board%20Press%20technique"
        ),
        LibraryExercise(
            name: "Взятие гири дном вверх с виса",
            category: .complex,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: Встань прямо, гиря в одной руке висит вдоль тела. Кисть и запястье жёсткие, готовься крепко сжать рукоять.\n\nДвижение: Заведи гирю немного назад между ног, затем мощно разверни движение и подними её к плечу, удерживая дном вверх. В верхней точке предплечье вертикально, гиря балансирует над кулаком.\n\nКлючи: Сжимай рукоять изо всех сил - именно хват и стабилизация запястья тут главная работа. Держи корпус ровным, не заваливайся. Отлично грузит предплечья и учит контролю; начинай с лёгкого веса.",
            videoUrl: "https://www.youtube.com/results?search_query=Bottoms-Up%20Kettlebell%20Clean%20from%20Hang%20technique"
        ),
        LibraryExercise(
            name: "Приседания на коробку с резиной",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: В силовой раме поставь коробку сзади на высоту параллельного приседа. Закрепи резину на грифе так, чтобы было нужное натяжение. Подведи гриф на верх спины, сведи лопатки, сними штангу и сделай шаг назад в прогибе.\n\nДвижение: Напряги корпус, разводи колени в стороны и садись тазом назад, пока не сядешь на коробку. Сделай короткую паузу без раскачки и взрывно встань, ведя движение головой.\n\nКлючи: Голень держи вертикально, вес на пятках. Никогда не отбивайся от коробки - сел, сохранил напряжение, встал. Резина добавляет нагрузку вверху и учит ускорению.",
            videoUrl: "https://www.youtube.com/results?search_query=Box%20Squat%20with%20Bands%20technique"
        ),
        LibraryExercise(
            name: "Приседания на коробку с цепями",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: В силовой раме поставь коробку сзади на высоту параллели. Перекинь цепи через концы грифа так, чтобы вверху пара звеньев ещё лежала на полу. Подведи гриф на верх спины, сведи лопатки, сними штангу и шагни назад в прогибе.\n\nДвижение: На напряжённом корпусе разводи колени и садись тазом назад на коробку. Короткая пауза без раскачки - и взрывной подъём, ведя движение головой.\n\nКлючи: Голень вертикально, вес на пятках. Не отбивайся от коробки. Цепи догружают штангу к верхней точке, заставляя продавливать весь подъём.",
            videoUrl: "https://www.youtube.com/results?search_query=Box%20Squat%20with%20Chains%20technique"
        ),
        LibraryExercise(
            name: "Сведение ноги в кроссовере",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Встань боком у нижнего блока, пристегни манжету к лодыжке ближней к блоку ноги. Отойди в сторону на широкую стойку и возьмись за стойку для равновесия. Рабочая нога отведена к блоку - это исходное положение.\n\nДвижение: Приводи рабочую ногу к опорной и проводи её перед ней, работая внутренней поверхностью бедра. Выдох на сведении, плавно верни ногу обратно на вдохе.\n\nКлючи: Двигайся только ногой, корпус держи стабильным и не разворачивайся. Контролируй возврат, не давай блоку дёргать ногу. Чувствуй приводящие, а не инерцию.",
            videoUrl: "https://www.youtube.com/results?search_query=Cable%20Hip%20Adduction%20technique"
        ),
        LibraryExercise(
            name: "Пуловер на блоке прямыми руками на наклонной",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Ляг на наклонную скамью спиной к верхнему блоку с прямой рукоятью. Возьми рукоять прямым хватом на ширине плеч и выпрями руки перед собой, гриф примерно в паре сантиметров над бёдрами.\n\nДвижение: Не сгибая локти, по дуге уводи прямые руки назад, пока рукоять не окажется прямо над головой. Затем силой широчайших верни руки в исходное и задержись в сокращении.\n\nКлючи: Локти держи почти прямыми и неподвижными - тянешь широчайшими, а не руками. Двигайся подконтрольно, без рывков. Вдох на разведении, выдох на возврате.",
            videoUrl: "https://www.youtube.com/results?search_query=Cable%20Incline%20Straight-Arm%20Pushdown%20technique"
        ),
        LibraryExercise(
            name: "Французский жим на блоке на наклонной скамье",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Ляг на наклонную скамью спиной к верхнему блоку с прямой рукоятью. Возьми рукоять узким прямым хватом, локти прижаты к бокам, плечи под углом около 25° к полу.\n\nДвижение: Сохраняя плечи неподвижными, разгибай локти и выпрямляй руки, напрягая трицепс. Выдох вверху, задержи сокращение на секунду, затем плавно верни в исходное.\n\nКлючи: Двигаются только предплечья - плечи не уплывают вперёд. Локти держи прижатыми и узко. Чувствуй трицепс, не помогай инерцией; в нижней точке сохраняй натяжение.",
            videoUrl: "https://www.youtube.com/results?search_query=Cable%20Incline%20Triceps%20Extension%20technique"
        ),
        LibraryExercise(
            name: "Внутренняя ротация плеча на блоке",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Сядь боком к нижнему блоку и возьми одиночную рукоять ближней к блоку рукой. Прижми локоть к боку, согни его под 90°, предплечье смотрит к блоку - это исходное положение.\n\nДвижение: Вращая плечо внутрь, веди рукоять к животу, пока предплечье не пересечёт пресс. Рисуешь как бы полукруг. Затем плавно вернись в исходное.\n\nКлючи: Локоть всё время прижат к боку, движение идёт только за счёт ротации плеча. Предплечье держи перпендикулярно корпусу. Вес лёгкий - это работа на ротаторную манжету, темп подконтрольный.",
            videoUrl: "https://www.youtube.com/results?search_query=Cable%20Internal%20Rotation%20technique"
        ),
        LibraryExercise(
            name: "Французский жим лёжа на блоке",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Ляг на горизонтальную скамью и возьми прямую рукоять нижнего блока узким прямым хватом. Выпрями руки над собой - руки и корпус образуют прямой угол. Это исходное положение.\n\nДвижение: Сгибая локти и держа плечи неподвижными, опусти рукоять почти до лба на вдохе. Затем напряги трицепс и верни рукоять вверх на выдохе.\n\nКлючи: Плечи держи на месте, локти не разъезжаются в стороны. В верхней точке задержись на секунду, не выключая трицепс. Блок даёт постоянное натяжение - используй это, двигайся плавно.",
            videoUrl: "https://www.youtube.com/results?search_query=Cable%20Lying%20Triceps%20Extension%20technique"
        ),
        LibraryExercise(
            name: "Жим над головой в кроссовере",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Опусти блоки кроссовера в нижнее положение и подбери вес. Встань ровно между стойками, возьми рукояти и держи их на уровне плеч ладонями вперёд - это исходное положение.\n\nДвижение: Держа грудь и голову поднятыми, разгибай локти и выжимай рукояти прямо над головой. Сделай паузу вверху и подконтрольно опусти их обратно.\n\nКлючи: Корпус держи стабильным, не прогибайся в пояснице - напряги пресс. Постоянное натяжение тросов грузит дельты во всей амплитуде. Не сводй рукояти в одну точку резко, веди по ровной траектории.",
            videoUrl: "https://www.youtube.com/results?search_query=Cable%20Shoulder%20Press%20technique"
        ),
        LibraryExercise(
            name: "Сгибание кистей на блоке",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: Поставь горизонтальную скамью перед нижним блоком с прямой рукоятью. Возьми рукоять узким хватом ладонями вверх и положи предплечья на бёдра так, чтобы кисти свисали за коленями.\n\nДвижение: Сгибай кисти вверх на выдохе и задержи сокращение на секунду. Затем плавно опусти кисти вниз на вдохе до полного растяжения.\n\nКлючи: Двигаются только запястья - предплечья неподвижны на бёдрах. Работай в полной амплитуде, без рывков, чувствуй сгибатели предплечья. Хват держи плотным, но не пережимай.",
            videoUrl: "https://www.youtube.com/results?search_query=Cable%20Wrist%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Подъем на носок на одной ноге с гантелью",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Возьмись рукой за устойчивую опору для баланса и встань носком одной ноги на гриф гантели, лучше с круглыми дисками - так он чуть катится и заставляет стабилизировать стопу. Подай стопу немного вперёд для растяжения икры.\n\nДвижение: Поднимайся на носок, прокатывая стопу через гриф до полного подъёма, и сильно сожми икру вверху на выдохе. На вдохе опускайся, прокатывая гантель чуть вперёд для лучшей растяжки.\n\nКлючи: Работай в полной амплитуде - глубокая растяжка внизу, жёсткое сокращение вверху с паузой. Балансируй за счёт опоры, не раскачивайся. Гантель вместо платформы добавляет работу стабилизаторам.",
            videoUrl: "https://www.youtube.com/results?search_query=Single-Leg%20Calf%20Raise%20on%20a%20Dumbbell%20technique"
        ),
        LibraryExercise(
            name: "Подъемы на носки с резиной",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Встань на эспандер носками так, чтобы длина резины с обеих сторон была одинаковой. Подними ручки к голове, как перед жимом над головой: ладони вперёд, локти согнуты и в стороны - резина уже под натяжением. Это исходное положение.\n\nДвижение: Держа руки у плеч, поднимайся на носки на выдохе и сильно сожми икры вверху. После секундной паузы плавно опустись в исходное.\n\nКлючи: Руки не двигаются - они только держат натяжение, работают икры. Поднимайся высоко на носок и контролируй спуск, не падай вниз. Удобный домашний вариант без отягощений.",
            videoUrl: "https://www.youtube.com/results?search_query=Banded%20Calf%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Растяжка икр у стены",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Встань лицом к стене на расстоянии примерно полуметра. Обопрись предплечьями о стену, перенося на них часть веса.\n\nДвижение: Наклонись к стене, стараясь держать пятки прижатыми к полу, и почувствуй растяжение икр. Задержись на 10-20 секунд.\n\nКлючи: Регулируй расстояние до стены: дальше - сильнее растяжка, ближе - мягче. Пятки не отрывай, иначе растяжение пропадает. Дыши спокойно и не пружинь - тяни плавно.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Calf%20Stretch%20Against%20Wall%20technique"
        ),
        LibraryExercise(
            name: "Бросок мяча из-за головы",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Встань лицом к стене или партнёру, медбол держи двумя руками. Ноги на ширине плеч, корпус напряжён.\n\nДвижение: Заведи мяч за голову, потянись назад до ощущения растяжения, затем мощно выбрось его вперёд из-за головы. Сразу готовься поймать отскок.\n\nКлючи: Сила идёт от корпуса, а не только от рук. У стены вставай поближе и целься чуть выше, чем при броске партнёру. Не задерживай дыхание - выдыхай на броске.",
            videoUrl: "https://www.youtube.com/results?search_query=Catch%20and%20Overhead%20Throw%20technique"
        ),
        LibraryExercise(
            name: "Растяжка груди и передних дельт с палкой",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Встань прямо, ноги вместе, возьми гимнастическую палку или бодибар. Хват чуть шире плеч, ладони смотрят вниз, палка перед собой.\n\nДвижение: Плавно подними палку вверх и заведи её за голову, пока не почувствуешь мягкое растяжение в груди и передних дельтах. Задержись и спокойно верни вперёд.\n\nКлючи: Работай медленно, без рывков - резкое заведение перегружает плечо. Чем уже хват, тем сильнее растяжение, начинай с широкого. Дыши ровно, не задерживай воздух.",
            videoUrl: "https://www.youtube.com/results?search_query=Chest%20And%20Front%20Of%20Shoulder%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Бросок мяча от груди (одиночный)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Встань на колени лицом к стене или партнёру, медбол прижми к груди двумя руками. Корпус напряжён, спина прямая.\n\nДвижение: Взрывным движением вытолкни таз вперёд и одновременно выжми мяч от груди как можно дальше. Доведи бросок до конца, падая вперёд и страхуя себя руками.\n\nКлючи: Импульс идёт от бёдер, руки лишь продолжают движение. Не зажимай мяч слишком долго - работай на скорость. Выдыхай резко в момент выброса.",
            videoUrl: "https://www.youtube.com/results?search_query=Chest%20Push%20%28Single%20Response%29%20technique"
        ),
        LibraryExercise(
            name: "Растяжка груди на фитболе",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Встань на четвереньки рядом с фитболом. Положи локоть на верх мяча, рука отведена в сторону. Это исходное положение.\n\nДвижение: Опускай корпус к полу, оставляя локоть на мяче, пока не почувствуешь растяжение в груди. Держи 20-30 секунд и повтори с другой рукой.\n\nКлючи: Тянись мягко, до приятного натяжения, а не до боли. Не проваливай поясницу - корпус держи единой линией. Дыши спокойно, на выдохе тянись чуть глубже.",
            videoUrl: "https://www.youtube.com/results?search_query=Chest%20Stretch%20on%20Stability%20Ball%20technique"
        ),
        LibraryExercise(
            name: "Становая тяга в стиле взятия",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга у голеней, стопы под тазом, носки чуть развёрнуты. Хват сверху или замковый, на ширине плеч. Присядь к грифу: спина прямая, плечи перед грифом, корпус максимально вертикально.\n\nДвижение: Толкайся через переднюю часть пяток, отрывая штангу. Пока гриф идёт вверх, сохраняй угол спины неизменным, колени слегка разводи в стороны от грифа. После прохождения колен дотолкни таз вперёд до полного выпрямления бёдер и коленей.\n\nКлючи: Угол спины фиксирован до колен - не выпрямляйся раньше времени. Гриф идёт вплотную к ногам. Вдох и напряжение пресса перед отрывом, выдох наверху.",
            videoUrl: "https://www.youtube.com/results?search_query=Clean%20Deadlift%20technique"
        ),
        LibraryExercise(
            name: "Протяжка в взятии (Clean Pull)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга на полу у голеней, хват сверху или замковый чуть шире ног. Опусти таз, вес на пятках, спина прямая, взгляд вперёд, грудь раскрыта, плечи чуть впереди грифа.\n\nДвижение: Первая тяга - толкайся через пятки, разгибая колени, угол спины и прямые руки сохраняй. Доведи гриф выше колен под контролем. Вторая тяга - у середины бедра резко разгибай бёдра, колени и стопы как в прыжке, разгоняя штангу. Руки не тянут, в финале тело полностью выпрямлено, лёгкий наклон назад.\n\nКлючи: Ускорение даёт взрыв таза, а не руки. Финальное разгибание мощное и короткое - не затягивай его. Гриф держи близко к телу.",
            videoUrl: "https://www.youtube.com/results?search_query=Clean%20Pull%20technique"
        ),
        LibraryExercise(
            name: "Взятие на грудь и толчок",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга у голеней, хват сверху или замковый чуть шире ног. Таз опущен, вес на пятках, спина прямая, грудь раскрыта, плечи чуть впереди грифа.\n\nДвижение: Тяни с пола через пятки, у середины бедра взрывом разгибай бёдра, колени и стопы. На пике подрыва агрессивно подсаживайся под штангу, оборачивая локти под гриф, и принимай её в передний присед на плечи. Встань, затем подсед-толчок: короткий дроп коленей и мощный выброс штанги над головой в ножницы, руки выпрямлены. Встань в стойку.\n\nКлючи: Не тяни штангу руками - они работают только в подрыве и подседе. Локти высоко при приёме на грудь. В толчке убирай голову с траектории грифа и фиксируй руки до выпрямления ног.",
            videoUrl: "https://www.youtube.com/results?search_query=Clean%20and%20Jerk%20technique"
        ),
        LibraryExercise(
            name: "Взятие на грудь и жим",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Стопы на ширине плеч, колени внутри рук. Спина прямая, согнись в коленях и тазе, возьми гриф прямым хватом чуть шире плеч, локти в стороны. Гриф у голеней, плечи над грифом или чуть впереди.\n\nДвижение: Тяни гриф, разгибая колени, таз и плечи поднимаются синхронно, угол спины постоянный. У колен взрывом разгибай голеностопы, колени и таз как в прыжке, подрывая штангу шрагом вверх. Подсаживайся под гриф, оборачивай локти и прими на передние дельты. Встань. Затем без шага выжми штангу над головой на выдохе и опусти под контролем.\n\nКлючи: Гриф идёт вплотную к телу, локти высоко в подрыве. Не жми раньше, чем встал из подседа. Вдох на подрыве, выдох на жиме.",
            videoUrl: "https://www.youtube.com/results?search_query=Clean%20and%20Press%20technique"
        ),
        LibraryExercise(
            name: "Отжимания по кругу (часы)",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Прими упор лёжа, опора на ладони и носки. Руки полностью выпрямлены, кисти на ширине плеч, тело прямой линией.\n\nДвижение: Опустись, сгибая локти, к полу. Из нижней точки взрывом оттолкнись так, чтобы оторваться от пола и сместиться на 30-45 см в сторону. В прыжке развернись корпусом примерно на 30 градусов и приземлись для следующего повтора. Иди по кругу, пока не вернёшься в старт.\n\nКлючи: Тело держи единой линией, не проваливай таз. Отжимание мощное и быстрое - смысл в полёте. Приземляйся мягко на согнутые локти, чтобы беречь плечи и запястья.",
            videoUrl: "https://www.youtube.com/results?search_query=Clock%20Push-Up%20technique"
        ),
        LibraryExercise(
            name: "Кроссовер с резиной",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Закрепи резину на устойчивой опоре. Встань спиной к опоре, возьми ручки в обе руки и шагни вперёд, чтобы создать натяжение. Разведи руки в стороны параллельно полу, ладони вперёд, локти чуть согнуты - корпус и руки образуют букву Т.\n\nДвижение: Сводя руки прямыми, веди их по дуге перед собой к центру груди на выдохе, напрягая грудные. Задержи сжатие на секунду. На вдохе медленно вернись в исходное.\n\nКлючи: Локти всё время чуть согнуты, фиксированы - двигай только плечевым суставом. В пике сжимай грудь, а не дотягивай руками. Возврат медленный и подконтрольный.",
            videoUrl: "https://www.youtube.com/results?search_query=Cross%20Over%20-%20With%20Bands%20technique"
        ),
        LibraryExercise(
            name: "Жим узким хватом с французским на наклоне вниз",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Закрепи ноги в конце наклонной скамьи головой вниз и ляг. Узким хватом (чуть уже плеч) сними штангу со стоек и держи над собой, руки выпрямлены, локти прижаты, гриф перпендикулярно полу.\n\nДвижение: На вдохе опусти штангу к нижней части груди, локти держи прижатыми, и трицепсами выжми обратно на выдохе. Затем, держа плечи неподвижно, на вдохе опусти гриф полукругом ко лбу до лёгкого касания, и снова разогни трицепсами на выдохе.\n\nКлючи: Локти не разводи в стороны - так нагрузка идёт в трицепс. Со стоек снимай штангу со страхующим, чтобы беречь плечо. Двигай только предплечьями, плечи зафиксированы.",
            videoUrl: "https://www.youtube.com/results?search_query=Decline%20Close-Grip%20Bench%20To%20Skull%20Crusher%20technique"
        ),
        LibraryExercise(
            name: "Скручивания на наклонной скамье вниз",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Закрепи ноги в конце наклонной скамьи головой вниз и ляг. Кисти положи легко по бокам головы, локти не разводи широко, пальцы за головой не сцепляй.\n\nДвижение: Прижимая поясницу к скамье, начни скручивать плечи вверх. Дави поясницей вниз, напрягая пресс на выдохе - плечи отрываются примерно на 10 см, поясница остаётся на скамье. В верхней точке задержи сжатие на секунду. На вдохе медленно опустись в исходное.\n\nКлючи: Работают только мышцы пресса, шею руками не тяни. Без рывков и инерции - медленно и подконтрольно. Поясницу от скамьи не отрывай.",
            videoUrl: "https://www.youtube.com/results?search_query=Decline%20Crunch%20technique"
        ),
        LibraryExercise(
            name: "Сведение гантелей на скамье с обратным наклоном",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Старт: Закрепи ноги в конце наклонной скамьи головой вниз и ляг, гантели сначала на бёдрах, ладони смотрят друг на друга. Выведи гантели над грудью на ширине плеч, руки выпрямлены перпендикулярно полу.\n\nДвижение: С лёгким сгибом в локтях разведи руки в стороны широкой дугой, пока не почувствуешь растяжение в груди - вдох. Сводя грудные и выдыхая, верни гантели наверх по той же дуге. В верхней точке задержись на секунду.\n\nКлючи: Лёгкий сгиб в локтях беречёт бицепс - не выпрямляй руки до замка. Движение только в плечевом суставе, руки неподвижны. Не опускай слишком глубоко, чтобы не перегрузить плечо.",
            videoUrl: "https://www.youtube.com/results?search_query=Decline%20Dumbbell%20Flyes%20technique"
        ),
        LibraryExercise(
            name: "Французский жим гантелями на обратном наклоне",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Закрепи ноги в конце наклонной скамьи головой вниз и ляг, гантели сначала на бёдрах, ладони смотрят друг на друга. Выведи гантели над грудью на ширине плеч, руки выпрямлены перпендикулярно полу.\n\nДвижение: Держа плечи неподвижно и локти прижатыми, на вдохе опусти гантели полукругом к голове, пока большие пальцы не окажутся у ушей. Затем разогни трицепсы и верни гантели наверх на выдохе.\n\nКлючи: Двигаются только предплечья, плечи зафиксированы - так нагрузка целиком в трицепсе. Локти не разводи в стороны. Опускай под контролем, без бросков веса.",
            videoUrl: "https://www.youtube.com/results?search_query=Decline%20Dumbbell%20Triceps%20Extension%20technique"
        ),
        LibraryExercise(
            name: "Французский жим EZ-штанги на обратном наклоне",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Закрепи ноги в конце наклонной скамьи головой вниз и ляг. Узким хватом (чуть уже плеч) сними EZ-гриф со стоек и держи над собой, руки выпрямлены, локти прижаты, гриф перпендикулярно полу.\n\nДвижение: Держа плечи неподвижно, на вдохе опусти гриф полукругом к голове, пока он слегка не коснётся лба. Затем разогни трицепсы и верни гриф наверх на выдохе.\n\nКлючи: Двигаются только предплечья - плечи фиксированы, нагрузка идёт в трицепс. Со стоек снимай EZ-гриф со страхующим, чтобы беречь плечо. Локти держи прижатыми, не разводи.",
            videoUrl: "https://www.youtube.com/results?search_query=Decline%20EZ%20Bar%20Triceps%20Extension%20technique"
        ),
        LibraryExercise(
            name: "Косые скручивания на наклонной скамье",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Зафиксируй ноги на наклонной скамье и ляг. Приподними корпус на 35-45° от пола, одну руку держи у головы, другую на бедре.\n\nДвижение: На выдохе медленно поднимай корпус и одновременно скручивайся в сторону, пока локоть не коснётся противоположного колена. Задержись на секунду и на вдохе опустись обратно.\n\nКлючи: Главное - не скорость, а скрутка и контроль. Тяни не шеей, а косыми, держи пресс в напряжении весь подход. Сделай все повторы на одну сторону, потом меняй.",
            videoUrl: "https://www.youtube.com/results?search_query=Decline%20Oblique%20Crunch%20technique"
        ),
        LibraryExercise(
            name: "Обратные скручивания на наклонной скамье",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг спиной на наклонную скамью и крепко возьмись руками за её верх, чтобы не сползать. Ноги вытяни почти прямо, слегка согнув колени, и держи параллельно полу за счёт пресса.\n\nДвижение: На выдохе подтягивай колени к груди, скручивая таз и отрывая бёдра от скамьи. В верхней точке колени почти у груди - задержись на секунду. На вдохе плавно опусти ноги обратно.\n\nКлючи: Работает пресс, а не мах ногами. Не раскачивайся и не сползай вниз. Чем медленнее опускаешь таз, тем сильнее нагрузка на низ живота.",
            videoUrl: "https://www.youtube.com/results?search_query=Decline%20Reverse%20Crunch%20technique"
        ),
        LibraryExercise(
            name: "Жим Смита на скамье с обратным наклоном",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Старт: Поставь скамью с обратным наклоном под Смит-машину. Гриф выставь так, чтобы лёжа доставать его почти прямыми руками. Возьми прямым хватом чуть шире плеч, сними гриф со стоек и держи над собой.\n\nДвижение: На вдохе подконтрольно опусти гриф, сгибая локти, до лёгкого касания нижней части груди. После короткой паузы выжми обратно вверх, выдыхая на усилии.\n\nКлючи: Обратный наклон смещает нагрузку на низ груди. Не бросай гриф на грудь и не отбивай. По завершении подхода обязательно защёлкни гриф на стойках.",
            videoUrl: "https://www.youtube.com/results?search_query=Decline%20Smith%20Machine%20Press%20technique"
        ),
        LibraryExercise(
            name: "Становая тяга с дефицита",
            category: .back,
            muscleGroup: .lowerBack,
            defaultType: .strength,
            technique: "Старт: Встань на платформу или блины высотой 3-8 см, гриф над серединой стоп, ноги на ширине таза. Наклонись от бёдер и возьмись за гриф на ширине плеч прямым или разнохватом.\n\nДвижение: Сделай вдох, опусти таз и согни колени, пока голени не коснутся грифа. Грудь вверх, спина прогнута, взгляд вперёд. Толкай пятками и веди штангу вверх, после колен резко выводи таз вперёд и своди лопатки.\n\nКлючи: Дефицит увеличивает амплитуду и сильнее грузит низ спины и ноги. Держи спину нейтральной от старта до верха, не округляй поясницу. Вес бери меньше, чем в обычной тяге.",
            videoUrl: "https://www.youtube.com/results?search_query=Deficit%20Deadlift%20technique"
        ),
        LibraryExercise(
            name: "Прыжок в глубину с запрыгиванием",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: Поставь две тумбы: одну ниже (30-40 см), вторую выше (55-65 см), на расстоянии метра друг от друга. Встань на низкую тумбу, стопы вместе и чуть у края, руки вдоль тела.\n\nДвижение: Спрыгни с тумбы и приземлись на обе ноги, тут же отталкиваясь без задержки. Взрывным движением выпрыгивай вверх и вперёд, помогая руками, и запрыгивай на высокую тумбу. Мягко гаси приземление ногами.\n\nКлючи: Это плиометрика на реактивную силу - время контакта с землёй минимальное. Не зависай в приседе, отскакивай сразу. Делай свежим, на качество, не на усталость.",
            videoUrl: "https://www.youtube.com/results?search_query=Depth%20Jump%20to%20Box%20technique"
        ),
        LibraryExercise(
            name: "Подъемы на носки в наклоне (ослик)",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Зайди в тренажёр для подъёмов осликом, подведи поясницу и таз под мягкий упор - касается область копчика. Возьмись за рукояти, поставь носки на платформу, пятки свисают. Колени выпрями, но не блокируй.\n\nДвижение: На выдохе поднимай пятки как можно выше, разгибая голеностоп и сжимая икры. Колени держи неподвижными, без сгибания. Задержись на секунду в верхней точке.\n\nКлючи: Наклон корпуса даёт икрам отличную растяжку под нагрузкой. На вдохе медленно опускай пятки до полного растяжения. Носки можно ставить прямо, внутрь или наружу, меняя акцент.",
            videoUrl: "https://www.youtube.com/results?search_query=Donkey%20Calf%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Толчок двух гирь",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Возьми по гире в каждую руку. Закинь их на грудь, разгибаясь в ногах и бёдрах и подтягивая гири к плечам. Проверни кисти, чтобы ладони смотрели вперёд - это исходная позиция.\n\nДвижение: Сделай короткий подсед, сгибая колени и держа корпус вертикально. Тут же резко толкнись пятками вверх, словно выпрыгиваешь, и за счёт инерции выжми гири над головой на прямые руки. Прими вес в небольшом разножке, затем выпрямись и сведи стопы.\n\nКлючи: Гири выталкивают ноги, а не руки - руки только фиксируют. Держи корпус жёстким, не прогибай поясницу под весом. Опусти гири на грудь и повтори.",
            videoUrl: "https://www.youtube.com/results?search_query=Double%20Kettlebell%20Jerk%20technique"
        ),
        LibraryExercise(
            name: "Мельница с двумя гирями",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Одну гирю положи перед передней стопой, вторую закинь на грудь и выжми над головой. Зафиксируй верхнюю гирю на прямой руке, ладонь вперёд. Стопы разверни примерно на 45° от поднятой руки.\n\nДвижение: Отводя таз в сторону поднятой гири, медленно наклоняйся вбок, пока не достанешь до нижней гири на полу. Глаз с верхней гири не своди. После касания пола сделай паузу и плавно вернись в исходное положение.\n\nКлючи: Верхняя рука всё время прямая и заблокированная - это упражнение на стабильность плеча и силу кора. Движение идёт от бедра, а не за счёт сгибания спины. Не торопись, контролируй каждый сантиметр.",
            videoUrl: "https://www.youtube.com/results?search_query=Double%20Kettlebell%20Windmill%20technique"
        ),
        LibraryExercise(
            name: "Жим гантелей лежа нейтральным хватом",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Ляг на горизонтальную скамью с гантелями, стопы плотно на полу, лопатки сведены. Держи нейтральный хват - ладони смотрят друг на друга, руки выпрямлены над собой перпендикулярно полу.\n\nДвижение: Сгибая локти, опускай гантели вдоль корпуса, пока они не окажутся у груди. Сделай паузу, затем выжимай вверх, разгибая локти, и возвращайся в исходное положение.\n\nКлючи: Нейтральный хват бережёт плечи и сильнее включает середину груди и трицепс. Не разводи локти широко в стороны, веди их ближе к телу. Гантели не сталкивай вверху, держи стабильную траекторию.",
            videoUrl: "https://www.youtube.com/results?search_query=Neutral-Grip%20Dumbbell%20Bench%20Press%20technique"
        ),
        LibraryExercise(
            name: "Взятие гантелей на грудь",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Встань с гантелями в руках, стопы на ширине плеч. Опусти вес к полу, сгибаясь в бёдрах и коленях и отводя таз назад, пока гантели не окажутся внизу - это исходная позиция.\n\nДвижение: Мощно выпрыгни вверх, разгибая бёдра, колени и голеностоп, чтобы разогнать гантели. Руки держи прямыми до полного выпрямления тела. Затем снова подсядь, согнув бёдра и колени, и прими гантели на плечи. Выпрямись в стойку.\n\nКлючи: Скорость придаёт разгон ногами и бёдрами, а не руками - это взрывное движение. Держи гантели близко к телу и спину нейтральной. Подсед под вес делай быстро, не лови гантели прямыми руками.",
            videoUrl: "https://www.youtube.com/results?search_query=Dumbbell%20Clean%20technique"
        ),
        LibraryExercise(
            name: "Жим гантели над головой одной рукой",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Сядь на скамью со спинкой или встань прямо, гантель в одной руке. Закинь её к плечу, проверни кисть ладонью вперёд. Вторую руку держи у пояса или за опору - это исходная позиция.\n\nДвижение: На выдохе выжимай гантель вверх, пока рука полностью не выпрямится. После короткой паузы на вдохе медленно опусти к плечу.\n\nКлючи: Работа одной рукой нагружает кор, удерживая корпус от заваливания вбок - не наклоняйся. Не дёргай вес поясницей, жми плечом. Сделай все повторы одной рукой, потом поменяй.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Dumbbell%20Shoulder%20Press%20technique"
        ),
        LibraryExercise(
            name: "Подъемы гантелей в плоскости лопатки (скапция)",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Возьми по лёгкой гантели и опусти руки вдоль тела, большие пальцы вверх. Встань прямо, плечи расслаблены.\n\nДвижение: Поднимай прямые руки вперёд и слегка в стороны - примерно на 30° от центра, в плоскости лопатки. Веди до уровня плеч, затем плавно опускай обратно.\n\nКлючи: Это упражнение на стабилизаторы лопатки, бери реально лёгкий вес. Большие пальцы смотрят вверх, не задирай руки выше плеч, чтобы не зажимать сустав. Движение медленное и контролируемое, без рывков.",
            videoUrl: "https://www.youtube.com/results?search_query=Dumbbell%20Scaption%20technique"
        ),
        LibraryExercise(
            name: "Приседания с гантелями",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Встань прямо с гантелями в руках, ладони к бёдрам. Стопы на ширине плеч, носки слегка наружу, спина прямая, взгляд вперёд.\n\nДвижение: Медленно опускайся, сгибая колени и сохраняя ровную осанку, пока бёдра не станут параллельны полу. На выдохе вставай, отталкиваясь пятками и выпрямляя ноги в исходное положение.\n\nКлючи: Колени двигаются в направлении носков, не заваливай их внутрь и не выводи далеко за носки. Смотри вперёд - взгляд вниз сбивает баланс. Гантели просто висят по бокам, не тяни ими плечи вверх.",
            videoUrl: "https://www.youtube.com/results?search_query=Dumbbell%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Динамическая растяжка спины (махи руками)",
            category: .complex,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Встань, стопы на ширине плеч, руки опущены вдоль тела - это исходное положение.\n\nДвижение: Держа руки прямыми, махом поднимай их перед собой вверх и опускай обратно, 5-10 раз. С каждым разом немного увеличивай амплитуду, пока руки не будут заходить выше головы.\n\nКлючи: Это динамическая разминка, а не статическая растяжка - двигайся плавно, без рывков на пределе. Начинай с малой амплитуды и наращивай постепенно. Отлично заходит как разогрев плеч и спины перед тренировкой.",
            videoUrl: "https://www.youtube.com/results?search_query=Dynamic%20Back%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Динамическая растяжка груди",
            category: .complex,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Встань прямо, руки соедини и вытяни прямо перед собой - это исходное положение.\n\nДвижение: Держа руки прямыми, быстро разводи их назад как можно дальше и своди обратно - словно утрированно хлопаешь. Повтори 5-10 раз, постепенно ускоряясь.\n\nКлючи: Это динамическая разминка для груди и плеч, не статика. Разводя руки, чувствуй растяжение грудных, но не уходи в боль. Хорошо открывает грудь перед жимами и любой работой на верх тела.",
            videoUrl: "https://www.youtube.com/results?search_query=Dynamic%20Chest%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Скручивания на фитболе",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ложись спиной на мяч так, чтобы поясница повторяла его изгиб, стопы упри в пол на ширине плеч. Руки скрести на груди или держи вдоль тела, верх корпуса свисает с мяча.\n\nДвижение: На выдохе скручивай корпус вверх за счёт пресса, поднимая плечи и грудной отдел. В верхней точке задержись на секунду и почувствуй сжатие. На вдохе плавно опустись обратно в лёгкое растяжение.\n\nКлючи: Поясница всё время лежит на мяче, шею не дёргай и не тяни руками за голову - работает пресс, а не рывок. Фокус на коротком, контролируемом сокращении, а не на амплитуде.",
            videoUrl: "https://www.youtube.com/results?search_query=Exercise%20Ball%20Crunch%20technique"
        ),
        LibraryExercise(
            name: "Подтягивание коленей на фитболе",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Прими упор лёжа, руки на полу на ширине плеч, голени положи на фитбол. Ноги выпрямлены, тело вытянуто в одну линию от плеч до пяток.\n\nДвижение: На выдохе подтягивай колени к груди, позволяя мячу прокатиться под лодыжки. В верхней точке сожми пресс и задержись на секунду. На вдохе медленно выпрямляй ноги, откатывая мяч в исходное.\n\nКлючи: Спину держи прямой, не проваливай поясницу и не задирай таз. Плечи над кистями, корпус неподвижен - двигаются только ноги. Если мяч уезжает в сторону, замедлись и контролируй его прессом.",
            videoUrl: "https://www.youtube.com/results?search_query=Exercise%20Ball%20Pull-In%20technique"
        ),
        LibraryExercise(
            name: "Внешняя ротация плеча с гантелью",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: Ляг на бок на скамью, нижней рукой поддержи голову. В верхней руке гантель, локоть согнут на 90 градусов и прижат к боку, предплечье лежит поперёк живота.\n\nДвижение: На выдохе разворачивай предплечье наружу полукругом, поднимая гантель вверх. Сохраняй угол в локте 90 градусов, пока предплечье не встанет вертикально. Задержись на секунду и на вдохе плавно опусти.\n\nКлючи: Локоть всё время прижат к боку, двигается только предплечье - это работа вращательной манжеты, а не дельт. Бери лёгкий вес и делай чисто, без рывков, чтобы беречь плечо. Повтори на другую руку.",
            videoUrl: "https://www.youtube.com/results?search_query=Dumbbell%20External%20Rotation%20technique"
        ),
        LibraryExercise(
            name: "Быстрые скиппинги",
            category: .cardio,
            muscleGroup: .calves,
            defaultType: .duration,
            technique: "Старт: Встань расслабленно, одна нога чуть впереди. Корпус прямой, взгляд вперёд, руки готовы работать в такт ногам.\n\nДвижение: Выполняй скиппинг по схеме шаг-подскок: правая-правая-смена на левую-левую-смена и так попеременно. Двигайся вперёд как можно быстрее, держа контакт с землёй минимальным.\n\nКлючи: Сокращай время в воздухе - частота важнее высоты подскока. Приземляйся на переднюю часть стопы и сразу отталкивайся, пружиня икрами. Дыши ровно, держи ритм, корпус не заваливай назад.",
            videoUrl: "https://www.youtube.com/results?search_query=Fast%20Skipping%20technique"
        ),
        LibraryExercise(
            name: "Сгибание пальцев со штангой",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: Возьми штангу хватом снизу на ширине плеч, ладони вверх. Стопы поставь чуть шире плеч, предплечья можно опереть на бёдра, чтобы работали только кисти.\n\nДвижение: Опусти гриф как можно ниже, разгибая пальцы и позволяя ему скатиться к их кончикам. Затем на выдохе сожми пальцы и закати гриф обратно как можно выше, задержавшись в верхней точке.\n\nКлючи: Двигаются только пальцы, запястье и предплечье неподвижны - это прокачка хвата и сгибателей кисти. Не роняй гриф, контролируй прокат вниз. Вес умеренный, амплитуда полная.",
            videoUrl: "https://www.youtube.com/results?search_query=Barbell%20Finger%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Подтягивание ног на скамье",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на скамью или коврик так, чтобы ноги свисали с края. Руки положи под ягодицы ладонями вниз или держись за края скамьи. Ноги выпрями.\n\nДвижение: На выдохе согни колени и подтягивай бёдра к животу, пока колени не подойдут к груди. Задержись в сжатии на секунду. На вдохе медленно выпрями ноги обратно в исходное.\n\nКлючи: Поясницу прижимай к опоре, не раскачивайся - тяни ноги прессом, а не инерцией. В нижней точке не бросай ноги вниз и не касайся пола, держи напряжение в животе всё время.",
            videoUrl: "https://www.youtube.com/results?search_query=Flat%20Bench%20Leg%20Pull-In%20technique"
        ),
        LibraryExercise(
            name: "Флаттер-кики (попеременные махи ногами)",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг лицом вниз на скамью так, чтобы таз был у края, а ноги свисали. Возьмись руками за передний край скамьи. Напряги ягодицы и выпрями ноги до уровня бёдер.\n\nДвижение: Подними левую ногу выше правой, затем опусти её и одновременно подними правую. Продолжай попеременно, как при плавании, держа ноги прямыми.\n\nКлючи: Движение мелкое и контролируемое, без раскачки таза - работают ягодицы и низ спины. Дыши ровно, не задерживай воздух. Если тянет поясницу, уменьши амплитуду маха.",
            videoUrl: "https://www.youtube.com/results?search_query=Flutter%20Kicks%20technique"
        ),
        LibraryExercise(
            name: "Протяжка салазок с жимом",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Прикрепи к салазкам ремни или канат с двумя ручками. Встань спиной к сани, по ручке в каждой руке, корпус слегка наклони вперёд.\n\nДвижение: Шагай вперёд, проталкивая сани за счёт ног и бёдер. На каждом шаге делай паузу и выжимай руки вперёд, разгибая локти. Так шагами тяни сани и одновременно жми.\n\nКлючи: Держи корпус наклонённым и напряжённым, усилие идёт от ног, а не от поясницы. Жим синхронизируй с шагом - это работа на всё тело и выносливость. Дыши размеренно, не задерживай дыхание под нагрузкой.",
            videoUrl: "https://www.youtube.com/results?search_query=Forward%20Sled%20Drag%20with%20Press%20technique"
        ),
        LibraryExercise(
            name: "Подъёмы перед собой на наклонной скамье",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Сядь на наклонную скамью с углом 30-60 градусов, в каждой руке гантель. Вытяни руки перед собой ладонями вниз, гантели чуть выше бёдер. Спиной обопрись на скамью.\n\nДвижение: На выдохе подними гантели прямо вверх до уровня чуть выше плеч, локти держи почти прямыми. Сожми дельты в верхней точке на секунду. На вдохе плавно опусти руки в исходное.\n\nКлючи: Не раскачивайся и не помогай корпусом - наклон скамьи как раз это исключает, поэтому работают именно передние дельты. Вес небольшой, движение чистое. Голову и ноги держи на месте.",
            videoUrl: "https://www.youtube.com/results?search_query=Incline%20Front%20Dumbbell%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Махи ногой вперёд (динамическая растяжка)",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Встань боком к стулу или опоре, держись за неё одной рукой. Спина прямая, опорная нога устойчиво на полу.\n\nДвижение: Махни рабочей ногой вперёд, держа её прямой, затем плавно отведи назад настолько, насколько позволяет гибкость. Двигайся маятником, постепенно увеличивая амплитуду. Сделай 5-10 махов и смени ногу.\n\nКлючи: Это динамическая растяжка, а не силовое - размах контролируемый, без резких рывков. Корпус держи ровно, не заваливайся за ногой. С каждым махом мах чуть свободнее, разогревая бёдра перед нагрузкой.",
            videoUrl: "https://www.youtube.com/results?search_query=Front%20Leg%20Swing%20technique"
        ),
        LibraryExercise(
            name: "Фронтальные приседания с двумя гирями",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Закинь две гири на плечи: разгибая ноги и бёдра, подтяни их вверх и проверни кисти, чтобы гири легли на предплечья у плеч. Локти подними, корпус прямой, взгляд вперёд.\n\nДвижение: Приседай как можно ниже, разводя колени в стороны, и сделай паузу внизу. Держи корпус вертикальным, грудь и голову поднятыми. Поднимайся, толкаясь пятками, и повтори.\n\nКлючи: Гири на плечах смещают центр тяжести вперёд, поэтому держи торс строго вертикально, иначе завалишься. Колени веди в направлении носков, не своди внутрь. Пятки от пола не отрывай.",
            videoUrl: "https://www.youtube.com/results?search_query=Double%20Kettlebell%20Front%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Грудинные подтягивания Жиронды",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Возьмись за перекладину обратным хватом на ширине плеч. Повисни на полностью прямых руках, выпяти грудь и отклонись назад - в этом наклоне ты останешься на всё движение.\n\nДвижение: На выдохе тянись к перекладине, прогибая спину и отводя голову назад. Поднимайся, пока ключица не пройдёт гриф и нижняя часть груди не коснётся его. В верхней точке таз и ноги под углом около 45 градусов к полу.\n\nКлючи: Тянись грудью, а не подбородком - в этом суть, акцент идёт на низ широчайших и грудной отдел. Прогиб держи активно, опускайся на вдохе медленно. Движение мощное, не дёргай рывком.",
            videoUrl: "https://www.youtube.com/results?search_query=Gironda%20Sternum%20Chin-Up%20technique"
        ),
        LibraryExercise(
            name: "Подтягивания с подъёмом коленей",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Повисни на перекладине обратным хватом чуть шире плеч. Согни колени на 90 градусов так, чтобы голени были параллельны полу, а бёдра перпендикулярны ему.\n\nДвижение: На выдохе одновременно подтягивайся вверх и подтягивай колени к груди. Останавливайся, когда нос окажется на уровне перекладины и колени дойдут до груди. На вдохе медленно вернись в вис.\n\nКлючи: Это гибрид подтягивания и скручивания - синхронизируй движение рук и ног, чтобы пик пришёлся одновременно. Работают и спина, и пресс. Не раскачивайся, опускайся под контролем.",
            videoUrl: "https://www.youtube.com/results?search_query=Gorilla%20Chin/Crunch%20technique"
        ),
        LibraryExercise(
            name: "Жим гантелей нейтральным хватом на наклонной",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: Ляг на наклонную скамью, гантели на бёдрах ладонями друг к другу. Закинь их к плечам по одной, помогая бёдрами. Локти разведи в стороны на уровне плеч, угол в локте 90 градусов, ладони смотрят друг на друга.\n\nДвижение: На вдохе медленно опускай гантели к бокам, полностью контролируя вес. На выдохе выжимай их вверх грудными, фиксируй вверху на секунду и снова плавно опускай.\n\nКлючи: Нейтральный хват бережёт плечи и смещает акцент на верх груди. Опускай вдвое медленнее, чем жмёшь. После сета опусти гантели на бёдра, а потом на пол - так безопаснее.",
            videoUrl: "https://www.youtube.com/results?search_query=Hammer%20Grip%20Incline%20Dumbbell%20Press%20technique"
        ),
        LibraryExercise(
            name: "Растяжка задней поверхности бедра с ремнём",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, подними одну ногу вверх так, чтобы бедро было под углом 90 градусов к полу. Вторая нога лежит прямо на полу. Накинь ремень или ленту на стопу поднятой ноги.\n\nДвижение: Тяни ремень на себя, создавая натяжение в задней поверхности бедра и икре. Держи положение 10-30 секунд, дыша ровно, затем поменяй ногу.\n\nКлючи: Ногу держи прямой, тянись до приятного натяжения, а не до боли. Поясницу и таз прижимай к полу, не отрывай. Расслабляйся на выдохе, мышца уступает мягче, когда не зажата.",
            videoUrl: "https://www.youtube.com/results?search_query=Strap%20Hamstring%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Взятие на грудь с виса",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Хват чуть шире плеч, штанга висит у середины бедра. Спина прямая, корпус слегка наклонён вперёд, плечи над грифом.\n\nДвижение: Резко разгибайся в бёдрах, коленях и голеностопе, выталкивая штангу вверх, и одновременно пожми плечами. Быстро уйди под гриф и прими штангу на грудь, удерживая локти высоко.\n\nКлючи: Толчок идёт от ног и бёдер, а не от рук. Не тяни штангу бицепсом - сначала разгон телом, потом подсед. Держи гриф близко к корпусу, спину - прямой.",
            videoUrl: "https://www.youtube.com/results?search_query=Hang%20Clean%20technique"
        ),
        LibraryExercise(
            name: "Рывок с виса",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Широкий хват сверху, стопы под бёдрами, носки слегка развёрнуты. Колени чуть согнуты, корпус наклонён вперёд, спина прямая, штанга у бёдер.\n\nДвижение: Мощно разогнись ногами и бёдрами, на пике пожми плечами и подведи локти. Резко уйди под штангу и прими её над головой на прямых руках, садясь как можно ниже, затем встань.\n\nКлючи: Это одно слитное движение, а не два рывка. Держи штангу близко к телу, разгон - телом, а не руками. Опускай вес под контролем, не роняй.",
            videoUrl: "https://www.youtube.com/results?search_query=Hang%20Snatch%20technique"
        ),
        LibraryExercise(
            name: "Сгибания на бицепс на верхних блоках",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Встань между двумя верхними блоками, в каждой руке по рукоятке. Плечи параллельны полу, ладони смотрят на тебя - это исходное положение.\n\nДвижение: Сгибай руки, подтягивая рукоятки к ушам, на усилии выдох. Локти и плечи неподвижны - работают только предплечья. В верхней точке на секунду сожми бицепс.\n\nКлючи: Не двигай локтями вперёд-назад, иначе нагрузка уходит с бицепса. Опускай вес медленно, чувствуя растяжение. Фокус на пиковом сокращении, а не на весе.",
            videoUrl: "https://www.youtube.com/results?search_query=High%20Cable%20Curls%20technique"
        ),
        LibraryExercise(
            name: "Растяжка ИТ-тракта и ягодиц",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, накинь ремень или резину на стопу одной ноги. Проведи прямую ногу через тело в противоположную сторону - это исходное положение.\n\nДвижение: Не опуская стопу на пол, мягко тяни ремень, разворачивая носок вверх и усиливая растяжение по внешней стороне бедра и ягодице. Держи 10-20 секунд, потом повтори на другую ногу.\n\nКлючи: Тяни плавно, без рывков и боли. Дыши спокойно, не задерживай дыхание. Ногу держи прямой - именно так растягивается ИТ-тракт.",
            videoUrl: "https://www.youtube.com/results?search_query=IT%20Band%20and%20Glute%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Французский жим на наклонной скамье",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Ляг на наклонную скамью (45-75°), возьми штангу хватом сверху чуть уже плеч. Выпрями руки и заведи гриф за голову, плечи на линии с корпусом - исходное положение.\n\nДвижение: На вдохе опускай штангу по дуге за голову, пока предплечья не коснутся бицепсов. На выдохе разгибай руки и в верхней точке на секунду сожми трицепс.\n\nКлючи: Двигаются только предплечья - плечи держи неподвижно и близко к голове. Не бросай вес за голову, контролируй амплитуду, береги локти.",
            videoUrl: "https://www.youtube.com/results?search_query=Incline%20Barbell%20Triceps%20Extension%20technique"
        ),
        LibraryExercise(
            name: "Жим в кроссовере на наклонной сидя",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: Сядь, возьми рукоятки. Плечи под углом около 45° к корпусу, локти согнуты примерно на 90°, грудь и голова подняты - это исходное положение.\n\nДвижение: Разгибай руки и своди рукоятки вместе прямо перед собой. Лопатки держи сведёнными на протяжении всего движения. В крайней точке короткая пауза, потом возврат.\n\nКлючи: Веди рукоятки навстречу друг другу, а не просто вперёд - так лучше включается грудь. Не теряй натяжение тросов в нижней точке. Спина прижата, плечи не задирай.",
            videoUrl: "https://www.youtube.com/results?search_query=Incline%20Cable%20Chest%20Press%20technique"
        ),
        LibraryExercise(
            name: "Сведения в кроссовере на наклонной скамье",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: Поставь скамью под 45° между блоками, поставленными в самый низ. Возьми по рукоятке в каждую руку, ляг и сведи руки над собой почти прямыми - исходное положение.\n\nДвижение: На вдохе разводи руки в стороны широкой дугой с лёгким сгибом в локтях, пока не почувствуешь растяжение груди. На выдохе своди руки обратно, сжимая грудь, и задержись на секунду.\n\nКлючи: Локти зафиксированы, движение идёт только в плечевом суставе - это не жим. Не разгибай руки полностью внизу, чтобы не грузить бицепс. Возвращай по той же дуге.",
            videoUrl: "https://www.youtube.com/results?search_query=Incline%20Cable%20Flye%20technique"
        ),
        LibraryExercise(
            name: "Молотковые сгибания на наклонной скамье",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Сядь на наклонную скамью, спина плотно прижата, в каждой руке гантель. Опусти руки вдоль тела нейтральным хватом, ладони смотрят друг на друга - это исходное положение.\n\nДвижение: Сгибай руку в локте, поднимая гантель вверх и удерживая плечо неподвижным. В верхней точке короткая пауза, затем медленно опусти обратно.\n\nКлючи: Наклон скамьи растягивает бицепс сильнее - не подключай плечи и не раскачивайся. Нейтральный хват грузит брахиалис и предплечья. Опускай под контролем.",
            videoUrl: "https://www.youtube.com/results?search_query=Incline%20Hammer%20Curls%20technique"
        ),
        LibraryExercise(
            name: "Отжимания от возвышения",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Старт: Встань лицом к скамье или устойчивому возвышению. Поставь руки на край чуть шире плеч, отойди ногами назад так, чтобы тело вытянулось в прямую линию.\n\nДвижение: Сгибая руки, опускай грудь к краю опоры, держа тело прямым. Затем выжимай себя вверх, пока руки не выпрямятся.\n\nКлючи: Чем выше опора, тем легче - удобный вариант для новичков. Держи корпус напряжённым, не проваливай поясницу. На опускании вдох, на жиме выдох.",
            videoUrl: "https://www.youtube.com/results?search_query=Incline%20Push-Up%20technique"
        ),
        LibraryExercise(
            name: "Растяжка паха лёжа",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Ляг на спину с прямыми ногами, накинь ремень или резину на стопу одной ноги. Отведи эту ногу в сторону так далеко, как можешь - это исходное положение.\n\nДвижение: Мягко тяни ремень, создавая натяжение в паху и задней поверхности бедра. Держи 10-20 секунд, затем повтори на другую ногу.\n\nКлючи: Растягивай плавно, без рывков, до лёгкого дискомфорта, а не до боли. Дыши спокойно и расслабляй мышцу на выдохе. Ногу держи прямой.",
            videoUrl: "https://www.youtube.com/results?search_query=Intermediate%20Groin%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Растяжка квадрицепса и сгибателей бедра",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Ляг на живот, накинь ремень, верёвку или резину на стопу одной ноги.\n\nДвижение: Согни колено и отведи бедро назад, подтягивая ремень обеими руками. Колено и бедро должны оторваться от пола, создавая натяжение в передней поверхности бедра и сгибателях. Держи 10-20 секунд, потом смени ногу.\n\nКлючи: Не выгибай поясницу - удлинение идёт за счёт бедра, а не прогиба спины. Тяни плавно, дыши ровно. Хорошо раскрывает бёдра после долгого сидения.",
            videoUrl: "https://www.youtube.com/results?search_query=Intermediate%20Hip%20Flexor%20and%20Quad%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Внутренняя ротация плеча с резиной",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Закрепи резину на стойке на высоте локтя. Встань правым боком к опоре в паре шагов, возьми конец резины правой рукой и плотно прижми локоть к боку (можно подложить валик).\n\nДвижение: При локте, согнутом на 90°, и кисти, отведённой от корпуса, вращай предплечьем внутрь к животу, удерживая локоть на месте. Дойди до предела, пауза, затем медленно вернись.\n\nКлючи: Локоть не должен отходить от тела - иначе работа уходит с ротаторной манжеты. Двигайся плавно и без рывков, вес лёгкий. Отлично для здоровья плеча.",
            videoUrl: "https://www.youtube.com/results?search_query=Internal%20Rotation%20with%20Band%20technique"
        ),
        LibraryExercise(
            name: "Скрутка ног лёжа (Железный крест)",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Ляг на живот, руки разведи в стороны, ладони прижаты к полу - это исходное положение.\n\nДвижение: Согни одно колено и заведи ногу через спину, стараясь коснуться пола у противоположной руки. Сразу верни ногу назад и тут же повтори другой ногой. Чередуй 10-20 повторений.\n\nКлючи: Это динамическая растяжка - двигайся ритмично, но контролируемо. Держи плечи и грудь прижатыми к полу, скручивай поясницу мягко. Хорошо разогревает бёдра и спину.",
            videoUrl: "https://www.youtube.com/results?search_query=Iron%20Crosses%20%28stretch%29%20technique"
        ),
        LibraryExercise(
            name: "Изометрия шеи вперёд-назад",
            category: .core,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: Голова и шея в нейтральном положении, взгляд прямо. Положи обе ладони на лоб.\n\nДвижение: Мягко дави головой вперёд, напрягая мышцы шеи, но руками не давай ей сдвинуться. Начинай с лёгкого усилия и плавно наращивай, дыши ровно. Удержи нужное число секунд, затем медленно отпусти.\n\nКлючи: Голова остаётся неподвижной - это статика, без рывков. После отдыха повтори, переложив ладони на затылок. Не задерживай дыхание и не дави резко.",
            videoUrl: "https://www.youtube.com/results?search_query=Isometric%20Neck%20Exercise%20-%20Front%20And%20Back%20technique"
        ),
        LibraryExercise(
            name: "Приседания Джефферсона",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Положи штангу на пол и встань над ней так, чтобы гриф проходил между ног. Присядь с прямой спиной и возьми гриф нейтральным хватом: одна рука спереди, другая сзади, корпус ровно посередине. Встань с весом, стопы на ширине плеч, носки слегка наружу.\n\nДвижение: На вдохе приседай, сгибая колени и держа спину прямой, пока бёдра не дойдут до параллели. На выдохе вставай, отталкиваясь ногами.\n\nКлючи: Руки - только крючки, груз держат ноги, не тяни вес руками. Колени не выводи за носки, спину держи вертикально. Чередуй положение рук между подходами для симметрии.",
            videoUrl: "https://www.youtube.com/results?search_query=Jefferson%20Squats%20technique"
        ),
        LibraryExercise(
            name: "Жим Арнольда с гирей",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Закинь гирю на плечо коротким взятием, разгибая ноги и таз. Ладонь смотрит на тебя, локоть прижат.\n\nДвижение: Смотри прямо перед собой и выжимай гирю вверх над головой, по ходу разворачивая запястье - в верхней точке ладонь повёрнута вперёд. Опусти обратно, возвращая ладонь к себе.\n\nКлючи: Вращение начинай плавно, а не рывком - так дельта работает в полной амплитуде. Не заваливай корпус назад, держи пресс в тонусе. Выдох на жиме, вдох на опускании.",
            videoUrl: "https://www.youtube.com/results?search_query=Kettlebell%20Arnold%20Press%20technique"
        ),
        LibraryExercise(
            name: "Взятие гири с пола (Dead Clean)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Поставь гирю между стоп, отведи таз назад и держи взгляд прямо. Спина прямая, грудь раскрыта.\n\nДвижение: Резко разгибая ноги и таз, выведи гирю к плечу. По ходу разверни запястье, чтобы гиря мягко легла на предплечье. Опусти вниз, сохраняя натяжение в задней поверхности бедра.\n\nКлючи: Каждый повтор стартует с пола из мёртвой точки - без раскачки и маха. Не тяни гирю руками, работает таз. Запястье подворачивай вовремя, иначе гиря бьёт по предплечью.",
            videoUrl: "https://www.youtube.com/results?search_query=Kettlebell%20Dead%20Clean%20technique"
        ),
        LibraryExercise(
            name: "Восьмёрка с гирей",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Поставь гирю между ног, стопы шире плеч. Наклонись, отводя таз назад, спина плоская, грудь вперёд.\n\nДвижение: Возьми гирю одной рукой и проведи её между ног назад, перехватывая другой рукой сзади бёдер. Дальше веди её вперёд и снова между ног - получается плавная восьмёрка.\n\nКлючи: Спина всё время прямая, движение идёт от таза, а не от поясницы. Не выпрямляйся слишком рано, держи лёгкий наклон. Смотри вперёд, перехваты делай уверенно, чтобы не уронить гирю.",
            videoUrl: "https://www.youtube.com/results?search_query=Kettlebell%20Figure%208%20technique"
        ),
        LibraryExercise(
            name: "Жим гири сидя на полу",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Сядь на пол, разведи ноги в удобную ширину. Закинь гирю на плечо коротким взятием, ладонь смотрит внутрь.\n\nДвижение: Выжимай гирю вверх и чуть наружу, пока рука полностью не выпрямится над головой. Опусти обратно к плечу под контролем.\n\nКлючи: Сидя на полу читинг корпусом отключён - жмёт только плечо, это и есть суть упражнения. Держи пресс и спину прямыми, не заваливайся назад. Не задерживай дыхание: выдох вверх, вдох вниз.",
            videoUrl: "https://www.youtube.com/results?search_query=Kettlebell%20Seated%20Press%20technique"
        ),
        LibraryExercise(
            name: "Попеременный жим гирь (Качели)",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Закинь две гири на плечи. Ладони смотрят внутрь, локти прижаты, корпус собран.\n\nДвижение: Выжми одну гирю вверх до полного выпрямления руки. Опуская её, тут же начинай жать вторую - руки двигаются навстречу, как качели. Чередуй без пауз.\n\nКлючи: Делай поровну повторов на обе стороны, иначе перекосишь нагрузку. Держи пресс жёстким - так корпус не гуляет под разнонаправленным весом. Не разгоняйся ногами, жми чисто плечами.",
            videoUrl: "https://www.youtube.com/results?search_query=Kettlebell%20Seesaw%20Press%20technique"
        ),
        LibraryExercise(
            name: "Сумо-тяга гири к подбородку",
            category: .complex,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: Поставь гирю между стоп, ноги шире плеч в стойке сумо. Возьми гирю двумя руками, таз уведи назад, колени согнуты, грудь и голова вверх.\n\nДвижение: Мощно разгибай таз и колени и одновременно тяни гирю к плечам, поднимая локти выше кистей. Верни гирю вниз обратным движением.\n\nКлючи: Тяга идёт за счёт разгона тазом, а не только руками - это придаёт мощность. Локти всегда выше кистей, иначе нагрузка уходит из трапеций. Спину держи прямой, не округляй поясницу.",
            videoUrl: "https://www.youtube.com/results?search_query=Kettlebell%20Sumo%20High%20Pull%20technique"
        ),
        LibraryExercise(
            name: "Мельница с гирей",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Закинь гирю на плечо и выжми над головой противоположной рукой, развернув ладонь вперёд. Рука прямая, гиря зафиксирована вверху.\n\nДвижение: Разверни стопы на 45° от поднятой руки, уведи таз в сторону гири. Сгибаясь в тазобедренном, медленно наклоняйся вбок, пока свободная рука не коснётся пола. Задержись на секунду и вернись обратно.\n\nКлючи: Глаз не своди с гири над головой - так контролируешь баланс и плечо. Сгибайся в тазу, а не в пояснице. Локоть верхней руки держи замкнутым на протяжении всего движения.",
            videoUrl: "https://www.youtube.com/results?search_query=Kettlebell%20Windmill%20technique"
        ),
        LibraryExercise(
            name: "Растяжка ягодиц лёжа (колено через тело)",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, правую ногу вытяни прямо. Согни левую ногу и опусти колено через тело вправо, придерживая его правой рукой к полу.\n\nДвижение: Левую руку положи свободно в сторону, голову поверни влево. Представь, что копчик тянет к полу, а грудь уходит в обратную сторону - так раскрывается поясница и ягодица. Подержи и поменяй стороны.\n\nКлючи: Колену не обязательно касаться пола, если тянет туго - не насилуй сустав. Не задерживай дыхание, на выдохе расслабляйся глубже. Плечи держи прижатыми к полу.",
            videoUrl: "https://www.youtube.com/results?search_query=Knee%20Across%20The%20Body%20technique"
        ),
        LibraryExercise(
            name: "Растяжка предплечий на коленях",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: Встань на колени на коврик, поставь ладони на пол пальцами назад - к коленям. Локти выпрямлены.\n\nДвижение: Медленно отклоняйся назад, не отрывая ладони от пола, пока не почувствуешь растяжение в запястьях и предплечьях. Задержись на 20-30 секунд.\n\nКлючи: Двигайся плавно, без рывков - связки запястья чувствительны к резкой нагрузке. Если тянет слишком сильно, уменьши наклон или приподними пальцы. Дыши ровно, на выдохе уходи чуть глубже.",
            videoUrl: "https://www.youtube.com/results?search_query=Kneeling%20Forearm%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Растяжка сгибателей бедра в выпаде",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Встань на коврик, выведи правое колено вперёд так, чтобы стопа стояла на полу, а левую ногу вытяни назад с опорой на верх стопы.\n\nДвижение: Плавно перенеси вес вперёд, пока не почувствуешь растяжение в передней части бедра и паху сзадистоящей ноги. Задержись на 15 секунд и поменяй сторону.\n\nКлючи: Таз слегка подкручивай вперёд - так растяжение идёт в сгибатель, а не в поясницу. Не заваливай переднее колено за носок. Держи корпус прямым, дыши спокойно.",
            videoUrl: "https://www.youtube.com/results?search_query=Kneeling%20Hip%20Flexor%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Выпрыгивание из положения на коленях",
            category: .complex,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Встань на колени, штангу положи на верх плеч (или работай с собственным весом). Удобно делать в силовой раме. Голова и грудь подняты.\n\nДвижение: Сядь тазом назад, пока ягодицы не коснутся пяток. Взрывным разгибанием таза выпрыгни вверх с такой силой, чтобы приземлиться стопами на пол. Дальше дожми присед через пятки и встань.\n\nКлючи: Вся мощь идёт из взрывного разгона тазом - без него на стопы не встанешь. Приземляйся на полную стопу мягко, гася удар коленями. Спину держи прямой, пресс жёстким на протяжении всего движения.",
            videoUrl: "https://www.youtube.com/results?search_query=Kneeling%20Jump%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Приседания на коленях со штангой",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Выставь штангу на нужной высоте в силовой раме. Встань на колени за грифом (подложи коврик под колени), заведи штангу на верх плеч. Лопатки сведи, гриф прижми к спине и сними со стоек.\n\nДвижение: Смотри вперёд и садись тазом назад, пока не коснёшься икр. Обратным движением вернись в вертикальное положение.\n\nКлючи: Это движение прицельно бьёт по ягодицам, потому что квадрицепс выключен - работай тазом. Не округляй поясницу в нижней точке. Сводя лопатки, держи гриф стабильно на спине.",
            videoUrl: "https://www.youtube.com/results?search_query=Kneeling%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Лэндмайн 180 (ротация)",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Закрепи гриф в лэндмайне или надёжно упри в угол, нагрузи рабочим весом. Подними гриф к высоте плеч обеими руками, руки вытянуты перед собой. Стойка широкая.\n\nДвижение: Поворачивая корпус и таз, проведи гриф по дуге вниз в одну сторону. Затем обратным движением переведи его в противоположную. Чередуй стороны до конца подхода.\n\nКлючи: Руки прямые на протяжении всего движения, иначе теряется дуга. Вращение идёт от таза и корпуса, ноги стабильны - так грузится кор, а не поясница. Двигайся под контролем, без рывков на развороте.",
            videoUrl: "https://www.youtube.com/results?search_query=Landmine%20180%27s%20technique"
        ),
        LibraryExercise(
            name: "Лэндмайн-джаммер",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Закрепи гриф в лэндмайне или надёжно упри в угол, нагрузи вес и поставь рукоятку. Подними гриф так, чтобы рукоятки оказались у плеч. Атлетичная стойка.\n\nДвижение: Присядь, сгибая колени и отводя таз назад, руки держи согнутыми. Мощно выпрямись через таз, колени и стопы, одновременно выталкивая руки вперёд до полного выпрямления. Делай взрывно. Вернись в исходное.\n\nКлючи: Это взрывное движение - выталкивай вес максимально резко, как джаммер-машина. Жми синхронно ногами и руками, иначе теряешь мощность. Кор держи жёстким, чтобы передать усилие в гриф.",
            videoUrl: "https://www.youtube.com/results?search_query=Landmine%20Linear%20Jammer%20technique"
        ),
        LibraryExercise(
            name: "Боковые запрыгивания на коробку",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: Встань в удобную стойку, невысокая коробка стоит сбоку от тебя. Это исходное положение.\n\nДвижение: Быстро уйди в четвертьприсед, чтобы запустить рефлекс растяжения, и тут же выпрыгни вверх и в сторону. Подними колени достаточно высоко, чтобы стопы чисто прошли над коробкой. Приземлись в центр, гася удар ногами. Аккуратно спрыгни на другую сторону и повторяй из стороны в сторону.\n\nКлючи: Связка приседа и прыжка должна быть быстрой - в этом вся плиометрика. Приземляйся мягко на полусогнутые ноги, не на прямые. Бери коробку по росту, чтобы не цеплять её стопами.",
            videoUrl: "https://www.youtube.com/results?search_query=Lateral%20Box%20Jump%20technique"
        ),
        LibraryExercise(
            name: "Махи в стороны с резиной",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Встань на середину ленты, чтобы уже на старте было натяжение. Возьми ручки нейтрально-прямым хватом чуть уже плеч, они лежат у бёдер, руки почти прямые с лёгким сгибом в локтях, спина ровная.\n\nДвижение: Силой средних дельт разведи руки в стороны на выдохе, чуть выше параллели с полом. На верхней точке слегка разверни кисти, будто выливаешь воду из стакана. Задержись на секунду и плавно опусти.\n\nКлючи: Корпус не раскачивай - работают только плечи. Не задирай руки выше за счёт трапеций, держи локти чуть выше кистей. Вес ленты подбирай так, чтобы последние повторы давались с усилием, но без рывка.",
            videoUrl: "https://www.youtube.com/results?search_query=Banded%20Lateral%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Жим гири с пола с переносом ноги",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Ляг на пол, гиря лежит на груди в одной руке, держишь за дужку. Ногу со стороны рабочей руки перекинь через другую ногу. Свободную руку отведи в сторону для опоры.\n\nДвижение: Выжми гирю вверх в прямую руку до полного выпрямления локтя. Затем медленно опусти, пока локоть не коснётся пола, удерживая гирю над локтем.\n\nКлючи: Запястье держи прямым, чтобы гиря не заваливалась назад. Пол ограничивает амплитуду и бережёт плечо - это плюс для тех, у кого плечи капризные. На жиме выдох, на опускании вдох.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Leg-Over%20Floor%20Press%20technique"
        ),
        LibraryExercise(
            name: "Растяжка задней поверхности бедра лёжа",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, одну ногу согни в колене и поставь стопу на пол - так стабилизируется поясница. Вторую ногу подними вверх.\n\nДвижение: Постарайся выпрямить поднятую ногу, чтобы подошва смотрела в потолок, насколько получится. Затем плавно тяни прямую ногу к лицу до приятного натяжения под бедром. Поменяй ноги.\n\nКлючи: Не дёргай и не пружинь - тянись медленно и держи. Если нога не выпрямляется до конца, это нормально, не насилуй колено. Дыши ровно, на выдохе чуть углубляй растяжку.",
            videoUrl: "https://www.youtube.com/results?search_query=Lying%20Leg-Up%20Hamstring%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Подтягивание коленей лёжа",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на коврик, ноги вытянуты, ладони лежат на полу рядом с тобой или под ягодицами для опоры. Это исходное положение.\n\nДвижение: Согни колени и подтяни бёдра к животу на выдохе, пока колени не окажутся примерно на уровне груди. Напряги пресс и задержись на секунду вверху, затем на вдохе вернись назад.\n\nКлючи: Голени держи параллельно полу на протяжении движения. Тяни ногами не по инерции, а за счёт пресса - чувствуй низ живота. Не бросай ноги вниз, опускай под контролем.",
            videoUrl: "https://www.youtube.com/results?search_query=Leg%20Pull-In%20technique"
        ),
        LibraryExercise(
            name: "Становая тяга в рычажном тренажере",
            category: .back,
            muscleGroup: .lowerBack,
            defaultType: .strength,
            technique: "Старт: Поставь нужный вес. Встань точно между рукоятями, возьмись за нижние ручки удобным хватом и опусти таз, делая вдох. Смотри вперёд, грудь раскрыта, спина прямая. Это исходное положение.\n\nДвижение: Толкнись ногами и разогни таз, выпрямляясь в полный рост. Затем подконтрольно опусти вес обратно в исходное.\n\nКлючи: Тяни не спиной, а ногами и тазом, держи поясницу нейтральной без округления. Тренажёр задаёт траекторию, поэтому проще держать технику - но не расслабляй корпус. На усилии выдох.",
            videoUrl: "https://www.youtube.com/results?search_query=Leverage%20Deadlift%20technique"
        ),
        LibraryExercise(
            name: "Жим в Хаммере на наклоне вниз",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Старт: Поставь вес и отрегулируй сиденье под свой рост так, чтобы рукояти были на уровне низа груди. Грудь и голова подняты, лопатки сведены. Это исходное положение.\n\nДвижение: Выжми рукояти вперёд, разгибая локти. После короткой паузы вверху верни вес чуть выше старта, не доводя до упоров.\n\nКлючи: Не возвращай вес на упоры до конца подхода - так мышцы остаются под нагрузкой. Лопатки держи сведёнными, не сводя плечи к ушам. Наклон вниз смещает акцент на низ груди. Выдох на жиме.",
            videoUrl: "https://www.youtube.com/results?search_query=Leverage%20Decline%20Chest%20Press%20technique"
        ),
        LibraryExercise(
            name: "Жим в Хаммере на наклоне вверх",
            category: .chest,
            muscleGroup: .upperChest,
            defaultType: .strength,
            technique: "Старт: Поставь вес и подгони сиденье под рост так, чтобы рукояти были у верха груди. Грудь и голова подняты, лопатки сведены. Это исходное положение.\n\nДвижение: Выжми рукояти вперёд за счёт разгибания локтей. После короткой паузы вверху верни вес чуть выше старта, не опуская на упоры.\n\nКлючи: Держи нагрузку постоянной - не клади вес на упоры до конца подхода. Наклон вверх грузит верх груди и переднюю дельту. Не отрывай поясницу от спинки и не сводй плечи к ушам. Выдох на усилии.",
            videoUrl: "https://www.youtube.com/results?search_query=Leverage%20Incline%20Chest%20Press%20technique"
        ),
        LibraryExercise(
            name: "Прыжок в глубину",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: Поставь две тумбы или скамьи в паре шагов друг от друга. Встань на одну тумбу лицом ко второй платформе.\n\nДвижение: Спрыгни на пол между платформами, мягко принимая приземление со сгибанием коленей и таза. Тут же взорвись вверх, мощно разгибая таз, колени и стопы, и запрыгни на вторую платформу. Приземлись мягко, гася удар ногами.\n\nКлючи: Главное - минимальный контакт с полом: приземлился и сразу выпрыгнул, как пружина. Колени смотрят по носкам, не заваливаются внутрь. Начинай с низких тумб, мягкое приземление важнее высоты.",
            videoUrl: "https://www.youtube.com/results?search_query=Linear%20Depth%20Jump%20technique"
        ),
        LibraryExercise(
            name: "Подъем бревна над головой",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Встань перед бревном, возьмись за ручки. Из наклона начни взятие на грудь: тяни бревно как можно выше, прижимая к груди, и разгибай таз и колени, выводя его на грудь.\n\nДвижение: Отклони голову назад и сделай из груди полку под бревно. Подсядь, чуть согнув колени, и взрывным разгибанием придай бревну импульс вверх, дожимая руками над головой. На каждом повторе проводи голову вперёд под бревно, глядя прямо.\n\nКлючи: Это силовой снаряд, жёстких канонов нет - используй то, что эффективно для тебя. Держи корпус жёстким, спину не круглу под весом. Опускай бревно подконтрольно, а не роняй.",
            videoUrl: "https://www.youtube.com/results?search_query=Log%20Lift%20technique"
        ),
        LibraryExercise(
            name: "Тяга нижнего блока к шее",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: Сядь у нижнего блока с канатной рукоятью. Возьми концы каната хватом ладонями вниз, спина прямая, колени чуть согнуты. Корпус почти вертикальный, руки вытянуты вперёд. Это исходное положение.\n\nДвижение: Не двигая корпусом, подними локти и тяни канат к шее на выдохе, держа плечи параллельно полу. Доводи кисти почти до ушей, локти разведены в стороны. Задержись на секунду и на вдохе плавно вернись назад.\n\nКлючи: Упражнение для задних дельт - локти веди вверх и в стороны, а не назад вдоль тела. Корпус не раскачивай ни в одной фазе. Тяни плечами, а не бицепсом.",
            videoUrl: "https://www.youtube.com/results?search_query=Low%20Pulley%20Row%20to%20Neck%20technique"
        ),
        LibraryExercise(
            name: "Выпады с проносом гири",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Встань прямо, держа гирю в правой руке. Это исходное положение.\n\nДвижение: Шагни вперёд левой ногой и опустись в выпад, сгибая таз и колено, корпус держи вертикально. Заднее колено опусти почти до пола. В нижней точке пронеси гирю под передней ногой в другую руку. Оттолкнись пяткой передней ноги и вернись в стойку. Повторяй, чередуя ноги.\n\nКлючи: Колено передней ноги не выходит сильно за носок и не заваливается внутрь. Пронос гири держит корпус ровным и включает мышцы кора. Передавай гирю чётко, не теряя равновесия.",
            videoUrl: "https://www.youtube.com/results?search_query=Lunge%20Pass-Through%20technique"
        ),
        LibraryExercise(
            name: "Сгибания на бицепс лёжа на блоке",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Возьми прямую или EZ-рукоять нижнего блока обратным хватом на ширине плеч. Ляг на спину на коврик перед стойкой блока, стопы упри в раму, ноги прямые. Руки вытянуты, локти прижаты к телу, чуть согнуты. Это исходное положение.\n\nДвижение: Держа плечи неподвижными и локти у корпуса, медленно сгибай руки, поднимая рукоять к груди на выдохе и сжимая бицепс. Задержись на секунду в верхней точке и плавно опусти назад.\n\nКлючи: Локти не уходят вперёд и не отрываются от корпуса - работает только предплечье. Трос держит нагрузку постоянной по всей амплитуде, без мёртвой точки. Опускай медленно, не бросай вес.",
            videoUrl: "https://www.youtube.com/results?search_query=Lying%20Cable%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Тяга штанги лёжа на скамье",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Положи изогнутый гриф под скамью. Ляг на скамью лицом вниз и возьмись за гриф хватом ладонями вниз шире плеч. Это исходное положение.\n\nДвижение: На выдохе тяни гриф вверх, держа локти близко к телу: к груди - чтобы нагрузить верх и середину спины, или к животу - если цель широчайшие. Задержись на секунду вверху и медленно опусти на вдохе.\n\nКлючи: Тяга лёжа убирает читинг корпусом, поэтому работают только мышцы спины - честный вес. Своди лопатки, тяни локтями, а не кистями. Не бросай гриф вниз, контролируй опускание.",
            videoUrl: "https://www.youtube.com/results?search_query=Lying%20Cambered%20Barbell%20Row%20technique"
        ),
        LibraryExercise(
            name: "Французский жим гантелей лёжа",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Ляг на горизонтальную скамью, держа две гантели прямо над собой. Руки выпрямлены под прямым углом к корпусу и полу, ладони смотрят друг на друга, локти сведены. Это исходное положение.\n\nДвижение: На вдохе, держа плечи неподвижными и локти сведёнными, медленно опусти гантели к ушам. Затем, удерживая локти на месте, силой трицепса выжми вес обратно вверх на выдохе.\n\nКлючи: Двигается только предплечье - плечи фиксированы, локти не разъезжаются в стороны. Опускай к ушам, а не на лоб - так больше растяжение трицепса. Локти не разводи, иначе нагрузка уходит.",
            videoUrl: "https://www.youtube.com/results?search_query=Lying%20Dumbbell%20Triceps%20Extension%20technique"
        ),
        LibraryExercise(
            name: "Махи на задние дельты лёжа на скамье",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: Ляг грудью на горизонтальную скамью с гантелями в руках. Ладони смотрят друг на друга (нейтральный хват), руки вытянуты вниз с лёгким сгибом в локтях. Это исходное положение.\n\nДвижение: На выдохе разведи руки в стороны, пока локти не окажутся на уровне плеч, а руки примерно параллельно полу. Держи руки перпендикулярно корпусу и вытянутыми, задержись на секунду в верхней точке. На вдохе плавно опусти.\n\nКлючи: Работают задние дельты - не тяни лопатками и не сгибай локти сильнее по ходу. Вес небольшой, движение чистое, без рывков и раскачки. Контролируй негатив, не роняй гантели.",
            videoUrl: "https://www.youtube.com/results?search_query=Lying%20Rear%20Delt%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Сгибания на бицепс гантелей лёжа",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Ляг на горизонтальную скамью лицом вверх, руки с гантелями свободно опусти по бокам вниз к полу, ладони смотрят к бёдрам. Локти прижми к корпусу - это исходное положение.\n\nДвижение: На выдохе плавно сгибай руки, одновременно разворачивая кисти ладонями вверх. Дойди до полного сокращения бицепса и задержи на секунду. На вдохе очень медленно опусти вес.\n\nКлючи: Работают только предплечья, плечи и локти стоят на месте - не раскачивайся. Из-за положения лёжа бицепс растягивается сильнее, чем стоя, поэтому вес бери поменьше и контролируй негатив.",
            videoUrl: "https://www.youtube.com/results?search_query=Lying%20Supine%20Dumbbell%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Тяга Т-грифа лёжа в тренажере",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Загрузи тренажёр и настрой упор так, чтобы верх груди был у края подушки. Ляг лицом вниз, возьми рукоятки удобным хватом, сними гриф со стоек и выпрями руки - это старт.\n\nДвижение: На выдохе тяни вес вверх, сводя лопатки, и задержи сокращение на секунду в верхней точке. На вдохе медленно опусти в исходное.\n\nКлючи: Держи локти близко к корпусу - так включается спина, а не бицепс. Не отрывай грудь от подушки и не дёргай весом, иначе теряешь нагрузку с целевых мышц.",
            videoUrl: "https://www.youtube.com/results?search_query=Lying%20T-Bar%20Row%20technique"
        ),
        LibraryExercise(
            name: "Сгибания на бицепс в тренажере Скотта",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Сядь в тренажёр Скотта, выстави вес. Положи задней стороной плеч на подушку, возьми рукоятки обратным хватом ладонями вверх, локти держи внутрь - это исходное положение.\n\nДвижение: На выдохе поднимай рукоятки, сокращая бицепс, и задержи сокращение на секунду в верхней точке. На вдохе медленно опусти в старт.\n\nКлючи: Двигаются только предплечья - плечи всё время лежат на подушке, не отрывай их. Подушка убирает читинг, поэтому фокус на медленном опускании и полной амплитуде, не бросай вес вниз.",
            videoUrl: "https://www.youtube.com/results?search_query=Machine%20Preacher%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Бросок мяча от груди",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Встань лицом к партнёру или к стене, держи набивной мяч у корпуса обеими руками. Стопы на ширине плеч, корпус собран.\n\nДвижение: Притяни мяч к груди, затем резко вытолкни его вперёд, полностью разгибая руки в локтях. Для спортивной версии можешь делать шаг в момент броска. Поймай ответный мяч на уровне груди обеими руками.\n\nКлючи: Толчок идёт от груди и трицепсов, а не только от рук - вкладывайся всем корпусом. Лови мяч мягко, гася движение, чтобы не отбить кисти. Работай взрывно, но контролируй приём.",
            videoUrl: "https://www.youtube.com/results?search_query=Medicine%20Ball%20Chest%20Pass%20technique"
        ),
        LibraryExercise(
            name: "Бросок мяча снизу-назад",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Прими положение полуприседа с набивным мячом в руках, руки опущены так, чтобы мяч был у самых стоп. Спина прямая.\n\nДвижение: Резко выталкивай таз вперёд, разгибаясь в ногах и подпрыгивая вверх. Одновременно махом веди прямые руки вверх и за голову, отпуская мяч в верхней точке. Цель - бросить мяч как можно дальше назад.\n\nКлючи: Сила идёт от ног и таза, руки только направляют мяч - не тяни его одними плечами. Делай движение единым взрывом, без паузы внизу. Следи, чтобы рядом не было людей в зоне броска.",
            videoUrl: "https://www.youtube.com/results?search_query=Medicine%20Ball%20Scoop%20Throw%20technique"
        ),
        LibraryExercise(
            name: "Сведение лопаток лёжа на наклонной",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: Ляг лицом вниз на наклонную скамью с гантелями в руках. Руки полностью выпрямлены и свисают вниз к полу, ладони смотрят друг на друга - это исходное положение.\n\nДвижение: На выдохе сведи лопатки вместе и задержи сокращение на полную секунду. Это похоже на обратное движение от объятий. На вдохе вернись в старт.\n\nКлючи: Работают именно лопатки и середина спины, руки остаются прямыми - не сгибай локти и не превращай в тягу. Движение короткое, поэтому делай его подчёркнуто медленно и чувствуй сведение.",
            videoUrl: "https://www.youtube.com/results?search_query=Middle%20Back%20Shrug%20technique"
        ),
        LibraryExercise(
            name: "Подтягивания разнохватом",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Возьмись за перекладину чуть шире плеч так, чтобы одна ладонь смотрела вперёд, а другая на тебя. Повисни на прямых руках - это исходное положение.\n\nДвижение: На выдохе подтягивайся вверх, пока подбородок не окажется над перекладиной, и задержись на секунду. На вдохе медленно опустись в вис.\n\nКлючи: Со стороны ладони к себе фокусируйся на бицепсе и держи локоть у корпуса, со стороны ладони от себя тяни широчайшими. На следующем подходе обязательно меняй хват местами, чтобы нагрузка была симметричной.",
            videoUrl: "https://www.youtube.com/results?search_query=Mixed%20Grip%20Chin-Up%20technique"
        ),
        LibraryExercise(
            name: "Ходьба монстра с резиной",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Надень одну резину на лодыжки, вторую на колени. Натяжение подбери так, чтобы резины были тугими, когда стопы на ширине плеч. Чуть присядь, таз отведи назад.\n\nДвижение: Делай короткие шаги вперёд, попеременно левой и правой ногой, сохраняя натяжение резины. Пройдя несколько шагов, так же иди назад к старту.\n\nКлючи: Колени держи разведёнными наружу, не давай им заваливаться внутрь - в этом весь смысл для ягодиц. Шаги мелкие и контролируемые, корпус слегка наклонён, спина ровная. Тянет средняя ягодичная - не спеши.",
            videoUrl: "https://www.youtube.com/results?search_query=Monster%20Walk%20technique"
        ),
        LibraryExercise(
            name: "Мускульный рывок",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Возьми штангу широким рывковым хватом, гриф у середины бедра. Стопы под тазом, носки слегка развёрнуты, грудь вверх, взгляд вперёд, плечи чуть впереди грифа.\n\nДвижение: Начни тягу, проталкиваясь через переднюю часть пяток, затем мощно разгибайся в тазу, коленях и голеностопе, разгоняя гриф вверх вдоль тела. Продолжай вести штангу до положения над головой, не подсаживаясь под неё.\n\nКлючи: Это рывок без ухода в сед, поэтому всё решает мощный разгон тазом. Гриф ведёшь близко к телу, руки включаются в самом конце. Не сгибай колени повторно при выходе наверх.",
            videoUrl: "https://www.youtube.com/results?search_query=Muscle%20Snatch%20technique"
        ),
        LibraryExercise(
            name: "Косые скручивания",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на пол, прижав поясницу к полу. Одну руку положи у головы, другую вытяни в сторону на полу. Стопы подними и поставь на возвышение.\n\nДвижение: Поднимай то плечо, у которого рука лежит у головы, скручиваясь по диагонали к противоположному колену, пока локоть не коснётся его. На вдохе опустись в исходное. Сделай нужные повторы и поменяй сторону.\n\nКлючи: Тяни корпус косыми мышцами живота, а не рукой за голову - шею не дёргай. Выдыхай в момент подъёма, вдыхай при опускании. Движение короткое и подчёркнуто плавное.",
            videoUrl: "https://www.youtube.com/results?search_query=Oblique%20Crunch%20technique"
        ),
        LibraryExercise(
            name: "Растяжка квадрицепса лёжа",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Ляг на скамью или степ так, чтобы одна нога и рука свисали с края. Поясницу не прогибай.\n\nДвижение: Согни свисающее колено и возьмись рукой за подъём стопы. Подтяни пупок к позвоночнику, чтобы остаться в нейтрали, и слегка надави стопой в ладонь. Чтобы добавить растяжку бедра, подними таз этой ноги к потолку. Поменяй сторону.\n\nКлючи: Тянуться должно по передней поверхности бедра, без боли в колене. Не выгибай поясницу - именно нейтральный таз делает растяжку безопасной. Дыши ровно и не тяни рывками.",
            videoUrl: "https://www.youtube.com/results?search_query=Lying%20Quad%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Боковые наклоны на верхнем блоке",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Поставь рукоятку на верхний блок. Встань боком к тренажёру, возьмись за рукоятку обратным хватом и подтяни её к плечу, пока локоть не упрётся в бок. Стопы на ширине таза, свободную руку положи на бедро.\n\nДвижение: Держа руку с рукояткой неподвижно, сокращай косые и наклоняйся в сторону, опуская вес. В нижней точке медленно верни вес обратно. Сделай нужные повторы и поменяй сторону.\n\nКлючи: Работают именно косые мышцы, рука лишь фиксирует рукоятку - не тяни плечом. Держи постоянное натяжение, не давай блоку лечь на упор между повторами. Наклон чёткий, без раскачки корпуса.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20High-Pulley%20Cable%20Side%20Bend%20technique"
        ),
        LibraryExercise(
            name: "Махи в стороны лёжа на наклонной",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Ляг боком на наклонную скамью, прижавшись плечом к спинке, гантель в верхней руке. Нижняя рука лежит поперёк тела, ладонь у живота, верхняя рука с гантелью выпрямлена перед собой параллельно полу - это старт.\n\nДвижение: На выдохе поднимай прямую руку точно вверх, пока она не укажет в потолок, держа гантель параллельно полу. Задержись на секунду, чувствуя дельту. На вдохе опусти вес поперёк тела в исходное. Поменяй сторону.\n\nКлючи: Изолируется средняя дельта, поэтому вес небольшой и без рывков. Не доворачивай кисть и не помогай корпусом - наклон убирает читинг, в этом и смысл. Веди руку строго в одной плоскости.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Incline%20Lateral%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Взятие гири на грудь одной рукой",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Поставь гирю между стоп. Наклонись за ней, отводя таз назад и держа взгляд вперёд, спина прямая. Возьмись за ручку одной рукой.\n\nДвижение: Взрывным разгибанием ног и таза разгони гирю вверх к плечу, одновременно проворачивая кисть, чтобы гиря мягко легла на предплечье в стойке у плеча. Контролируемо верни её вниз в исходное.\n\nКлючи: Сила идёт от ног и таза, а не от руки - это не подъём бицепсом. В верхней точке не давай гире бить по запястью, провернув кисть и пропустив руку внутрь. Держи спину прямой на протяжении всего движения.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Kettlebell%20Clean%20technique"
        ),
        LibraryExercise(
            name: "Толчок гири одной рукой",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Возьми гирю за ручку одной рукой. Взятием на грудь разгони её к плечу разгибанием ног и таза, провернув кисть ладонью вперёд, и зафиксируй в стойке у плеча.\n\nДвижение: Слегка подсядь, сгибая колени с прямым корпусом, затем резко оттолкнись пятками, как бы выпрыгивая, и выжми гирю над головой на прямую руку. Прими вес наверху, уйдя в небольшой присед под него, выпрямись. Опусти гирю на пол для следующего повтора.\n\nКлючи: Толчок идёт за счёт импульса ног, рука лишь дожимает фиксацию - не выжимай одним плечом. Чётко лови момент подсёда и выхода, не теряя баланс. Над головой полностью выпрями руку и зафиксируй гирю.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Kettlebell%20Clean%20and%20Jerk%20technique"
        ),
        LibraryExercise(
            name: "Жим гири с пола одной рукой",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Ляг на пол, гиря в одной руке, плечо лежит на полу, ладонь смотрит внутрь.\n\nДвижение: Выжми гирю строго вверх к потолку, разворачивая запястье. Плавно опусти обратно и повтори.\n\nКлючи: Пол ограничивает амплитуду и бережёт плечо - это плюс. Держи кор в тонусе, чтобы не заваливаться. Жми на выдохе, опускай на вдохе.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Kettlebell%20Floor%20Press%20technique"
        ),
        LibraryExercise(
            name: "Жим гири одной рукой",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Закинь гирю на плечо: подними через ноги и таз, развернув запястье так, чтобы ладонь смотрела вперёд. Локоть в сторону.\n\nДвижение: Выжми гирю вверх и наружу до полного выпрямления руки над головой. Контролируемо опусти обратно на плечо.\n\nКлючи: Напряги широчайшие, ягодицы и живот - это даёт устойчивость и силу. Не прогибай поясницу, тянись вверх макушкой.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Kettlebell%20Press%20technique"
        ),
        LibraryExercise(
            name: "Швунг гири одной рукой",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Закинь гирю на плечо через работу ног и таза, разверни запястье ладонью вперёд. Корпус прямой.\n\nДвижение: Сделай короткий подсед, сгибая колени и держа спину вертикально. Резко выпрямись через пятки, как в прыжке, и этим импульсом выжми гирю над головой до полного выпрямления руки.\n\nКлючи: Сила идёт от ног, рука только дожимает - не пытайся выжать одними плечами. Подсед короткий, без завала корпуса вперёд.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Kettlebell%20Push%20Press%20technique"
        ),
        LibraryExercise(
            name: "Тяга гири в наклоне одной рукой",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Поставь гирю перед стопами. Слегка согни колени, отведи таз назад и наклонись вперёд с прямой спиной. Возьмись за гирю одной рукой.\n\nДвижение: Тяни гирю к животу, сводя лопатку и сгибая локоть. Опусти контролируемо и повтори.\n\nКлючи: Тяни лопаткой, а не бицепсом - локоть идёт вдоль корпуса. Спина прямая всю амплитуду, не круглись. Не дёргай рывком.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Kettlebell%20Row%20technique"
        ),
        LibraryExercise(
            name: "Бросок мяча об пол одной рукой",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Встань в атлетическую стойку с разножкой стоп. Медбол в одной руке, на стороне задней ноги.\n\nДвижение: Замахнись, поднимая мяч над головой, и одновременно выпрямись через таз, колени и стопы. На пике резко сложись плечами, спиной и тазом и брось мяч изо всех сил в пол прямо перед собой. Поймай на отскоке.\n\nКлючи: Это взрывное движение - вкладывайся всем телом, не только рукой. Кор работает на сброс силы, дыши резко на броске.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Medicine%20Ball%20Slam%20technique"
        ),
        LibraryExercise(
            name: "Приседания с гирей над головой одной рукой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Закинь гирю на плечо через ноги и таз, разверни запястье и выжми её над головой до прямой руки. Это исходное положение.\n\nДвижение: Смотри прямо, гиря зафиксирована над головой. Сгибай колени и таз, опуская корпус между ног, держа голову и грудь поднятыми. Внизу пауза на секунду, затем встань через пятки.\n\nКлючи: Главная сложность - удержать гирю строго над плечом, не уводя руку вперёд. Кор и плечо в постоянном напряжении.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Overhead%20Kettlebell%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Сгибание на скамье Скотта одной рукой",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Возьми гантель в руку и положи плечо на пюпитр скамьи Скотта. Рука вытянута, гантель на уровне плеча.\n\nДвижение: На вдохе медленно опусти гантель, полностью растягивая бицепс. На выдохе согни руку, поднимая вес до полного сокращения у плеча. Задержи на секунду и повтори.\n\nКлючи: Не бросай вниз - именно нижняя фаза растягивает бицепс и даёт рост. Плечо плотно прижато к скамье, рывков нет.",
            videoUrl: "https://www.youtube.com/results?search_query=One-Arm%20Dumbbell%20Preacher%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Подтягивание колена к груди лёжа",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Ляг на спину на пол. Одну ногу вытяни прямо, второе колено подтяни к груди.\n\nДвижение: Возьмись руками под коленом, чтобы не давить на чашечку, и мягко тяни колено к лицу. Подержи, затем смени ногу.\n\nКлючи: Тяни под суставом, а не за саму чашечку. Растягивается ягодица и поясница согнутой ноги и сгибатель бедра прямой. Не дёргай, дыши ровно и расслабленно.",
            videoUrl: "https://www.youtube.com/results?search_query=Lying%20Knee-to-Chest%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Сгибания на бицепс в кроссовере над головой",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Поставь одинаковый вес с обеих сторон кроссовера, рукояти выше уровня плеч. Встань посередине, возьмись хватом снизу (ладони вверх). Руки полностью выпрямлены и параллельны полу, стопы на ширине плеч.\n\nДвижение: На выдохе медленно сгибай руки, пока предплечья почти не коснутся бицепсов. На вдохе верни предплечья назад. Движутся только предплечья.\n\nКлючи: Локти зафиксированы и не уходят - так весь акцент идёт в пик бицепса. Корпус неподвижен.",
            videoUrl: "https://www.youtube.com/results?search_query=Overhead%20Cable%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Бросок мяча об пол",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Возьми медбол обеими руками, стопы на ширине плеч.\n\nДвижение: Подними мяч над головой и полностью вытянись вверх, как в замахе. Затем резко смени направление и со всей силы швырни мяч в пол прямо перед собой. Поймай его на отскоке обеими руками и повтори.\n\nКлючи: Замах и бросок - единое взрывное движение, без паузы наверху. Сила идёт от кора и таза, выдыхай резко в момент броска. Спину не круглить при наклоне.",
            videoUrl: "https://www.youtube.com/results?search_query=Overhead%20Medicine%20Ball%20Slam%20technique"
        ),
        LibraryExercise(
            name: "Приседания со штангой над головой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Подними штангу на грудь широким хватом, затем выжми её над головой и заведи чуть за линию головы. Руки полностью выпрямлены, лопатки сведены, спина прямая, взгляд вперёд. Стопы шире плеч.\n\nДвижение: На вдохе медленно опускайся, сгибая колени, пока бёдра не станут параллельны полу. На выдохе вставай через ноги в исходное.\n\nКлючи: Штанга всё время строго над головой - руки не сгибаются и не уходят вперёд. Это упражнение на мобильность и баланс, держи кор крепким.",
            videoUrl: "https://www.youtube.com/results?search_query=Overhead%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Pallof Press с ротацией",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Закрепи рукоять на уровне плеча. Встань боком к блоку, возьмись одной рукой и отойди на длину руки, чтобы трос натянулся. Подведи вторую руку, обе на рукояти, стопы на ширине таза.\n\nДвижение: Выжми рукоять от груди прямыми руками. Держа таз неподвижным, разверни корпус от блока на четверть оборота, затем плавно вернись и прижми рукоять к груди.\n\nКлючи: Кор не даёт тросу скрутить тебя - в этом весь смысл. Таз и плечи стабильны, поворот идёт только корпусом, без рывка.",
            videoUrl: "https://www.youtube.com/results?search_query=Pallof%20Press%20with%20Rotation%20technique"
        ),
        LibraryExercise(
            name: "Ягодичный мост на фитболе",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Ляг верхней частью спины на фитбол, таз на весу. Обе стопы на полу, на ширине таза или чуть шире.\n\nДвижение: Подними таз вверх, выталкивая его ягодицами и бицепсами бёдер, пока тело не выстроится в линию. Задержись наверху и опустись в исходное.\n\nКлючи: Толкай тазом за счёт ягодиц, а не поясницы. Наверху сожми ягодицы и не прогибай поясницу. Мяч добавляет нестабильности - кор работает на баланс.",
            videoUrl: "https://www.youtube.com/results?search_query=Physioball%20Hip%20Bridge%20technique"
        ),
        LibraryExercise(
            name: "Сгибание ног со скольжением",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Нужен гладкий пол. Ляг на спину, ноги вытянуты. Под пятку положи полотенце или лёгкий блин, чтобы пятка скользила.\n\nДвижение: Согни колено, подтягивая пятку к себе скольжением по полу, вторая нога остаётся прямой. На полном сгибе плавно верни ногу в исходное.\n\nКлючи: Контролируй и сгибание, и обратное движение - именно сопротивление на возврате грузит бицепс бедра. Таз не отрывай, спину держи прижатой.",
            videoUrl: "https://www.youtube.com/results?search_query=Floor%20Hamstring%20Slides%20technique"
        ),
        LibraryExercise(
            name: "Приседания плие с гантелью",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Встань прямо, ноги шире плеч, носки развёрнуты наружу, колени чуть согнуты. Возьми гантель обеими руками за верхний блин и держи перед собой на прямых руках.\n\nДвижение: На вдохе плавно опускайся, сгибая колени, пока бёдра не станут параллельны полу. Затем толкайся пятками и на выдохе возвращайся вверх.\n\nКлючи: Корпус держи вертикально, руки неподвижны - они только удерживают вес. Колени веди в сторону носков, не заваливай внутрь. Так нагрузка идёт во внутреннюю поверхность бёдер и ягодицы.",
            videoUrl: "https://www.youtube.com/results?search_query=Plie%20Dumbbell%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Плиометрические отжимания через гирю",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Прими упор лёжа на носках, одна ладонь на полу, другая на гире, локти выпрямлены. Спина прямая, корпус в одну линию.\n\nДвижение: Опустись как можно ниже, держа спину ровной. Резко и мощно оттолкнись вверх, перебрасывая тело на другую сторону гири и меняя руки. Дальше повторяй переброс из стороны в сторону.\n\nКлючи: Главное - взрывной толчок, иначе руки не успеешь переставить. Держи пресс в тонусе, не проваливай поясницу. Начинай с малой амплитуды, пока не поймаешь баланс.",
            videoUrl: "https://www.youtube.com/results?search_query=Plyo%20Kettlebell%20Push-Ups%20technique"
        ),
        LibraryExercise(
            name: "Взятие на грудь с плинтов",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга на плинтах нужной высоты, хват чуть шире ног. Опусти таз, вес на пятках, спина прямая, грудь вверх, плечи чуть впереди грифа, взгляд вперёд.\n\nДвижение: Первая тяга - выжимай пятками, разгибая колени, угол спины не меняй. У середины бедра мощно включай таз: разгибай бёдра, колени, голеностоп, как в прыжке. На пике подрывай плечами и уходи под штангу, проворачивая локти и принимая гриф на дельты.\n\nКлючи: Руки тянут в последнюю очередь - разгон даёт таз, а не бицепс. Гриф веди близко к телу. Локти держи высоко при приёме, иначе вес уйдёт вперёд.",
            videoUrl: "https://www.youtube.com/results?search_query=Power%20Clean%20from%20Blocks%20technique"
        ),
        LibraryExercise(
            name: "Силовой рывок с плинтов",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга на плинтах, хват широкий. Стопы под тазом, чуть развёрнуты, таз опущен, грудь и взгляд вперёд, плечи перед грифом, локти в стороны.\n\nДвижение: Первая тяга - выжимай через переднюю часть пяток, снимая гриф с опоры. Затем мощно разгибай таз, колени и голеностоп, разгоняя штангу близко к телу. На пике подрывай плечами и резко уходи под гриф, фиксируя его над головой на прямых руках.\n\nКлючи: Гриф держи у тела всю траекторию - уйдёт вперёд, потеряешь баланс. Принимай вес над головой жёстко, руки полностью выпрямлены. Вставай через пятки, грудь вверх.",
            videoUrl: "https://www.youtube.com/results?search_query=Power%20Snatch%20from%20Blocks%20technique"
        ),
        LibraryExercise(
            name: "Молотковые сгибания на скамье Скотта",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Положи плечи на подушку скамьи Скотта, в каждой руке гантель, ладони смотрят друг на друга (нейтральный хват).\n\nДвижение: На вдохе медленно опускай гантели, пока руки не выпрямятся и бицепс полностью не растянется. На выдохе сгибай руки и поднимай вес до уровня плеч, работая бицепсом.\n\nКлючи: В верхней точке задержись на секунду и сожми мышцу. Не бросай вес в негативе - опускай под контролем, иначе теряешь половину работы. Нейтральный хват добавляет нагрузку на брахиалис и предплечья.",
            videoUrl: "https://www.youtube.com/results?search_query=Preacher%20Hammer%20Dumbbell%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Подъём корпуса с жимом штанги",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на скамью, штанга лежит на груди, ноги надёжно зафиксированы в упорах для пресса.\n\nДвижение: На вдохе напряги пресс и ягодицы. Одновременно скручивай корпус вверх как в обычном подъёме и на выдохе выжимай штангу над головой. На вдохе плавно опускайся обратно, возвращая штангу к груди.\n\nКлючи: Поднимай тело прессом, а не за счёт рывка руками - руки лишь дожимают вес. Двигайся подконтрольно, без рывков в пояснице. Если штанга тяжело идёт, снизь вес и работай на технику.",
            videoUrl: "https://www.youtube.com/results?search_query=Press%20Sit-Up%20technique"
        ),
        LibraryExercise(
            name: "Отжимания с ногами на фитболе",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Прими упор лёжа, ладони примерно на ширине, чуть шире плеч, руки выпрямлены. Носки положи на фитбол, чтобы тело было приподнято и вытянуто в линию.\n\nДвижение: На вдохе опускайся, пока грудь почти не коснётся пола. На выдохе мощно отжимайся вверх грудными и сжимай грудь в верхней точке.\n\nКлючи: Держи корпус жёстко - мяч заставляет балансировать и сильнее включает пресс. Не проваливай поясницу и не задирай таз. Чем дальше мяч под стопами, тем сложнее удерживать равновесие.",
            videoUrl: "https://www.youtube.com/results?search_query=Push-Ups%20With%20Feet%20on%20an%20Exercise%20Ball%20technique"
        ),
        LibraryExercise(
            name: "Отжимание с переходом в боковую планку",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Прими упор лёжа на носках, ладони чуть шире плеч, корпус в одну линию.\n\nДвижение: Сделай отжимание, сгибая локти и держа тело прямым. Поднимаясь, перенеси вес на левую руку, развернись в сторону и подними правую руку к потолку - получится боковая планка. Опусти руку, сделай ещё отжимание и поворот в другую сторону. Чередуй стороны на 10 и больше повторов.\n\nКлючи: Держи пресс и ягодицы в тонусе - тело не должно провисать в развороте. В боковой планке таз тяни вверх, взгляд за поднятой рукой. Это связка на грудь, плечи и устойчивость кора.",
            videoUrl: "https://www.youtube.com/results?search_query=Push-Up%20to%20Side%20Plank%20technique"
        ),
        LibraryExercise(
            name: "Растяжка квадрицепса лёжа на боку",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Ляг на бок. Накинь ремень, верёвку или резину на верхнюю стопу. Согни колено и отведи бедро назад, стараясь дотянуться пяткой до ягодицы, концы ремня держи в руках.\n\nДвижение: Перекинь ремень через плечо или над головой и мягко подтягивай, усиливая растяжение квадрицепса. Держи 10-20 секунд, затем смени сторону.\n\nКлючи: Тяни плавно, без рывков - растяжку доводи до приятного натяжения, а не до боли. Бедро держи отведённым назад, не разворачивай таз. Колено в линию с телом, не уводи в сторону.",
            videoUrl: "https://www.youtube.com/results?search_query=Side-Lying%20Quad%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Тяга с плинтов (Rack Pull)",
            category: .back,
            muscleGroup: .lowerBack,
            defaultType: .strength,
            technique: "Старт: Поставь гриф на упоры силовой рамы на нужной высоте - под коленями, чуть выше или на середине бедра. Встань к штанге как для становой: стопы под тазом, хват на ширине плеч, спина прогнута, таз отведён назад. На большом весе используй разнохват, замок или лямки.\n\nДвижение: Взгляд вперёд, разгибай таз и колени, тяни вес вверх и назад до полного выпрямления. В верхней точке своди лопатки. Верни штангу на упоры и повтори.\n\nКлючи: Спину держи прогнутой всю амплитуду - округлишь поясницу под весом, получишь травму. Тяни телом, а не руками. Гриф веди вплотную к ногам.",
            videoUrl: "https://www.youtube.com/results?search_query=Rack%20Pulls%20technique"
        ),
        LibraryExercise(
            name: "Горизонтальный велотренажёр",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: Сядь в тренажёр и отрегулируй сиденье под свой рост так, чтобы нога в нижней точке оставалась чуть согнутой. Спина опирается на спинку.\n\nДвижение: Выбери программу или ручной режим, начни крутить педали. По ходу меняй сопротивление под нужную интенсивность. Через ручки можно отслеживать пульс и держаться в своей зоне.\n\nКлючи: Горизонтальная посадка снимает нагрузку со спины и суставов - удобно для восстановления и долгого кардио. Дыши ровно, не задерживай дыхание. Для справки: человек 70 кг за 30 минут в среднем темпе сжигает около 230 ккал.",
            videoUrl: "https://www.youtube.com/results?search_query=Recumbent%20Bike%20technique"
        ),
        LibraryExercise(
            name: "Отжимания на кольцах (дипы)",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Возьмись за кольца, лёгким прыжком выйди в упор с выпрямленными руками. Тело вертикально, корпус напряжён.\n\nДвижение: Сгибай локти и опускайся, пока плечи не уйдут ниже параллели (локоть глубже 90°). Не раскачивайся, держи осанку. Затем разгибай руки и выжимай себя обратно вверх.\n\nКлючи: Кольца гуляют, поэтому стабилизация - половина работы: держи кисти и предплечья жёстко. В верхней точке доводи руки до конца. Опускайся подконтрольно, без провала плеч вперёд.",
            videoUrl: "https://www.youtube.com/results?search_query=Ring%20Dips%20technique"
        ),
        LibraryExercise(
            name: "Румынская тяга с дефицита",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Встань прямо, держи штангу на прямых руках перед собой. Для большей амплитуды встань на возвышение (блин или платформу).\n\nДвижение: Чуть согни колени и наклоняйся в тазобедренном суставе, отводя таз назад как можно дальше, опуская корпус до предела гибкости. Спина всё время в жёстком прогибе, гриф скользит по ногам. Почувствуешь сильное натяжение в задней поверхности бедра - реверсируй движение и вернись в старт.\n\nКлючи: Работает таз, а не поясница - не округляй спину. Колени держи чуть согнутыми и зафиксированными. Дефицит даёт больший растяг бицепса бедра, но и требует хорошей гибкости.",
            videoUrl: "https://www.youtube.com/results?search_query=Deficit%20Romanian%20Deadlift%20technique"
        ),
        LibraryExercise(
            name: "Лазание по канату",
            category: .complex,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Возьмись за канат обеими руками над головой. Потяни канат вниз и сделай небольшой прыжок вверх.\n\nДвижение: Обвей канат вокруг ноги, зажимая его стопами. Тянись руками как можно выше и крепко берись за канат. Отпусти зажим стоп и подтягивайся руками, подводя колени к груди. Снова зафиксируй стопы и выпрямись, перехватив канат повыше. Так лезь до верха. Для спуска ослабляй зажим стоп и сползай, перехватывая руками поочерёдно.\n\nКлючи: Главную работу делают ноги - стопы держат вес, руки только перехватывают. Не виси на одних руках, иначе быстро забьёшься. Зажим стопами должен быть надёжным перед каждым перехватом.",
            videoUrl: "https://www.youtube.com/results?search_query=Rope%20Climb%20technique"
        ),
        LibraryExercise(
            name: "Вращение рук с палкой за спиной",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Встань прямо, ноги вместе, возьми гимнастическую палку или черенок. Заведи палку за бёдра хватом шире плеч, ладони вниз, большие пальцы наружу.\n\nДвижение: Медленно поднимай прямые руки с палкой вверх за спиной, насколько позволяет подвижность плеч. Не форсируй, если дальше идёт туго - остановись.\n\nКлючи: Двигайся плавно и без рывков - это мягкое раскрытие грудного отдела и плеч. Чем шире хват, тем легче упражнение; сужай со временем. Не выгибай поясницу, чтобы дотянуть руки выше - работай только плечами.",
            videoUrl: "https://www.youtube.com/results?search_query=Around-the-World%20Shoulder%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Растяжка бегуна",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Встань прямо, одну ногу отведи далеко назад и медленно опусти корпус к полу, ладони поставь по бокам от передней стопы.\n\nДвижение: Пятка передней ноги остаётся прижатой к полу - если отрывается, отодвинь заднюю ногу ещё дальше. Поднимай таз вверх, затем плавно опускай вниз, усиливая растяжку.\n\nКлючи: Тянутся сгибатель бедра задней ноги, задняя поверхность и ягодица передней. Не делай рывков, дыши ровно и не блокируй переднее колено.",
            videoUrl: "https://www.youtube.com/results?search_query=Runner%27s%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Ножницы лёжа",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, прижми поясницу к полу, руки вытяни вдоль тела ладонями вниз. Слегка согни колени и подними ноги так, чтобы пятки были примерно в 15 см от пола.\n\nДвижение: Подними левую ногу до угла около 45°, правую одновременно опусти почти к полу. Затем поменяй ноги местами плавным скрещивающим движением.\n\nКлючи: Поясница всё время прижата, руки неподвижны. Работай за счёт пресса, не задерживай дыхание. Не опускай ноги до самого пола, чтобы держать живот в напряжении.",
            videoUrl: "https://www.youtube.com/results?search_query=Scissor%20Kick%20technique"
        ),
        LibraryExercise(
            name: "Прыжковые выпады со сменой ног",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: Встань в выпад: одна нога впереди, колено согнуто, заднее колено почти касается пола. Переднее колено над серединой стопы.\n\nДвижение: Отталкиваясь обеими ногами, прыгни как можно выше, помогая взмахом рук. В воздухе поменяй ноги местами - передняя уходит назад, задняя вперёд. Приземляйся мягко обратно в выпад и повторяй.\n\nКлючи: Гаси удар при приземлении, сгибая ноги, спину держи прямой. Колено не должно заваливаться внутрь. Темп взрывной, но контролируй посадку, чтобы беречь суставы.",
            videoUrl: "https://www.youtube.com/results?search_query=Scissor%20Jump%20technique"
        ),
        LibraryExercise(
            name: "Сгибание ног с резиной сидя",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Закрепи резину у самого пола, поставь скамью в паре шагов от неё. Сядь и заведи петлю за лодыжки, ноги при этом выпрямлены - это исходное положение.\n\nДвижение: Сгибай колени, подтягивая стопы к скамье против сопротивления резины. Слегка отклонись назад, чтобы стопы не задевали пол.\n\nКлючи: В конце амплитуды сделай короткую паузу и почувствуй заднюю поверхность бедра, затем медленно вернись. Не дёргай резину - именно подконтрольный негатив даёт нагрузку.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Band%20Hamstring%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Армейский жим штанги сидя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Сядь на скамью со штангой за головой, возьми гриф хватом чуть шире плеч, ладони вперёд. Подними штангу над головой на прямых руках, удерживая чуть впереди головы на уровне плеч - это старт.\n\nДвижение: На вдохе медленно опусти гриф к ключицам, локти под кистями. На выдохе мощно выжми штангу обратно вверх.\n\nКлючи: При нижней точке предплечье и плечо образуют угол около 90°. Спину держи прямой, не прогибайся в пояснице. Лучше брать гриф со стоек или у помощника - так бережёшь плечо.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Barbell%20Military%20Press%20technique"
        ),
        LibraryExercise(
            name: "Жим на плечи в кроссовере сидя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Выставь рабочий вес, сядь и возьми рукояти. Плечи примерно под 90° к корпусу, локти тоже согнуты под 90°, голова и грудь подняты - это исходное положение.\n\nДвижение: Разгибая локти, выжимай рукояти вверх и своди их над головой. Сделай паузу в верхней точке и вернись назад, не теряя натяжения тросов.\n\nКлючи: Держи постоянное напряжение на тросах - не бросай вес вниз. Можно делать без опоры на спинку и попеременно руками. Корпус не раскачивай, работай дельтами.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Cable%20Shoulder%20Press%20technique"
        ),
        LibraryExercise(
            name: "Растяжка икр сидя",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Сядь прямо на коврик. Одну ногу согни и поставь стопу на пол, чтобы стабилизировать корпус.\n\nДвижение: Вторую ногу выпрями и потяни носок на себя. Если дотягиваешься рукой - возьми за стопу, иначе используй ремень или полотенце и подтяни носок к себе.\n\nКлючи: Тянется икра выпрямленной ноги. Держи 10-20 секунд, спину не сутуль, дыши спокойно, затем смени сторону. Никаких рывков - тянем мягко.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Calf%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Подтягивание коленей к груди сидя",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Сядь на скамью, ноги вытяни вперёд чуть ниже параллели, руками держись за края скамьи. Корпус отклони назад примерно на 45° - это исходное положение.\n\nДвижение: На выдохе подтягивай колени к себе, одновременно подавая корпус им навстречу. Задержись на секунду в верхней точке.\n\nКлючи: На вдохе медленно вернись в старт, не бросая ноги. Работай прессом, а не инерцией. Не округляй спину сильно - движение идёт за счёт живота.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Flat%20Bench%20Leg%20Pull-In%20technique"
        ),
        LibraryExercise(
            name: "Good Morning сидя",
            category: .back,
            muscleGroup: .lowerBack,
            defaultType: .strength,
            technique: "Старт: Установи ящик в силовой раме, штифты на нужной высоте. Подсядь под гриф, положи его на заднюю часть плеч, не на трапеции, сведи лопатки. Сними штангу, сделай арку в пояснице и сядь на ящик, разводя колени - это исходное положение.\n\nДвижение: Удерживая гриф плотно, наклоняйся вперёд от тазобедренных как можно глубже, голова смотрит вперёд. Чуть выше штифтов сделай паузу и вернись в вертикаль.\n\nКлючи: Поясница всё время в напряжённой арке - не круглить спину. Штифты на уровне нижней точки дают и страховку, и ориентир. Корпус и кор держи жёстко.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Good%20Mornings%20technique"
        ),
        LibraryExercise(
            name: "Растяжка задней поверхности и икр с ремнём",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Накинь ремень, верёвку или резину на одну стопу. Сядь, обе ноги вытянуты вперёд - это исходное положение.\n\nДвижение: Слегка наклонись вперёд и потяни за ремень, оттягивая носок стопы на себя. Удерживай положение 10-20 секунд, затем повтори с другой ногой.\n\nКлючи: Растягиваются задняя поверхность бедра и икра рабочей ноги. Тяни плавно, без рывков, спину держи длинной. Если тянет слишком резко - ослабь натяжение ремня.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Hamstring%20and%20Calf%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Боковая растяжка корпуса сидя",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Сядь прямо на коврик. Сведи стопы подошвами вместе, расположив их в 15-20 см перед бёдрами.\n\nДвижение: Одну ладонь поставь на пол сбоку, другую заведи за голову. Тянись локтем верхней руки к потолку, наклоняя корпус в противоположную сторону.\n\nКлючи: Растягивается боковая поверхность корпуса и широчайшие. Удерживай 10-20 секунд, не заваливайся вперёд, дыши ровно, затем смени сторону. Тянись в длину, а не вниз.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Overhead%20Side%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Попеременный жим гантелей (See-Saw)",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Возьми по гантели в каждую руку и встань прямо. Закинь гантели к плечам и разверни кисти ладонями к себе, как перед жимом Арнольда - это исходное положение.\n\nДвижение: На выдохе выжимай левую руку вверх, разворачивая кисть ладонью вперёд, и одновременно наклоняйся корпусом в правую сторону. В верхней точке вдохни и начинай движение в другую сторону.\n\nКлючи: Будто тянешься левой рукой к чему-то наверху справа. Наклон идёт от таза, кор держи жёстко. Двигайся плавно, без рывков, поочерёдно меняя стороны.",
            videoUrl: "https://www.youtube.com/results?search_query=See-Saw%20Press%20%28Alternating%20Side%20Press%29%20technique"
        ),
        LibraryExercise(
            name: "Жим на плечи с резиной",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Встань на резину так, чтобы натяжение начиналось при выпрямленных вниз руках. Возьми рукояти и подними кисти на уровень плеч. Разверни ладони вперёд, локти согнуты, плечи и предплечья вдоль корпуса - это исходное положение.\n\nДвижение: На выдохе выжимай рукояти вверх, пока руки полностью не выпрямятся над головой. Затем подконтрольно вернись назад.\n\nКлючи: Не бросай руки вниз - держи натяжение резины на всём пути. Корпус стабилен, поясницу не прогибай. Работай дельтами, а не рывком корпуса.",
            videoUrl: "https://www.youtube.com/results?search_query=Band%20Shoulder%20Press%20technique"
        ),
        LibraryExercise(
            name: "Растяжка плеча перед собой",
            category: .shoulders,
            muscleGroup: .rearDelts,
            defaultType: .strength,
            technique: "Старт: Встань ровно, плечи опущены и расслаблены.\n\nДвижение: Вытяни левую руку прямо перед собой и заведи её поперёк тела вправо. Другой рукой мягко прижми её ближе к груди, держа выпрямленной.\n\nКлючи: Тянется задняя дельта и капсула плеча. Плечи не поднимай к ушам, удерживай 15-20 секунд и смени руку. Тяни до приятного натяжения, без боли.",
            videoUrl: "https://www.youtube.com/results?search_query=Shoulder%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Растяжка боков лёжа на боку",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Ляг на левый бок, левое колено согни перед собой для устойчивости и слегка подключи живот, чтобы держать корпус ровно.\n\nДвижение: Правую ногу выпрями и поставь стопу на пол позади левой. Правую руку вытяни над головой и мягко потяни себя за запястье, растягивая всю правую сторону тела. Затем смени сторону.\n\nКлючи: Тянутся бок, широчайшие и косые. Не заваливайся на спину - таз и плечи в одной плоскости. Тяни плавно, дыши, удерживай комфортное натяжение.",
            videoUrl: "https://www.youtube.com/results?search_query=Side-Lying%20Floor%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Боковая складка лёжа",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на бок, ноги прямые и сложены одна на другую, нижняя рука на полу для опоры, верхняя за головой.\n\nДвижение: На выдохе одновременно поднимай корпус и верхнюю ногу навстречу друг другу, складываясь в боку. На вдохе плавно опускайся обратно, не роняя корпус.\n\nКлючи: Работают боковые мышцы пресса - чувствуй сокращение в талии, а не рывок шеей. Не помогай себе руками, движение идёт от косых. Сделай все повторы на один бок, потом перевернись.",
            videoUrl: "https://www.youtube.com/results?search_query=Side%20Jackknife%20technique"
        ),
        LibraryExercise(
            name: "Махи в стороны с переводом перед собой",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Встань прямо, гантели по бокам у бёдер, локти чуть согнуты, спина ровная.\n\nДвижение: Подними гантели через стороны до уровня плеч без раскачки, затем сведи их прямыми руками перед собой. Опусти под контролем. На следующем повторе сначала подними перед собой, потом разведи в стороны и опусти.\n\nКлючи: Чередуй направления - так дельты получают нагрузку под разными углами. Не бери лишний вес, иначе пойдёт рывок корпусом. Держи локти мягкими, кисти не выше плеч.",
            videoUrl: "https://www.youtube.com/results?search_query=Side%20Laterals%20to%20Front%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Растяжка приводящих лёжа на боку",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Ляг на правый бок, правое колено согни перед собой для устойчивости, голову положи на правую руку.\n\nДвижение: Подними левую ногу вверх и возьмись за неё под коленом (легче) или за стопу (тяжелее). Тяни колено к плечу и одновременно опускай стопу к полу. Для усиления выпрями ногу.\n\nКлючи: Тянутся приводящие мышцы внутренней поверхности бедра. Двигайся медленно, без рывков, дыши ровно и не задерживай вдох. Держи положение спокойно, затем поменяй сторону.",
            videoUrl: "https://www.youtube.com/results?search_query=Side%20Lying%20Groin%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Боковая растяжка шеи",
            category: .core,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: Сядь или встань ровно, плечи расслаблены и опущены, взгляд прямо перед собой.\n\nДвижение: Мягко наклони голову к плечу, тянясь ухом вниз. Чтобы усилить, положи ладонь на висок и слегка дотяни голову без давления. Задержись и медленно вернись.\n\nКлючи: Растягивается боковая поверхность шеи и трапеция. Не поднимай противоположное плечо - именно это убирает натяжение. Тяни очень аккуратно, без рывков, и поработай в обе стороны поровну.",
            videoUrl: "https://www.youtube.com/results?search_query=Side%20Neck%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Подтягивания из стороны в сторону",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Возьмись за перекладину широким хватом, ладони от себя. Отклони корпус назад примерно на 30°, прогни поясницу и выведи грудь вперёд.\n\nДвижение: На выдохе подтянись вверх, смещаясь влево, пока перекладина не окажется у верха груди, опуская и сводя лопатки. Опустись и сделай то же со смещением вправо.\n\nКлючи: Тяни спиной, а не предплечьями, корпус не раскачивай - двигаются только руки. В верхней точке на секунду сожми мышцы спины. Чередуй стороны на каждом повторе.",
            videoUrl: "https://www.youtube.com/results?search_query=Side%20To%20Side%20Chins%20technique"
        ),
        LibraryExercise(
            name: "Боковые перепрыгивания через коробку",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: Встань сбоку от коробки, левую стопу поставь на её середину, руки готовы к работе.\n\nДвижение: Оттолкнись и перепрыгни на другую сторону, приземляясь правой стопой на коробку, а левой на пол. Помогай себе руками. Сразу перепрыгивай обратно и продолжай в ритме из стороны в сторону.\n\nКлючи: Приземляйся мягко на носок, гася удар коленом, держи темп ровным. Это кардио на ноги и координацию - дыши ритмично и не задерживай дыхание. Смотри вперёд, а не под ноги.",
            videoUrl: "https://www.youtube.com/results?search_query=Side%20to%20Side%20Box%20Shuffle%20technique"
        ),
        LibraryExercise(
            name: "Отжимания на одной руке",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Прими упор лёжа на носках и одной руке. Рабочая ладонь точно под плечом, ноги поставь пошире для устойчивости, свободную руку убери за спину.\n\nДвижение: Медленно опускайся, сгибая локоть, пока грудь не коснётся пола. Затем выжми себя вверх, разгибая руку, до исходной.\n\nКлючи: Это требует серьёзной силы и стабильности корпуса - держи тело прямой линией, не проваливай таз и не скручивайся. Чем шире ноги, тем легче баланс. Опускайся подчёркнуто медленно.",
            videoUrl: "https://www.youtube.com/results?search_query=Single-Arm%20Push-Up%20technique"
        ),
        LibraryExercise(
            name: "Ягодичный мост на одной ноге",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, стопы на полу, колени согнуты. Подними одну ногу, подтянув колено к груди - это исходное положение.\n\nДвижение: Упрись пяткой опорной ноги в пол и вытолкни таз вверх, отрывая ягодицы от пола. Поднимись максимально, задержись на секунду и опустись обратно.\n\nКлючи: Толкай именно через пятку - так нагрузка идёт в ягодицу, а не в поясницу. В верхней точке сожми ягодицу и не прогибай спину. Сделай все повторы на одну ногу, потом смени.",
            videoUrl: "https://www.youtube.com/results?search_query=Single%20Leg%20Glute%20Bridge%20technique"
        ),
        LibraryExercise(
            name: "Подъём корпуса (Sit-Up)",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, колени согнуты, стопы зафиксированы под опорой или партнёром. Ладони сложи за головой, переплетя пальцы.\n\nДвижение: На выдохе подними корпус вверх, пока он не образует с бёдрами V-образный угол. На секунду задержись в сокращении, затем на вдохе плавно опустись назад.\n\nКлючи: Поднимайся за счёт пресса, а не тяни себя за шею руками - ладони лишь придерживают голову. Не швыряй корпус по инерции, держи контроль на спуске. Дыши размеренно.",
            videoUrl: "https://www.youtube.com/results?search_query=Sit-Up%20technique"
        ),
        LibraryExercise(
            name: "Тяга салазок над головой спиной вперёд",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Прицепи к салазкам две рукояти на тросе или цепи, поставь лёгкий вес. Встань лицом к салазкам, отойди до лёгкого натяжения и подними руки прямо над головой.\n\nДвижение: Иди назад мелкими шагами, удерживая руки выпрямленными над головой и сохраняя натяжение троса. Двигайся плавно, без рывков.\n\nКлючи: Сильно грузятся плечи и верх спины - держи руки строго над головой, не роняй их вперёд. Корпус ровный, пресс в тонусе, чтобы не прогибать поясницу. Вес бери реально лёгкий.",
            videoUrl: "https://www.youtube.com/results?search_query=Sled%20Overhead%20Backward%20Walk%20technique"
        ),
        LibraryExercise(
            name: "Тяга салазок к себе",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Прицепи к салазкам две рукояти на тросе или цепи с подходящим весом. Встань лицом к ним, отойди до натяжения, по рукояти в каждой руке. Чуть согни колени, грудь и голову держи высоко, руки выпрямлены.\n\nДвижение: Согни локти и сведи лопатки, подтягивая салазки к себе. Затем отступи на пару шагов назад, чтобы вернуть натяжение, и повтори.\n\nКлючи: Тяни спиной, сводя лопатки, а не рывком рук. Корпус держи жёстко, не округляй поясницу. Локти веди вдоль тела.",
            videoUrl: "https://www.youtube.com/results?search_query=Sled%20Row%20technique"
        ),
        LibraryExercise(
            name: "Удары кувалдой по покрышке",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Встань примерно в полуметре от покрышки в шахматной стойке. Возьми кувалду: для правши левая рука внизу рукояти, правая ближе к бойку.\n\nДвижение: Заводя кувалду вверх, правая рука скользит к бойку. На ударе вниз правая рука съезжает к левой, и ты со всей силы бьёшь по покрышке. Гаси отскок и повтори с другой стороны.\n\nКлючи: Бей всем телом - бёдра и корпус, а не одни руки. Держи покрышку под контролем после удара. Чередуй стороны, чтобы нагрузка шла ровно. Дыши на выдохе в момент удара.",
            videoUrl: "https://www.youtube.com/results?search_query=Sledgehammer%20Swings%20technique"
        ),
        LibraryExercise(
            name: "Тяга в наклоне в Смите",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Установи гриф Смита примерно на 5 см ниже колен. Чуть согни ноги и наклони корпус вперёд от пояса, держа спину прямой, почти параллельно полу, голову вверх.\n\nДвижение: Возьми гриф верхним хватом и сними со стопоров - руки висят перпендикулярно полу. На выдохе тяни гриф вверх, локти близко к телу, в верхней точке сожми спину на секунду. На вдохе медленно опусти.\n\nКлючи: Тяни лопатками и спиной, предплечья только держат гриф. Корпус неподвижен - не выпрямляйся рывком. Поясницу держи ровной.",
            videoUrl: "https://www.youtube.com/results?search_query=Smith%20Machine%20Bent-Over%20Row%20technique"
        ),
        LibraryExercise(
            name: "Подъёмы на носки в Смите",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Положи под гриф Смита брусок или блин, выставь гриф под свой рост. Встань носками на возвышение, гриф ляжет на верх спины. Возьмись за гриф и поверни, чтобы снять со стопоров.\n\nДвижение: Поднимись на носки как можно выше, выталкивая себя подушечками стоп, и сожми икры в верхней точке на секунду. Колени держи прямыми. На вдохе медленно опусти пятки вниз.\n\nКлючи: Работай через полную амплитуду - глубокая растяжка внизу и максимальный подъём вверху. Не сгибай колени, иначе нагрузка уйдёт. Держи баланс на грифе.",
            videoUrl: "https://www.youtube.com/results?search_query=Smith%20Machine%20Calf%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Жим в Смите с обратным наклоном",
            category: .chest,
            muscleGroup: .lowerChest,
            defaultType: .strength,
            technique: "Старт: Поставь скамью с обратным наклоном в раму так, чтобы гриф был над грудью. Загрузи вес и ляг. Поверни гриф, сними со стопоров и выпрями руки. Спина чуть прогнута, лопатки сведены.\n\nДвижение: Согни руки и опусти гриф к низу груди. Сделай короткую паузу, затем выжми вес вверх, разгибая руки до исходной.\n\nКлючи: Акцент на нижней части груди. Опускай гриф под контролем, не роняй на грудь. В Смите траектория задана, так что сосредоточься на сведении груди. Закончив, поверни гриф на стопоры.",
            videoUrl: "https://www.youtube.com/results?search_query=Smith%20Machine%20Decline%20Press%20technique"
        ),
        LibraryExercise(
            name: "Жим над головой в Смите",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Сядь на лавку (лучше со спинкой) под грифом Смита так, чтобы гриф шёл по линии лица. Возьми его прямым хватом, сними со стопоров и выжми вверх до прямых рук.\n\nДвижение: На вдохе медленно опускай гриф до уровня подбородка. На выдохе выжимай обратно вверх силой плеч до полного выпрямления рук.\n\nКлючи: Спина прижата к спинке, корпус не отклоняй. Фиксированная траектория Смита снимает нагрузку со стабилизаторов - можно сосредоточиться на дельтах. Не бросай гриф вниз и не сваливай вес в поясницу.",
            videoUrl: "https://www.youtube.com/results?search_query=Smith%20Machine%20Overhead%20Shoulder%20Press%20technique"
        ),
        LibraryExercise(
            name: "Румынская тяга в Смите",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Выставь гриф Смита на уровень середины бедра, возьми прямым хватом на ширине плеч. Подними гриф, выпрями руки и встань ровно, колени чуть согнуты.\n\nДвижение: На выдохе наклоняйся вперёд от таза, опуская гриф вдоль ног, колени почти не двигаются. Иди вниз, пока не почувствуешь растяжение в бицепсах бедра. На вдохе выпрямляйся за счёт разгибания таза.\n\nКлючи: Спина прямая всё время, не круглить поясницу. Работа идёт от таза, а не от спины. Глубину задаёт растяжение задней поверхности - не гонись за полом любой ценой.",
            videoUrl: "https://www.youtube.com/results?search_query=Smith%20Machine%20Romanian%20Deadlift%20technique"
        ),
        LibraryExercise(
            name: "Тяга к подбородку в Смите",
            category: .shoulders,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: Выставь гриф Смита на уровень середины бедра и возьми прямым хватом на ширине плеч. Подними гриф, выпрями руки с лёгким сгибом в локтях - это стартовое положение.\n\nДвижение: На выдохе тяни гриф вверх вдоль тела до уровня подбородка, ведя локтями. Локти всё время выше предплечий. Задержись на секунду наверху, затем на вдохе медленно опусти.\n\nКлючи: Движение ведут локти, а не кисти. Корпус неподвижен, не раскачивайся. Если в плечах дискомфорт - сократи амплитуду и не тяни выше уровня плеч.",
            videoUrl: "https://www.youtube.com/results?search_query=Smith%20Machine%20Upright%20Row%20technique"
        ),
        LibraryExercise(
            name: "Болгарские сплит-приседания в Смите",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Поставь лавку в 60-90 см позади Смита, выставь гриф под свой рост и заведи его на верх спины. Сними со стопоров, одну ногу поставь под гриф, носок задней ноги положи на лавку.\n\nДвижение: На вдохе медленно опускайся, сгибая переднее колено, корпус прямой, голова поднята. Иди вниз, пока бедро не уйдёт чуть ниже параллели. На выдохе вставай, толкаясь пяткой передней ноги.\n\nКлючи: Колено передней ноги не выходит за носок - иначе перегрузишь сустав. Держи вес на пятке, корпус вертикально. Сделай все повторы, затем поменяй ногу.",
            videoUrl: "https://www.youtube.com/results?search_query=Smith%20Machine%20Bulgarian%20Split%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Уход в сед в рывке (Snatch Balance)",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Поставь ноги в тяговую позицию, гриф лежит на верху спины, хват широкий рывковый. Корпус вертикальный, мышцы собраны.\n\nДвижение: Резко подсядь и оттолкнись коленями, затем агрессивно уйди под гриф, переставляя ноги в позицию приёма. Поймай гриф на прямых руках над головой ближе к нижней точке седа. Опустись в полный сед и встань.\n\nКлючи: Корпус остаётся вертикальным, таз уходит между ног. Главное - скорость ухода под гриф, а не сила выжимания. Локти фиксируются мгновенно, без дожима. Аккуратно опусти вес вниз.",
            videoUrl: "https://www.youtube.com/results?search_query=Snatch%20Balance%20technique"
        ),
        LibraryExercise(
            name: "Тяга в рывковом хвате",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Возьми штангу широким рывковым хватом, ноги под тазом, носки слегка развёрнуты. Опустись к грифу, спина в жёстком прогибе, взгляд вперёд, грудь раскрыта.\n\nДвижение: Начни движение, толкаясь пятками и поднимая таз. Угол наклона спины не меняй, пока гриф не пройдёт колени. После этого выводи таз вперёд через гриф, слегка отклоняясь назад. Верни штангу вниз обратным движением.\n\nКлючи: Это база первой фазы рывка - учит держать спину и стартовать ногами. Гриф идёт близко к телу. Не спеши открывать таз раньше, чем штанга минует колени.",
            videoUrl: "https://www.youtube.com/results?search_query=Snatch%20Deadlift%20technique"
        ),
        LibraryExercise(
            name: "Рывковая протяжка",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга на полу у голеней, хват широкий рывковый. Опусти таз, вес на пятках, спина прямая, взгляд вперёд, грудь вверх, плечи чуть впереди грифа.\n\nДвижение: Первая фаза - толкайся пятками и разгибай колени, угол спины и руки неизменны, веди гриф до уровня выше колен. Затем вторая фаза: у середины бедра мощно раскрывай таз, разгибая бёдра, колени и стопы, как в прыжке, разгоняя штангу вверх.\n\nКлючи: Руками не подтягивай - ускорение даёт раскрытие тела. В конце тело полностью разогнуто, чуть отклонено назад. Финал резкий и короткий, не затягивай разгибание.",
            videoUrl: "https://www.youtube.com/results?search_query=Snatch%20Pull%20technique"
        ),
        LibraryExercise(
            name: "Шраги рывковым хватом",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: Возьми гриф широким хватом - крюком или прямым - и держи его на уровне середины бедра. Спина прямая, корпус чуть наклонён вперёд.\n\nДвижение: Подними плечи к ушам, сжимая трапеции, и контролируемо опусти обратно. Работают только плечи, руки прямые.\n\nКлючи: Здесь можно работать с весом тяжелее рывкового, но не перегружай так, чтобы движение замедлилось. Фокус на трапециях и верхней фазе протяжки. Не помогай локтями и не дёргай корпусом.",
            videoUrl: "https://www.youtube.com/results?search_query=Snatch%20Shrug%20technique"
        ),
        LibraryExercise(
            name: "Рывок с плинтов",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга лежит на плинтах нужной высоты, хват широкий рывковый. Ноги под тазом, носки развёрнуты, таз опущен, грудь вверх, взгляд вперёд, плечи чуть впереди грифа, локти в стороны.\n\nДвижение: Первая фаза - толкайся передней частью пяток, снимая гриф с плинтов. Затем вторая фаза: мощно разгибай таз, колени и стопы, разгоняя гриф у тела, в верхней точке шраг и сгиб локтей в стороны. Уходи под гриф, переставляя ноги, и поймай его на прямых руках над головой как можно ниже.\n\nКлючи: Гриф идёт близко к телу. Высокий старт убирает фазу от пола - можно отработать вторую тягу и быстрый уход. Вставай через пятки, грудь и голова подняты. Аккуратно верни вес на плинты.",
            videoUrl: "https://www.youtube.com/results?search_query=Snatch%20from%20Blocks%20technique"
        ),
        LibraryExercise(
            name: "Разгибание на трицепс с резиной из-за головы",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Закрепи резину у пола (на базе наклонной лавки или встань на неё ногами). Заведи резину за голову, держи прямым хватом, локти подняты вверх - это стартовое положение.\n\nДвижение: Разгибай руки в локтях, выпрямляя их вверх, плечи держи на месте. Сделай паузу и вернись в исходное.\n\nКлючи: Двигаются только предплечья, плечи зафиксированы у головы. Сопротивление резины растёт к концу - отличный пик на трицепс. Не разводи локти в стороны и не помогай корпусом.",
            videoUrl: "https://www.youtube.com/results?search_query=Banded%20Overhead%20Triceps%20Extension%20technique"
        ),
        LibraryExercise(
            name: "Скоростные приседания на коробку с резиной",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Прикрепи резину к грифу, надёжно заякорив её у пола, при необходимости укороти для натяжения. Поставь гриф на верх спины, лопатки сведены, спина прогнута, всё тело собрано.\n\nДвижение: Сними гриф и встань перед коробкой. Отводи таз назад и садись на коробку под контролем, не падая на неё. Сделай короткую паузу и взрывно вставай, разгибая таз и колени.\n\nКлючи: Вес 50-70% от максимума - тут важна скорость, а не тоннаж. Резина учит ускоряться по всей амплитуде. Не отбивайся от коробки и не теряй прогиб спины при паузе.",
            videoUrl: "https://www.youtube.com/results?search_query=Speed%20Box%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Скручивание позвоночника сидя",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Сядь на стул, спина прямая, стопы на полу. Сцепи пальцы за головой, локти разведены в стороны, подбородок опущен.\n\nДвижение: Поверни верх корпуса в одну сторону до предела, повтори несколько раз. Затем наклонись вперёд и скрутись, потянувшись локтем к полу с внутренней стороны колена. Вернись и сделай то же в другую сторону.\n\nКлючи: Это растяжка - двигайся плавно, без рывков. Поворот идёт от грудного отдела, таз остаётся на месте. Дыши ровно, не задерживай дыхание в скрутке.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Spinal%20Twist%20technique"
        ),
        LibraryExercise(
            name: "Взятие на грудь в разножку",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга у голеней, хват сверху чуть шире ног. Опусти таз, вес на пятках, спина прямая, грудь вверх, взгляд вперёд, плечи чуть впереди грифа.\n\nДвижение: Первая фаза - толкайся пятками, разгибая колени, гриф идёт до уровня выше колен. Вторая фаза - у середины бедра мощно раскрывай таз, колени и стопы как в прыжке. Третья фаза - резкий шраг и сгиб локтей вверх, уход под гриф с разведением ног: одна вперёд, другая назад. Поймай гриф на плечах, локти высоко.\n\nКлючи: Ускорение даёт тело, а не руки. Гриф ложится на дельты, кисти расслаблены, гриф чуть касается горла. Встав, сведи ноги. Корпус всё время вертикальный.",
            videoUrl: "https://www.youtube.com/results?search_query=Split%20Clean%20technique"
        ),
        LibraryExercise(
            name: "Выпрыгивания в выпаде",
            category: .cardio,
            muscleGroup: .quadriceps,
            defaultType: .duration,
            technique: "Старт: Прими позицию выпада - одна нога впереди, колено согнуто, заднее колено почти касается пола. Переднее колено над серединой стопы.\n\nДвижение: Разгибая обе ноги, выпрыгни как можно выше, помогая взмахом рук. В прыжке сведи стопы, а при приземлении верни их в исходные позиции. Мягко погаси удар, уходя обратно в выпад.\n\nКлючи: Это плиометрика - важна взрывная сила и мягкое приземление. Гаси удар сгибом коленей, не приземляйся на прямые ноги. Колено передней ноги держи над стопой, не заваливай внутрь.",
            videoUrl: "https://www.youtube.com/results?search_query=Split%20Jump%20technique"
        ),
        LibraryExercise(
            name: "Рывок в разножку",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга на полу у голеней, хват широкий рывковый. Ноги под тазом, носки развёрнуты, таз опущен, грудь вверх, взгляд вперёд, плечи чуть впереди грифа.\n\nДвижение: Первая фаза - толкайся передней частью пяток, угол спины не меняй до колен. Вторая фаза - мощно разгибай таз, колени и стопы, в верхней точке шраг и сгиб локтей в стороны. Уходи под гриф, разводя ноги в разножку: одна вперёд, другая назад, и поймай гриф на прямых руках над головой как можно ниже.\n\nКлючи: Гриф идёт близко к телу, удерживай его над линией пяток. Голова и грудь подняты. Встав, сведи ноги вместе и аккуратно опусти штангу.",
            videoUrl: "https://www.youtube.com/results?search_query=Split%20Snatch%20technique"
        ),
        LibraryExercise(
            name: "Сплит-прыжки",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Встань прямо, сделай выпад - одна нога впереди, другая сзади, корпус ровный.\n\nДвижение: Опустись, согнув колени, и сразу взрывным прыжком вытолкнись вверх, меняя ноги местами в воздухе. Приземляйся мягко в новый выпад и тут же повторяй.\n\nКлючи: Держи корпус вертикально, переднее колено не уводи за носок. Приземление на полусогнутых пружинит удар - так бережёшь колени. Дыши ритмично, не задерживай воздух. Делай 5-10 смен на каждую ногу.",
            videoUrl: "https://www.youtube.com/results?search_query=Split%20Squat%20Jumps%20technique"
        ),
        LibraryExercise(
            name: "Толчок из приседа",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Штанга лежит на передней части плеч, стопы под бёдрами, грудь раскрыта, локти высоко.\n\nДвижение: Сделай короткий подсед - согни колени, не уводя таз назад, и тут же мощно вытолкнись через пятки. Когда штанга идёт вверх, убери голову и быстро уйди в полный сед под штангу с прямыми руками над головой. Зафиксируй и встань, толкаясь пятками.\n\nКлючи: Подсед короткий и резкий, вся сила - в обратном движении. Штанга над пятками, голова и грудь вверх. Делай мощно и уверенно, без рывка в спине. Опускай вес на пол под контролем.",
            videoUrl: "https://www.youtube.com/results?search_query=Squat%20Jerk%20technique"
        ),
        LibraryExercise(
            name: "Подъемы на носки со штангой стоя",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Поставь штангу на трапеции в раме, чуть ниже шеи. Сними её, выпрямив корпус, отойди и встань на ширине плеч, носки чуть в стороны. Колени слегка согнуты, спина прямая, взгляд вперёд.\n\nДвижение: На выдохе поднимись на носки как можно выше, сжимая икры. Задержись на секунду в верхней точке. На вдохе медленно опусти пятки до полного растяжения икр.\n\nКлючи: Колени держи неподвижными - работают только стопы. Не смотри вниз, иначе теряешь баланс. Для большей амплитуды встань носками на брусок, но следи за устойчивостью.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Barbell%20Calf%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Растяжка бицепса стоя",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Встань прямо, сцепи руки за спиной ладонь к ладони. Выпрями руки и разверни кисти так, чтобы ладони смотрели вниз.\n\nДвижение: Медленно поднимай прямые руки вверх за спиной, пока не почувствуешь мягкое натяжение в бицепсах и передней части плеч. Удержи положение.\n\nКлючи: Не сутулься, грудь держи раскрытой - так растяжение идёт именно по бицепсу. Двигайся плавно, без рывков, до приятного тянущего ощущения, а не до боли. Спокойно дыши и держи 15-20 секунд.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Biceps%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Жим Брэдфорда",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Сними штангу со стойки, хват пронированный на ширине плеч, гриф лежит на передних дельтах перед головой.\n\nДвижение: Выжми штангу вверх, разгибая локти, но не до полного замка, и пронеси её за голову. Опусти к затылку, пока локти не образуют прямой угол. Снова выжми над головой и опусти спереди. Чередуй спереди и сзади без остановки.\n\nКлючи: Не блокируй локти в верхней точке - так нагрузка остаётся на дельтах. Опускай за голову только при хорошей подвижности плеч, без боли. Корпус держи стабильным, без раскачки. Вес лёгкий-средний, движение плавное.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Bradford%20Press%20technique"
        ),
        LibraryExercise(
            name: "Жим от груди в кроссовере стоя",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Поставь оба блока на высоту груди, возьми по рукоятке в каждую руку. Встань в шаге-двух от стоек, можно поставить ноги в небольшой выпад для устойчивости. Локти согнуты под 90°, лопатки сведены.\n\nДвижение: Удерживая корпус неподвижным, выжми рукоятки вперёд, разгибая локти, и сведи их перед собой. Сделай паузу, почувствуй сокращение груди, и вернись в исходное.\n\nКлючи: Двигаются только руки - корпус не помогает раскачкой. В конце своди рукоятки вместе, это добавляет нагрузку грудным. На жиме выдох, на возврате вдох. Не разводи руки слишком далеко назад, береги плечи.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Cable%20Chest%20Press%20technique"
        ),
        LibraryExercise(
            name: "Подъемы на носки с гантелями стоя",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Встань прямо с гантелями в опущенных руках. Поставь носки на устойчивый брусок 5-7 см высотой, пятки свисают и касаются пола.\n\nДвижение: На выдохе поднимись на носки как можно выше, сжимая икры, задержись на секунду в верхней точке. На вдохе медленно опусти пятки в исходное положение, растягивая икры.\n\nКлючи: Носки прямо - грузишь икры равномерно; внутрь - акцент на внешнюю головку, наружу - на внутреннюю. Колени держи почти прямыми, без приседа. Работай в полной амплитуде и не отбивай пятками от пола.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Dumbbell%20Calf%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Обратные сгибания с гантелями",
            category: .arms,
            muscleGroup: .forearms,
            defaultType: .strength,
            technique: "Старт: Встань прямо, гантели в опущенных руках хватом сверху (ладони смотрят вниз), стопы на ширине плеч, руки выпрямлены.\n\nДвижение: Удерживая плечи неподвижными, на выдохе сгибай руки и поднимай гантели до уровня плеч. Двигаются только предплечья. В верхней точке на секунду напряги мышцы. На вдохе медленно опусти вес в исходное.\n\nКлючи: Кисти зафиксированы в положении хвата сверху - так грузишь предплечья и плечелучевую, а не бицепс. Локти прижаты к корпусу, не раскачивай руками. Опускай медленно, контролируй негатив.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Dumbbell%20Reverse%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Растяжка квадрицепса с опорой",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Встань спиной к скамье или степу на расстоянии 60-90 см, корпус прямой.\n\nДвижение: Заведи одну ногу назад и положи подъём стопы или носок на возвышение - как удобнее. Слегка согни опорное колено и подай таз чуть вперёд, пока не почувствуешь натяжение по передней поверхности бедра. Удержи, затем поменяй ногу.\n\nКлючи: Опорное колено не выводи за линию носка. Держи таз подобранным, не прогибай поясницу - тогда тянется именно квадрицепс. Двигайся плавно, дыши спокойно, держи 20-30 секунд на каждую ногу.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Elevated%20Quad%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Растяжка икроножной мышцы",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Поставь правую пятку на степ с выпрямленным коленом и наклонись вперёд, чтобы взяться правой рукой за носок. Левое колено слегка согнуто, спина прямая.\n\nДвижение: Перенеси вес на левую ногу, левую ладонь положи на левое бедро. Потяни носок правой стопы на себя, пока не почувствуешь натяжение в икре. Удержи, затем поменяй ногу.\n\nКлючи: Колено растягиваемой ноги держи прямым - так работает именно икроножная. Тяни плавно, без рывков, до приятного натяжения. Спина прямая, дыши ровно, держи 15-20 секунд на каждую сторону.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Gastrocnemius%20Calf%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Растяжка задней поверхности бедра и голени",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Накинь ремень или резинку петлёй на стопу одной ноги. Стоя, выставь эту ногу вперёд.\n\nДвижение: Согни заднюю ногу, переднюю держи прямой. Подними носок передней стопы от пола и наклонись вперёд. Потяни ремнём за верх стопы, усиливая натяжение в голени и под коленом. Удержи 10-20 секунд и поменяй ногу.\n\nКлючи: Переднюю ногу держи выпрямленной - тянется задняя поверхность бедра, носок на себя добавляет голень. Спину держи прямой, наклоняйся от таза, а не округляй поясницу. Тяни мягко, без боли.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Hamstring%20and%20Calf%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Круговые движения бедром стоя",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Встань на одной ноге, держась рукой за вертикальную опору. Подними свободное колено до 90°.\n\nДвижение: Раскрой бедро как можно шире, рисуя коленом большой круг наружу. Медленно проведи колено по кругу и верни в исходное. Сделай нужное число повторов и поменяй ногу.\n\nКлючи: Двигайся медленно и контролируй амплитуду - это разогрев и мобилизация тазобедренного сустава, а не силовое. Корпус держи ровным, не заваливайся в сторону. Опора нужна для баланса, не виси на ней.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Hip%20Circles%20technique"
        ),
        LibraryExercise(
            name: "Растяжка сгибателей бедра стоя",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Встань прямо, позвоночник вертикально, левая стопа чуть впереди правой.\n\nДвижение: Согни оба колена, оторви пятку задней ноги от пола и подай правое бедро вперёд, пока не почувствуешь натяжение по передней части бедра и в паху. Удержи положение, затем поменяй стороны.\n\nКлючи: Подбери таз и напряги ягодицу задней ноги - так растяжение точно ложится на сгибатель бедра. Не прогибай поясницу. Двигайся плавно, дыши спокойно, держи 20-30 секунд на каждую сторону.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Hip%20Flexor%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Боковая растяжка корпуса стоя",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Поставь ноги чуть шире таза, колени слегка согнуты. Правую руку положи на правое бедро для опоры спины.\n\nДвижение: Подними левую руку вертикально вверх, ладонь заведи за голову. Плавно наклони корпус вправо, тянись вбок, пока не почувствуешь натяжение по левому боку. Удержи и поменяй сторону.\n\nКлючи: Вес распределяй равномерно на обе ноги, не заваливайся в правое бедро. Тянись в длину, а не просто вниз - так раскрывается боковая линия и косые мышцы. Дыши спокойно, держи 15-20 секунд на сторону.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Lateral%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Разгибание одной рукой из-за головы на нижнем блоке",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Возьми рукоятку нижнего блока левой рукой, отвернись от тренажёра. Обеими руками подними рукоятку над головой ладонью вперёд, плечо строго вертикально. Правую ладонь положи на левый локоть для опоры.\n\nДвижение: На вдохе опусти рукоятку по дуге за голову, пока предплечье не коснётся бицепса. Плечо неподвижно, работает только предплечье. На выдохе разогни руку трицепсом в исходное.\n\nКлючи: Локоть держи у головы и строго вверх - не уводи в сторону. Свободная рука стабилизирует локоть, чтобы плечо не гуляло. Двигайся подконтрольно, без рывков. Сделай повторы и поменяй руку.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Low-Pulley%20One-Arm%20Triceps%20Extension%20technique"
        ),
        LibraryExercise(
            name: "Скручивания на блоке стоя",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Встань спиной к верхнему блоку, возьми канат обеими руками и удерживай его у верха груди над плечами. Стопы на ширине плеч, корпус слегка наклонен вперед.\n\nДвижение: Скручивай корпус вниз за счет пресса, тянись локтями к бедрам и опускай вес как можно ниже. На пике задержись на секунду, затем плавно вернись назад.\n\nКлючи: Работает именно пресс, а не руки и не вес тела - таз держи на месте, наклоняйся силой мышц живота. Выдыхай на скручивании. Не дергай канат руками, иначе нагрузка уйдет с цели.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Cable%20Crunch%20technique"
        ),
        LibraryExercise(
            name: "Растяжка камбаловидной мышцы и ахилла",
            category: .legs,
            muscleGroup: .calves,
            defaultType: .strength,
            technique: "Старт: Встань, стопы на ширине таза, одну ногу выставь чуть вперед. Пятку задней ноги прижми к полу.\n\nДвижение: Согни оба колена, опускаясь вниз и не отрывая заднюю пятку от пола. Почувствуй растяжение в нижней части голени и ахилле, задержись, потом смени ногу.\n\nКлючи: Согнутое колено смещает акцент с икроножной на камбаловидную и ахилл. Не отрывай пятку - иначе растяжка пропадает. Дыши ровно и не пружинь, просто мягко удерживай положение.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Soleus%20and%20Achilles%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Наклоны к носкам стоя",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Встань прямо, оставь немного места спереди и сзади. Ноги прямые, стопы рядом.\n\nДвижение: Наклоняйся в тазобедренных суставах, не сгибая колен, пока корпус не повиснет вниз. Руки и кисти свободно свисают к носкам. Задержись на 10-20 секунд.\n\nКлючи: Не тянись рывками - расслабь спину и шею, пусть вес корпуса сам углубляет растяжку задней поверхности бедра. Если колени сильно тянет, чуть смягчи их. Дыши спокойно, на выдохе опускайся чуть ниже.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Toe%20Touches%20technique"
        ),
        LibraryExercise(
            name: "Бросок мяча из-за головы стоя",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Встань, стопы на ширине плеч, медбол в обеих руках. Заведи мяч глубоко за голову, слегка согни колени и отклонись назад.\n\nДвижение: Мощно выбрось мяч вперед, складываясь в тазе и подключая все тело - ноги, корпус, руки в одно движение. Бросай в стену или партнеру и лови мяч на отскоке.\n\nКлючи: Сила идет от бедер и корпуса, а не только от рук - представь, что хлещешь телом, как кнутом. Не теряй равновесие назад на замахе. Резкий выдох в момент броска добавит мощности.",
            videoUrl: "https://www.youtube.com/results?search_query=Standing%20Two-Arm%20Overhead%20Throw%20technique"
        ),
        LibraryExercise(
            name: "Зашагивание с подъемом колена",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Встань лицом к тумбе или скамье подходящей высоты, стопы вместе. Это исходное положение.\n\nДвижение: Поставь левую стопу на тумбу и поднимись, разгибая бедро и колено опорной ноги. На самом верху подними правое колено как можно выше. Спустись по той же траектории и повтори с другой ноги.\n\nКлючи: Толкайся через пятку рабочей ноги, не отталкивайся задней - так нагрузка идет в ягодицу и квадрицепс. Подъем колена держи контролируемым, не закидывай инерцией. Колено не заваливай внутрь.",
            videoUrl: "https://www.youtube.com/results?search_query=Step-Up%20with%20Knee%20Raise%20technique"
        ),
        LibraryExercise(
            name: "Становая на прямых ногах",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Возьми штангу хватом сверху, ладони к себе. Встань прямо, ноги на ширине плеч или уже, колени чуть согнуты и зафиксированы. Это исходное положение.\n\nДвижение: Не меняя угол в коленях, опускай штангу вдоль ног, сгибаясь в тазобедренных суставах. Спина прямая, таз уходит назад, пока не почувствуешь растяжение бицепса бедра. Затем разгибай бедра и поднимай корпус назад.\n\nКлючи: Колени держи стационарными - движение идет из таза, не из поясницы. Спину не круглить ни секунды. Вдох на опускании, выдох на подъеме. Гриф ведешь близко к ногам.",
            videoUrl: "https://www.youtube.com/results?search_query=Stiff-Legged%20Barbell%20Deadlift%20technique"
        ),
        LibraryExercise(
            name: "Супермен",
            category: .back,
            muscleGroup: .lowerBack,
            defaultType: .strength,
            technique: "Старт: Ляг на живот на пол или коврик, тело вытянуто в линию. Руки полностью вытянуты вперед. Это исходное положение.\n\nДвижение: Одновременно оторви от пола руки, ноги и грудь и задержись в этом положении на 2 секунды. Сожми поясницу для лучшего эффекта. Затем медленно опусти все обратно.\n\nКлючи: Тяни усилие из поясницы и ягодиц, а не из шеи - взгляд вниз, шею не запрокидывай. Выдыхай на подъеме, вдыхай на опускании. Не поднимайся рывком, важна короткая удерживаемая пауза наверху.",
            videoUrl: "https://www.youtube.com/results?search_query=Superman%20technique"
        ),
        LibraryExercise(
            name: "Бросок мяча от груди лежа",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, колени согнуты, стопы на полу. Возьми медбол обеими руками снизу и держи у груди.\n\nДвижение: Взрывным движением выжми мяч строго вверх над собой, полностью разгибая локти, и подбрось его как можно выше. Поймай обеими руками на спуске и сразу повтори.\n\nКлючи: Толчок идет от груди и трицепсов, мяч летит ровно вверх - не уводи его в сторону, иначе поймать сложно. Резкий выдох в момент выжима. Лови мяч мягко, амортизируя руками, чтобы не отбить грудь.",
            videoUrl: "https://www.youtube.com/results?search_query=Supine%20Chest%20Throw%20technique"
        ),
        LibraryExercise(
            name: "Фоллаут на TRX",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Отрегулируй петли так, чтобы рукоятки были ниже уровня пояса. Возьми их в руки и наклонись вперед в положение наклонного отжимания. Это исходное положение.\n\nДвижение: Держа руки прямыми, наклоняйся дальше в петли, опуская тело к полу и выводя прямые руки вверх и за голову. Из крайней точки вернись назад в исходное.\n\nКлючи: Двигаются только плечи - корпус остается жесткой прямой линией, поясница не провисает. Держи пресс в напряжении весь подход, иначе прогнешься в спине. Не уходи дальше, чем можешь контролировать.",
            videoUrl: "https://www.youtube.com/results?search_query=Suspension%20Trainer%20Fallout%20technique"
        ),
        LibraryExercise(
            name: "Отжимания на TRX",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Надежно закрепи петли на верху стойки. Возьми по рукоятке в каждую руку и встань в планку для отжиманий. Руки полностью выпрямлены, тело максимально близко к параллели с полом, осанка ровная.\n\nДвижение: Держа корпус жестким и прямым, медленно опускайся, сгибая локти. Опускайся, пока локти не пройдут 90 градусов, сделай паузу и выжмись обратно в исходное.\n\nКлючи: Нестабильные петли заставляют пресс и плечи работать на стабилизацию - держи тело одной линией, без провиса таза. Локти не разводи широко в стороны. Опускайся подконтрольно, без падения.",
            videoUrl: "https://www.youtube.com/results?search_query=Suspension%20Trainer%20Push-Up%20technique"
        ),
        LibraryExercise(
            name: "Обратные скручивания на TRX",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Закрепи петли так, чтобы рукоятки висели примерно в 30 см от пола. Встань в планку для отжиманий спиной к стойке и вставь стопы в петли. Корпус прямой, таз не провисает. Это исходное положение.\n\nДвижение: Согни колени и бедра, подтягивая колени к корпусу. В этот момент подкручивай таз вперед, позволяя позвоночнику сгибаться. В верхней точке подконтрольно вернись назад.\n\nКлючи: Скручивай именно пресс, а не просто подтягивай ноги - подкрутка таза включает нижнюю часть живота. Двигайся плавно, петли любят раскачку. В исходном не давай тазу провалиться вниз.",
            videoUrl: "https://www.youtube.com/results?search_query=Suspension%20Trainer%20Reverse%20Crunch%20technique"
        ),
        LibraryExercise(
            name: "Сплит-присед на TRX",
            category: .legs,
            muscleGroup: .quadriceps,
            defaultType: .strength,
            technique: "Старт: Закрепи петли так, чтобы рукоятки были в 45-75 см от пола. Стоя спиной к креплению, вставь заднюю стопу в петлю позади себя. Голову держи прямо, грудь раскрыта, переднее колено слегка согнуто. Это исходное положение.\n\nДвижение: Опускайся вниз, сгибая колено и бедро передней ноги, до глубокого приседа. Вес держи на пятке опорной стопы, осанку сохраняй. Из нижней точки разгибай бедро и колено и вернись наверх.\n\nКлючи: Вес на пятке передней ноги, не на носке - так грузишь квадрицепс и ягодицу, а не колено. Колено не выводи за носок и не заваливай внутрь. Корпус держи вертикально, не падай вперед.",
            videoUrl: "https://www.youtube.com/results?search_query=Suspension%20Trainer%20Split%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Растяжка в широком седе",
            category: .legs,
            muscleGroup: .hamstrings,
            defaultType: .strength,
            technique: "Старт: Сядь прямо на пол и разведи прямые ноги в стороны буквой V. Спина ровная.\n\nДвижение: Поставь руки на пол перед собой и наклоняйся вперед как можно дальше, ведя корпус между ног. Задержись на 10-20 секунд, дыша ровно.\n\nКлючи: Тянись от таза, удлиняя спину, а не скругляя ее - так растягиваются приводящие и задняя поверхность бедра. Не пружинь и не тянись через резкую боль. С каждым выдохом мягко уходи чуть дальше.",
            videoUrl: "https://www.youtube.com/results?search_query=Seated%20Straddle%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Становая тяга с трэп-грифом",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Загрузи трэп-гриф (он же гекс-гриф) подходящим весом, он стоит на полу. Встань в центр рамы и возьмись за обе рукоятки. Опусти таз, смотри вперед, грудь раскрыта.\n\nДвижение: Толкайся через пятки и разгибай бедра и колени, поднимая гриф вверх. Не округляй спину ни на одном участке. В верхней точке выпрямись, затем подконтрольно опусти вес обратно на пол.\n\nКлючи: Трэп-гриф ставит руки по бокам, нагрузка идет ровнее в позвоночник, чем в классике - используй это, держа корпус жестким. Толчок именно от ног, а не рывок спиной. Вдох перед подъемом, выдох наверху.",
            videoUrl: "https://www.youtube.com/results?search_query=Trap%20Bar%20Deadlift%20technique"
        ),
        LibraryExercise(
            name: "Разгибание на трицепс из-за головы с канатом",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Закрепи канат на нижнем блоке, возьми его обеими руками и встань спиной к тренажеру. Заведи руки за голову, локти смотрят строго вверх и согнуты. Поставь ноги в разножку и слегка наклонись вперед для устойчивости. Это исходное положение.\n\nДвижение: Разгибай руки в локтях, удерживая плечи на месте, и поднимай кисти над головой. Сожми трицепс наверху, затем медленно верни вес в исходное.\n\nКлючи: Двигаются только предплечья - локти зафиксированы и направлены вверх, не разводи их в стороны. Не помогай корпусом и спиной. Полное разгибание наверху и контролируемый негатив дают максимум трицепсу.",
            videoUrl: "https://www.youtube.com/results?search_query=Overhead%20Rope%20Triceps%20Extension%20technique"
        ),
        LibraryExercise(
            name: "Сгибания на скамье Скотта с гантелями",
            category: .arms,
            muscleGroup: .biceps,
            defaultType: .strength,
            technique: "Старт: Сядь за парту Скотта, плечи плотно лежат на наклонной подушке, в каждой руке гантель на уровне плеч.\n\nДвижение: На вдохе медленно опусти гантели, пока руки полностью не выпрямятся и бицепс не растянется. На выдохе согни руки, поднимая вес к плечам силой бицепса.\n\nКлючи: В верхней точке задержись на секунду и сильно сожми бицепс. Локти не отрывай от подушки, не бросай вес вниз - именно негатив дает рост. Без рывков корпусом.",
            videoUrl: "https://www.youtube.com/results?search_query=Two-Arm%20Dumbbell%20Preacher%20Curl%20technique"
        ),
        LibraryExercise(
            name: "Взятие двух гирь на грудь",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Поставь две гири между стоп, отведи таз назад, спина прямая, взгляд вперед.\n\nДвижение: Резко разогни ноги и таз и подними гири к плечам, по ходу проворачивая кисти так, чтобы гири легли на предплечья. Опусти обратно и повтори.\n\nКлючи: Силу дают ноги и таз, а не руки - гири как бы выстреливают вверх. Прими их мягко, без удара по предплечью. Спина все время прямая, кор в напряжении.",
            videoUrl: "https://www.youtube.com/results?search_query=Two-Arm%20Kettlebell%20Clean%20technique"
        ),
        LibraryExercise(
            name: "Жим двух гирь стоя",
            category: .shoulders,
            muscleGroup: .frontDelts,
            defaultType: .strength,
            technique: "Старт: Возьми две гири на грудь, кисти проверни ладонями вперед, гири у плеч на предплечьях. Стой прямо, ноги на ширине плеч.\n\nДвижение: Выжми гири вверх и чуть в стороны. Когда снаряды проходят голову, слегка подайся под них корпусом, чтобы они зафиксировались над головой.\n\nКлючи: Напряги широчайшие, ягодицы и живот - это держит корпус жестким и бережет поясницу. Жми строго силой плеч, без подсаживания ногами. Не прогибайся в пояснице.",
            videoUrl: "https://www.youtube.com/results?search_query=Two-Arm%20Kettlebell%20Military%20Press%20technique"
        ),
        LibraryExercise(
            name: "Тяга двух гирь в наклоне",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Поставь две гири перед стопами. Чуть согни колени, отведи таз назад и наклонись вперед со спиной прямой - это исходное положение.\n\nДвижение: Возьми обе гири и подтяни их к животу, сводя лопатки и сгибая локти. Опусти и повтори.\n\nКлючи: Тяни локтями вдоль корпуса, а не кистями - так включается спина, а не руки. Спина все время ровная, без округления в пояснице. В верхней точке сведи лопатки.",
            videoUrl: "https://www.youtube.com/results?search_query=Two-Arm%20Kettlebell%20Row%20technique"
        ),
        LibraryExercise(
            name: "Растяжка верха спины",
            category: .back,
            muscleGroup: .trapezius,
            defaultType: .strength,
            technique: "Старт: Встань ровно, сцепи пальцы в замок перед собой большими пальцами вниз.\n\nДвижение: Округли спину, вытягивая руки вперед как можно дальше, словно отталкиваешь что-то от себя. Почувствуй растяжение между лопатками.\n\nКлючи: Тянись плавно, без рывков, дыши спокойно и удерживай позу. Старайся именно раскрыть верх спины, а не просто отвести руки. Подбородок слегка опусти к груди.",
            videoUrl: "https://www.youtube.com/results?search_query=Upper%20Back%20Stretch%20technique"
        ),
        LibraryExercise(
            name: "Тяга к подбородку на блоке",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Возьми прямую рукоять нижнего блока хватом сверху чуть уже плеч, ладони к бедрам. Руки выпрямлены с легким сгибом в локтях, спина прямая, рукоять у бедер.\n\nДвижение: На выдохе подними рукоять вдоль тела к подбородку, ведя движение локтями. Локти все время выше предплечий. В верхней точке задержись на секунду.\n\nКлючи: Тяни локтями, а не кистями - так работают средние дельты. Корпус неподвижен, без раскачки. Не задирай рукоять выше подбородка, чтобы не зажимать плечевой сустав.",
            videoUrl: "https://www.youtube.com/results?search_query=Upright%20Cable%20Row%20technique"
        ),
        LibraryExercise(
            name: "Тяга к подбородку с резиной",
            category: .shoulders,
            muscleGroup: .sideDelts,
            defaultType: .strength,
            technique: "Старт: Встань на резину так, чтобы натяжение начиналось на прямых руках. Возьми рукояти хватом сверху чуть уже плеч, ладони к бедрам, руки выпрямлены с легким сгибом, спина прямая.\n\nДвижение: На выдохе подними рукояти вдоль тела к подбородку, ведя локтями. Локти все время выше предплечий, в верхней точке пауза на секунду.\n\nКлючи: Движение ведут локти, а не кисти - тогда грузятся средние дельты. Корпус держи неподвижно. Не тяни выше подбородка, чтобы не перегружать плечо.",
            videoUrl: "https://www.youtube.com/results?search_query=Upright%20Row%20-%20With%20Bands%20technique"
        ),
        LibraryExercise(
            name: "Тяга верхнего блока нейтральным хватом (V-рукоять)",
            category: .back,
            muscleGroup: .lats,
            defaultType: .strength,
            technique: "Старт: Сядь в тренажер, закрепи V-рукоять на верхнем блоке и заведи бедра под валики. Возьми рукоять нейтральным хватом ладонями друг к другу, грудь вперед, корпус отклони назад примерно на 30°.\n\nДвижение: Силой широчайших тяни рукоять вниз, сводя лопатки, пока она почти не коснется груди. На выдохе. Задержись на секунду и плавно верни вверх на вдохе.\n\nКлючи: Тяни спиной, а не руками - локти идут вниз и назад. Корпус держи неподвижным, без раскачки. Вверху дай широчайшим полностью растянуться.",
            videoUrl: "https://www.youtube.com/results?search_query=V-Bar%20Pulldown%20technique"
        ),
        LibraryExercise(
            name: "Гиперэкстензия на фитболе с весом",
            category: .back,
            muscleGroup: .lowerBack,
            defaultType: .strength,
            technique: "Старт: Ляг животом на фитбол так, чтобы корпус был параллелен полу, носки упри в пол для равновесия. Возьми блин под подбородок или за шею.\n\nДвижение: Медленно подними корпус вверх, разгибаясь в пояснице, на выдохе. Задержи сокращение на секунду и на вдохе плавно опустись обратно.\n\nКлючи: Поднимайся за счет поясницы, не дергай шеей и не перегибайся назад - двигайся только до прямой линии тела. Носки держат баланс. Контролируй мяч, чтобы он не уехал.",
            videoUrl: "https://www.youtube.com/results?search_query=Weighted%20Ball%20Hyperextension%20technique"
        ),
        LibraryExercise(
            name: "Обратные отжимания от скамьи с весом",
            category: .arms,
            muscleGroup: .triceps,
            defaultType: .strength,
            technique: "Старт: Поставь две скамьи параллельно. Обопрись руками о край ближней на ширине плеч, руки прямые, пятки на дальней скамье, ноги параллельны полу. Партнер кладет гантель тебе на бедра.\n\nДвижение: На вдохе медленно опустись, сгибая локти, чуть ниже угла в 90°. На выдохе выжми себя вверх силой трицепса в исходное положение.\n\nКлючи: Локти держи близко к телу, направлены назад - так грузится трицепс, а не плечи. Вес на бедра кладет партнер, иначе можно травмироваться. Не проваливайся слишком низко.",
            videoUrl: "https://www.youtube.com/results?search_query=Weighted%20Bench%20Dip%20technique"
        ),
        LibraryExercise(
            name: "Скручивания с отягощением",
            category: .core,
            muscleGroup: .core,
            defaultType: .strength,
            technique: "Старт: Ляг на спину, стопы на полу или на скамье, колени согнуты под 90°. Прижми вес к груди или держи его на прямых руках над собой.\n\nДвижение: На выдохе медленно скрути корпус, отрывая лопатки от пола примерно на 10 см, поясница остается прижатой. В верхней точке сожми пресс на пару секунд.\n\nКлючи: Работает только пресс - не тяни себя руками за голову и не отрывай поясницу. Двигайся медленно и контролируй опускание на вдохе. Подбородок не прижимай к груди.",
            videoUrl: "https://www.youtube.com/results?search_query=Weighted%20Crunches%20technique"
        ),
        LibraryExercise(
            name: "Жим штанги широким хватом",
            category: .chest,
            muscleGroup: .middleChest,
            defaultType: .strength,
            technique: "Старт: Ляг на горизонтальную скамью, стопы плотно на полу. Возьми штангу хватом сверху примерно на 8 см шире плеч с каждой стороны, сними со стоек и держи на прямых руках над собой.\n\nДвижение: На вдохе медленно опусти штангу до касания середины груди. После секундной паузы на выдохе мощно выжми вверх грудью, в верхней точке сожми грудные.\n\nКлючи: Опускай вдвое дольше, чем поднимаешь - негатив дает результат. Широкий хват сильнее грузит грудь, но береги плечи: не разводи локти слишком сильно. Лопатки сведены, не отрывай таз от скамьи.",
            videoUrl: "https://www.youtube.com/results?search_query=Wide-Grip%20Barbell%20Bench%20Press%20technique"
        ),
        LibraryExercise(
            name: "Приседания с широкой постановкой ног",
            category: .legs,
            muscleGroup: .glutes,
            defaultType: .strength,
            technique: "Старт: Установи штангу в стойке на нужной высоте. Подсядь под гриф, положи его на верх спины чуть ниже шеи, сними со стоек, разогнув ноги и корпус.\n\nДвижение: Сделай шаг назад, поставь ноги шире плеч, носки чуть наружу. На вдохе медленно опускайся, сгибая колени, пока бедра не уйдут чуть ниже параллели. На выдохе встань, толкаясь пятками.\n\nКлючи: Колени идут в сторону носков и не выходят за их линию, иначе перегружается сустав. Спина прямая, голова поднята - взгляд вниз сбивает баланс. Широкая стойка сильнее включает ягодицы.",
            videoUrl: "https://www.youtube.com/results?search_query=Wide-Stance%20Barbell%20Squat%20technique"
        ),
        LibraryExercise(
            name: "Прогулка с ярмом",
            category: .complex,
            muscleGroup: .fullBody,
            defaultType: .strength,
            technique: "Старт: Заведи ярмо на верх спины, как штангу. Голова смотрит вперед, спина прогнута, сними вес с упоров, проталкиваясь пятками.\n\nДвижение: Иди вперед как можно быстрее частыми короткими шагами. Можно придерживать боковые стойки ярма, чтобы оно не раскачивалось. Пройди заданную дистанцию, обычно 23-30 метров.\n\nКлючи: Корпус держи жестким и напряженным - кор не отпускай ни на секунду. Шаги короткие и частые, без широких выпадов, иначе вес начнет качаться. Дыши ровно, не задерживай дыхание на всю дистанцию.",
            videoUrl: "https://www.youtube.com/results?search_query=Yoke%20Walk%20technique"
        ),
    ]
}
