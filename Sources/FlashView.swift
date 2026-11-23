import SwiftUI
import UIKit

struct FlashView: View {
    @ObservedObject var controller: FlashController

    /// Как показывать фото.
    /// true  — фото заполняет весь экран, лишние края обрезаются (максимально «экран превратился в фото»).
    /// false — фото видно целиком, а пустые поля сверху/снизу закрывает размытая копия этого же фото.
    static let fillScreen = true

    /// Куда сдвигать кадр при fillScreen: 0 — центр, 0.5 — край.
    /// Для этого фото 0.25: человек стоит левее центра, без сдвига ему режет лицо.
    static let horizontalBias: CGFloat = 0.25

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                if controller.isVisible, let photo = controller.photo {
                    photoLayer(photo, size: geometry.size)
                        .transition(.opacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            // Тап по экрану — повтор вспышки. Удобно проверять звук и тайминги без передёргивания кабеля.
            .onTapGesture {
                controller.trigger()
            }
        }
        .ignoresSafeArea()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func photoLayer(_ photo: UIImage, size: CGSize) -> some View {
        if Self.fillScreen {
            ZStack {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .offset(x: cropShift(photo, size: size))
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        } else {
            ZStack {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .blur(radius: 40)
                    .overlay(Color.black.opacity(0.35))

                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    /// Насколько сдвинуть фото, чтобы обрезка пришлась не по центру, а по horizontalBias.
    private func cropShift(_ photo: UIImage, size: CGSize) -> CGFloat {
        let imageWidth = photo.size.width
        let imageHeight = photo.size.height
        guard imageWidth > 0, imageHeight > 0, size.width > 0, size.height > 0 else { return 0 }
        let scale = max(size.width / imageWidth, size.height / imageHeight)
        let overflow = imageWidth * scale - size.width
        return max(0, overflow) * Self.horizontalBias
    }
}
