//
//  UIView + Constraints.swift
//  Beanfun
//
//  Created by Aaron Ni on 2019/7/30.
//  Copyright © 2019 Aaron_Ni. All rights reserved.
//

import UIKit

public extension UIView {
    
    // MARK: - Add to targetView
    @discardableResult
    func add(to superView: UIView) -> Self {
        superView.addSubview(self)
        return self
    }
    
    // MARK: - NSLayoutAnchor
    @discardableResult
    func anchor<LayoutType: NSLayoutAnchor<AnchorType>, AnchorType> (
        _ keyPath: KeyPath<UIView, LayoutType>,
        _ relation: NSLayoutConstraint.Relation = .equal,
        to anchor: LayoutType,
        constant: CGFloat = 0,
        multiplier: CGFloat? = nil,
        priority: UILayoutPriority = .required) -> Self {
        
        constraint(keyPath, relation, to: anchor, constant: constant, multiplier: multiplier, priority: priority)
        return self
    }
    
    @discardableResult
    func constraint
        <LayoutType: NSLayoutAnchor<AnchorType>, AnchorType>
        (_ keyPath: KeyPath<UIView, LayoutType>,
         _ relation: NSLayoutConstraint.Relation = .equal,
         to anchor: LayoutType,
         constant: CGFloat = 0,
         multiplier: CGFloat? = nil,
         priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint
        
        if let multiplier = multiplier,
            let dimension = self[keyPath: keyPath] as? NSLayoutDimension,
            let anchor = anchor as? NSLayoutDimension {
            
            switch relation {
            case .equal:
                constraint = dimension.constraint(equalTo: anchor, multiplier: multiplier, constant: constant)
            case .greaterThanOrEqual:
                constraint = dimension.constraint(greaterThanOrEqualTo: anchor, multiplier: multiplier, constant: constant)
            case .lessThanOrEqual:
                constraint = dimension.constraint(lessThanOrEqualTo: anchor, multiplier: multiplier, constant: constant)
            @unknown default:
            constraint = dimension.constraint(equalTo: anchor, multiplier: multiplier, constant: constant)
            }
        } else {
            switch relation {
            case .equal:
                constraint = self[keyPath: keyPath].constraint(equalTo: anchor, constant: constant)
            case .greaterThanOrEqual:
                constraint = self[keyPath: keyPath].constraint(greaterThanOrEqualTo: anchor, constant: constant)
            case .lessThanOrEqual:
                constraint = self[keyPath: keyPath].constraint(lessThanOrEqualTo: anchor, constant: constant)
            @unknown default:
            constraint = self[keyPath: keyPath].constraint(equalTo: anchor, constant: constant)
            }
        }
        translatesAutoresizingMaskIntoConstraints = false
        constraint.priority = priority
        constraint.isActive = true
        
        return constraint
    }
    
    // MARK: - NSLayoutDimension
    @discardableResult
    func anchor(_ anchor: KeyPath<UIView, NSLayoutDimension>,
                _ relation: NSLayoutConstraint.Relation = .equal,
                to constant: CGFloat,
                priority: UILayoutPriority = .required) -> Self {
        
        constraint(anchor, relation, to: constant, priority: priority)
        return self
    }
    
    @discardableResult
    func constraint(_ keyPath: KeyPath<UIView, NSLayoutDimension>,
                    _ relation: NSLayoutConstraint.Relation = .equal,
                    to constant: CGFloat = 0,
                    priority: UILayoutPriority) -> NSLayoutConstraint {
        
        let constraint: NSLayoutConstraint
        
        switch relation {
        case .equal:
            constraint = self[keyPath: keyPath].constraint(equalToConstant: constant)
        case .greaterThanOrEqual:
            constraint = self[keyPath: keyPath].constraint(greaterThanOrEqualToConstant: constant)
        case .lessThanOrEqual:
            constraint = self[keyPath: keyPath].constraint(lessThanOrEqualToConstant: constant)
        @unknown default:
            constraint = self[keyPath: keyPath].constraint(equalToConstant: constant)
        }
        constraint.priority = priority
        constraint.isActive = true
        return constraint
    }
}
