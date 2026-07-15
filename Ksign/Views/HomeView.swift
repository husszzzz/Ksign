//
//  HomeView.swift
//  Feather (Modified for Hassany Store - Elite UI)
//
//  Created for Hassany Store.
//  Features: Intro, 3D Banner, Auto-scrolling Top 5 Recent Apps.
//

import SwiftUI
import AltSourceKit
import CoreData

// MARK: - مسار التطبيق (للانتقال للتفاصيل)
struct HomeAppRoute: Identifiable, Hashable {
    let source: ASRepository
    let app: ASRepository.App
    let id: String = UUID().uuidString
}

// MARK: - الواجهة الرئيسية الفخمة
struct HomeView: View {
    @ObservedObject var viewModel: SourcesViewModel
    
    // سحب السورسات من قاعدة البيانات
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _allSources: FetchedResults<AltSource>
    
    @State private var _sources: [ASRepository]?
    
    // حالة الإنترو والسكرول
    @State private var showIntro = true
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    // 🚀 جلب أحدث 5 تطبيقات فقط
    private var top5Apps: [HomeAppRoute] {
        guard let sources = _sources else { return [] }
        var all: [HomeAppRoute] = []
        
        for source in sources {
            for app in source.apps {
                all.append(HomeAppRoute(source: source, app: app))
            }
        }
        
        // عكس المصفوفة لجلب الأحدث، ثم أخذ أول 5 فقط
        all = all.reversed()
        return Array(all.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea() // خلفية سوداء عميقة
                
                if showIntro {
                    // 1. الإنترو السينمائي
                    IntroAnimationView(showIntro: $showIntro)
                } else {
                    // 2. محتوى الصفحة الرئيسية
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 25) {
                            
                            // الهيدر الترحيبي
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("مرحباً بك، يا بطل ⚡️")
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("اكتشف أقوى التطبيقات المعدلة")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Circle()
                                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 45, height: 45)
                                    .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            
                            // البانر الفخم VIP
                            PremiumBannerView()
                            
                            // شريط أحدث 5 تطبيقات (متحرك تلقائياً ومربوط بالبيانات الحقيقية)
                            if top5Apps.isEmpty {
                                ProgressView("جاري تحميل التطبيقات...")
                                    .padding(.top, 30)
                            } else {
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        Text("🔥 أحدث الإضافات")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    ScrollViewReader { proxy in
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(Array(top5Apps.enumerated()), id: \.offset) { index, route in
                                                    NavigationLink(destination: SourceAppsDetailView(source: route.source, app: route.app)) {
                                                        GlassAppCard(app: route.app)
                                                    }
                                                    .buttonStyle(.plain)
                                                    .id(index)
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.bottom, 10)
                                        }
                                        .onReceive(timer) { _ in
                                            if !top5Apps.isEmpty {
                                                withAnimation(.easeInOut(duration: 0.6)) {
                                                    currentIndex = (currentIndex + 1) % top5Apps.count
                                                    proxy.scrollTo(currentIndex, anchor: .center)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                _loadData()
            }
            .onChange(of: viewModel.isFinished) { _ in
                _loadData()
            }
        }
    }
    
    // دالة جلب البيانات الخاصة بالمتجر
    private func _loadData() {
        Task {
            // تحميل السورسات من الفيو مودل الأساسي
            let loadedSources = _allSources.compactMap { viewModel.sources[$0] }
            _sources = loadedSources
        }
    }
}

// MARK: - 1. الإنترو السينمائي
struct IntroAnimationView: View {
    @Binding var showIntro: Bool
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
                logoScale = 1.2
                logoOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showIntro = false
                }
            }
        }
    }
}

// MARK: - 2. البانر الفخم (Premium Banner 3D)
struct PremiumBannerView: View {
    @State private var pulse = false
    @State private var gradientShift = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(LinearGradient(colors: [.purple.opacity(0.4), .blue.opacity(0.4)], startPoint: gradientShift ? .topLeading : .bottomTrailing, endPoint: gradientShift ? .bottomTrailing : .topLeading))
                .frame(height: 160)
                .blur(radius: 20)
                .padding(.horizontal, 25)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ترقية إلى VIP 👑")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .shadow(color: .orange.opacity(0.5), radius: 5)
                    
                    Text("حمل بدون إعلانات، وتطبيقات معدلة حصرية فقط للمشتركين.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                    
                    Spacer()
                    
                    Text("اشترك الآن ➔")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .padding(20)
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .orange.opacity(0.8), radius: pulse ? 15 : 5)
                    .scaleEffect(pulse ? 1.1 : 1.0)
                    .padding(.trailing, 20)
            }
            .frame(height: 160)
            .background(RoundedRectangle(cornerRadius: 25).fill(Color(white: 0.08).opacity(0.9)))
            .overlay(RoundedRectangle(cornerRadius: 25).stroke(LinearGradient(colors: [.orange.opacity(0.6), .purple.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: true)) { gradientShift = true }
        }
    }
}

// MARK: - تصميم كارت التطبيق الحقيقي (يسحب الأيقونة والاسم من السورس)
struct GlassAppCard: View {
    let app: ASRepository.App
    
    var body: some View {
        VStack(spacing: 12) {
            // سحب الأيقونة الحقيقية من الرابط
            AsyncImage(url: app.iconURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Image(systemName: "app.dashed")
                        .resizable()
                        .foregroundColor(.gray)
                } else {
                    ProgressView()
                }
            }
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .purple.opacity(0.2), radius: 5)
            
            // سحب الاسم والإصدار الحقيقي
            VStack(spacing: 4) {
                Text(app.name ?? "تطبيق")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                    Text("v\(app.version ?? "1.0")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // زر التنزيل
            Text("تنزيل")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 80, height: 28)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(width: 130)
        .background(Color(white: 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
