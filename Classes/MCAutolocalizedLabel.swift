//
//  MCLocalizationLabel.swift
//  MCLocalization2
//
//  Created by Baglan on 12/12/15.
//  Copyright © 2015 Mobile Creators. All rights reserved.
//

import Foundation
import UIKit

/// UILabel automatically localized using MCLocalization
///
/// **Note:** only the *text* property is localized. This should have no effect
/// on attributed text labels
@IBDesignable class MCAutolocalizedLabel: UILabel {
    @IBInspectable var localizationKey: String? { didSet { localize() } }
    
    private let localizationKeyKey = "localizationKeyKey"
    
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(localizationKey, forKey: localizationKeyKey)
    }
    
    // This, otherwise unnecessary, override is required for init(coder) to work.
    // See http://wezzard.com/2015/03/22/principles-on-ios-custom-view-implementation/
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MCAutolocalizedLabel.localize), name: MCLocalization.updatedNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        if aDecoder.containsValueForKey(localizationKeyKey) {
            if let localizationKey = aDecoder.decodeObjectForKey(localizationKeyKey) as? String {
                self.localizationKey = localizationKey
            }
        }
        
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MCAutolocalizedLabel.localize), name: MCLocalization.updatedNotification, object: nil)
    }
    
    func localize() {
        if let localizationKey = localizationKey, let localizedString = MCLocalization.stringForKey(localizationKey) {
            text = localizedString
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

