import Foundation

// RGBValue struct definition
struct RGBValue: Codable {
    let red: Int
    let green: Int
    let blue: Int
}

// RGBStorage class definition
class RGBStorage {
    static let shared = RGBStorage()
    private let fileName = "rgbValues.json"
    private var rgbValues: [String: RGBValue] = [:]

    init() {
        loadRGBValues()
        print("Documents Directory Path: \(getDocumentsDirectory().path)")
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    private func loadRGBValues() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                rgbValues = try JSONDecoder().decode([String: RGBValue].self, from: data)
            } catch {
                print("Failed to load RGB values: \(error)")
            }
        } else {
            rgbValues = [:]  // Initialize with an empty dictionary if the file does not exist
            saveInitialRGBValues()  // Call to save an initial empty dictionary
        }
    }

    private func saveInitialRGBValues() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(rgbValues)
            try data.write(to: fileURL, options: [.atomicWrite])
        } catch {
            print("Failed to save initial RGB values: \(error)")
        }
    }

    func saveRGBValue(for key: String, rgbValue: RGBValue) {
        rgbValues[key] = rgbValue
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(rgbValues)
            try data.write(to: fileURL, options: [.atomicWrite])
        } catch {
            print("Failed to save RGB values: \(error)")
        }
    }

    func getRGBValue(for key: String) -> RGBValue? {
        return rgbValues[key]
    }
}
