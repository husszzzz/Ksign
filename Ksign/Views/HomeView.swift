import SwiftUI
import CoreData
import AltSourceKit

// MARK: - البيانات (Models)
struct VIPPackage: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let duration: String
    let warranty: String
    let features: [String]
    let colors: [Color]
}

struct StoreSettings: Codable {
    let banners: [String]
}

// MARK: - محرك جلب البنرات من السورس القياسي
class BannerManager: ObservableObject {
    @Published var banners: [String] = []
    
    // الرابط الحقيقي لملف الـ JSON الخاص بمتجرك
    let sourceURL = "https://raw.githubusercontent.com/husszzzz/Ksign/refs/heads/main/banners.json"
    
    func fetchBanners() {
        guard let url = URL(string: sourceURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let settings = try JSONDecoder().decode(StoreSettings.self, from: data)
                    DispatchQueue.main.async {
                        if !settings.banners.isEmpty {
                            self.banners = settings.banners
                        }
                    }
                } catch {
                    print("فشل في قراءة ملف البنرات: \(error)")
                    // صور احتياطية في حال فشل الاتصال
                    DispatchQueue.main.async {
                        if self.banners.isEmpty {
                            self.banners = [
                                "https://j.top4top.io/p_38372zx3z0.png",
                                "https://k.top4top.io/p_3837l7crg1.png"
                            ]
                        }
                    }
                }
            }
        }.resume()
    }
}

// MARK: - الشاشة الرئيسية
struct HomeView: View {
    @StateObject private var bannerManager = BannerManager()
    @State private var currentBanner = 0
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 25) {
                    
                    // 1. قسم البنرات المتحركة (مربوط بالسورس)
                    if bannerManager.banners.isEmpty {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 180)
                            .overlay(ProgressView())
                            .padding(.horizontal)
                    } else {
                        TabView(selection: $currentBanner) {
                            ForEach(0..<bannerManager.banners.count, id: \.self) { index in
                                AsyncImage(url: URL(string: bannerManager.banners[index])) { phase in
                                    if let image = phase.image {
                                        image.resizable()
                                             .aspectRatio(contentMode: .fill)
                                    } else if phase.error != nil {
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                                    } else {
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.gray.opacity(0.15))
                                            .overlay(ProgressView())
                                    }
                                }
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .padding(.horizontal)
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        .frame(height: 180)
                        .onReceive(timer) { _ in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                if !bannerManager.banners.isEmpty {
                                    currentBanner = (currentBanner + 1) % bannerManager.banners.count
                                }
                            }
                        }
                    }
                    
                    // 2. قسم أحدث الإضافات
                    NavigationLink(destination: RecentUpdatesView()) {
                        _menuButton(title: "أحدث الإضافات والتحديثات", subtitle: "اكتشف التطبيقات والميزات الجديدة", icon: "sparkles", color: .blue)
                    }
                    
                    // 3. قسم الترقية إلى VIP
                    NavigationLink(destination: VIPUpgradeView()) {
                        _menuButton(title: "الترقية إلى VIP", subtitle: "اشترك الآن واستمتع بمميزات حصرية", icon: "crown.fill", color: .orange)
                    }
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("الرئيسية")
            .onAppear {
                bannerManager.fetchBanners()
            }
        }
    }
    
    @ViewBuilder
    private func _menuButton(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.left")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
}

// MARK: - صفحة الترقية إلى VIP
struct VIPUpgradeView: View {
    let commonFeatures = [
        "متجر تطبيقات معدلة ومكركة ومحذوفة",
        "تدعم جميع برامج التوقيع المختلفة",
        "تفعيل فوري خلال خمس دقائق",
        "خدمة دعم فني متكاملة أثناء المدة",
        "توفر ايضاً هاكات للألعاب القوية مجاناً"
    ]
    
    var packages: [VIPPackage] {
        [
            VIPPackage(title: "الباقة النارية", price: "10,000 د.ع", duration: "سنة كاملة", warranty: "شهر واحد", features: commonFeatures, colors: [Color.orange, Color.red]),
            VIPPackage(title: "الباقة النارية VIP", price: "15,000 د.ع", duration: "سنة كاملة", warranty: "شهرين", features: commonFeatures, colors: [Color.red, Color.purple]),
            VIPPackage(title: "الباقة الألماسية", price: "25,000 د.ع", duration: "سنة كاملة", warranty: "6 أشهر", features: commonFeatures, colors: [Color.blue, Color.cyan]),
            VIPPackage(title: "الباقة السوبر VIP", price: "30,000 د.ع", duration: "سنة كاملة", warranty: "سنة كاملة", features: commonFeatures, colors: [Color.black, Color.yellow.opacity(0.8)])
        ]
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 15) {
                ForEach(packages) { package in
                    VIPPackageCard(package: package)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("باقات VIP")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - تصميم بطاقة الباقة
struct VIPPackageCard: View {
    let package: VIPPackage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(package.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Text(package.price)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 20) {
                Label(package.duration, systemImage: "clock.fill")
                Label("ضمان \(package.warranty)", systemImage: "shield.fill")
            }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.9))
            
            Divider().background(Color.white.opacity(0.5))
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(package.features, id: \.self) { feature in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            
            Button(action: {
                if let telegramURL = URL(string: "https://t.me/OM_G9") {
                    UIApplication.shared.open(telegramURL)
                }
            }) {
                Text("اشترك الآن")
                    .font(.headline)
                    .foregroundColor(package.colors.first)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 5)
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: package.colors), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .scaleEffect(isAnimating ? 1.015 : 1.0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - صفحة أحدث الإضافات (المحدثة والمربوطة)
struct RecentUpdatesView: View {
    @StateObject private var viewModel = SourcesViewModel.shared
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var sources: FetchedResults<AltSource>
    
    struct SafeApp: Identifiable {
        let id = UUID()
        let source: ASRepository 
        let app: ASRepository.App
    }
    
    var recentApps: [SafeApp] {
        var allApps: [SafeApp] = []
        for source in sources {
            if let repo = viewModel.sources[source] {
                for app in repo.apps {
                    allApps.append(SafeApp(source: repo, app: app))
                }
            }
        }
        return Array(allApps.prefix(50))
    }
    
    var body: some View {
        List {
            if recentApps.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("جاري جلب التحديثات...")
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(recentApps) { safeItem in
                    let app = safeItem.app
                    NavigationLink(destination: SourceAppsDetailView(source: safeItem.source, app: app)) {
                        HStack(spacing: 15) {
                            AsyncImage(url: app.iconURL) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                         .aspectRatio(contentMode: .fit)
                                } else if phase.error != nil {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(Image(systemName: "app.fill").foregroundColor(.gray))
                                } else {
                                    ProgressView()
                                }
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.name ?? "تطبيق غير معروف")
                                    .font(.headline)
                                Text("إصدار: \(app.version ?? "1.0")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Text("تنزيل")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("أحدث الإضافات")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: Array(sources)) {
            await viewModel.fetchSources(sources)
        }
    }
}
