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
    
    @IBAction func switchToEn(sender: AnyObject) {
        MCLocalization.sharedInstance.language = "en"
    }
    
    @IBAction func switchToRu(sender: AnyObject) {
        MCLocalization.sharedInstance.language = "ru"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.localize), name: MCLocalization.updatedNotification, object: nil)
        localize()
    }
    
    func localize() {
        availableLocalizationsLabel.text = MCLocalization.sharedInstance.availableLanguages().joinWithSeparator(", ")
        systemLanguageLabel.text = NSLocale.preferredLanguages().first
        preferredLanguageLabel.text = MCLocalization.sharedInstance.language
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

