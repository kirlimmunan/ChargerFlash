import SwiftUI
import UIKit
import AVFoundation
import AudioToolbox

/// Вся логика вспышки: загрузка фото и звука, проигрывание, тайминги.
@MainActor
final class FlashController: ObservableObject {

    // MARK: - Настройки (правь здесь)

    /// Сколько миллисекунд фото держится на экране.
    /// 100–400 мс — то, что человек воспринимает как «вспышку». Меньше 50 мс уже не видно.
    static let holdMilliseconds: Int = 250

    /// Плавное исчезновение, мс. 0 — исчезает мгновенно.
    static let fadeMilliseconds: Int = 120

    /// Громкость 0...1.
    static let volume: Float = 1.0

    /// true — не останавливать музыку в наушниках, а только приглушать её.
    static let duckOtherAudio: Bool = false

    /// Защита от двойного срабатывания при холодном старте (onAppear + didBecomeActive).
    static let debounce: TimeInterval = 0.5

    /// Имена файлов в бандле (без расширения). Первое найденное побеждает.
    static let photoNames = ["flash-photo", "photo", "flash"]
    static let soundNames = ["flash-sound", "sound", "charger"]

    static let photoExtensions = ["jpg", "jpeg", "png", "heic", "heif"]
    static let soundExtensions = ["m4a", "mp3", "wav", "caf", "aiff", "aif", "aac"]

    // MARK: - Состояние

    @Published private(set) var isVisible = false
    private(set) var photo: UIImage?

    private var player: AVAudioPlayer?
    private var lastTrigger = Date.distantPast
    private var hideTask: Task<Void, Never>?

    init() {
        photo = Self.loadPhoto()
        player = Self.loadSound()
        Self.configureAudioSession()
    }

    /// Запустить вспышку: звук + фото.
    func trigger() {
        let now = Date()
        guard now.timeIntervalSince(lastTrigger) >= Self.debounce else { return }
        lastTrigger = now

        playSound()

        hideTask?.cancel()
        withAnimation(.linear(duration: 0.01)) {
            isVisible = true
        }

        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(Self.holdMilliseconds))
            guard !Task.isCancelled, let self else { return }
            withAnimation(.easeOut(duration: Double(Self.fadeMilliseconds) / 1000)) {
                self.isVisible = false
            }
        }
    }

    // MARK: - Звук

    private func playSound() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)

        guard let player else {
            // Файла нет — хотя бы системный «тик», чтобы было слышно, что триггер сработал.
            AudioServicesPlaySystemSound(1104)
            return
        }

        player.volume = Self.volume
        if player.isPlaying {
            player.currentTime = 0
        } else {
            player.prepareToPlay()
        }
        player.play()
    }

    private static func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        let options: AVAudioSession.CategoryOptions = duckOtherAudio ? [.duckOthers] : []
        // Категория .playback играет даже при включённом бесшумном режиме.
        try? session.setCategory(.playback, mode: .default, options: options)
    }

    private static func loadSound() -> AVAudioPlayer? {
        for name in soundNames {
            for ext in soundExtensions {
                guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { continue }
                guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }
                player.volume = volume
                player.prepareToPlay()
                return player
            }
        }
        return nil
    }

    // MARK: - Фото

    private static func loadPhoto() -> UIImage? {
        // Если положить фото в Assets.xcassets как "FlashPhoto" — возьмётся оттуда.
        if let image = UIImage(named: "FlashPhoto") {
            return image
        }
        for name in photoNames {
            for ext in photoExtensions {
                guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { continue }
                if let image = UIImage(contentsOfFile: url.path) {
                    return image
                }
            }
        }
        return nil
    }
}
