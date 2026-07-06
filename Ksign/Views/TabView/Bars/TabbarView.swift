//
//  TabbarView.swift
//  feather
//
//  Created by samara on 23.03.2025.
//  Modified for Hassany Store (Forced Floating Glassmorphism TabBar)
//

import SwiftUI

struct TabbarView: View {
    @State private var selectedTab: TabEnum = .home
    @Namespace private var animation

    init() {
        // الطريقة القاضية لإخفاء شريط أبل الافتراضي نهائياً في كل إصدارات الـ iOS
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            
            // 1. محتوى الشاشات
            TabView(selection: $selectedTab) {
                ForEach(TabEnum.defaultTabs, id: \.hashValue) { tab in
                    TabEnum.view(for: tab)
                        .tag(tab)
                        // إجبار إخفاء الشريط في iOS 16 وما فوق
                        .toolbar(.hidden, for: .tabBar)
                        // مسافة سفلية حتى المحتوى ما يختفي خلف الشريط العائم
                        .padding(.bottom, 90) 
                }
            }

            // 2. الشريط العائم الزجاجي الفخم
            HStack(spacing: 0) {
                ForEach(TabEnum.defaultTabs, id: \.hashValue) { tab in
                    let isSelected = selectedTab == tab
                    
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: isSelected ? 8 : 0) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .semibold))
                            
                            if isSelected {
                                Text(tab.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                        }
                        .foregroundColor(isSelected ? .white : .gray.opacity(0.7))
                        .padding(.vertical, 12)
                        .padding(.horizontal, isSelected ? 20 : 15)
                        .background(
                            ZStack {
                                if isSelected {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color(red: 0.4, green: 0.1, blue: 0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: .purple.opacity(0.5), radius: 8, x: 0, y: 4)
                                    .matchedGeometryEffect(id: "TAB_ANIMATION", in: animation)
                                }
                            }
                        )
                    }
                    .frame(maxWidth: isSelected ? .infinity : nil)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Color.black.opacity(0.65)
                    if #available(iOS 15.0, *) {
                        Rectangle().fill(.ultraThinMaterial)
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 15)
            .padding(.horizontal, 20)
            .padding(.bottom, 10) // ارتفاع الشريط عن حافة الشاشة
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
