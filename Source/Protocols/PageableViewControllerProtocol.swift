//
//  PageableViewControllerProtocol.swift
//  Pods
//
//  Created by Alex Hill on 6/4/17.
//
//

@objc(AXPageableViewControllerProtocol) protocol PageableViewControllerProtocol: AnyObject, NSObjectProtocol {
    
    var pageIndex: Int { get set }
    
    @objc optional func prepareForReuse()
    @objc optional func prepareForRecycle()
    
}
