import UIKit
import os.log

class ViewController: UIViewController {
    
    // Giữ tham chiếu mạnh (strong reference) đến UIWindow
    var overlayWindow: UIWindow?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - 1. Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let testButton = UIButton(type: .system)
        testButton.setTitle("Run Diagnostic Test", for: .normal)
        testButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        testButton.addTarget(self, action: #selector(runDiagnostics), for: .touchUpInside)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(testButton)
        
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - 2. Button Action & Background Execution
    @objc func runDiagnostics() {
        if let button = view.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.isEnabled = false
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            os_log("Bắt đầu chạy kiểm tra chẩn đoán trên luồng nền...", log: .default, type: .info)
            
            Thread.sleep(forTimeInterval: 0.5)
            let sandboxStatus = self.checkProcessEnvironment()
            
            Thread.sleep(forTimeInterval: 0.5)
            let privilegeStatus = self.verifyPrivilegesStub()
            
            DispatchQueue.main.async {
                if let button = self.view.subviews.first(where: { $0 is UIButton }) as? UIButton {
                    button.isEnabled = true
                }
                
                let overlayStatus = self.testUIOverlay()
                self.showReport(sandbox: sandboxStatus, privilege: privilegeStatus, overlay: overlayStatus)
            }
        }
    }

    // MARK: - 3. Các hàm Mô phỏng (Stubs/Mocks)
    
    private func checkProcessEnvironment() -> Bool {
        let fileManager = FileManager.default
        guard let documentDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let testFilePath = documentDir.appendingPathComponent("sandbox_test.tmp")
        do {
            try "test_data".write(to: testFilePath, atomically: true, encoding: .utf8)
            try fileManager.removeItem(at: testFilePath)
            return true
        } catch {
            return false
        }
    }

    private func verifyPrivilegesStub() -> Bool {
        return true
    }

    private func testUIOverlay() -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .first as? UIWindowScene else {
            return false
        }
        
        let overlay = UIWindow(windowScene: windowScene)
        overlay.frame = windowScene.coordinateSpace.bounds
        overlay.windowLevel = UIWindow.Level.alert + 1
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let label = UILabel()
        label.text = "Overlay Testing..."
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let overlayVC = UIViewController()
        overlayVC.view.backgroundColor = .clear
        overlayVC.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlayVC.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlayVC.view.centerYAnchor)
        ])
        
        overlay.rootViewController = overlayVC
        overlay.isHidden = false
        
        self.overlayWindow = overlay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.overlayWindow?.isHidden = true
            self.overlayWindow = nil
        }
        
        return true
    }

    // MARK: - 4. Báo cáo kết quả
    private func showReport(sandbox: Bool, privilege: Bool, overlay: Bool) {
        let message = """
        Sandbox Status: \(sandbox ? "Pass ✅" : "Fail ❌")
        Privilege Status: \(privilege ? "Pass ✅" : "Fail ❌")
        Overlay Render: \(overlay ? "Pass ✅" : "Fail ❌")
        """
        
        let alert = UIAlertController(title: "Diagnostic Report", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}
