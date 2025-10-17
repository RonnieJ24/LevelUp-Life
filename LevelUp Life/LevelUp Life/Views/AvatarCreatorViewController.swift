import UIKit
import WebKit
import SwiftUI

/// UIKit ViewController to host the Ready Player Me WebView Creator
/// Rebuilt with proper WKWebView configuration for reliable Frame API communication
class AvatarCreatorViewController: UIViewController {
    
    // MARK: - Properties
    private var webView: WKWebView!
    private var onAvatarExported: ((String) -> Void)?
    private var onDismiss: (() -> Void)?
    
    // MARK: - Loading State Management
    private var isLoading = true
    private var frameReadyReceived = false
    private var retryCount = 0
    private let maxRetries = 2
    private var frameReadyTimer: Timer?
    
    // MARK: - Shared Configuration
    private static let sharedProcessPool = WKProcessPool()
    private static let sharedDataStore = WKWebsiteDataStore.default()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadCreator()
    }
    
    deinit {
        frameReadyTimer?.invalidate()
    }
    
    // MARK: - WebView Setup
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        
        // Use shared process pool and data store for persistent cookies
        config.processPool = Self.sharedProcessPool
        config.websiteDataStore = Self.sharedDataStore
        
        // Enable JavaScript and allow arbitrary loads
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Enable camera access and media playback
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        
        // Add message handler for Frame API (required for postMessage events)
        config.userContentController.add(self, name: "readyPlayerMe")
        
        // Add console logging for debugging
        config.userContentController.add(self, name: "console")
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Enable user interaction
        webView.isUserInteractionEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        
        view.addSubview(webView)
    }
    
    // MARK: - Creator Loading
    
    private func loadCreator() {
        let creatorURL = ReadyPlayerMeConfig.creatorURL(withCacheBuster: true)
        print("🔧 RPM Debug: Loading Ready Player Me creator from: \(creatorURL)")
        
        guard let url = URL(string: creatorURL) else {
            print("❌ RPM Debug: Invalid creator URL: \(creatorURL)")
            showErrorAndFallback()
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        print("🔧 RPM Debug: Starting web view load...")
        isLoading = true
        frameReadyReceived = false
        
        // Start frame ready timeout
        startFrameReadyTimeout()
        
        webView.load(request)
    }
    
    private func startFrameReadyTimeout() {
        frameReadyTimer?.invalidate()
        frameReadyTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            self?.handleFrameReadyTimeout()
        }
        
        // Also start a fallback timer that considers the creator ready after 5 seconds
        // if no errors have occurred and the page has loaded successfully
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.checkIfCreatorIsReady()
        }
    }
    
    private func checkIfCreatorIsReady() {
        guard !frameReadyReceived else { return }
        
        // Check if the page has loaded and no errors occurred
        let readyCheckScript = """
        (function() {
            // Check if the page is loaded and has content
            if (document.readyState === 'complete' && document.body && document.body.children.length > 0) {
                console.log('🔍 RPM: Page appears to be loaded, checking for Ready Player Me...');
                
                // Check for Ready Player Me specific elements
                const rpmElements = document.querySelectorAll('[class*="rpm"], [id*="rpm"], [class*="avatar"], [id*="avatar"]');
                if (rpmElements.length > 0) {
                    console.log('✅ RPM: Found RPM elements, creator appears ready');
                    return { ready: true, reason: 'rpm_elements_found' };
                }
                
                // Check if there's an iframe or canvas (common RPM elements)
                const iframes = document.querySelectorAll('iframe');
                const canvases = document.querySelectorAll('canvas');
                if (iframes.length > 0 || canvases.length > 0) {
                    console.log('✅ RPM: Found iframe/canvas, creator appears ready');
                    return { ready: true, reason: 'media_elements_found' };
                }
                
                // Check for any interactive elements (buttons, inputs)
                const interactiveElements = document.querySelectorAll('button, input, select, textarea');
                if (interactiveElements.length > 0) {
                    console.log('✅ RPM: Found interactive elements, creator appears ready');
                    return { ready: true, reason: 'interactive_elements_found' };
                }
                
                console.log('⚠️ RPM: Page loaded but no RPM elements found');
                return { ready: false, reason: 'no_rpm_elements' };
            }
            
            return { ready: false, reason: 'page_not_loaded' };
        })();
        """
        
        webView.evaluateJavaScript(readyCheckScript) { [weak self] result, error in
            if let error = error {
                print("❌ RPM: Ready check failed: \(error.localizedDescription)")
                return
            }
            
            if let resultDict = result as? [String: Any],
               let ready = resultDict["ready"] as? Bool,
               let reason = resultDict["reason"] as? String {
                
                print("🔍 RPM: Ready check result: \(ready), reason: \(reason)")
                
                if ready && !(self?.frameReadyReceived ?? true) {
                    print("✅ RPM: Creator appears ready based on page analysis")
                    self?.handleFrameReady()
                }
            }
        }
    }
    
    private func handleFrameReadyTimeout() {
        guard !frameReadyReceived else { return }
        
        print("⏰ RPM Debug: Frame ready timeout after 8 seconds")
        
        if retryCount < maxRetries {
            retryCount += 1
            print("🔄 RPM Debug: Retrying load (attempt \(retryCount)/\(maxRetries))")
            loadCreator()
        } else {
            print("❌ RPM Debug: Max retries reached, showing error")
            showErrorAndFallback()
        }
    }
    
    private func showErrorAndFallback() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Avatar Creator Unavailable",
                message: "The avatar creator couldn't load properly. Would you like to open it in Safari instead?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Open in Safari", style: .default) { _ in
                self.openInSafari()
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.dismissCreator()
            })
            
            self.present(alert, animated: true)
        }
    }
    
    private func openInSafari() {
        let creatorURL = ReadyPlayerMeConfig.creatorURL(withCacheBuster: false)
        if let url = URL(string: creatorURL) {
            UIApplication.shared.open(url)
        }
        dismissCreator()
    }
    
    private func dismissCreator() {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.onDismiss?()
            }
        }
    }
    
    // MARK: - Callbacks
    
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
        
        // Wait a bit for the page to fully load before injecting script
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.injectFrameAPIScript()
        }
    }
    
    private func injectFrameAPIScript() {
        let script = """
        (function() {
            console.log('🔧 RPM: Frame API initialization...');
            
            // Override console.log to forward messages to native
            const originalLog = console.log;
            const originalError = console.error;
            const originalWarn = console.warn;
            
            function forwardConsoleMessage(level, args) {
                try {
                    window.webkit.messageHandlers.console.postMessage({
                        message: Array.from(args).map(arg => String(arg)).join(' ')
                    });
                } catch (e) {
                    // Ignore console forwarding errors
                }
            }
            
            console.log = function(...args) {
                originalLog.apply(console, args);
                forwardConsoleMessage('log', args);
            };
            
            console.error = function(...args) {
                originalError.apply(console, args);
                forwardConsoleMessage('error', args);
            };
            
            console.warn = function(...args) {
                originalWarn.apply(console, args);
                forwardConsoleMessage('warn', args);
            };
            
            // Function to forward messages to native
            function forwardToNative(type, data) {
                try {
                    window.webkit.messageHandlers.readyPlayerMe.postMessage({
                        type: type,
                        data: data || {}
                    });
                    console.log('📤 RPM: Forwarded event to native:', type);
                } catch (e) {
                    console.error('❌ RPM: Failed to forward event:', e);
                }
            }
            
            // Listen for postMessage events from RPM iframe
            window.addEventListener('message', function(event) {
                console.log('📨 RPM: Received postMessage:', event.origin, event.data);
                
                // Check if this is from Ready Player Me
                if (event.origin.includes('readyplayer.me')) {
                    console.log('📨 RPM: Message from RPM origin:', event.origin);
                    
                    // Try to parse the data
                    let data = event.data;
                    if (typeof data === 'string') {
                        try {
                            data = JSON.parse(data);
                        } catch (e) {
                            console.log('📨 RPM: Could not parse message data:', data);
                            return;
                        }
                    }
                    
                    console.log('📨 RPM: Parsed data:', data);
                    
                    // Handle different event formats
                    if (data.eventName) {
                        console.log('📨 RPM: Event name format:', data.eventName);
                        forwardToNative(data.eventName, data.data || {});
                    } else if (data.type) {
                        console.log('📨 RPM: Type format:', data.type);
                        forwardToNative(data.type, data.data || {});
                    } else {
                        console.log('📨 RPM: Unknown message format:', data);
                    }
                }
            });
            
            // Also listen for Ready Player Me specific events if available
            if (window.ReadyPlayerMe) {
                console.log('🔧 RPM: ReadyPlayerMe object found, setting up listeners...');
                
                window.ReadyPlayerMe.on('v1.frame.ready', function() {
                    console.log('✅ RPM: Frame ready event received');
                    forwardToNative('v1.frame.ready', {});
                });
                
                window.ReadyPlayerMe.on('v1.scene.ready', function() {
                    console.log('✅ RPM: Scene ready event received');
                    forwardToNative('v1.scene.ready', {});
                });
                
                window.ReadyPlayerMe.on('v1.user.set', function(data) {
                    console.log('✅ RPM: User set event received');
                    forwardToNative('v1.user.set', data);
                });
                
                window.ReadyPlayerMe.on('v1.avatar.exported', function(data) {
                    console.log('✅ RPM: Avatar exported event received');
                    forwardToNative('v1.avatar.exported', data);
                });
            } else {
                console.log('⚠️ RPM: ReadyPlayerMe object not found, relying on postMessage only');
            }
            
            // Send a test message to verify the bridge is working
            setTimeout(function() {
                console.log('🧪 RPM: Sending test message...');
                forwardToNative('test', { message: 'Frame API bridge is working' });
            }, 2000);
            
            // Add export button to the creator interface - wait longer for RPM to load
            setTimeout(function() {
                addExportButton();
            }, 5000);
            
            // Function to add export button
            function addExportButton() {
                console.log('🔧 RPM: Adding export button...');
                
                // Look for the Ready Player Me interface elements
                const rpmContainer = document.querySelector('[class*="rpm"], [id*="rpm"], [class*="avatar"], [id*="avatar"]') || 
                                   document.querySelector('iframe') || 
                                   document.body;
                
                if (!rpmContainer) {
                    console.log('⚠️ RPM: Could not find container for export button');
                    return;
                }
                
                // Check if button already exists
                if (document.querySelector('#rpm-export-button')) {
                    console.log('⚠️ RPM: Export button already exists');
                    return;
                }
                
                // Create export button
                const exportButton = document.createElement('button');
                exportButton.id = 'rpm-export-button';
                exportButton.innerHTML = '📤 Export Avatar';
                exportButton.style.cssText = `
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    z-index: 10000;
                    background: #007AFF;
                    color: white;
                    border: none;
                    border-radius: 8px;
                    padding: 12px 16px;
                    font-size: 14px;
                    font-weight: 600;
                    cursor: pointer;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.3);
                    transition: all 0.2s ease;
                `;
                
                // Add hover effect
                exportButton.addEventListener('mouseenter', function() {
                    this.style.background = '#0056CC';
                    this.style.transform = 'translateY(-1px)';
                });
                
                exportButton.addEventListener('mouseleave', function() {
                    this.style.background = '#007AFF';
                    this.style.transform = 'translateY(0)';
                });
                
                // Add click handler
                exportButton.addEventListener('click', function() {
                    console.log('📤 RPM: Export button clicked');
                    
                    // Show loading state
                    const originalText = this.innerHTML;
                    this.innerHTML = '⏳ Exporting...';
                    this.disabled = true;
                    
                    // Try export
                    exportAvatar();
                    
                    // Reset button after 3 seconds
                    setTimeout(() => {
                        this.innerHTML = originalText;
                        this.disabled = false;
                    }, 3000);
                });
                
                // Add button to page
                document.body.appendChild(exportButton);
                console.log('✅ RPM: Export button added successfully');
                
                // Try to extract avatar ID immediately for debugging
                const currentAvatarId = extractAvatarIdFromURL();
                if (currentAvatarId) {
                    console.log('🎯 RPM: Avatar ID detected:', currentAvatarId);
                    // Update button text to show ID is available
                    exportButton.innerHTML = '📤 Export (' + currentAvatarId.substring(0, 8) + '...)';
                } else {
                    console.log('⚠️ RPM: No avatar ID detected yet');
                }
            }
            
            // Function to trigger avatar export
            function exportAvatar() {
                console.log('📤 RPM: Triggering avatar export...');
                
                // Try Ready Player Me API first if available
                if (window.ReadyPlayerMe) {
                    console.log('✅ RPM: ReadyPlayerMe object found, using API');
                    tryRPMExport();
                } else {
                    console.log('⚠️ RPM: ReadyPlayerMe object not found, trying alternative methods');
                    tryAlternativeExport();
                }
            }
            
            // Try Ready Player Me API methods
            function tryRPMExport() {
                // Try multiple methods to trigger export
                if (window.ReadyPlayerMe.exportAvatar) {
                    console.log('📤 RPM: Using ReadyPlayerMe.exportAvatar()');
                    try {
                        window.ReadyPlayerMe.exportAvatar();
                        return;
                    } catch (e) {
                        console.log('❌ RPM: exportAvatar failed:', e);
                    }
                }
                
                if (window.ReadyPlayerMe.export) {
                    console.log('📤 RPM: Using ReadyPlayerMe.export()');
                    try {
                        window.ReadyPlayerMe.export();
                        return;
                    } catch (e) {
                        console.log('❌ RPM: export failed:', e);
                    }
                }
                
                console.log('❌ RPM: No export methods found on ReadyPlayerMe object');
                tryAlternativeExport();
            }
            
            // Alternative export methods
            function tryAlternativeExport() {
                console.log('📤 RPM: Trying alternative export methods...');
                
                // First, try to extract avatar ID from URL
                const avatarId = extractAvatarIdFromURL();
                if (avatarId) {
                    console.log('📤 RPM: Found avatar ID in URL:', avatarId);
                    console.log('📤 RPM: Triggering export with extracted ID');
                    forwardToNative('v1.avatar.exported', {
                        avatarId: avatarId,
                        url: 'https://models.readyplayer.me/' + avatarId + '.glb'
                    });
                    return;
                }
                
                // Try to find and click the export button in the interface
                const exportButtons = document.querySelectorAll('[class*="export"], [id*="export"], button[class*="save"], button[class*="download"], button[class*="done"], button[class*="finish"]');
                if (exportButtons.length > 0) {
                    console.log('📤 RPM: Found export button in interface, clicking...');
                    exportButtons[0].click();
                } else {
                    console.log('📤 RPM: No export button found, trying to trigger via events...');
                    // Try to trigger export via custom events
                    const event = new CustomEvent('avatarExport', { detail: { source: 'manual' } });
                    document.dispatchEvent(event);
                    
                    // Also try window events
                    window.dispatchEvent(event);
                    
                    // As last resort, send a manual export event
                    setTimeout(function() {
                        console.log('📤 RPM: Sending manual export event as fallback');
                        forwardToNative('v1.avatar.exported', {
                            avatarId: 'manual_export_' + Date.now(),
                            url: 'https://models.readyplayer.me/manual_export.glb'
                        });
                    }, 2000);
                }
            }
            
            // Function to extract avatar ID from URL
            function extractAvatarIdFromURL() {
                console.log('🔍 RPM: Extracting avatar ID from URL...');
                const currentURL = window.location.href;
                console.log('🔍 RPM: Current URL:', currentURL);
                
                // Try to extract ID from URL parameters
                const urlParams = new URLSearchParams(window.location.search);
                const idParam = urlParams.get('id');
                if (idParam) {
                    console.log('✅ RPM: Found ID parameter:', idParam);
                    return idParam;
                }
                
                // Try to extract from URL path or other patterns
                const idMatch = currentURL.match(/[?&]id=([a-f0-9]{24})/);
                if (idMatch && idMatch[1]) {
                    console.log('✅ RPM: Found ID in URL pattern:', idMatch[1]);
                    return idMatch[1];
                }
                
                // Try to find ID in the page content or other elements
                const idElements = document.querySelectorAll('[data-avatar-id], [data-id], [id*="avatar"]');
                for (let element of idElements) {
                    const id = element.getAttribute('data-avatar-id') || 
                               element.getAttribute('data-id') || 
                               element.id;
                    if (id && /^[a-f0-9]{24}$/.test(id)) {
                        console.log('✅ RPM: Found ID in element:', id);
                        return id;
                    }
                }
                
                console.log('❌ RPM: No avatar ID found in URL or page');
                return null;
            }
            
            console.log('✅ RPM: Message listener installed');
        })();
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ RPM: Script injection failed: \(error.localizedDescription)")
            } else {
                print("✅ RPM: Frame API script injected, waiting for events...")
                
                // Check if Ready Player Me is loaded
                self.checkReadyPlayerMeStatus()
            }
        }
    }
    
    private func checkReadyPlayerMeStatus() {
        let checkScript = """
        (function() {
            console.log('🔍 RPM: Checking Ready Player Me status...');
            
            // Check if ReadyPlayerMe object exists
            if (window.ReadyPlayerMe) {
                console.log('✅ RPM: ReadyPlayerMe object found');
                return {
                    readyPlayerMeExists: 1,
                    readyPlayerMeVersion: window.ReadyPlayerMe.version || 'unknown',
                    pageTitle: document.title,
                    pageURL: window.location.href
                };
            } else {
                console.log('❌ RPM: ReadyPlayerMe object not found');
                
                // Check if the page is still loading or if there are any RPM-related elements
                const rpmElements = document.querySelectorAll('[class*="rpm"], [id*="rpm"], [class*="ready"], [id*="ready"], iframe, canvas');
                const hasRPMContent = rpmElements.length > 0;
                
                return {
                    readyPlayerMeExists: 0,
                    pageTitle: document.title,
                    pageURL: window.location.href,
                    hasRPMContent: hasRPMContent,
                    rpmElementsCount: rpmElements.length
                };
            }
        })();
        """
        
        webView.evaluateJavaScript(checkScript) { result, error in
            if let error = error {
                print("❌ RPM: Status check failed: \(error.localizedDescription)")
            } else {
                print("🔍 RPM: Status check result: \(result ?? "nil")")
                
                // If Ready Player Me is not found but we have RPM content, wait a bit more
                if let resultDict = result as? [String: Any],
                   let exists = resultDict["readyPlayerMeExists"] as? Int,
                   exists == 0,
                   let hasContent = resultDict["hasRPMContent"] as? Bool,
                   hasContent {
                    print("⏳ RPM: Ready Player Me not ready but content detected, waiting...");
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.checkReadyPlayerMeStatus()
                    }
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ RPM: Navigation failed: \(error.localizedDescription)")
        handleFrameReadyTimeout()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ RPM: Provisional navigation failed: \(error.localizedDescription)")
        handleFrameReadyTimeout()
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
        case ReadyPlayerMeConfig.FrameEvents.frameReady:
            handleFrameReady()
            
        case ReadyPlayerMeConfig.FrameEvents.sceneReady:
            print("✅ Scene ready")
            
        case ReadyPlayerMeConfig.FrameEvents.userSet:
            print("✅ User set: \(data)")
            
        case ReadyPlayerMeConfig.FrameEvents.avatarExported, ReadyPlayerMeConfig.FrameEvents.avatarExportedNew:
            handleAvatarExported(data: data)
            
        case "test":
            print("🧪 RPM: Test message received - Frame API bridge is working!")
            // Don't treat test messages as frame ready
            
        case "console":
            // Handle console messages from JavaScript
            if let message = body["message"] as? String {
                print("🌐 Console: \(message)")
            }
            
        default:
            print("📨 Unknown Frame API event: \(type)")
        }
    }
    
    private func handleFrameReady() {
        print("✅ RPM: Frame API ready")
        frameReadyReceived = true
        isLoading = false
        frameReadyTimer?.invalidate()
    }
    
    private func handleAvatarExported(data: [String: Any]) {
        print("🔍 RPM: Avatar exported, extracting ID from data: \(data)")
        print("🔍 RPM: Data keys: \(Array(data.keys))")
        
        var avatarId: String?
        
        // Method 1: Extract from data.url (e.g., "https://models.readyplayer.me/{id}.glb")
        if let urlString = data["url"] as? String {
            print("🔍 RPM: Found URL in data: \(urlString)")
            if let url = URL(string: urlString) {
                // Get last path component and strip .glb extension
                let filename = url.lastPathComponent
                avatarId = filename.replacingOccurrences(of: ".glb", with: "")
                print("✅ RPM: Extracted avatar ID from URL: \(avatarId ?? "nil")")
            }
        }
        
        // Method 2: Fallback to direct avatarId field
        if avatarId == nil {
            avatarId = data["avatarId"] as? String
            print("✅ RPM: Got avatar ID from data.avatarId: \(avatarId ?? "nil")")
        }
        
        // Method 3: Check for other possible fields
        if avatarId == nil {
            if let id = data["id"] as? String {
                avatarId = id
                print("✅ RPM: Got avatar ID from data.id: \(id)")
            }
        }
        
        // Method 4: Check for nested data
        if avatarId == nil, let nestedData = data["data"] as? [String: Any] {
            avatarId = nestedData["avatarId"] as? String
            print("✅ RPM: Got avatar ID from nested data: \(avatarId ?? "nil")")
        }
        
        guard let id = avatarId, !id.isEmpty else {
            print("❌ RPM: No valid avatar ID found in export data")
            print("❌ RPM: Available data fields: \(data)")
            return
        }
        
        // Validate ID format: must be 24-character hex string
        let idRegex = "^[0-9a-f]{24}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", idRegex)
        
        if !predicate.evaluate(with: id) {
            print("❌ RPM: Invalid avatar ID format: \(id) (must be 24-character hex)")
            print("❌ RPM: ID length: \(id.count), characters: \(id)")
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