//
//  MCLocalization.swift
//  MCLocalization2
//
//  Created by Baglan on 12/5/15.
//  Copyright © 2015 Mobile Creators. All rights reserved.
//

import Foundation

protocol MCLocalizationProvider: class {
    var languages: [String] { get }
    func string(for key: String, language: String) -> String?
}

protocol MCLocalizationObserver: class {
    func localize(localization: MCLocalization?)
}

class MCLocalization: NSObject {
    // MARK: - Current language
    let languageStorageKey = "MCLocalization.languageStorageKey"
    static let updatedNotification = "MCLocalization.updatedNotification"
    var language: String? {
        get {
            return preferredLanguage()
        }
        set {
            if let newValue = newValue {
                NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: languageStorageKey)
                NSUserDefaults.standardUserDefaults().synchronize()
                notifyOfUpdates()
            }
        }
    }
    
    func availableLanguages() -> [String] {
        var languages = Set<String>()
        for provider in providers {
            languages.unionInPlace(provider.languages)
        }
        return Array(languages.sort())
    }
    
    // MARK: - Preferred language
    var defaultLanguage: String?
    
    func preferredLanguage() -> String? {
        var preferences = [String]()
        let available = availableLanguages()
        
        // Stored language if there is one available
        if let storedLanguage = NSUserDefaults.standardUserDefaults().stringForKey(languageStorageKey) {
            preferences.append(storedLanguage)
        }
        
        // Preferred languages from user's locale
        preferences.appendContentsOf(NSLocale.preferredLanguages())
        
        // Default language if available
        if let defaultLanguage = defaultLanguage {
            preferences.append(defaultLanguage)
        }
        
        // This construct is necessary because 'preferredLocalizationsFromArray' would return
        // a value even if there are no available languages and we want to be able to capture
        // this condition
        if let language = NSBundle.preferredLocalizationsFromArray(available, forPreferences: preferences).first where available.indexOf(language) != nil {
            return language
        }

        return nil
    }
    
    // MARK: - Strings
    func string(for key: String, replacements: [String: String]? = nil) -> String? {
        var string: String? = nil
        
        if let language = language {
            for provider in providers {
                if let str = provider.string(for: key, language: language) {
                    string = str
                    break
                }
            }
        }
        
        if let str = string, let replacements = replacements  {
            var result = str
            for (key,value) in replacements {
                result = result.stringByReplacingOccurrencesOfString(key, withString: value)
            }
            string = result
        }
        
        return string
    }
    
    /**
     Asynchronous version for lengthy lookups.
     
     Lookup will be done in a background queue. Completion handler will be called on the current queue
     
     - parameter for: localization key
     - parameter completionHandler: completion handler
     */
    func string(for key: String, completionHandler: ((string: String?) -> Void)) {
        let currentQueue = NSOperationQueue.currentQueue()
        NSOperationQueue().addOperationWithBlock { [unowned self] in
            let string = self.string(for: key)
            currentQueue?.addOperationWithBlock({ 
                completionHandler(string: string)
            })
        }
    }
    
    // MARK: - Convenience class functions
    class func string(for key: String, replacements: [String: String]? = nil) -> String? {
        return MCLocalization.sharedInstance.string(for: key, replacements: replacements)
    }
    
    // MARK: - Providers
    private var providers = [MCLocalizationProvider]()
    func addProvider(provider: MCLocalizationProvider) {
        providers.append(provider)
        providerUpdated(provider)
    }
    
    func providerUpdated(updatedProvider: MCLocalizationProvider) {
        for provider in providers {
            if provider === updatedProvider {
                notifyOfUpdates()
                return
            }
        }
    }
    
    // MARK: - Notify of updates
    
    func notifyOfUpdates() {
        // Post notification
        NSNotificationCenter.defaultCenter().postNotificationName(MCLocalization.updatedNotification, object: self)
        
        // Update notifiers
        for observer in observers  {
            observer.localize(self)
        }
    }
    
    // MARK: - Observers
    
    var observers = [MCLocalizationObserver]()
    
    func addObserver(observer: MCLocalizationObserver) {
        observers.append(observer)
    }
    
    func removeObserver(observer: MCLocalizationObserver) {
        let index = observers.indexOf { (item) -> Bool in
            return observer === item
        }
        if let index = index {
            observers.removeAtIndex(index)
        }
    }
    
    // MARK: - Shared instance
    static let sharedInstance = MCLocalization()
}