//
//  MCLocalizationProviders.swift
//  MCLocalization2
//
//  Created by Baglan on 12/12/15.
//  Copyright © 2015 Mobile Creators. All rights reserved.
//

import Foundation

extension MCLocalization {
    /// Placeholder provider designed to be put as the last one in queue
    /// to "catch" unlocalized strings and display a placeholder for them
    /// that would look something like this:
    ///
    /// [en: some_unlocalized_key]
    class PlaceholderProvider: MCLocalizationProvider {
        var languages: [String] { get { return [] } }
        func string(for key: String, language: String) -> String? {
            return "[\(language): \(key)]"
        }
    }
    
    /// Provider for the default main bundle localization.
    ///
    /// *Does not support switching languages*
    class MainBundleProvider: MCLocalizationProvider {
        fileprivate var table: String?
        
        required init(table: String?) {
            self.table = table
        }
        
        let uniqueString = UUID().uuidString
        
        var languages: [String] { get { return Bundle.main.localizations } }
        func string(for key: String, language: String) -> String? {
            // The 'defaultValue' "trickery" is here because 'localizedStringForKey'
            // will always return a string even if there is no localization available
            // and we want to capture this condition
            let defaultValue = "\(uniqueString)-\(key)"
            let localizedString = Bundle.main.localizedString(forKey: key, value: defaultValue, table: table)
            if localizedString == defaultValue {
                return nil
            }
            return localizedString
        }
    }
    
    /// Provider for single- and multiple-language JSON sources
    class JSONProvider: MCLocalizationProvider {
        fileprivate var strings = [String:[String:String]]()
        
        fileprivate let synchronousURL: URL?
        fileprivate let asynchronousURL: URL?
        fileprivate let language: String?
        
        /// Main init
        ///
        /// - parameter synchronousURL URL to be fetched synchronously (perhaps a local file)
        /// - parameter asynchronousURL URL to be fetched asynchronously (perhaps a remote resource)
        /// - parameter language for single language JSON resources
        required init(synchronousURL: URL?, asynchronousURL: URL?, language: String?) {
            self.synchronousURL = synchronousURL
            self.asynchronousURL = asynchronousURL
            self.language = language
            
            guard synchronousURL != nil || asynchronousURL != nil else { return }
            
            if let synchronousURL = synchronousURL, let data = try? Data(contentsOf: synchronousURL), let JSONObject = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)  {
                adoptJSONObject(JSONObject as AnyObject)
            }
        }
        
        /// Convenience init for a file in the main bundle
        ///
        /// - parameter language for a single language JSON resource
        /// - parameter fileName file name for a file in the main bundle
        convenience init(language: String?, fileName: String) {
            self.init(synchronousURL: Bundle.main.url(forResource: fileName, withExtension: nil), asynchronousURL: nil, language: language)
        }
        
        /// Convenience init for a multiple language file in the main bundle
        ///
        /// - parameter fileName file name for a file in the main bundle
        convenience init(fileName: String) {
            self.init(language: nil, fileName: fileName)
        }
        
        /// Convenience init for a remote URL resource with an optional local cache
        ///
        /// - parameter language for a single language JSON resource
        /// - parameter remoteURL URL for a remote resource
        /// - parameter localName file name for the local cache (will be stored in the 'Application Support' directory)
        convenience init(language: String?, remoteURL: URL, localName: String?) {
            let directoryURL = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let localURL: URL?
            if let directoryURL = directoryURL, let localName = localName {
                localURL = directoryURL.appendingPathComponent(localName)
            } else {
                localURL = nil
            }
            self.init(synchronousURL: localURL, asynchronousURL: remoteURL, language: language)
        }
        
        /// Convenience init for a multiple language remote URL resource with an optional local cache
        ///
        /// - parameter remoteURL URL for a remote resource
        /// - parameter localName file name for the local cache (will be stored in the 'Application Support' directory)
        convenience init(remoteURL: URL, localName: String?) {
            self.init(language: nil, remoteURL: remoteURL, localName: localName)
        }
        
        @discardableResult func adoptJSONObject(_ JSONObject: AnyObject) -> Bool {
            if let multipleLanguages = JSONObject as? [String:[String:String]] {
                self.strings = multipleLanguages
                return true
            } else if let singleLanguage = JSONObject as? [String:String], let language = self.language  {
                self.strings[language] = singleLanguage
                return true
            }
            return false
        }
        
        /// Request asynchronousURL and, optionally, store it in a local cache
        func fetchAsynchronously() {
            if let asynchronousURL = asynchronousURL {
                OperationQueue().addOperation({ () -> Void in
                    if let data = try? Data(contentsOf: asynchronousURL), let JSONObject = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) {
                        
                        if self.adoptJSONObject(JSONObject as AnyObject) {
                            OperationQueue.main.addOperation({ () -> Void in
                                MCLocalization.sharedInstance.providerUpdated(self)
                            })
                            
                            // If synchronous URL (e.g. cache) is configured, attempt to save data to it
                            if let synchronousURL = self.synchronousURL {
                                try? data.write(to: synchronousURL, options: [.atomic])
                            }
                        }
                    }
                })
            }
        }
        
        var languages: [String] {
            get {
                return strings.map { (key: String, _) -> String in
                    return key
                }
            }
        }
        
        func string(for key: String, language: String) -> String? {
            if let strings = strings[language] {
                return strings[key]
            }
            return nil
        }
    }
}


