import SwiftUI

struct RandomizerWheel<Collection: RandomAccessCollection, ID>: View where ID: Hashable {
  @State private var vm = RandomizerWheelViewModel()
  
  private var pointerColor: Color = .gray
  private var borderColor: Color = .black
  private var borderWidth: Double = 4
  private var colors: [Color]
  
  private let items: Collection
  private let identifiableKeyPath: KeyPath<Collection.Element, ID>
  private let toTitle: (Collection.Element) -> String
  private let onSelection: (Collection.Element) -> Void
  
  private let sliceOffset = -Double.pi / 2
  
  init(items: Collection, id: KeyPath<Collection.Element, ID>, toTitle: @escaping (Collection.Element) -> String, onSelection: @escaping (Collection.Element) -> Void) {
    self.items = items
    self.identifiableKeyPath = id
    self.toTitle = toTitle
    self.onSelection = onSelection
    
    let count = Double(items.count)
    self.colors = items.enumerated().map { (offset, _) in
      Color(hue: Double(offset) / count, saturation: 1, brightness: 1)
    }
  }
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        let boltDiameter = geometry.size.width / 10
        
        ZStack {
          ForEach(Array(items.enumerated()), id: \.offset) { (index, item) in
            let backgroundColor = colors[index % colors.count]
            let (start, end, rotation, offset) = data(for: index, size: geometry.size)
            
            SpinWheelCell(
              startAngle: start,
              endAngle: end
            )
            .fill(backgroundColor)
            
            Text(toTitle(item))
              .foregroundStyle(.white)
              .fontWeight(.bold)
              .frame(maxWidth: geometry.size.width / 2 - boltDiameter / 2  - 10)
              .shadow(color: .black, radius: 3)
              .rotationEffect(rotation)
              .offset(offset)
          }
        }
        .rotationEffect(.degrees(vm.degree))
        .gesture(DragGesture()
          .onChanged { value in
            guard value.translation.width < 0 else {
              return
            }
            
            vm.degree = Double(-value.translation.width)
          }
          .onEnded { _ in
            vm.spinWheel()
          }
        )
        
        Circle()
          .strokeBorder(borderColor, lineWidth: borderWidth)
        
        bolt(size: boltDiameter)
      }
      .overlay(alignment: .top) {
        pointer
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .padding(.top, 25)
    .onAppear {
      vm.count = items.count
      vm.onSpinEnd = { index in
        onSelection(items[items.index(items.startIndex, offsetBy: index)])
      }
    }
  }
  
  private var pointer: some View {
    Image(systemName: "arrowtriangle.down.fill")
      .resizable()
      .scaledToFit()
      .frame(width: 50, height: 50)
      .foregroundColor(pointerColor)
      .cornerRadius(24)
      .shadow(
        color: Color(red: 0.082, green: 0.082, blue: 0.082, opacity: 0.5),
        radius: 5,
        x: 0.0,
        y: 1.0
      )
      .offset(x: 0, y: -25)
  }
  
  private func bolt(size: Double) -> some View {
    Circle()
      .frame(width: size)
      .foregroundStyle(.white)
      .onTapGesture {
        vm.spinWheel()
      }
  }
  
  private func data(for index: Int, size: CGSize) -> (start: Double, end: Double, rotation: Angle, offset: CGSize) {
    var start = Double.zero
    var end = Double.zero
    var rotation = Angle.zero
    var offset = CGSize.zero
    
    let radius = min(size.width, size.height) / 3.6
    let dataRatio = (Double(index) + 0.5) / Double(items.count)
    let angle = CGFloat(sliceOffset + (2 * .pi * dataRatio))
    
    if index == 0 {
      start = sliceOffset
    } else {
      let ratio: Double = Double(index) / Double(items.count)
      start = sliceOffset + 2 * .pi * ratio
    }
    
    if index == items.count - 1 {
      end = sliceOffset + 2 * .pi
    } else {
      let ratio: Double = Double(index + 1) / Double(items.count)
      end = sliceOffset + 2 * .pi * ratio
    }
    
    rotation = .radians((start + end) / 2)
    
    offset = CGSize(width: radius * cos(angle), height: radius * sin(angle))
    
    return (start, end, rotation, offset)
  }
}

extension RandomizerWheel where Collection.Element: Identifiable {
  init(items: Collection, toTitle: @escaping (Collection.Element) -> String, onSelection: @escaping (Collection.Element) -> Void) where ID == Collection.Element.ID {
    self.init(items: items, id: \.id, toTitle: toTitle, onSelection: onSelection)
  }
}


#Preview {
  RandomizerWheel(items: ["A game of thrones", "A clash of kings", "A storm of swords", "A feast for crows", "A dance with dragons"], id: \.self) {
    $0
  } onSelection: { element in
    print(element)
  }
  
}

struct SpinWheelCell: Shape {
  let startAngle: Double, endAngle: Double
  
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let radius = min(rect.width, rect.height) / 2
    let alpha = CGFloat(startAngle)
    let center = CGPoint(
      x: rect.midX,
      y: rect.midY
    )
    path.move(to: center)
    path.addLine(
      to: CGPoint(
        x: center.x + cos(alpha) * radius,
        y: center.y + sin(alpha) * radius
      )
    )
    path.addArc(
      center: center, radius: radius,
      startAngle: Angle(radians: startAngle),
      endAngle: Angle(radians: endAngle),
      clockwise: false
    )
    path.closeSubpath()
    return path
  }
}
