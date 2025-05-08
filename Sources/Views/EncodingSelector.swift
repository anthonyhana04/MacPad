// Sources/Views/EncodingSelector.swift
import SwiftUI

struct EncodingSelector: View {
    @EnvironmentObject private var encodingManager: EncodingManager
    @State private var showingPicker = false
    @State private var searchText = ""
    
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
        .fixedSize(horizontal: true, vertical: true)
        .help("Select Text Encoding")
        .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Select Encoding")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                Divider()
                
                // Search field
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if searchText.isEmpty {
                            // Show grouped by region
                            ForEach(EncodingRegion.allCases, id: \.self) { region in
                                if let encodings = encodingManager.encodingsByRegion[region], !encodings.isEmpty {
                                    EncodingRegionSection(
                                        region: region,
                                        encodings: encodings,
                                        currentEncoding: encodingManager.currentEncoding,
                                        onSelect: { encoding in
                                            encodingManager.setEncoding(encoding)
                                            showingPicker = false
                                        }
                                    )
                                }
                            }
                        } else {
                            // Show filtered results
                            let filtered = encodingManager.availableEncodings.filter {
                                $0.name.localizedCaseInsensitiveContains(searchText) ||
                                $0.region.rawValue.localizedCaseInsensitiveContains(searchText)
                            }
                            
                            ForEach(filtered) { option in
                                EncodingOptionRow(
                                    option: option,
                                    isSelected: option.id == encodingManager.currentEncoding.id,
                                    onSelect: {
                                        encodingManager.setEncoding(option)
                                        showingPicker = false
                                    }
                                )
                                
                                if option.id != filtered.last?.id {
                                    Divider()
                                        .padding(.leading, 12)
                                }
                            }
                            
                            if filtered.isEmpty {
                                Text("No encodings match your search")
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                    }
                }
                .frame(width: 280, height: 320)
            }
        }
    }
}

struct EncodingRegionSection: View {
    let region: EncodingRegion
    let encodings: [EncodingOption]
    let currentEncoding: EncodingOption
    let onSelect: (EncodingOption) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(region.rawValue)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)
            
            ForEach(encodings) { option in
                EncodingOptionRow(
                    option: option,
                    isSelected: option.id == currentEncoding.id,
                    onSelect: { onSelect(option) }
                )
                
                if option.id != encodings.last?.id {
                    Divider()
                        .padding(.leading, 12)
                }
            }
            
            Divider()
        }
    }
}

struct EncodingOptionRow: View {
    let option: EncodingOption
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject private var encodingManager: EncodingManager
    
    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.name)
                        .font(.body)
                    
                    // Only show the script description for selected item or on hover
                    if isSelected {
                        Text(encodingManager.scriptDescription(for: option))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
