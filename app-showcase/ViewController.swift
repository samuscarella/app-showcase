//
//  ViewController.swift
//  app-showcase
//
//  Created by Stephen Muscarella on 9/3/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
    }
    
    
    @IBAction func fbBtnPressed(sender: UIButton) {
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"], fromViewController: self) { (facebookResult:  FBSDKLoginManagerLoginResult!, facebookError: NSError!) -> Void in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString!
                print("Successfully logged in with facebook. \(accessToken)")
                
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(accessToken)
                
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    
                    if error != nil {
                        print("Login Failed. \(error)")
                    } else {
                        print("Logged In! \(user)")
                        
                        let userData = ["provider": credential.provider, "blah":"test"]
                        DataService.ds.createFirebaseUser(user!.uid, user: userData)
                        NSUserDefaults.standardUserDefaults().setValue(user!.uid, forKey: KEY_UID)
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                }
            }
        }
    }
    
    
    @IBAction func attemptLogin(sender: UIButton!) {
        
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            
            
            FIRAuth.auth()?.signInWithEmail(email, password: pwd) { (user, error) in
                
                if error != nil {
                    
//                    print(error)
                    
                    if error!.code == USER_NOT_FOUND {
                        
                        print("User not found. Attempting to create new user...")
                        
                        FIRAuth.auth()?.createUserWithEmail(email, password: pwd) { (user, error) in
                            
                            
                            if error != nil {
                                
                                print(error)
                                self.showErrorAlert("Could not create account", msg: "Problem creating account. Try something else")
                            } else {
                                
                                NSUserDefaults.standardUserDefaults().setValue(user!.uid, forKey: KEY_UID)
                                
                                FIRAuth.auth()?.signInWithEmail(email, password: pwd) { (user, error) in
                                    
                                    let userData = ["provider": FIREBASE]
                                    DataService.ds.createFirebaseUser(user!.uid, user: userData)

                                }

                                print("New user created...")
                                self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                            }
                        }
                    } else if error!.code == PASSWORD_NOT_FOUND {
                        self.showErrorAlert("Could not login", msg: "Please check your username or password!")
                    }
                } else {
                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                }
            }

        } else {
            
            showErrorAlert("Email and Password Required", msg: "You must enter an email and a password.")
        }
    }
    
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    

}

