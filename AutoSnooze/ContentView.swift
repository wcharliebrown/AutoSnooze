import SwiftUI

struct ContentView: View {
    @Environment(AlarmStore.self) private var store
    @State private var showSettings = false
    @AppStorage("displayBrightness") private var brightness = 1.0
    @State private var showBrightnessSlider = false
    @State private var sliderHideToken = UUID()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TimelineView(.everyMinute) { context in
                let c = Calendar.current.dateComponents([.hour, .minute], from: context.date)
                ClockFaceView(hour: c.hour ?? 0,
                              minute: c.minute ?? 0,
                              alarmsEnabled: store.alarms.map(\.enabled))
            }
            .padding(24)
            .opacity(brightness)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(Color(white: 0.25))
                            .padding(12)
                    }
                }
            }

            if showBrightnessSlider {
                VStack {
                    Spacer()
                    Slider(value: $brightness, in: 0.05...1)
                        .tint(Color(red: 1.0, green: 0.165, blue: 0.0).opacity(0.7))
                        .frame(maxWidth: 320)
                        .padding(.horizontal, 44)
                        .padding(.bottom, 60)
                }
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showBrightnessSlider.toggle()
            }
            sliderHideToken = UUID()
        }
        .onChange(of: brightness) {
            sliderHideToken = UUID()
        }
        .task(id: sliderHideToken) {
            guard showBrightnessSlider else { return }
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeInOut(duration: 0.4)) {
                showBrightnessSlider = false
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }
}

#Preview {
    ContentView()
        .environment(AlarmStore())
}
