import SwiftUI
import UIKit

@main
struct ChargerFlashApp: App {

    @StateObject private var flash = FlashController()

    var body: some Scene {
        WindowGroup {
            FlashView(controller: flash)
                // Холодный старт: приложение открыли из автоматизации Shortcuts.
                .onAppear {
                    flash.trigger()
                }
                // Приложение уже висело в фоне и его снова открыли — вспышка повторяется.
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    flash.trigger()
                }
        }
    }
}

/*
 Автозакрытие приложения после вспышки.
 iOS не даёт публичного способа свернуть приложение, поэтому есть только приватный трюк.
 Для личной сборки (Sideloadly / AltStore) он работает, для App Store — нет.

 Включить: раскомментировать строку в FlashController.flashFinished() или вызвать здесь
 после вспышки:

     UIApplication.shared.perform(Selector(("suspend")))

 Тогда после фото телефон вернётся на домашний экран / в предыдущее приложение.
*/
