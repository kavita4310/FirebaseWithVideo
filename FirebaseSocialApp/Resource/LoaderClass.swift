//
//  LoaderClass.swift
//  FirebaseSocialApp
//
//  Created by kavita chauhan on 23/05/24.
//

import Foundation
import PKHUD
class Loader{
    static func showLoader(){
        HUD.show(.progress)
    }
    
    static func hideLoader(){
        HUD.hide()
    }
}

