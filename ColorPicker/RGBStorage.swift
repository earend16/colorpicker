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
    private let fileName = "rgbValues.txt"
    private var rgbValues: [(timestamp: String, unixTimestamp: Double, unixDelta: Double, x: Double, y: Double, Y: Double, value: RGBValue)] = []  // Use an array of tuples to maintain order

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
                    let parts = line.split(separator: ",")
                    guard parts.count == 9,
                          let unixTimestamp = Double(parts[1]),
                          let unixDelta = Double(parts[2]),
                          let x = Double(parts[3]),
                          let y = Double(parts[4]),
                          let Y = Double(parts[5]),
                          let rgbValue = RGBValue.decodeFromString("\(parts[6]),\(parts[7]),\(parts[8])")
                    else {
                        return nil
                    }
                    return (timestamp: String(parts[0]), unixTimestamp: unixTimestamp, unixDelta: unixDelta, x: x, y: y, Y: Y, value: rgbValue)
                }
            } catch {
                print("Failed to load RGB values: \(error)")
            }
        }
    }

    func saveRGBValue(rgbValue: RGBValue) {
        // Generate a timestamp key
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
        let timestampKey = dateFormatter.string(from: Date())
        
        // Calculate Unix timestamp and delta
        let unixTimestamp = Date().timeIntervalSince1970
        let unixDelta = rgbValues.last.map { unixTimestamp - $0.unixTimestamp } ?? 0

        // Perform conversions
        let (x, y, Y) = convertRGBToXyY(rgbValue)

        rgbValues.append((timestamp: timestampKey, unixTimestamp: unixTimestamp, unixDelta: unixDelta, x: x, y: y, Y: Y, value: rgbValue))
        saveRGBValues()
    }

    private func saveRGBValues() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        let data = rgbValues.map { "\($0.timestamp),\($0.unixTimestamp),\($0.unixDelta),\($0.x),\($0.y),\($0.Y),\($0.value.encodeToString())" }.joined(separator: "\n")
        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save RGB values: \(error)")
        }
    }

    func getRGBValue(for key: String) -> RGBValue? {
        return rgbValues.first { $0.timestamp == key }?.value
    }

    private func convertRGBToXyY(_ rgbValue: RGBValue) -> (Double, Double, Double) {
        // De-gammafication
        func degamma(_ value: Double) -> Double {
            return (value <= 0.0031308) ? (value / 12.92) : pow((value + 0.055) / 1.055, 2.4)
        }

        let rLinear = degamma(rgbValue.red / 255.0)
        let gLinear = degamma(rgbValue.green / 255.0)
        let bLinear = degamma(rgbValue.blue / 255.0)

        //print("Linear RGB:")
        //print("rLinear: \(rLinear), gLinear: \(gLinear), bLinear: \(bLinear)")

        // DCI P3 to sRGB matrix
        let p3ToSrgbMatrix: [[Double]] = [
         [1.2249, -0.2247, 0],
         [-0.042, 1.0419, 0],
         [-0.0197, -0.0786, 1.0979]
        ]

        let rSrgb = p3ToSrgbMatrix[0][0] * rLinear + p3ToSrgbMatrix[0][1] * gLinear + p3ToSrgbMatrix[0][2] * bLinear
        let gSrgb = p3ToSrgbMatrix[1][0] * rLinear + p3ToSrgbMatrix[1][1] * gLinear + p3ToSrgbMatrix[1][2] * bLinear
        let bSrgb = p3ToSrgbMatrix[2][0] * rLinear + p3ToSrgbMatrix[2][1] * gLinear + p3ToSrgbMatrix[2][2] * bLinear

        //print("sRGB:")
        //print("rSrgb: \(rSrgb), gSrgb: \(gSrgb), bSrgb: \(bSrgb)")

        // sRGB to CIE XYZ matrix
        let srgbToXyzMatrix: [[Double]] = [
         [0.4177, 0.3468, 0.1859],
         [0.2201, 0.7185, 0.0609],
         [0.0182, 0.1282, 0.9426]
        ]

        let X = srgbToXyzMatrix[0][0] * rSrgb + srgbToXyzMatrix[0][1] * gSrgb + srgbToXyzMatrix[0][2] * bSrgb
        let Y = srgbToXyzMatrix[1][0] * rSrgb + srgbToXyzMatrix[1][1] * gSrgb + srgbToXyzMatrix[1][2] * bSrgb
        let Z = srgbToXyzMatrix[2][0] * rSrgb + srgbToXyzMatrix[2][1] * gSrgb + srgbToXyzMatrix[2][2] * bSrgb

        //print("CIE XYZ:")
        //print("X: \(X), Y: \(Y), Z: \(Z)")

        // XYZ to xyY
        let sumXYZ = X + Y + Z
        let x = X / sumXYZ
        let y = Y / sumXYZ

        //print("xyY:")
        //print("x: \(x), y: \(y), Y: \(Y)")

        return (x, y, Y)
    }


    func testRGBConversion() {
        let testRGBValue = RGBValue(red: 150, green: 200, blue: 100)
        let (x, y, Y) = convertRGBToXyY(testRGBValue)
        print("Test RGB Value: \(testRGBValue)")
        print("Converted xyY Values: x = \(x), y = \(y), Y = \(Y)")
    }
}
