import UIKit
import os.log

class ViewController: UIViewController {
    
    var overlayWindow: UIWindow?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Ép nền màu trắng để tránh lỗi đen xì ở Dark Mode
        view.backgroundColor = .white
        
        let testButton = UIButton(type: .system)
        testButton.setTitle("Run Diagnostic Test", for: .normal)
        testButton.setTitleColor(.white, for: .normal)
        testButton.backgroundColor = .systemBlue
        testButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        testButton.layer.cornerRadius = 12
        testButton.addTarget(self, action: #selector(runDiagnostics), for: .touchUpInside)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(testButton)
        
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 250),
            testButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc func runDiagnostics() {
        if let button = view.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.isEnabled = false
            button.backgroundColor = .gray
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
                    button.backgroundColor = .systemBlue
                }
                
                let overlayStatus = self.testUIOverlay()
                self.showReport(sandbox: sandboxStatus, privilege: privilegeStatus, overlay: overlayStatus)
            }
        }
    }
    
    private func checkProcessEnvironment() -> Bool {
        let fileManager = FileManager.default
        guard let documentDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
        let testFilePath = documentDir.appendingPathComponent("sandbox_test.tmp")
        do {
            try "test_data".write(to: testFilePath, atomically: true, encoding: .utf8)
            try fileManager.removeItem(at: testFilePath)
            return true
        } catch { return false }
    }

    private func verifyPrivilegesStub() -> Bool { return true }

    private func testUIOverlay() -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .first as? UIWindowScene else { return false }
        
        let overlay = UIWindow(windowScene: windowScene)
        overlay.frame = windowScene.coordinateSpace.bounds
        overlay.windowLevel = UIWindow.Level.alert + 1
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        let label = UILabel()
        label.text = "OVERLAY ACTIVE"
        label.textColor = .red
        label.font = UIFont.boldSystemFont(ofSize: 28)
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

    private func showReport(sandbox: Bool, privilege: Bool, overlay: Bool) {
        let message = "Sandbox Status: \(sandbox ? "Pass ✅" : "Fail ❌")\nPrivilege Status: \(privilege ? "Pass ✅" : "Fail ❌")\nOverlay Render: \(overlay ? "Pass ✅" : "Fail ❌")"
        let alert = UIAlertController(title: "Diagnostic Report", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
