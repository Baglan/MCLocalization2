//
//  MCLocalization+UILabelLocalizer.swift
//  MCLocalization2
//
//  Created by Baglan on 7/30/16.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation
import UIKit

extension MCLocalization {
    class Localizer: MCLocalizationObserver {
        
        var localizationHandler: ((_ localization: MCLocalization) -> Void)?
        
        /**
         Triggers localization.
         
         Designed to be used as the initial localization.
         
         - parameter localization: defaults to _MCLocalization.sharedInstance_
         */
        func localize(_ localization: MCLocalization? = nil) {
            guard let localizationHandler = localizationHandler else { return }
            let l10n = localization ?? MCLocalization.sharedInstance
            localizationHandler(l10n)
        }
        
        // MARK: - Convenience class methods
        
        /**
         Creates a localizer with a given _localizationHandler_, attaches it to
         _MCLocalization.sharedInstance_ and triggers _localize()_ on it
         
         - parameter with: Localization handler
        */
        class func localizer(with localizationHandler: @escaping ((_ localization: MCLocalization) -> Void)) -> Localizer {
            let localization = MCLocalization.sharedInstance
            let localizer = Localizer()
            localization.addObserver(localizer)
            localizer.localizationHandler = localizationHandler
            localizer.localize(localization)
            return localizer
        }
    }
}
