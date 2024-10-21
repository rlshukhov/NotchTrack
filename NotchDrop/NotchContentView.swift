//
//  NotchContentView.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//  Edited by Lane Shukhov on 2024/10/21.
//

import ColorfulX
import SwiftUI
import UniformTypeIdentifiers
import Cocoa

struct NotchContentView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            switch vm.contentType {
                case .normal:
                    normalView
                        .transition(
                            .scale(scale: 0.8)
                                .combined(with: .opacity)
                                .combined(with: .blur)
                        )
                case .menu:
                    NotchMenuView(vm: vm)
                        .transition(
                            .scale(scale: 0.8)
                                .combined(with: .opacity)
                                .combined(with: .blur)
                        )
                case .settings:
                    NotchSettingsView(vm: vm)
                        .transition(
                            .scale(scale: 0.8)
                                .combined(with: .opacity)
                                .combined(with: .blur)
                        )
            }
        }
        .animation(vm.animation, value: vm.contentType)
        .onAppear {
            tvm.loadEntriesFromFile()
            tvm.showLastEntry = tvm.entries.last != nil
            tvm.displayTime = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isInputFocused = true
            }
        }
    }
    
    var normalView: some View {
        VStack(spacing: vm.spacing) {
            HStack(spacing: 10) {
                CustomDatePicker(date: Binding(
                    get: { tvm.displayTime },
                    set: { newDate in
                        tvm.displayTime = newDate
                        if var entry = tvm.currentEntry {
                            entry.startTime = newDate
                            tvm.currentEntry = entry
                        }
                    }
                ))
                .disabled(tvm.isTracking)
                
                CustomTextField(placeholder: NSLocalizedString("What are you doing?", comment: ""), text: $tvm.description)
                    .focused($isInputFocused)
                    .disabled(tvm.isTracking)
                
                MainButton(
                    color: tvm.isTracking ? ColorfulPreset.sunset.colors : ColorfulPreset.colorful.colors,
                    image: Image(systemName: tvm.isTracking ? "pause.fill" : "play.fill"),
                    title: ""
                )
                .frame(width: 50, height: 50)
                .onTapGesture(perform: toggleTracking)
            }
            .padding(.horizontal)
            
            if let lastEntry = tvm.entries.last {
                LastEntryView(entry: lastEntry, show: $tvm.showLastEntry)
                    .id(tvm.lastEntryId)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top).combined(with: .blur)),
                        removal: .opacity.combined(with: .move(edge: .bottom).combined(with: .blur))
                    ))
            }
        }
    }
    
    private func toggleTracking() {
        withAnimation(.easeInOut(duration: 0.7)) {
            tvm.toggleTracking()
        }
    }
}

struct LastEntryView: View {
    let entry: TimeEntry
    @Binding var show: Bool
    
    var body: some View {
        HStack {
            Text(entry.startTime, style: .time)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            if let endTime = entry.endTime {
                Text("-")
                Text(endTime, style: .time)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            Text(entry.description)
                .font(.system(size: 12, design: .rounded))
            Spacer()
        }
        .padding(.horizontal)
        .opacity(show ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: show)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    show = true
                }
            }
        }
    }
}

struct CustomDatePicker: View {
    @Binding var date: Date
    @State private var isPickerPresented = false
    @State private var tempDate: Date
    
    init(date: Binding<Date>) {
        self._date = date
        self._tempDate = State(initialValue: date.wrappedValue)
    }
    
    var body: some View {
        Button(action: {
            tempDate = date
            isPickerPresented.toggle()
        }) {
            HStack {
                Text(date, style: .time)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Image(systemName: "clock")
            }
            .padding(10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $isPickerPresented, arrowEdge: .bottom) {
            VStack {
                DatePicker("", selection: $tempDate, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .onChange(of: tempDate) { newValue in
                        date = newValue
                    }
            }
            .frame(width: 80, height: 50)
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 18, design: .rounded))
            .padding(10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .focused($isFocused)
    }
}

struct MainButton: View {
    let color: [Color]
    let image: Image
    let title: String

    @State var hover: Bool = false

    var body: some View {
        Color.white
            .opacity(0.1)
            .overlay(
                ColorfulView(
                    color: .constant(color),
                    speed: .constant(0)
                )
                .mask {
                    VStack(spacing: 8) {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                        if !title.isEmpty {
                            Text(title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                    }
                }
                .contentShape(Rectangle())
                .scaleEffect(hover ? 1.05 : 1)
                .animation(.spring(), value: hover)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onHover { hover = $0 }
    }
}

struct BlurModifier: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

extension AnyTransition {
    static var blur: AnyTransition {
        AnyTransition.modifier(
            active: BlurModifier(radius: 10),
            identity: BlurModifier(radius: 0)
        )
    }
}

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
