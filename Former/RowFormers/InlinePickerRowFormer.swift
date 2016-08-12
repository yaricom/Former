//
//  InlinePickerRowFormer.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 8/2/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//

import UIKit

public protocol InlinePickerFormableRow: FormableRow {
    
    func formTitleLabel() -> UILabel?
    func formDisplayLabel() -> UILabel?
}

public class InlinePickerItem<S>: PickerItem<S> {
    
    public let displayTitle: NSAttributedString?
    public init(title: String, displayTitle: NSAttributedString? = nil, value: S? = nil) {
        self.displayTitle = displayTitle
        super.init(title: title, value: value)
    }
}

public class InlinePickerRowFormer<T: UITableViewCell, S where T: InlinePickerFormableRow>
: BaseRowFormer<T>, Formable, ConfigurableInlineForm {
    
    // MARK: Public
    
    public typealias InlineCellType = FormPickerCell
    
    public let inlineRowFormer: RowFormer
    override public var canBecomeEditing: Bool {
        return enabled
    }
    
    public var pickerItems: [InlinePickerItem<S>] = []
    public var selectedRow: Int = 0
    public var titleDisabledColor: UIColor? = .lightGrayColor()
    public var displayDisabledColor: UIColor? = .lightGrayColor()
    public var titleEditingColor: UIColor?
    public var displayEditingColor: UIColor?
    
    required public init(
        instantiateType: Former.InstantiateType = .Class,
        cellSetup: (T -> Void)?) {
            inlineRowFormer = PickerRowFormer<InlineCellType, S>(instantiateType: .Class)
            super.init(instantiateType: instantiateType, cellSetup: cellSetup)
    }
    
    public final func onValueChanged(handler: (InlinePickerItem<S> -> Void)) -> Self {
        onValueChanged = handler
        return self
    }
    
    public override func update() {
        super.update()
        
        let titleLabel = cell.formTitleLabel()
        let displayLabel = cell.formDisplayLabel()
        if pickerItems.isEmpty {
            displayLabel?.text = ""
        } else {
            displayLabel?.text = pickerItems[selectedRow].title
            _ = pickerItems[selectedRow].displayTitle.map { displayLabel?.attributedText = $0 }
        }
        
        if enabled {
            if isEditing {
                if self.titleEditingColor != nil {
                    // store title color to restore after edit complete
                    if titleColor == nil { titleColor = titleLabel?.textColor }
                    // change color
                    titleLabel?.textColor = self.titleEditingColor
                }
                
                if self.pickerItems[selectedRow].displayTitle == nil {
                    if self.displayTextColor == nil { self.displayTextColor = displayLabel?.textColor ?? .blackColor() }
                    if self.displayEditingColor != nil { displayLabel?.textColor = self.displayEditingColor }
                }
            } else {
                if self.titleColor != nil {
                    titleLabel?.textColor = self.titleColor
                    self.titleColor = nil
                }
                if self.displayTextColor != nil {
                    displayLabel?.textColor = self.displayTextColor
                    displayTextColor = nil
                }
            }
        } else {
            if self.titleColor == nil {self.titleColor = titleLabel?.textColor ?? .blackColor() }
            titleLabel?.textColor = self.titleDisabledColor
            if self.displayTextColor == nil { self.displayTextColor = displayLabel?.textColor ?? .blackColor() }
            displayLabel?.textColor = self.displayDisabledColor
        }
        
        let inlineRowFormer = self.inlineRowFormer as! PickerRowFormer<InlineCellType, S>
        inlineRowFormer.configure {
            $0.pickerItems = pickerItems
            $0.selectedRow = selectedRow
            $0.enabled = enabled
            if UIDevice.currentDevice().systemVersion.compare("8.0.0", options: .NumericSearch) == .OrderedDescending {
                $0.cell.pickerView.reloadAllComponents()
            }
        }.onValueChanged(valueChanged).update()
    }

    public override func cellSelected(indexPath: NSIndexPath) {
        former?.deselect(true)
    }
    
    public func editingDidBegin() {
        if enabled {
            if self.titleEditingColor != nil {
                let titleLabel = cell.formTitleLabel()
                // store title color to restore after edit complete
                if titleColor == nil { titleColor = titleLabel?.textColor }
                // change color
                titleLabel?.textColor = self.titleEditingColor
            }
            
            if self.pickerItems[selectedRow].displayTitle == nil {
                let displayLabel = cell.formDisplayLabel()
                if self.displayTextColor == nil { self.displayTextColor = displayLabel?.textColor ?? .blackColor() }
                if self.displayEditingColor != nil { displayLabel?.textColor = self.displayEditingColor }
            }
            isEditing = true
        }
    }
    
    public func editingDidEnd() {
        isEditing = false
        let titleLabel = cell.formTitleLabel()
        let displayLabel = cell.formDisplayLabel()
        
        if enabled {
            if self.titleColor != nil {
                // restore previous title color if any
                titleLabel?.textColor = self.titleColor
                self.titleColor = nil
            }
            
            if self.pickerItems[selectedRow].displayTitle == nil && self.displayTextColor != nil {
                displayLabel?.textColor = self.displayTextColor
                self.displayTextColor = nil
            }
        } else {
            if self.titleColor == nil { self.titleColor = titleLabel?.textColor ?? .blackColor() }
            if self.displayTextColor == nil { self.displayTextColor = displayLabel?.textColor ?? .blackColor() }
            titleLabel?.textColor = self.titleDisabledColor
            displayLabel?.textColor = self.displayDisabledColor
        }
    }
    
    // MARK: Private
    
    private final var onValueChanged: (InlinePickerItem<S> -> Void)?
    private final var titleColor: UIColor?
    private final var displayTextColor: UIColor?
    
    private func valueChanged(pickerItem: PickerItem<S>) {
        if enabled {
            let inlineRowFormer = self.inlineRowFormer as! PickerRowFormer<InlineCellType, S>
            let inlinePickerItem = pickerItem as! InlinePickerItem
            let displayLabel = cell.formDisplayLabel()
            
            selectedRow = inlineRowFormer.selectedRow
            displayLabel?.text = inlinePickerItem.title
            if let displayTitle = inlinePickerItem.displayTitle {
                displayLabel?.attributedText = displayTitle
            } else {
                if displayTextColor == nil { displayTextColor = displayLabel?.textColor ?? .blackColor() }
                _ = displayEditingColor.map { displayLabel?.textColor = $0 }
            }
            onValueChanged?(inlinePickerItem)
        }
    }
}