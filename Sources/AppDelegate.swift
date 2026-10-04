import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Khởi tạo giao diện trực tiếp tại đây, loại bỏ hoàn toàn SceneDelegate
        window = UIWindow(frame: UIScreen.main.bounds)
        let rootVC = ViewController()
        window?.rootViewController = rootVC
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
        
        return true
    }
}
