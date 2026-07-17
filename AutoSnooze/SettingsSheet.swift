import SwiftUI

struct SettingsSheet: View {
    @Environment(AlarmStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                ForEach(store.alarms.indices, id: \.self) { i in
                    Section("Alarm \(i + 1)") {
                        Toggle("Enabled", isOn: $store.alarms[i].enabled)
                        DatePicker("Time",
                                   selection: timeBinding(for: i),
                                   displayedComponents: .hourAndMinute)
                        Picker("Sound", selection: $store.alarms[i].soundName) {
                            ForEach(AlarmStore.soundNames, id: \.self) { name in
                                Text(name.capitalized).tag(name)
                            }
                        }
                        .onChange(of: store.alarms[i].soundName) { _, newValue in
                            AlarmSoundPlayer.shared.play(newValue)
                        }
                    }
                }
                Section {
                } footer: {
                    Text("Each alarm plays its sound once — no repeat, no snooze. Alarms only sound while the app is open.")
                }
            }
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func timeBinding(for i: Int) -> Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: store.alarms[i].hour,
                                  minute: store.alarms[i].minute,
                                  second: 0,
                                  of: Date()) ?? Date()
        } set: { date in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            store.alarms[i].hour = c.hour ?? 0
            store.alarms[i].minute = c.minute ?? 0
        }
    }
}

#Preview {
    SettingsSheet()
        .environment(AlarmStore())
}
