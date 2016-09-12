//
//  DataService.swift
//  app-showcase
//
//  Created by Stephen Muscarella on 9/3/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import Foundation
import Firebase

let URL_BASE = FIRDatabase.database().reference()

class DataService {
    
    static let ds = DataService()

    private var _ref = FIRDatabase.database().reference()

    var ref: FIRDatabaseReference {
            return _ref
    }
    
    var REF_USER_CURRENT: FIRDatabaseReference {
        let uid = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String
        let user = self.ref.child("users").child(uid)
        return user
    }

    func createFirebaseUser(uid: String, user: Dictionary<String, String>) {
        self.ref.child("users").child(uid).setValue(user)
    }

}