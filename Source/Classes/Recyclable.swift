//
//  Recyclable.swift
//  Pods
//
//  Created by Alex Hill on 5/23/17.
//
//

protocol Recyclable: AnyObject, NSObjectProtocol {
    
    func prepareForReuse() -> Void
    func prepareForRecycle() -> Void
    
}
