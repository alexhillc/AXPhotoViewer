//
//  Array+Sorted.swift
//  Pods
//
//  Created by Alex Hill on 5/30/17.
//
//

extension Array {
    
    func insertionIndex(of element: Element, isOrderedBefore: (Element, Element) -> Bool) -> (index: Int, alreadyExists: Bool) {
        var lowIndex = 0
        var highIndex = self.count - 1
        
        while lowIndex <= highIndex {
            let midIndex = (lowIndex + highIndex) / 2
            if isOrderedBefore(self[midIndex], element) {
                lowIndex = midIndex + 1
            } else if isOrderedBefore(element, self[midIndex]) {
                highIndex = midIndex - 1
            } else {
                return (midIndex, true)
            }
        }
        
        return (lowIndex, false)
    }
    
}
