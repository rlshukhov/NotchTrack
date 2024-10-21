//
//  NotchSettingsView.swift
//  NotchDrop
//
//  Created by 曹丁杰 on 2024/7/29.
//  Edited by Lane Shukhov on 2024/10/21.
//

import LaunchAtLogin
import SwiftUI
import KeyboardShortcuts

struct NotchSettingsView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm: TrayDrop = .shared

    var body: some View {
        VStack(spacing: vm.spacing) {
            HStack {
                Picker("Language: ", selection: $vm.selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.localized).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 160)

                Spacer()
                LaunchAtLogin.Toggle {
                    Text(NSLocalizedString("Launch at Login", comment: ""))
                }

                Spacer()
                Toggle("Haptic Feedback ", isOn: $vm.hapticFeedback)
            }

            HStack {
                Text("Logs folder: ")
                TextField("Choose folder", text: .constant(tvm.logDirectory))
                    .disabled(true)
                    .textFieldStyle(.plain)
                Button("Choose") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    if panel.runModal() == .OK {
                        if let url = panel.url {
                            tvm.setLogDirectory(url)
                        }
                    }
                }
            }
            
            Form {
                KeyboardShortcuts.Recorder(NSLocalizedString("Open tracker window:", comment: ""), name: .toogleNotch)
            }
        }
        .padding(.horizontal)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
}

#Preview {
    NotchSettingsView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
