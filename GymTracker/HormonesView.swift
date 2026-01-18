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
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    Text("Гормоны и нейромедиаторы")
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.md)
                    
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Тестостерон
                        HormoneCard(
                            name: "ТЕСТОСТЕРОН",
                            subtitle: "Мужитское состояние",
                            color: .red,
                            highLevel: "Тестостерон ощущается как уверенность в себе, внушение уважения к себе окружающим.",
                            lowLevel: "Неуверенность в себе, робость, стеснительность, неверие в позитивный исход жизни, в свои силы. Общая вялость во всем.",
                            relations: "Обратно связан с кортизолом и пролактином, растет с дофамином, норадреналином и серотонином, снижается с ростом адреналина, и снижается при высоких значениях окситоцина."
                        )
                        
                        // Кортизол
                        HormoneCard(
                            name: "КОРТИЗОЛ",
                            subtitle: "Стресс",
                            color: .orange,
                            highLevel: "Человек нервный, раздражительный, злобный.",
                            lowLevel: "Человек чувствует себя замечательно, бодро.",
                            relations: "Рост сопровождается с пролактином и адреналином. Снижается вместе с серотонином, мелатонином, окситоцином и тестостероном."
                        )
                        
                        // Серотонин
                        HormoneCard(
                            name: "СЕРОТОНИН",
                            subtitle: "Оптимизм",
                            color: .yellow,
                            highLevel: "Спокойствие, безмятежность, удовлетворение жизнью.",
                            lowLevel: "Возникает беспокойство, трудно начать активную здоровую деятельность, долго работать над одним проектом, не отвлекаться, не бросать на полпути. Трудно отказаться от искушений.",
                            relations: "Зависит от окситоцина, немного от кортизола и тестостерона."
                        )
                        
                        // Окситоцин
                        HormoneCard(
                            name: "ОКСИТОЦИН",
                            subtitle: "Привязанность",
                            color: .pink,
                            highLevel: "Божественное единение. Единый разум с близкими, понимание с полуслова.",
                            lowLevel: "Ругаетесь, не понимаете друг друга; небезопасность, угнетенность, недоверчивость, поиск подвоха.",
                            relations: "Связь с серотонином: при низком окситоцине практически гарантирован низкий серотонин."
                        )
                        
                        // Мелатонин
                        HormoneCard(
                            name: "МЕЛАТОНИН",
                            subtitle: "Отдых, расслабление",
                            color: .purple,
                            highLevel: "Глубокий сон, быстрое пробуждение полностью отдохнувшим.",
                            lowLevel: "Сон поверхностный, не восстанавливающий, разбитость, вечером настроение падает, склонность к бесплодным рефлексиям.",
                            relations: "Связан с накопленным за день серотонином и окситоцином. Снижается с кортизолом и адреналином."
                        )
                        
                        // Пролактин
                        HormoneCard(
                            name: "ПРОЛАКТИН",
                            subtitle: "Социальное подчинение",
                            color: .blue,
                            highLevel: "Беззащитность, состояние «тряпки», рефлексия, самообвинение. Готовность подчиняться без согласия.",
                            lowLevel: "Бескомпромиссность. Подумал – сделал. Готовность уживаться только с приятными людьми.",
                            relations: "Обратно связан с тестостероном и дофамином. Растет с кортизолом, коррелирует с эстрадиолом."
                        )
                        
                        // Эстрадиол
                        HormoneCard(
                            name: "ЭСТРАДИОЛ",
                            subtitle: "Эмоции и импульс",
                            color: .mint,
                            highLevel: "Психованность, манерность, истероидность, эгоцентризм, вспышки ярости, гнева и обиды.",
                            lowLevel: "Ровное настроение. Нет лишних мыслей и эмоций, хладнокровие. Отсутствует избыточная мимика.",
                            relations: "Рост коррелирует с пролактином, меньше проявляется при перекосе в адреналин и глутамат."
                        )
                        
                        // Адреналин
                        HormoneCard(
                            name: "АДРЕНАЛИН",
                            subtitle: "Беги, остановись или бей",
                            color: .red,
                            highLevel: "Неспособность сфокусироваться, тревожность, дерганность, мнительность, страх.",
                            lowLevel: "Полный контроль, эмоциональная собранность, концентрация, бесстрашие, стрессоустойчивость.",
                            relations: "Меньше вырабатывается при высоком тестостероне и низком кортизоле."
                        )
                        
                        // Норадреналин
                        HormoneCard(
                            name: "НОРАДРЕНАЛИН",
                            subtitle: "Охота и ярость",
                            color: .green,
                            highLevel: "Глубокое спокойствие, сфокусированность, состояние потока, азарт. Отсутствие мандража.",
                            lowLevel: "Дефицит внимания, невозможность сфокусироваться, скука, поиск легкого дофамина.",
                            relations: "Реализует программу «Бей», ответное наступление на опасность."
                        )
                        
                        // Дофамин
                        HormoneCard(
                            name: "ДОФАМИН",
                            subtitle: "Предвкушение и интерес",
                            color: .cyan,
                            highLevel: "Все хочется, все интересно, все любопытно, жизнь играет красками.",
                            lowLevel: "Жизнь не интересна, ничего не хочется, поиск только привычных стимуляторов.",
                            relations: "Привязка к предвосхищаемым действиям, поисковый инстинкт."
                        )
                        
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Гормоны")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HormoneCard: View {
    let name: String
    let subtitle: String
    let color: Color
    let highLevel: String
    let lowLevel: String
    let relations: String
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Button
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(color)
                        
                        Text(subtitle)
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
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Divider().background(Color.gray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Высокий уровень:", systemImage: "arrow.up.circle.fill")
                            .font(.caption).bold()
                            .foregroundColor(.green)
                        Text(highLevel)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Низкий уровень:", systemImage: "arrow.down.circle.fill")
                            .font(.caption).bold()
                            .foregroundColor(.red)
                        Text(lowLevel)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    if !relations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Связи:", systemImage: "link.circle.fill")
                                .font(.caption).bold()
                                .foregroundColor(.blue)
                            Text(relations)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .italic()
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground.opacity(0.5))
            }
        }
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(isExpanded ? color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
