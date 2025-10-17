import SwiftUI

/// Quick Adjust Bar for Avatar Workshop v1.1
struct QuickAdjustBar: View {
    @Binding var lightingPreset: String
    @Binding var backgroundPreset: String
    @Binding var scaleMultiplier: Float
    
    var onPresetChange: (String) -> Void
    var onBackgroundChange: (String) -> Void
    var onScaleChange: (Float) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Lighting Preset Menu
            Menu {
                Button("Studio") { 
                    lightingPreset = "studio"
                    onPresetChange("studio")
                }
                Button("Daylight") { 
                    lightingPreset = "daylight"
                    onPresetChange("daylight")
                }
                Button("Cyber") { 
                    lightingPreset = "cyber"
                    onPresetChange("cyber")
                }
            } label: {
                Label("Lighting", systemImage: "lightbulb")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            
            // Scale Slider
            VStack(spacing: 4) {
                Text("Scale")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { Double(scaleMultiplier) },
                    set: { 
                        scaleMultiplier = Float($0)
                        onScaleChange(Float($0))
                    }
                ), in: 0.8...1.3)
                .frame(width: 120)
                .tint(.purple)
            }
            
            // Background Preset Menu
            Menu {
                Button("Black") { 
                    backgroundPreset = "black"
                    onBackgroundChange("black")
                }
                Button("Gradient") { 
                    backgroundPreset = "gradient"
                    onBackgroundChange("gradient")
                }
            } label: {
                Label("BG", systemImage: "photo")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
}

/// Avatar Workshop Controls Panel
struct AvatarWorkshopControls: View {
    @Binding var lightingPreset: String
    @Binding var backgroundPreset: String
    @Binding var scaleMultiplier: Float
    @Binding var showDevTools: Bool
    
    var onPresetChange: (String) -> Void
    var onBackgroundChange: (String) -> Void
    var onScaleChange: (Float) -> Void
    var onDevToolsToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick Adjust Bar
            QuickAdjustBar(
                lightingPreset: $lightingPreset,
                backgroundPreset: $backgroundPreset,
                scaleMultiplier: $scaleMultiplier,
                onPresetChange: onPresetChange,
                onBackgroundChange: onBackgroundChange,
                onScaleChange: onScaleChange
            )
            
            // Bottom Toolbar
            HStack {
                Button(action: onDevToolsToggle) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Avatar Workshop v1.1")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "camera")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
}
