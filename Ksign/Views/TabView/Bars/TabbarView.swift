//
//  TabbarView.swift
//  feather
//
//  Created by samara on 23.03.2025.
//  Modified for Hassany Store (Ultra VIP Floating Glassmorphism TabBar)
//

import SwiftUI

struct TabbarView: View {
    @State private var selectedTab: TabEnum = .home // التعديل لتفتح الرئيسية أولاً
    @Namespace private var animation // للأنيميشن السلس (Dynamic Effect)

    init() {
        // إخفاء شريط النظام الافتراضي الكئيب بالكامل
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            
            // 1. محتوى الشاشات
            TabView(selection: $selectedTab) {
                ForEach(TabEnum.defaultTabs, id: \.hashValue) { tab in
                    TabEnum.view(for: tab)
                        .tag(tab)
                        // إضافة مسافة سفلية حتى لا يغطي الشريط العائم على محتوى التطبيقات
                        .padding(.bottom, 90) 
                        .ignoresSafeArea(.all, edges: .bottom)
                }
            }

            // 2. الشريط العائم الزجاجي (VIP Floating Bar)
            HStack(spacing: 0) {
                ForEach(TabEnum.defaultTabs, id: \.hashValue) { tab in
                    let isSelected = selectedTab == tab
                    
                    Button(action: {
                        // هزة خفيفة (Haptic Feedback) عند الضغط للشعور بالفخامة
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: isSelected ? 8 : 0) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .bold))
                            
                            if isSelected {
                                Text(tab.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                        }
                        .foregroundColor(isSelected ? .white : .gray.opacity(0.8))
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
                    .frame(maxWidth: isSelected ? .infinity : nil) // التمدد للزر النشط فقط
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Color.black.opacity(0.5) // عتامة خفيفة
                    if #available(iOS 15.0, *) {
                        Rectangle().fill(.ultraThinMaterial) // تأثير الزجاج (Glassmorphism)
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1) // إطار زجاجي فخم
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // حتى لا يرتفع الشريط مع الكيبورد
    }
}
