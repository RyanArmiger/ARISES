//
//  ViewControllerAdvice.swift
//  ARISES
//
//  Created by Ryan Armiger on 16/05/2018.
//  Copyright © 2018 Ryan Armiger. All rights reserved.
//

import UIKit

/**
 Controls all UI elements within the advice domain. Currently this is only the expanding suggestion bar
 */
class ViewControllerAdvice: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var expandButtonOutlet: UILabel!
    @IBOutlet weak var suggestionView: UIView!

    //MARK: - Override viewDidLoad
    /**
     viewDidLoad override to set initial state of the epanding suggestion bar
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        expandButtonOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
        expandButtonOutlet.text = "+"
    }
    
    //MARK: - Expand button
    ///Toggles whether suggestion is hidden
    @IBAction func expandButton(_ sender: Any) {
        if expandButtonOutlet.text == "+"{
            expandButtonOutlet.text = "-"
            suggestionView.isHidden = false
        }
        else {
            expandButtonOutlet.text = "+"
            suggestionView.isHidden = true
        }
    }
    
}
