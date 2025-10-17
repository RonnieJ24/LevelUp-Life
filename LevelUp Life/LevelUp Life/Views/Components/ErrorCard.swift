import SwiftUI

/// Error card component - no fallback avatars, only error state
struct ErrorCard: View {
    let error: Error
    let debugTicket: String?
    let onRetry: () -> Void
    let onOpenCreator: () -> Void
    
    @State private var showingDebugInfo = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            // Error Content
            VStack(spacing: 12) {
                Text("Avatar Error")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("We couldn't load your Ready Player Me model.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let debugTicket = debugTicket {
                    Text("Debug ID: \(debugTicket)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Open Creator") {
                    onOpenCreator()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                #if DEBUG
                if let debugTicket = debugTicket {
                    Button("Copy Debug ID") {
                        UIPasteboard.general.string = debugTicket
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .font(.caption)
                }
                #endif
            }
            
            // Debug Info (Dev Only)
            #if DEBUG
            Button("Show Debug Info") {
                showingDebugInfo.toggle()
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .font(.caption)
            
            if showingDebugInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug Information:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.top)
            }
            #endif
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ErrorCard(
        error: NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error message"]),
        debugTicket: "AVT-2025-000123",
        onRetry: {},
        onOpenCreator: {}
    )
    .background(Color(.systemGroupedBackground))
}
