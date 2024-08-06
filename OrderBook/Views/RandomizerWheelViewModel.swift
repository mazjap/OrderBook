import SwiftUI

@Observable
class RandomizerWheelViewModel {
  var degree = 0.0
  
  @ObservationIgnored
  var count: Int = 0
  
  @ObservationIgnored
  var onSpinEnd: ((Int) -> Void)?
  
  private var animation = Animation.timingCurve(0.51, 0.97, 0.56, 0.99, duration: 6)
  private var pendingRequestWorkItem: DispatchWorkItem?
  
  private func getWheelStopDegree() -> Double {
    let index = Int.random(in: 0..<count)
    let itemRange = 360 / count
    let indexDegree = itemRange * index
    let freeRange = Int.random(in: 0...itemRange)
    let freeSpins = (2...20).map({ return $0 * 360 }).randomElement()!
    let finalDegree = freeSpins + indexDegree + freeRange
    return Double(finalDegree)
  }
  
  func spinWheel() {
    withAnimation(animation) {
      degree = Double(360 * Int(degree / 360)) + getWheelStopDegree()
    }
    
    pendingRequestWorkItem?.cancel()
    
    let requestWorkItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      
      let pointer = floor(degree.truncatingRemainder(dividingBy: 360) / (360 / Double(self.count)))
      
      onSpinEnd?(count - Int(pointer) - 1)
    }
    // Save the new work item and execute it after duration
    pendingRequestWorkItem = requestWorkItem
    DispatchQueue.main.asyncAfter(
      deadline: .now() + 6 + 1,
      execute: requestWorkItem
    )
  }
}
