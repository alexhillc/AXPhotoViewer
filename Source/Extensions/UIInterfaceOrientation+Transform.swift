//
//  UIInterfaceOrientation+Transform.swift
//  Pods
//
//  Created by Alex Hill on 6/24/17.
//
//

extension UIInterfaceOrientation {
    
    func transform(from interfaceOrientation: UIInterfaceOrientation) -> CGAffineTransform {
        func rotationAngleRadians(for interfaceOrientation: UIInterfaceOrientation) -> CGFloat {
            switch interfaceOrientation {
            case .landscapeLeft:
                return CGFloat.pi / 2
            case .landscapeRight:
                return CGFloat.pi + (CGFloat.pi / 2)
            case .portraitUpsideDown:
                return CGFloat.pi
            default:
                return 0
            }
        }
        
        return CGAffineTransform(rotationAngle: rotationAngleRadians(for: self) - rotationAngleRadians(for: interfaceOrientation))
    }
    
}
