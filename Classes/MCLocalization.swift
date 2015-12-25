//
//  MCLocalization.swift
//  MCLocalization2
//
//  Created by Baglan on 12/5/15.
//  Copyright © 2015 Mobile Creators. All rights reserved.
//

import Foundation

protocol MCLocalizationProvider: class {
    var availableLanguages: [String] { get }
    func stringForKey(key: String, language: String) -> String?
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
                NSNotificationCenter.defaultCenter().postNotificationName(MCLocalization.updatedNotification, object: self)
            }
        }
    }
    
    func availableLanguages() -> [String] {
        var languages = Set<String>()
        for provider in providers {
            languages.unionInPlace(provider.availableLanguages)
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
    func stringForKey(key: String) -> String? {
        if let language = language {
            for provider in providers {
                if let str = provider.stringForKey(key, language: language) {
                    return str
                }
            }
        }
        
        return nil
    }
    
    func stringForKey(key: String, replacements: [String: String]) -> String? {
        if let str = stringForKey(key) {
            var result = str
            for (key,value) in replacements {
                result = result.stringByReplacingOccurrencesOfString(key, withString: value)
            }
            return result
        }
        
        return nil
    }
    
    // MARK: - Convenience class functions
    class func stringForKey(key: String) -> String? {
        return MCLocalization.sharedInstance.stringForKey(key)
    }
    
    class func stringForKey(key: String, replacements: [String: String]) -> String? {
        return MCLocalization.sharedInstance.stringForKey(key, replacements: replacements)
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
                NSNotificationCenter.defaultCenter().postNotificationName(MCLocalization.updatedNotification, object: self)
                return
            }
        }
    }
    
    // MARK: - Shared instance
    static let sharedInstance = MCLocalization()
}