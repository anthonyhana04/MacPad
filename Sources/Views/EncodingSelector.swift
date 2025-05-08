// Sources/Views/EncodingSelector.swift
import SwiftUI

struct EncodingSelector: View {
    @EnvironmentObject private var encodingManager: EncodingManager
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: { showingPicker.toggle() }) {
            HStack(spacing: 4) {
                Text(encodingManager.currentEncoding.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .frame(minWidth: 60, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
                    .font(.system(size: 10))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(height: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Select Encoding")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(encodingManager.availableEncodings) { option in
                            Button {
                                encodingManager.setEncoding(option)
                                showingPicker = false
                            } label: {
                                HStack {
                                    Text(option.name)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if option.id == encodingManager.currentEncoding.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            if option.id != encodingManager.availableEncodings.last?.id {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
                .frame(width: 220, height: min(CGFloat(encodingManager.availableEncodings.count) * 32, 300))
            }
        }
    }
}
