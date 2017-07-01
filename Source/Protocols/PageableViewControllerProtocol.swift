//
//  PageableViewControllerProtocol.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 6/4/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

@objc(AXPageableViewControllerProtocol) protocol PageableViewControllerProtocol: AnyObject, NSObjectProtocol {
    
    var pageIndex: Int { get set }
    
    @objc optional func prepareForReuse()
    @objc optional func prepareForRecycle()
    
}
