//
//  MCLocalization.swift
//  MCLocalization2
//
//  Created by Baglan on 12/5/15.
//  Copyright © 2015 Mobile Creators. All rights reserved.
//

import Foundation

protocol MCLocalizationProvider {
    var availableLanguages: [String] { get }
    func stringForKey(key: String, language: String) -> String?
}

class MCLocalization: NSObject {
    // MARK: - Current language
    let languageStorageKey = "MCLocalization.languageStorageKey"
    let languageUpdatedNotification = "MCLocalization.languageUpdatedNotification"
    var language: String? {
        get {
            return preferredLanguage()
        }
        set {
            if let newValue = newValue {
                NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: languageStorageKey)
                NSUserDefaults.standardUserDefaults().synchronize()
                NSNotificationCenter.defaultCenter().postNotificationName(languageUpdatedNotification, object: self)
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
        let languages = availableLanguages()
        
        // Stored language if it's available
        if let storedLanguage = NSUserDefaults.standardUserDefaults().stringForKey(languageStorageKey), let _ = languages.indexOf(storedLanguage) {
            return storedLanguage
        }
        
        // Are any of the preferred languages available
        for language in NSLocale.preferredLanguages() {
            if let _ = languages.indexOf(language) {
                return language
            }
        }
        
        // Is the default language available
        if let defaultLanguage = defaultLanguage, let _ = languages.indexOf(defaultLanguage) {
            return defaultLanguage
        }
        
        // First avaialble language
        if let first = languages.first {
            return first
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
        return MCLocalization.sharedInstance().stringForKey(key)
    }
    
    class func stringForKey(key: String, replacements: [String: String]) -> String? {
        return MCLocalization.sharedInstance().stringForKey(key, replacements: replacements)
    }
    
    // MARK: - Providers
    private var providers = [MCLocalizationProvider]()
    func addProvider(provider: MCLocalizationProvider) {
        providers.append(provider)
    }
    
    // MARK: - Shared instance
    private static let _instance = MCLocalization()
    class func sharedInstance() -> MCLocalization {
        return _instance
    }
}

class MCLocalizationPlaceholderProvider: MCLocalizationProvider {
    var availableLanguages: [String] { get { return [] } }
    func stringForKey(key: String, language: String) -> String? {
        return "[\(language): \(key)]"
    }
}

class MCLocalizationSingleLanguageJSONFileProvider: MCLocalizationProvider {
    internal let _language: String
    internal let _strings: [String: String]
    
    required init(language: String, JSONFileURL: NSURL?) {
        _language = language
        
        var strings: [String: String]?
        if let URL = JSONFileURL, let data = NSData(contentsOfURL: URL) {
            do {
                let JSONObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                if let JSONObject = JSONObject as? [String: String] {
                    strings = JSONObject
                }
            } catch {
            }
        }
        
        if let strings = strings {
            _strings = strings
        } else {
            _strings = [String:String]()
        }
    }
    
    convenience init(language: String, JSONFileName: String, bundle: NSBundle?) {
        let sourceBundle = bundle == nil ? NSBundle.mainBundle() : bundle!
        let JSONFileURL = sourceBundle.URLForResource(JSONFileName, withExtension: nil)
        self.init(language: language, JSONFileURL: JSONFileURL)
    }
    
    convenience init(language: String, JSONFileName: String) {
        self.init(language: language, JSONFileName: JSONFileName, bundle: nil)
    }
    
    var availableLanguages: [String] { get { return [_language] } }
    func stringForKey(key: String, language: String) -> String? {
        if _language == language {
            return _strings[key]
        }
        return nil
    }
}

class MCLocalizationMultipleLanguageJSONFileProvider: MCLocalizationProvider {
    let _strings: [String:[String:String]]
    
    required init(JSONFileURL: NSURL?) {
        var strings: [String:[String:String]]?
        if let URL = JSONFileURL, let data = NSData(contentsOfURL: URL) {
            do {
                let JSONObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                if let JSONObject = JSONObject as? [String:[String:String]] {
                    strings = JSONObject
                }
            } catch {
            }
        }
        
        if let strings = strings {
            _strings = strings
        } else {
            _strings = [String:[String:String]]()
        }
    }
    
    convenience init(JSONFileName: String, bundle: NSBundle?) {
        let sourceBundle = bundle == nil ? NSBundle.mainBundle() : bundle!
        let JSONFileURL = sourceBundle.URLForResource(JSONFileName, withExtension: nil)
        self.init(JSONFileURL: JSONFileURL)
    }
    
    convenience init(JSONFileName: String) {
        self.init(JSONFileName: JSONFileName, bundle: nil)
    }
    
    var availableLanguages: [String] {
        get {
            return _strings.map { (key: String, _) -> String in
                return key
            }
        }
    }
    
    func stringForKey(key: String, language: String) -> String? {
        if let strings = _strings[language] {
            return strings[key]
        }
        return nil
    }
}