import UIKit
import WebKit
import SwiftUI

/// UIKit ViewController to host the Ready Player Me WebView Creator
class AvatarCreatorViewController: UIViewController {
    
    private var webView: WKWebView!
    private var onAvatarExported: ((String) -> Void)?
    private var onDismiss: (() -> Void)?
    
    // SwiftUI-compatible initializer
    convenience init(isPresented: Binding<Bool>, onAvatarExported: @escaping (String) -> Void) {
        self.init()
        self.onAvatarExported = onAvatarExported
        self.onDismiss = {
            isPresented.wrappedValue = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadCreator()
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        
        // Enable camera access and media playback
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        
        // Enable JavaScript and allow arbitrary loads
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Add message handler for Frame API (required for postMessage events)
        config.userContentController.add(self, name: "readyPlayerMe")
        
        // Allow camera and microphone access
        config.allowsPictureInPictureMediaPlayback = true
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Enable user interaction
        webView.isUserInteractionEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        
        view.addSubview(webView)
    }
    
    private func loadCreator() {
        let creatorURL = ReadyPlayerMeConfig.creatorURL
        print("🔧 RPM Debug: Loading Ready Player Me creator from: \(creatorURL)")
        
        guard let url = URL(string: creatorURL) else {
            print("❌ RPM Debug: Invalid creator URL: \(creatorURL)")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        print("🔧 RPM Debug: Starting web view load...")
        webView.load(request)
    }
    
    func setCallbacks(onAvatarExported: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
        self.onAvatarExported = onAvatarExported
        self.onDismiss = onDismiss
    }
}

// MARK: - WKNavigationDelegate

extension AvatarCreatorViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("🔧 RPM Debug: Started loading Ready Player Me creator")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ RPM: Creator loaded successfully, injecting Frame API script...")
        
        // Only inject script once after full load - no reloads or recreations
        let script = """
        (function() {
            console.log('🔧 RPM: Frame API initialization...');
            
            let frameReady = false;
            
            // Listen for postMessage events from RPM iframe
            window.addEventListener('message', function(event) {
                if (!event.data || !event.data.type) return;
                
                console.log('📨 RPM: Received event:', event.data.type);
                
                // Forward to native
                try {
                    window.webkit.messageHandlers.readyPlayerMe.postMessage({
                        type: event.data.type,
                        data: event.data.data || {}
                    });
                } catch (e) {
                    console.error('❌ RPM: Failed to forward event:', e);
                }
                
                // Track frame ready state
                if (event.data.type === 'v1.frame.ready') {
                    frameReady = true;
                    console.log('✅ RPM: Frame is ready, subscribed to events');
                }
            });
            
            console.log('✅ RPM: Message listener installed');
        })();
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ RPM: Script injection failed: \(error.localizedDescription)")
            } else {
                print("✅ RPM: Frame API script injected, waiting for events...")
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ RPM: Navigation failed: \(error.localizedDescription)")
        // No retries or fallbacks - stable initialization only
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ RPM: Provisional navigation failed: \(error.localizedDescription)")
        // No retries or fallbacks - stable initialization only
    }
}

// MARK: - WKUIDelegate

extension AvatarCreatorViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle popup windows (like camera)
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension AvatarCreatorViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }
        
        let data = body["data"] as? [String: Any] ?? [:]
        
        switch type {
        case "v1.frame.ready":
            print("✅ Frame API ready")
            
        case "v1.scene.ready":
            print("✅ Scene ready")
            
        case "v1.user.set":
            print("✅ User set: \(data)")
            
        case "v1.avatar.exported":
            handleAvatarExported(data: data)
            
        default:
            print("📨 Unknown Frame API event: \(type)")
        }
    }
    
    private func handleAvatarExported(data: [String: Any]) {
        print("🔍 RPM: Avatar exported, extracting ID from data: \(data)")
        
        var avatarId: String?
        
        // Method 1: Extract from data.url (e.g., "https://models.readyplayer.me/{id}.glb")
        if let urlString = data["url"] as? String, let url = URL(string: urlString) {
            // Get last path component and strip .glb extension
            let filename = url.lastPathComponent
            avatarId = filename.replacingOccurrences(of: ".glb", with: "")
            print("✅ RPM: Extracted avatar ID from URL: \(avatarId ?? "nil")")
        }
        
        // Method 2: Fallback to direct avatarId field
        if avatarId == nil {
            avatarId = data["avatarId"] as? String
            print("✅ RPM: Got avatar ID from data.avatarId: \(avatarId ?? "nil")")
        }
        
        guard let id = avatarId, !id.isEmpty else {
            print("❌ RPM: No valid avatar ID found in export data")
            return
        }
        
        // Validate ID format: must be 24-character hex string
        let idRegex = "^[0-9a-f]{24}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", idRegex)
        
        if !predicate.evaluate(with: id) {
            print("❌ RPM: Invalid avatar ID format: \(id) (must be 24-character hex)")
            return
        }
        
        print("✅ RPM: Valid avatar ID: \(id)")
        
        // Call the callback with validated ID
        onAvatarExported?(id)
        
        // Dismiss the creator
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.onDismiss?()
            }
        }
    }
}

// MARK: - SwiftUI Wrapper

struct AvatarCreatorView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onAvatarExported: (String) -> Void
    
    func makeUIViewController(context: Context) -> AvatarCreatorViewController {
        return AvatarCreatorViewController(isPresented: $isPresented, onAvatarExported: onAvatarExported)
    }
    
    func updateUIViewController(_ uiViewController: AvatarCreatorViewController, context: Context) {
        // No updates needed
    }
}