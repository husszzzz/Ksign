import SwiftUI

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

struct HomeView: View {
    // روابط صور البنرات
    let bannerImages = [
        "https://j.top4top.io/p_38372zx3z0.png",
        "https://k.top4top.io/p_3837l7crg1.png"
    ]
    
    @State private var currentBanner = 0
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    // المميزات المشتركة لكل الباقات (حسب طلبك)
    let commonFeatures = [
        "متجر تطبيقات معدلة ومكركة ومحذوفة",
        "تدعم جميع برامج التوقيع المختلفة",
        "تفعيل فوري خلال خمس دقائق",
        "خدمة دعم فني متكاملة أثناء المدة",
        "توفر ايضاً هاكات للألعاب القوية مجاناً"
    ]
    
    // قائمة باقات الـ VIP بالأسعار والضمان الجديد
    var packages: [VIPPackage] {
        [
            VIPPackage(title: "الباقة النارية", price: "10,000 د.ع", duration: "سنة كاملة", warranty: "شهر واحد", features: commonFeatures, colors: [Color.orange, Color.red]),
            VIPPackage(title: "الباقة النارية VIP", price: "15,000 د.ع", duration: "سنة كاملة", warranty: "شهرين", features: commonFeatures, colors: [Color.red, Color.purple]),
            VIPPackage(title: "الباقة الألماسية", price: "25,000 د.ع", duration: "سنة كاملة", warranty: "6 أشهر", features: commonFeatures, colors: [Color.blue, Color.cyan]),
            VIPPackage(title: "الباقة السوبر VIP", price: "30,000 د.ع", duration: "سنة كاملة", warranty: "سنة كاملة", features: commonFeatures, colors: [Color.black, Color.yellow.opacity(0.8)])
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 25) {
                    
                    // 1. قسم البنرات المتحركة
                    TabView(selection: $currentBanner) {
                        ForEach(0..<bannerImages.count, id: \.self) { index in
                            AsyncImage(url: URL(string: bannerImages[index])) { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Color.gray.opacity(0.3))
                                    .overlay(ProgressView())
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
                            currentBanner = (currentBanner + 1) % bannerImages.count
                        }
                    }
                    
                    // 2. قسم أحدث الإضافات (مربوط بصفحة التحديثات)
                    NavigationLink(destination: RecentUpdatesView()) {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("أحدث الإضافات والتحديثات")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("اكتشف التطبيقات والميزات الجديدة")
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
                    
                    // 3. قسم الباقات (VIP)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("ارتقِ إلى VIP")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(packages) { package in
                            VIPPackageCard(package: package)
                        }
                    }
                    .padding(.top, 10)
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("الرئيسية")
        }
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
            
            // زر الاشتراك (ينقل مباشرة إلى التلجرام)
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

// MARK: - صفحة أحدث الإضافات (آخر 50 تطبيق)
struct RecentUpdatesView: View {
    // ملاحظة لحسين: هذا المتغير يمثل آخر 50 تطبيق. 
    // لاحقاً يمكنك استبداله بمصفوفة التطبيقات القادمة من JSON متجرك
    // مثال: AppManager.shared.apps.prefix(50)
    
    let recentApps = Array(1...50).map { "تطبيق رقم \($0)" } // بيانات وهمية مؤقتة للحفاظ على الواجهة
    
    var body: some View {
        List {
            Section(header: Text("آخر 50 تحديث")) {
                ForEach(recentApps, id: \.self) { appName in
                    HStack {
                        // أيقونة التطبيق
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(Image(systemName: "app.fill").foregroundColor(.gray))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appName)
                                .font(.headline)
                            Text("تم التحديث مؤخراً")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        Button(action: {
                            // إجراء التنزيل
                        }) {
                            Text("تنزيل")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("أحدث الإضافات")
        .navigationBarTitleDisplayMode(.inline)
    }
}
