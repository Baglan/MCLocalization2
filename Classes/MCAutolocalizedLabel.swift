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
    
    fileprivate let localizationKeyKey = "localizationKeyKey"
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(localizationKey, forKey: localizationKeyKey)
    }
    
    // This, otherwise unnecessary, override is required for init(coder) to work.
    // See http://wezzard.com/2015/03/22/principles-on-ios-custom-view-implementation/
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MCAutolocalizedLabel.localize), name: NSNotification.Name(rawValue: MCLocalization.updatedNotification), object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        if aDecoder.containsValue(forKey: localizationKeyKey) {
            if let localizationKey = aDecoder.decodeObject(forKey: localizationKeyKey) as? String {
                self.localizationKey = localizationKey
            }
        }
        
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MCAutolocalizedLabel.localize), name: NSNotification.Name(rawValue: MCLocalization.updatedNotification), object: nil)
    }
    
    @objc func localize() {
        if let localizationKey = localizationKey, let localizedString = MCLocalization.string(for: localizationKey) {
            text = localizedString
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

