//
//  TextFieldRowFormer.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 7/25/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//

import UIKit

public protocol TextFieldFormableRow: FormableRow {
    
    func formTextField() -> UITextField
    func formTitleLabel() -> UILabel?
}

public class TextFieldRowFormer<T: UITableViewCell where T: TextFieldFormableRow>
: BaseRowFormer<T>, Formable {
    
    // MARK: Public
    
    override public var canBecomeEditing: Bool {
        return enabled
    }
    
    public var text: String?
    public var placeholder: String?
    public var attributedPlaceholder: NSAttributedString?
    public var textDisabledColor: UIColor? = .lightGrayColor()
    public var titleDisabledColor: UIColor? = .lightGrayColor()
    public var titleEditingColor: UIColor?
    public var returnToNextRow = true
    
    public required init(instantiateType: Former.InstantiateType = .Class, cellSetup: (T -> Void)? = nil) {
        super.init(instantiateType: instantiateType, cellSetup: cellSetup)
    }
    
    public final func onTextChanged(handler: (String -> Void)) -> Self {
        onTextChanged = handler
        return self
    }
    
    public override func cellInitialized(cell: T) {
        super.cellInitialized(cell)
        let textField = cell.formTextField()
        textField.delegate = observer
        let events: [(Selector, UIControlEvents)] = [(#selector(TextFieldRowFormer.textChanged(_:)), .EditingChanged),
            (#selector(TextFieldRowFormer.editingDidBegin(_:)), .EditingDidBegin),
            (#selector(TextFieldRowFormer.editingDidEnd(_:)), .EditingDidEnd)]
        events.forEach {
            textField.addTarget(self, action: $0.0, forControlEvents: $0.1)
        }
    }
    
    public override func update() {
        super.update()
        
        cell.selectionStyle = .None
        let titleLabel = cell.formTitleLabel()
        let textField = cell.formTextField()
        textField.text = text
        _ = placeholder.map { textField.placeholder = $0 }
        _ = attributedPlaceholder.map { textField.attributedPlaceholder = $0 }
        textField.userInteractionEnabled = false
        
        if enabled {
            if self.titleColor != nil {
                titleLabel?.textColor = self.titleColor
                self.titleColor = nil
            }
            
            if self.textColor != nil {
                textField.textColor = self.textColor
                self.textColor = nil
            }
        } else {
            // set disabled colors
            if titleColor == nil { titleColor = titleLabel?.textColor ?? .blackColor() }
            if textColor == nil { textColor = textField.textColor ?? .blackColor() }
            titleLabel?.textColor = titleDisabledColor
            textField.textColor = textDisabledColor
        }
    }
    
    public override func cellSelected(indexPath: NSIndexPath) {
        let textField = cell.formTextField()
        if !textField.editing {
            textField.userInteractionEnabled = true
            textField.becomeFirstResponder()
        }
    }
    
    // MARK: Private
    
    private final var onTextChanged: (String -> Void)?
    private final var textColor: UIColor?
    private final var titleColor: UIColor?
    
    private lazy var observer: Observer<T> = Observer<T>(textFieldRowFormer: self)
    
    private dynamic func textChanged(textField: UITextField) {
        if enabled {
            let text = textField.text ?? ""
            self.text = text
            onTextChanged?(text)
        }
    }
    
    private dynamic func editingDidBegin(textField: UITextField) {
        if self.titleEditingColor != nil {
            // store title color to restore after edit complete
            let titleLabel = cell.formTitleLabel()
            if self.titleColor == nil {
                self.titleColor = titleLabel?.textColor ?? .blackColor()
            }
            titleLabel?.textColor = self.titleEditingColor
        }
    }
    
    private dynamic func editingDidEnd(textField: UITextField) {
        let titleLabel = cell.formTitleLabel()
        if enabled {
            if self.titleColor != nil {
                titleLabel?.textColor = self.titleColor
                self.titleColor = nil
            }
            
        } else {
            if self.titleColor == nil { self.titleColor = titleLabel?.textColor ?? .blackColor() }
            if self.textColor == nil { self.textColor = textField.textColor ?? .blackColor() }
            titleLabel?.textColor = titleDisabledColor
            textField.textColor = textDisabledColor
        }
        cell.formTextField().userInteractionEnabled = false
        
        // notify text changed due to possible changes with autocorrection
        self.textChanged(textField)
    }
}

private class Observer<T: UITableViewCell where T: TextFieldFormableRow>: NSObject, UITextFieldDelegate {
    
    private weak var textFieldRowFormer: TextFieldRowFormer<T>?
    
    init(textFieldRowFormer: TextFieldRowFormer<T>) {
        self.textFieldRowFormer = textFieldRowFormer
    }
    
    private dynamic func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard let textFieldRowFormer = textFieldRowFormer else { return false }
        if textFieldRowFormer.returnToNextRow {
            let returnToNextRow = (textFieldRowFormer.former?.canBecomeEditingNext() ?? false) ?
                textFieldRowFormer.former?.becomeEditingNext :
                textFieldRowFormer.former?.endEditing
            returnToNextRow?()
        }
        return !textFieldRowFormer.returnToNextRow
    }
}