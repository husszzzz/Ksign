//
//  HomeView.swift
//  Feather (Modified for Hassany Store - Elite Xsing UI, Flawless Standalone Logic)
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
    // 🚀 المحرك الخاص بالشاشة (يعمل بصمت بدون التأثير على باقي التطبيق)
    @StateObject private var viewModel = SourcesViewModel()
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _allSources: FetchedResults<AltSource>
    
    @State private var showIntro = true
    @State private var hasLoadedOnce = false
    @State private var bannerURLs: [String] = []
    
    @State private var loadedRepositories: [ASRepository] = []
    @State private var isAppsLoading = true
    
    // جلب التطبيقات
    private var allAppsSorted: [HomeAppRoute] {
        var all: [HomeAppRoute] = []
        for repo in loadedRepositories {
            for app in repo.apps {
                all.append(HomeAppRoute(source: repo, app: app))
            }
        }
        return all.reversed()
    }
    
    // أول 10 فوك، وثاني 10 جوه، وأول 50 لصفحة المزيد
    private var top10Apps: [HomeAppRoute] { Array(allAppsSorted.prefix(10)) }
    private var bottom10Apps: [HomeAppRoute] { allAppsSorted.count > 10 ? Array(allAppsSorted.dropFirst(10).prefix(10)) : [] }
    private var top50Apps: [HomeAppRoute] { Array(allAppsSorted.prefix(50)) }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if showIntro {
                    XsingIntroView(showIntro: $showIntro)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            // 1. بانر الصور
                            DynamicImageSliderBanner(urls: bannerURLs)
                                .padding(.top, 15)
                            
                            // 2. زر VIP
                            NavigationLink(destination: VIPPackagesView()) {
                                CleanVIPButton()
                            }
                            .buttonStyle(.plain)
                            
                            // 3. التطبيقات المتحركة
                            if isAppsLoading {
                                VStack {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                    Text("جاري ترتيب التطبيقات...").foregroundColor(.gray).font(.system(size: 14)).padding(.top, 8)
                                }
                                .padding(.top, 40)
                            } else if top10Apps.isEmpty {
                                Text("لا توجد تطبيقات حالياً.").foregroundColor(.gray).padding(.top, 40)
                            } else {
                                VStack(alignment: .leading, spacing: 25) {
                                    
                                    // السطر الأول
                                    VStack(alignment: .leading, spacing: 15) {
                                        HStack {
                                            Text("أحدث الإضافات").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                            Spacer()
                                            NavigationLink(destination: Top50AppsView(apps: top50Apps)) {
                                                Text("اكتشف المزيد ➔").font(.system(size: 14, weight: .bold)).foregroundColor(.purple)
                                            }
                                        }.padding(.horizontal, 20)
                                        
                                        ContinuousMarquee(apps: top10Apps, moveLeft: true)
                                    }
                                    
                                    // السطر الثاني
                                    if !bottom10Apps.isEmpty {
                                        VStack(alignment: .leading, spacing: 15) {
                                            HStack {
                                                Text("آخر التحديثات").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                                Spacer()
                                            }.padding(.horizontal, 20)
                                            
                                            ContinuousMarquee(apps: bottom10Apps, moveLeft: false)
                                        }
                                    }
                                }
                            }
                            Spacer(minLength: 40)
                        }
                        .frame(maxWidth: UIScreen.main.bounds.width)
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                if !hasLoadedOnce {
                    hasLoadedOnce = true
                    Task { await fetchBannersJSON() }
                    
                    // 🚀 السحر هنا: تأخير ثانية ونص يمنع تضارب قاعدة البيانات نهائياً
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        await viewModel.fetchSources(_allSources, refresh: false)
                        await MainActor.run {
                            self.loadedRepositories = _allSources.compactMap { viewModel.sources[$0] }
                            self.isAppsLoading = false
                        }
                    }
                } else {
                    // تحديث فوري عند الرجوع للصفحة
                    self.loadedRepositories = _allSources.compactMap { viewModel.sources[$0] }
                }
            }
            // 🚀 يلقط التطبيقات تلقائياً إذا تأخرت
            .onChange(of: _allSources.count) { _ in
                self.loadedRepositories = _allSources.compactMap { viewModel.sources[$0] }
                if !self.loadedRepositories.isEmpty { self.isAppsLoading = false }
            }
        }
    }
    
    private func fetchBannersJSON() async {
        let defaultBanners = [
            "https://a.top4top.io/p_3837rcc760.png",
            "https://k.top4top.io/p_383717crg1.png"
        ]
        guard let url = URL(string: "https://raw.githubusercontent.com/Nyasami/Ksign/main/banners.json") else {
            self.bannerURLs = defaultBanners; return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let config = try JSONDecoder().decode(BannersConfig.self, from: data)
            self.bannerURLs = (config.banners?.isEmpty == false) ? config.banners! : defaultBanners
        } catch {
            self.bannerURLs = defaultBanners
        }
    }
}

// MARK: - 🚀 محرك الحركة المستمرة (Marquee Effect)
struct ContinuousMarquee: View {
    let apps: [HomeAppRoute]
    let moveLeft: Bool
    @State private var animate = false
    
    var body: some View {
        let itemWidth: CGFloat = 146
        let totalWidth = itemWidth * CGFloat(apps.count)
        
        GeometryReader { proxy in
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { loopIndex in
                    ForEach(apps, id: \.id) { route in
                        NavigationLink(destination: SourceAppsDetailView(source: route.source, app: route.app)) {
                            GlassAppCard(app: route.app)
                        }
                        .buttonStyle(.plain)
                        // 🚀 معرف فريد يمنع تداخل الكروت
                        .id("\(loopIndex)-\(route.id)")
                    }
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .offset(x: animate ? (moveLeft ? -totalWidth : 0) : (moveLeft ? 0 : -totalWidth))
        }
        .frame(height: 160)
        .clipped()
        .onAppear {
            animate = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.linear(duration: Double(apps.count) * 2.5).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
        }
    }
}

// MARK: - إنترو Xsing
struct XsingIntroView: View {
    @Binding var showIntro: Bool
    @State private var xOpacity: Double = 0.0
    @State private var xScale: CGFloat = 0.3
    @State private var singOpacity: Double = 0.0
    @State private var singOffset: CGFloat = -30
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HStack(spacing: 0) {
                Text("X").font(.system(size: 80, weight: .black, design: .rounded)).foregroundColor(.purple).scaleEffect(xScale).opacity(xOpacity)
                Text("sing").font(.system(size: 65, weight: .black, design: .rounded)).foregroundStyle(LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom)).opacity(singOpacity).offset(x: singOffset)
            }.environment(\.layoutDirection, .leftToRight)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { xScale = 1.0; xOpacity = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { withAnimation(.easeOut(duration: 0.6)) { singOpacity = 1.0; singOffset = 0 } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation(.easeInOut(duration: 0.5)) { showIntro = false } }
        }
    }
}

// MARK: - صفحة باقات VIP (الباقة النارية)
struct VIPPackagesView: View {
    let commonFeatures = ["تطبيقات معدلة حصرية وبدون إعلانات", "تكرار التطبيقات اللامحدود", "إشعارات شغالة 100%", "تحديثات مستمرة وفورية للتطبيقات", "دعم فني مباشر وسريع"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill").font(.system(size: 50)).foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                        Text("الاشتراكات المميزة").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                    }.padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("الباقة النارية 🔥").font(.system(size: 24, weight: .heavy)).foregroundColor(.white)
                            Spacer()
                            Text("10,000 د.ع").font(.system(size: 20, weight: .bold)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 6).background(Color.black.opacity(0.3)).clipShape(Capsule())
                        }
                        HStack(spacing: 15) {
                            HStack { Image(systemName: "calendar").foregroundColor(.yellow); Text("سنة كاملة").foregroundColor(.white).font(.system(size: 14, weight: .bold)) }
                            HStack { Image(systemName: "checkmark.shield.fill").foregroundColor(.green); Text("ضمان شهر").foregroundColor(.white).font(.system(size: 14, weight: .bold)) }
                        }
                        Divider().background(Color.white.opacity(0.3))
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(commonFeatures, id: \.self) { feature in
                                HStack(spacing: 10) { Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(.yellow); Text(feature).font(.system(size: 15, weight: .medium)).foregroundColor(.white) }
                            }
                        }
                        Spacer()
                        Link(destination: URL(string: "https://t.me/OM_G9")!) {
                            HStack { Image(systemName: "paperplane.fill"); Text("شراء الآن عبر التيليجرام") }.font(.system(size: 18, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(Color.black.opacity(0.4)).clipShape(RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        }
                    }
                    .padding(25).background(LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 25)).shadow(color: .red.opacity(0.5), radius: 15, x: 0, y: 10).padding(.horizontal, 20)
                }
            }
        }.navigationTitle("الباقات").navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - صفحة أحدث 50 تطبيق
struct Top50AppsView: View {
    let apps: [HomeAppRoute]
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                    ForEach(apps, id: \.id) { route in
                        NavigationLink(destination: SourceAppsDetailView(source: route.source, app: route.app)) { GlassAppCard(app: route.app) }.buttonStyle(.plain)
                    }
                }.padding(16)
            }
        }.navigationTitle("أحدث التطبيقات").navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - بانر الصور الديناميكي
struct DynamicImageSliderBanner: View {
    let urls: [String]
    @State private var currentBanner = 0
    let timer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if urls.isEmpty {
            RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.1)).frame(height: 180).padding(.horizontal, 20)
        } else {
            TabView(selection: $currentBanner) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                    AsyncImage(url: URL(string: urlString)) { phase in
                        if let image = phase.image { image.resizable().aspectRatio(contentMode: .fill).frame(height: 180).clipped() }
                        else { ZStack { Color(white: 0.1); ProgressView() } }
                    }.tag(index)
                }
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)).frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 20)).padding(.horizontal, 20)
            .onReceive(timer) { _ in withAnimation { currentBanner = (currentBanner + 1) % urls.count } }
        }
    }
}

// MARK: - زر VIP النظيف
struct CleanVIPButton: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "crown.fill").font(.system(size: 26)).foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
            VStack(alignment: .leading, spacing: 4) { Text("الترقية إلى VIP").font(.system(size: 18, weight: .bold)).foregroundColor(.white); Text("اكتشف الباقة النارية والمميزات الحصرية").font(.system(size: 13, weight: .medium)).foregroundColor(.gray) }
            Spacer()
            Image(systemName: "chevron.left").foregroundColor(.gray.opacity(0.6))
        }.padding(20).background(Color(white: 0.08)).clipShape(RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1)).padding(.horizontal, 20)
    }
}

// MARK: - كارت التطبيق
struct GlassAppCard: View {
    let app: ASRepository.App
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: app.iconURL) { phase in
                if let image = phase.image { image.resizable().aspectRatio(contentMode: .fill) }
                else if phase.error != nil { Image(systemName: "app.dashed").resizable().foregroundColor(.gray) }
                else { ProgressView() }
            }.frame(width: 65, height: 65).clipShape(RoundedRectangle(cornerRadius: 18))
            
            VStack(spacing: 4) {
                Text(app.name ?? "تطبيق").font(.system(size: 14, weight: .bold)).foregroundColor(.white).lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.system(size: 9)).foregroundColor(.yellow)
                    Text("v\(app.version ?? "1.0")").font(.system(size: 11, weight: .medium)).foregroundColor(.gray)
                }
            }
            Text("تنزيل").font(.system(size: 13, weight: .bold)).foregroundColor(.white).frame(width: 80, height: 28).background(Color.white.opacity(0.15)).clipShape(Capsule())
        }.padding(.vertical, 16).padding(.horizontal, 12).frame(width: 130).background(Color(white: 0.06)).clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
