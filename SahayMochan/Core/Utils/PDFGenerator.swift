import UIKit
import SwiftUI

struct PDFGenerator {

    // MARK: - Generate PDF
    static func generatePDF(
        for result: AssessmentResult,
        user: User,
        recommendations: [String],
        crisisHelplines: [String] = [
            "iCall: +91-9152987821 (Mon-Sat, 10am-8pm)",
            "AASRA: +91-9820466726 (24/7)",
            "Vandrevala Foundation: +91-9999666555 (24/7)"
        ]
    ) -> URL? {
        let pdfFileName = "\(result.type.title)_Report_\(Int(Date().timeIntervalSince1970)).pdf"
        let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent(pdfFileName)

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()

            let pageWidth = pageRect.width
            var y: CGFloat = 40

            // ----- 1. TITLE -----
            let title = result.type == .anxiety ? "SAHAY ANXIETY ASSESSMENT REPORT" : "MOCHAN DEPRESSION ASSESSMENT REPORT"
            var titleFontSize: CGFloat = 28
            let maxWidth = pageWidth - 100
            let titleSize = (title as NSString).size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: titleFontSize)])
            if titleSize.width > maxWidth {
                titleFontSize = 20
            }
            let titleFont = UIFont.boldSystemFont(ofSize: titleFontSize)
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.systemBlue]
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: y, width: titleSize.width, height: titleSize.height)
            (title as NSString).draw(in: titleRect, withAttributes: titleAttributes)
            y += titleSize.height + 20

            // ----- 2. PATIENT INFO -----
            let infoFont = UIFont.systemFont(ofSize: 14)
            let infoAttributes: [NSAttributedString.Key: Any] = [.font: infoFont]
            let infoLines = [
                "Patient Name: \(user.name)",
                "Email: \(user.email)",
                "Registration ID: \(user.registrationID)",
                "Age: \(user.age)",
                "Gender: \(user.gender)",
                "Assessment Date: \(DateFormatter.shortDateTime.string(from: Date()))"
            ]
            for line in infoLines {
                let rect = CGRect(x: 40, y: y, width: pageWidth - 80, height: 20)
                (line as NSString).draw(in: rect, withAttributes: infoAttributes)
                y += 24
            }
            y += 10

            // ----- 3. SCORES & SEVERITY -----
            let boldFont = UIFont.boldSystemFont(ofSize: 16)
            let boldAttributes: [NSAttributedString.Key: Any] = [.font: boldFont]
            let scoreText = "Questionnaire Score: \(result.score) / \(result.type.maxScore)"
            (scoreText as NSString).draw(in: CGRect(x: 40, y: y, width: pageWidth - 80, height: 20), withAttributes: boldAttributes)
            y += 24

            // Severity with colored background box
            let severityColor = result.severity.color.uiColor
            let severityRect = CGRect(x: 40, y: y, width: pageWidth - 80, height: 30)
            severityColor.withAlphaComponent(0.2).setFill()
            UIRectFill(severityRect)
            let severityString = "Severity: \(result.severity.rawValue)"
            let severityFont = UIFont.boldSystemFont(ofSize: 18)
            let severityAttributes: [NSAttributedString.Key: Any] = [.font: severityFont, .foregroundColor: severityColor]
            let severitySize = (severityString as NSString).size(withAttributes: severityAttributes)
            let severityX = (pageWidth - severitySize.width) / 2
            (severityString as NSString).draw(at: CGPoint(x: severityX, y: y + 4), withAttributes: severityAttributes)
            y += 34

            // AI Score
            if let aiScore = result.aiScore {
                let aiText = "AI Score: \(String(format: "%.2f", aiScore))"
                (aiText as NSString).draw(in: CGRect(x: 40, y: y, width: pageWidth - 80, height: 20), withAttributes: boldAttributes)
                y += 24
            }

            y += 10

            // ----- 4. RECOMMENDATIONS -----
            let recHeader = "Recommendations"
            (recHeader as NSString).draw(in: CGRect(x: 40, y: y, width: pageWidth - 80, height: 20), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
            y += 24
            let recFont = UIFont.systemFont(ofSize: 13)
            let recAttributes: [NSAttributedString.Key: Any] = [.font: recFont]
            for rec in recommendations {
                let bullet = "• \(rec)"
                let rect = CGRect(x: 60, y: y, width: pageWidth - 100, height: 30)
                (bullet as NSString).draw(in: rect, withAttributes: recAttributes)
                y += 28
            }
            y += 10

            // ----- 5. CRISIS RESOURCES -----
            let crisisHeader = "Crisis Helplines"
            (crisisHeader as NSString).draw(in: CGRect(x: 40, y: y, width: pageWidth - 80, height: 20), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
            y += 24
            let helplineFont = UIFont.systemFont(ofSize: 13)
            let helplineAttributes: [NSAttributedString.Key: Any] = [.font: helplineFont]
            for line in crisisHelplines {
                let rect = CGRect(x: 60, y: y, width: pageWidth - 100, height: 25)
                (line as NSString).draw(in: rect, withAttributes: helplineAttributes)
                y += 25
            }
            y += 20

            // ----- 6. FOOTER -----
            let footer = "This report is for informational purposes only. Consult a qualified professional for medical advice."
            let footerFont = UIFont.italicSystemFont(ofSize: 10)
            let footerAttributes: [NSAttributedString.Key: Any] = [.font: footerFont, .foregroundColor: UIColor.gray]
            let footerSize = (footer as NSString).size(withAttributes: footerAttributes)
            let footerRect = CGRect(x: (pageWidth - footerSize.width) / 2, y: pageRect.height - 40, width: footerSize.width, height: footerSize.height)
            (footer as NSString).draw(in: footerRect, withAttributes: footerAttributes)
        }

        do {
            try data.write(to: pdfURL)
            return pdfURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
}

// Helper to convert SwiftUI Color to UIColor
extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}

// MARK: - Share Sheet (for iOS 15+)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
