import SwiftUI

extension UIColor {
    @available(iOS 17.0, *)
    func mix(with color: UIColor, by amount: Double) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        let amount1 = 1 - amount
        
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let amount2 = amount
        
        let r = r1 * amount1 + r2 * amount2
        let g = g1 * amount1 + g2 * amount2
        let b = b1 * amount1 + b2 * amount2
        let a = a1 * amount1 + a2 * amount2
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension Color {
    @available(iOS 17.0, *)
    func mix(with color: Color, by amount: Double) -> Color {
        Color(uiColor: UIColor(self).mix(with: UIColor(color), by: amount))
    }
}
