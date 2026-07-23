import CoreGraphics
import Vision

enum OCRService {
    static func recognize(in image: CGImage) async throws -> String {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = [Locale.Language(identifier: "zh-Hans"),
                                        Locale.Language(identifier: "en-US")]
        request.usesLanguageCorrection = true
        let observations = try await request.perform(on: image)
        return observations.compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
