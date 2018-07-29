//
//  Field.swift
//
//  Created by Daniel Burke on 7/3/17.
//  Copyright © 2017 Daniel Burke. All rights reserved.
//

import UIKit

typealias FieldAction = (_ field: Field) -> ()

class Field: UITextField {
    let padding: UIEdgeInsets
    
    var focusAction: FieldAction? = nil
    var blurAction: FieldAction? = nil
    var changeAction: FieldAction? = nil
    var returnAction: FieldAction? = nil
    var clearAction: FieldAction? = nil
    
    var placeholderColor: UIColor = .gray {
        didSet {
            guard let text = placeholder else { return }
            let attributedString = NSAttributedString(string: text, attributes: [kCTForegroundColorAttributeName as NSAttributedString.Key:placeholderColor])
            attributedPlaceholder = attributedString
        }
    }
    
    init(insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)) {
        padding = insets
        super.init(frame: .zero)
        
        delegate = self
        addTarget(self, action: #selector(valueChanged), for: .editingChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        layoutIfNeeded()
        return resigned
    }
}

//MARK: Actions
extension Field {
    @objc func valueChanged(field: Field) {
        if let action = changeAction {
            action(self)
        }
    }
}

extension Field: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let action = returnAction {
            action(self)
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let action = focusAction {
            action(self)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let action = blurAction {
            action(self)
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if let action = clearAction {
            action(self)
        }
        return true
    }
}
