import SwiftUI
import WebKit
import Combine

/// SwiftUI wrapper for the Ready Player Me Avatar Creator
struct AvatarCreatorView: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    let onAvatarExported: (String) -> Void
    
    func makeUIViewController(context: Context) -> AvatarCreatorViewController {
        let controller = AvatarCreatorViewController()
        
        controller.setCallbacks(
            onAvatarExported: { avatarId in
                onAvatarExported(avatarId)
            },
            onDismiss: {
                isPresented = false
            }
        )
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AvatarCreatorViewController, context: Context) {
        // No updates needed
    }
}

/// SwiftUI WebView wrapper with Frame API support
struct WebViewRepresentable: UIViewRepresentable {
    @Binding var isPresented: Bool
    let onAvatarExported: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Enable camera access
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Add message handler for Frame API
        config.userContentController.add(context.coordinator, name: "readyPlayerMe")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Load the creator URL
        let url = URL(string: ReadyPlayerMeConfig.creatorURL())!
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    var parent: WebViewRepresentable
    
    init(_ parent: WebViewRepresentable) {
        self.parent = parent
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject JavaScript to listen for Frame API events
        let script = """
        window.addEventListener('message', function(event) {
            if (event.data && event.data.type) {
                window.webkit.messageHandlers.readyPlayerMe.postMessage({
                    type: event.data.type,
                    data: event.data.data
                });
            }
        });
        
        // Listen for Ready Player Me events
        if (window.ReadyPlayerMe) {
            window.ReadyPlayerMe.on('v1.frame.ready', function() {
                window.webkit.messageHandlers.readyPlayerMe.postMessage({
                    type: 'v1.frame.ready',
                    data: {}
                });
            });
            
            window.ReadyPlayerMe.on('v1.scene.ready', function() {
                window.webkit.messageHandlers.readyPlayerMe.postMessage({
                    type: 'v1.scene.ready',
                    data: {}
                });
            });
            
            window.ReadyPlayerMe.on('v1.user.set', function(data) {
                window.webkit.messageHandlers.readyPlayerMe.postMessage({
                    type: 'v1.user.set',
                    data: data
                });
            });
            
            window.ReadyPlayerMe.on('v1.avatar.exported', function(data) {
                window.webkit.messageHandlers.readyPlayerMe.postMessage({
                    type: 'v1.avatar.exported',
                    data: data
                });
            });
        }
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Failed to inject Frame API script: \(error)")
            } else {
                print("✅ Frame API script injected successfully")
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView navigation failed: \(error)")
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle popup windows (like camera)
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }
        
        let data = body["data"] as? [String: Any] ?? [:]
        
        switch type {
        case ReadyPlayerMeConfig.FrameEvents.frameReady:
            print("✅ Frame API ready")
            
        case ReadyPlayerMeConfig.FrameEvents.sceneReady:
            print("✅ Scene ready")
            
        case ReadyPlayerMeConfig.FrameEvents.userSet:
            print("✅ User set: \(data)")
            
        case ReadyPlayerMeConfig.FrameEvents.avatarExported:
            handleAvatarExported(data: data)
            
        default:
            print("📨 Unknown Frame API event: \(type)")
        }
    }
    
    private func handleAvatarExported(data: [String: Any]) {
        guard let avatarId = data["avatarId"] as? String else {
            print("❌ No avatarId in export data")
            return
        }
        
        print("✅ Avatar exported: \(avatarId)")
        
        // Call the callback
        parent.onAvatarExported(avatarId)
        
        // Dismiss the creator
        DispatchQueue.main.async {
            self.parent.isPresented = false
        }
    }
}
