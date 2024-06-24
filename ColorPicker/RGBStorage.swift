import Foundation

// RGBValue struct definition
struct RGBValue: Codable {
    let red: Double
    let green: Double
    let blue: Double
}

// Custom encoder for RGBValue to String
extension RGBValue {
    func encodeToString() -> String {
        return "\(red),\(green),\(blue)"
    }

    static func decodeFromString(_ string: String) -> RGBValue? {
        let components = string.split(separator: ",").map(String.init).compactMap(Double.init)
        if components.count == 3 {
            return RGBValue(red: components[0], green: components[1], blue: components[2])
        }
        return nil
    }
}

// RGBStorage class definition
class RGBStorage {
    static let shared = RGBStorage()
    private let fileName = "rgbValues.txt"  // File extension changed to .txt to reflect non-JSON format
    private var rgbValues: [(key: String, value: RGBValue)] = []  // Use an array of tuples to maintain order

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
                let data = try String(contentsOf: fileURL, encoding: .utf8)
                let lines = data.split(separator: "\n")
                rgbValues = lines.compactMap { line in
                    let parts = line.split(separator: ":")
                    guard parts.count == 2, let value = RGBValue.decodeFromString(String(parts[1])) else {
                        return nil
                    }
                    return (key: String(parts[0]), value: value)
                }
            } catch {
                print("Failed to load RGB values: \(error)")
            }
        }
    }

    func saveRGBValue(rgbValue: RGBValue) {
        // Generate a timestamp key
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS" // Year, Month, Day, Hour, Minute, Second, Millisecond
        let timestampKey = dateFormatter.string(from: Date())
        
        rgbValues.append((key: timestampKey, value: rgbValue))
        saveRGBValues()
    }

    private func saveRGBValues() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        let data = rgbValues.map { "\($0.key):\($0.value.encodeToString())" }.joined(separator: "\n")
        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save RGB values: \(error)")
        }
    }

    func getRGBValue(for key: String) -> RGBValue? {
        return rgbValues.first { $0.key == key }?.value
    }
}
