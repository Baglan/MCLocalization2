//
//  ViewController.swift
//  MCLocalization2
//
//  Created by Baglan on 12/5/15.
//  Copyright © 2015 Mobile Creators. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var availableLocalizationsLabel: UILabel!
    @IBOutlet weak var systemLanguageLabel: UILabel!
    @IBOutlet weak var preferredLanguageLabel: UILabel!
    
    @IBAction func switchToEn(_ sender: AnyObject) {
        MCLocalization.sharedInstance.language = "en"
    }
    
    @IBAction func switchToRu(_ sender: AnyObject) {
        MCLocalization.sharedInstance.language = "ru"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.localize), name: NSNotification.Name(rawValue: MCLocalization.updatedNotification), object: nil)
        localize()
    }
    
    @objc func localize() {
        availableLocalizationsLabel.text = MCLocalization.sharedInstance.availableLanguages().joined(separator: ", ")
        systemLanguageLabel.text = Locale.preferredLanguages.first
        preferredLanguageLabel.text = MCLocalization.sharedInstance.language
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

