import Foundation

final class DanmakuXMLParser: NSObject, XMLParserDelegate {
    private var items: [DanmakuItem] = []
    private var currentAttributes: [String: String] = [:]
    private var currentText = ""

    func parse(data: Data) -> [DanmakuItem] {
        items = []
        currentAttributes = [:]
        currentText = ""

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items.sorted { $0.time < $1.time }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        guard elementName == "d" else { return }
        currentAttributes = attributeDict
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard elementName == "d" else { return }

        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let payload = (currentAttributes["p"] ?? "").split(separator: ",")
        let time = payload.indices.contains(0) ? (Double(payload[0]) ?? 0) : 0
        let mode = payload.indices.contains(1) ? (Int(payload[1]) ?? 1) : 1
        let fontSize = payload.indices.contains(2) ? (Int(payload[2]) ?? 25) : 25
        let colorValue = payload.indices.contains(3) ? (Int(payload[3]) ?? 16_777_215) : 16_777_215
        let timestamp = payload.indices.contains(4) ? String(payload[4]) : UUID().uuidString
        let pool = payload.indices.contains(5) ? String(payload[5]) : "0"
        let identifier = "\(timestamp)-\(pool)-\(time)-\(text)"
        let colorHex = String(format: "#%06X", colorValue)

        items.append(
            DanmakuItem(
                id: identifier,
                time: time,
                text: text,
                colorHex: colorHex,
                mode: mode,
                fontSize: fontSize
            )
        )
    }
}
