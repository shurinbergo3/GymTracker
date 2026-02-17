//
//  HormonesView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct HormonesView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // 1. Header & Theory Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        Text("Гормонально-нейромедиаторная теория".localized())
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Общие законы управления".localized())
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        TheoryBlock(
                            title: "Движение — основа всего",
                            content: "Необходим базовый уровень движения на ногах (6–10 км ходьбы, 50–100 приседаний), чтобы обеспечить логистику (крово- и лимфоток). Без этого гормоны просто не дойдут до рецепторов."
                        )
                        
                        TheoryBlock(
                            title: "Чувствительность важнее количества",
                            content: "Выгоднее повышать чувствительность рецепторов, чем наращивать выработку гормонов. Постоянная высокая выработка «выжигает» рецепторы (кроме кортизола)."
                        )
                        
                        TheoryBlock(
                            title: "Восстановление через воздержание",
                            content: "Чувствительность рецепторов восстанавливается только при длительном отсутствии взаимодействия с гормоном."
                        )
                        
                        TheoryBlock(
                            title: "Срок адаптации — 2 недели",
                            content: "Мозг регистрирует изменения образа жизни и начинает адаптироваться только через 14–16 дней. Всё, что меньше — считается случайной флуктуацией."
                        )
                        
                        TheoryBlock(
                            title: "Ловушка привыкания",
                            content: "Организм привыкает к неестественно высоким пикам (наркотики, абуз тела) и начинает воспринимать норму как недостаток. Механизмов быстрого «отвыкания» нет, восстановление может занять годы."
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // 2. Hormones List
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(HormoneRepository.hormones) { hormone in
                            HormoneCard(data: hormone)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // 3. Axiomatics Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        Text("Аксиоматика (Базовые принципы)".localized())
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            AxiomBlock(title: "Мозг не отличает реальность от вымысла", content: "Фильм ужасов вызывает реальный гормональный отклик. Этим можно пользоваться для самопрограммирования (аутотренинг).")
                            AxiomBlock(title: "Понимаемое ≠ Ощущаемое", content: "Знание того, что опасности нет, не останавливает выброс гормонов. Нужно работать с ощущениями, а не словами.")
                            AxiomBlock(title: "Зеркальные нейроны", content: "Мы становимся теми, за кем наблюдаем.")
                            AxiomBlock(title: "Гомеостаз", content: "Организм стремится сохранить привычное состояние, даже если оно плохое. Сперва вы работаете на гомеостаз, потом он на вас.")
                            AxiomBlock(title: "Все элементы связаны", content: "Нельзя починить только один гормон, нужно менять систему целиком.")
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Справочник".localized())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Components

struct TheoryBlock: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.localized())
                .font(DesignSystem.Typography.subheadline())
                .foregroundColor(DesignSystem.Colors.primaryText)
                .bold()
            
            Text(content.localized())
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct AxiomBlock: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 4) {
                Text("•")
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.accent)
                Text(title.localized())
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            
            Text(content.localized())
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.leading, DesignSystem.Spacing.md)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct HormoneCard: View {
    let data: HormoneData
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Button
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.name.localized())
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(data.color)
                        
                        Text(data.subtitle.localized())
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground)
            }
            
            // Content
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Essence/Metaphysics/Physics
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        if let meta = data.metaphysics {
                            DescriptionRow(title: "Метафизика".localized(), content: meta, icon: "sparkles")
                        }
                        if let phys = data.physics {
                            DescriptionRow(title: "Физика".localized(), content: phys, icon: "atom")
                        }
                        if let essence = data.essence {
                            DescriptionRow(title: "Суть".localized(), content: essence, icon: "info.circle")
                        }
                    }
                    
                    // Levels
                    if let high = data.highLevel {
                        DescriptionRow(title: "Высокий уровень".localized(), content: high, icon: "arrow.up.circle.fill", titleColor: .green)
                    }
                    
                    if let low = data.lowLevel {
                        DescriptionRow(title: "Низкий уровень".localized(), content: low, icon: "arrow.down.circle.fill", titleColor: .red)
                    }
                    
                    // Normalization
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.blue)
                            Text("Как нормализовать:".localized())
                                .font(.caption).bold()
                                .foregroundColor(.blue)
                        }
                        
                        if let normPhys = data.normalizePhysics {
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                (Text("Физика".localized()) + Text(": ") + Text(normPhys.localized()))
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        if let normPsych = data.normalizePsyche {
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                (Text("Психика".localized()) + Text(": ") + Text(normPsych.localized()))
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        if let normSoc = data.normalizeSocial {
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                (Text("Социум".localized()) + Text(": ") + Text(normSoc.localized()))
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        if let normGen = data.generalNormalization {
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                Text(normGen.localized())
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground.opacity(0.5))
            }
        }
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(isExpanded ? data.color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct DescriptionRow: View {
    let title: String
    let content: String
    let icon: String
    var titleColor: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title.localized(), systemImage: icon)
                .font(.caption).bold()
                .foregroundColor(titleColor ?? DesignSystem.Colors.primaryText)
            
            Text(content.localized())
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Data Models

struct HormoneData: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let color: Color
    var metaphysics: String? = nil
    var physics: String? = nil
    var essence: String? = nil
    var highLevel: String? = nil
    var lowLevel: String? = nil
    var normalizePhysics: String? = nil
    var normalizePsyche: String? = nil
    var normalizeSocial: String? = nil
    var generalNormalization: String? = nil
}

struct HormoneRepository {
    static let hormones: [HormoneData] = [
        HormoneData(
            name: "1. ТЕСТОСТЕРОН",
            subtitle: "Гормон победы и права",
            color: .red,
            metaphysics: "Выделяется в ответ на преодоление посильной агрессивной среды. Это коридор, где борьба напряженная, но победа возможна.",
            physics: "Регулирует интеллект (пространственное мышление), настроение (мужской антидепрессант), крепость костей и мышц.",
            highLevel: "Спокойная уверенность, фокус на себе и своей территории, антирефлексия, желание действовать.",
            lowLevel: "Робость, вялость, одутловатость, желание спрятаться от проблем.",
            normalizePhysics: "Сон (главный сброс стресса), контроль сексуальной энергии (эякуляция снижает тестостерон и повышает пролактин), много движения для разгона лимфы.",
            normalizePsyche: "Победы. Постоянно ставить планку и брать её. Фокус на том, что можно победить, игнорирование того, что вне контроля (новости).",
            normalizeSocial: "Вести себя как лидер (расправленные плечи, взгляд вверх). Занимать место в пространстве."
        ),
        HormoneData(
            name: "2. КОРТИЗОЛ",
            subtitle: "Ресурс выживания",
            color: .orange,
            metaphysics: "Саморазрушительный допинг. Выделяется, когда не хватает ресурсов для борьбы, разлагая ткани тела ради энергии.",
            physics: "Влияет на состояние тканей, молодость. Хронический избыток делает тело дряблым.",
            highLevel: "Раздражительность, ожидание проблем («ничего не делаю, пока не клюнет»), тревожный сон или сонливость, падение потребностей до уровня выживания.",
            lowLevel: "Бодрость, здоровье, отсутствие груза прошлых ошибок.",
            normalizePhysics: "Сон, восстановление сахарного обмена. Холостое жевание (смола, забрус) — организм воспринимает это как гарантию еды и успокаивается.",
            normalizePsyche: "Аутотренинг («я выжил в худших ситуациях»), вера в судьбу/бога. Исключить поражение из картины мира.",
            normalizeSocial: "Здоровое окружение, поддержка близких (антистресс-система)."
        ),
        HormoneData(
            name: "3. СЕРОТОНИН",
            subtitle: "Оптимизм и безопасность",
            color: .yellow,
            metaphysics: "Ощущение социальной справедливости, «мир ко мне добр». Тихая радость.",
            physics: "Регулирует пищеварение, циклы сна.",
            highLevel: "Безмятежность, «завтра будет лучше, чем вчера», способность к самоограничению ради будущего.",
            lowLevel: "«Кругом враги», депрессивность, рабство страстей, невозможность отказать себе во вредном.",
            normalizePhysics: "Солнечный свет, здоровье кишечника (там синтезируется серотонин), отказ от алкоголя/синтетической еды. Контролируемая гипоксия (горы, задержки дыхания).",
            normalizePsyche: "Принять мир как нейтральный, убрать враждебную реакцию.",
            normalizeSocial: "Много общения. Каждое удачное взаимодействие подтверждает, что стая вас принимает."
        ),
        HormoneData(
            name: "4. МЕЛАТОНИН",
            subtitle: "Восстановление",
            color: .purple,
            essence: "Гормон молодости и отдыха. Превращает накопленный за день серотонин в восстановление.",
            generalNormalization: "Полная темнота, отказ от гаджетов и еды после 18:00 (или задолго до сна), прохлада, тяжелое одеяло."
        ),
        HormoneData(
            name: "5. ПРОЛАКТИН",
            subtitle: "Покорность и жертвенность",
            color: .blue,
            metaphysics: "Гормон подчинения и самопожертвования. Снижает тестостерон, чтобы избежать смертельной схватки.",
            highLevel: "Состояние «тряпки», невозможность отказать, самобичевание, готовность подчиняться ради избегания конфликта.",
            lowLevel: "Бескомпромиссность, четкость действий («подумал — сделал»).",
            normalizePhysics: "Воздержание (секс повышает пролактин), качественный сон.",
            normalizePsyche: "Не вестись на «пожалейку», блокировать попытки вызвать жалость.",
            normalizeSocial: "Общение с сильными, жесткими мужчинами, избегание нытиков."
        ),
        HormoneData(
            name: "6. ЭСТРАДИОЛ",
            subtitle: "Эмоции и пластика",
            color: .mint,
            metaphysics: "Демонстрация эмоций, артистизм. Нужен для пиковых «взрывных» усилий.",
            physics: "Женский тип фигуры, отечность при избытке.",
            highLevel: "Истеричность, манерность, обидчивость, много лишних движений и слов.",
            lowLevel: "Хладнокровие шахматиста, отсутствие лишнего жира и воды.",
            normalizePhysics: "Капуста (крестоцветные), цитрусовые (лимонный сок), цинк, снижение процента жира (жир ароматизирует тестостерон в эстрадиол), бритье головы.",
            normalizePsyche: "Давать выход эмоциям (петь, танцевать, плакать), не запирать их в себе.",
            normalizeSocial: "Быть там, где можно быть собой и не нужно притворяться."
        ),
        HormoneData(
            name: "7. ОКСИТОЦИН",
            subtitle: "Свои и чужие",
            color: .pink,
            essence: "Инкорпорация в ближний круг. Делит мир на «мы» и «они». Без него — чувство одиночества и гибели.",
            generalNormalization: "Тактильный контакт, доверительные разговоры, создание глубоких связей (\"своей стаи\")."
        ),
        HormoneData(
            name: "8. АДРЕНАЛИН",
            subtitle: "Страх и бегство",
            color: .red,
            metaphysics: "Реакция «Беги». Страх, тревога, суета.",
            highLevel: "Тремор, суета, невозможность сфокусироваться, желание убежать «куда глаза глядят».",
            lowLevel: "Полный контроль, бесстрашие.",
            normalizePhysics: "Реальное движение с изменением картинки перед глазами (бег, авто, велик). Продрагивание телом (стряхнуть стресс).",
            normalizePsyche: "Рационализация («Где хищник?»). Разрушение иллюзии опасности.",
            normalizeSocial: "Отключить уведомления, убрать токсичных паникеров из окружения."
        ),
        HormoneData(
            name: "9. НОРАДРЕНАЛИН",
            subtitle: "Ярость и охота",
            color: .green,
            metaphysics: "Реакция «Бей». Ярость, фокус охотника, состояние потока.",
            highLevel: "Глубокое спокойствие, азарт, четкость мыслей, отсутствие мандража.",
            lowLevel: "Дефицит внимания (СДВГ), скука, поиск дешевого дофамина.",
            normalizePhysics: "L-Тирозин (сырье), отказ от кофеина (он истощает систему). Тренировка концентрации (смотреть в точку).",
            normalizeSocial: "Утверждения «Я могу, я достоин, я беру». Защита своих границ."
        ),
        HormoneData(
            name: "10. ДОФАМИН",
            subtitle: "Предвкушение",
            color: .cyan,
            metaphysics: "Мотивация, поисковый инстинкт. Обещание награды.",
            highLevel: "Любопытство, драйв, желание исследовать.",
            lowLevel: "Скука, жизнь от дозы до дозы (игры, соцсети), отсутствие интереса.",
            normalizePhysics: "Микродвижения (разминка пальцев) для запуска. Тирозин.",
            normalizePsyche: "Отказ от пассивного потребления контента. Развлекать себя самому активными действиями."
        )
    ]
}

#Preview {
    NavigationView {
        HormonesView()
    }
}
