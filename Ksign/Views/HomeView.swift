//
//  HomeView.swift
//  Feather (Modified for Hassany Store - Elite Xsing UI)
//

import SwiftUI
import AltSourceKit
import CoreData

// MARK: - هيكل البيانات لملف البانرات JSON
struct BannersConfig: Codable {
    let banners: [String]?
}

// MARK: - مسار التطبيق
struct HomeAppRoute: Identifiable, Hashable {
    let source: ASRepository
    let app: ASRepository.App
    let id: String = UUID().uuidString
}

// MARK: - الواجهة الرئيسية
struct HomeView: View {
    @StateObject private var viewModel = SourcesViewModel()
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _allSources: FetchedResults<AltSource>
    
    @State private var showIntro = true
    @State private var currentIndex = 0
    @State private var hasLoadedOnce = false
    @State private var bannerURLs: [String] = []
    
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    // 🚀 جلب جميع التطبيقات مرتبة من الأحدث للأقدم
    private var allAppsSorted: [HomeAppRoute] {
        var all: [HomeAppRoute] = []
        for source in _allSources {
            if let repo = viewModel.sources[source] {
                for app in repo.apps {
                    all.append(HomeAppRoute(source: repo, app: app))
                }
            }
        }
        return all.reversed()
    }
    
    // أول 5 تطبيقات للشاشة الرئيسية
    private var top5Apps: [HomeAppRoute] {
        return Array(allAppsSorted.prefix(5))
    }
    
    // أول 50 تطبيق لصفحة "اكتشف المزيد"
    private var top50Apps: [HomeAppRoute] {
        return Array(allAppsSorted.prefix(50))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if showIntro {
                    XsingIntroView(showIntro: $showIntro)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            // 1. بانر الصورتين المتحرك (يسحب من JSON)
                            DynamicImageSliderBanner(urls: bannerURLs)
                                .padding(.top, 15)
                            
                            // 2. زر الترقية إلى VIP
                            NavigationLink(destination: VIPPackagesView()) {
                                CleanVIPButton()
                            }
                            .buttonStyle(.plain)
                            
                            // 3. شريط أحدث 5 تطبيقات
                            if top5Apps.isEmpty {
                                VStack {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                    Text("جاري سحب التطبيقات...").foregroundColor(.gray).font(.system(size: 14)).padding(.top, 8)
                                }
                                .padding(.top, 40)
                            } else {
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        Text("أحدث الإضافات")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        
                                        // 🚀 زر اكتشف المزيد (ينقل لصفحة الـ 50 تطبيق)
                                        NavigationLink(destination: Top50AppsView(apps: top50Apps)) {
                                            Text("اكتشف المزيد ➔")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.purple)
                                        }
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
                if !hasLoadedOnce {
                    Task {
                        await viewModel.fetchSources(_allSources, refresh: false)
                        await fetchBannersJSON()
                        hasLoadedOnce = true
                    }
                }
            }
        }
    }
    
    // MARK: - دالة سحب البانرات من ملف JSON
    private func fetchBannersJSON() async {
        // ضع رابط الـ RAW لملف banners.json الخاص بك هنا.
        // استخدمت روابطك بالصورة كقيمة افتراضية حتى لا تعطل الشاشة أبداً.
        let defaultBanners = [
            "https://a.top4top.io/p_3837rcc760.png",
            "https://k.top4top.io/p_383717crg1.png"
        ]
        
        guard let url = URL(string: "https://raw.githubusercontent.com/Nyasami/Ksign/main/banners.json") else {
            self.bannerURLs = defaultBanners
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let config = try JSONDecoder().decode(BannersConfig.self, from: data)
            if let fetchedBanners = config.banners, !fetchedBanners.isEmpty {
                self.bannerURLs = fetchedBanners
            } else {
                self.bannerURLs = defaultBanners
            }
        } catch {
            print("❌ فشل جلب البانرات: \(error)")
            self.bannerURLs = defaultBanners
        }
    }
}

// MARK: - صفحة أحدث 50 تطبيق (Top 50 Apps)
struct Top50AppsView: View {
    let apps: [HomeAppRoute]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                    ForEach(apps, id: \.id) { route in
                        NavigationLink(destination: SourceAppsDetailView(source: route.source, app: route.app)) {
                            GlassAppCard(app: route.app)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("أحدث التطبيقات")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - إنترو Xsing
struct XsingIntroView: View {
    @Binding var showIntro: Bool
    @State private var textScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Xsing")
                .font(.system(size: 65, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom))
                .scaleEffect(textScale)
                .opacity(textOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                textScale = 1.0
                textOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showIntro = false
                }
            }
        }
    }
}

// MARK: - بانر الصور الديناميكي (يسحب الروابط من الإنترنت)
struct DynamicImageSliderBanner: View {
    let urls: [String]
    @State private var currentBanner = 0
    let timer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if urls.isEmpty {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.1))
                .frame(height: 180)
                .padding(.horizontal, 20)
        } else {
            TabView(selection: $currentBanner) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                    AsyncImage(url: URL(string: urlString)) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            ZStack {
                                Color(white: 0.1)
                                ProgressView()
                            }
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)
            .onReceive(timer) { _ in
                withAnimation {
                    currentBanner = (currentBanner + 1) % urls.count
                }
            }
        }
    }
}

// MARK: - زر VIP النظيف
struct CleanVIPButton: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 26))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("الترقية إلى VIP")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("اكتشف الباقات والمميزات الحصرية")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.left")
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(20)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 20)
    }
}

// MARK: - صفحة باقات VIP
struct VIPPackagesView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                    .padding(.bottom, 20)
                Text("باقات VIP")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Text("هنا يمكنك تصميم وعرض الباقات الخاصة بك")
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
        .navigationTitle("الاشتراكات")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - كارت التطبيق
struct GlassAppCard: View {
    let app: ASRepository.App
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: app.iconURL) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Image(systemName: "app.dashed").resizable().foregroundColor(.gray)
                } else {
                    ProgressView()
                }
            }
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
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
            
            Text("تنزيل")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 80, height: 28)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(width: 130)
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
