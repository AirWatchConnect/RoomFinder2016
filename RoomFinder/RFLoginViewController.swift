//
//  RFLoginViewController.swift
//  RoomFinderSwift
//
//  Created by Jing Wang on 3/24/16.
//  Copyright © 2016 Jing Wang. All rights reserved.
//

import UIKit



class RFLoginViewController: UIViewController, UIAlertViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var serverTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    var CompletionHandler : (NSData?, NSURLResponse?, NSError?) -> Void = { (data: NSData?,response: NSURLResponse?,error: NSError?) -> Void in }
    var progressHUD:MBProgressHUD? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initCompletionHandler()

        let tapGestureRecognizer : UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action:#selector(RFLoginViewController.tapOnBackground) )
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        loginButton!.layer.cornerRadius = 5
        self.loginButton.enabled = false
        self.serverTextField.delegate = self
        self.serverTextField.autocorrectionType = .No
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = defaultColor()
        
        loginButton!.enabled = self.serverTextField.text?.characters.count > 0
        loginButton!.titleLabel?.textColor = defaultColor()
        
        self.navigationController?.navigationBar.barTintColor = defaultColor()
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.topViewController?.title = "RoomFinder"
        RFCredential.shareInstance.setCredential("", pw: "")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func initCompletionHandler() {
        CompletionHandler = {[unowned self] (data: NSData?,response: NSURLResponse?,error: NSError?) -> Void in
            if( error != nil) {
                RFCredential.shareInstance.setCredential("", pw: "")
                if( error!.code == RFCredentialError.Empty.rawValue ) {
                    self.showAlertView("Login", message: "", style: UIAlertViewStyle.LoginAndPasswordInput)
                } else if( error!.code == RFCredentialError.Invalid.rawValue )  {
                    self.showAlertView("Warning", message: error!.localizedDescription + " Please try again", style: UIAlertViewStyle.Default)
                } else if( error!.localizedDescription != "cancelled" )  {
                    self.showTryAgainAlert("Error", message: error!.localizedDescription, okActionRequired: true)
                }
            } else if( (response as! NSHTTPURLResponse).statusCode != 200 ) {
                RFCredential.shareInstance.setCredential("", pw: "")
                let message = NSHTTPURLResponse .localizedStringForStatusCode((response as! NSHTTPURLResponse).statusCode)
                self.showTryAgainAlert("Error", message: message, okActionRequired: false)
            } else {
                NSLog("Connect Success, show RoomList")
                dispatch_async(dispatch_get_main_queue(), {
                self.progressHUD!.hideAnimated(true)
                    let roomlistVC = self.storyboard?.instantiateViewControllerWithIdentifier("RoomListTableViewController")
                    self.showViewController(roomlistVC!, sender: nil)
                })
            }
        }
    }
    
    @IBAction func login(sender: AnyObject) {
        loginButton.enabled = false
        dissmissKeyboard()
        
        let server : String = serverTextField.text!
        if( !server.isEmpty ) {
            RFSoap.shareInstance.server = server
            progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            progressHUD!.label.text = "Loading..."
            RFSoap.shareInstance.sendRequest(CompletionHandler)
        } else {
            loginButton.enabled = true
        }
    }
    
    func showAlertView( title : String?, message : String?, style : UIAlertViewStyle ) {
        dispatch_async(dispatch_get_main_queue(), {
            self.progressHUD!.hideAnimated(true)
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            
            let loginAction = UIAlertAction(title: "Login", style: .Default) { (_) in
                let loginTextField = alertController.textFields![0] as UITextField
                let passwordTextField = alertController.textFields![1] as UITextField
                
                self.loginWithUsernamePassword(loginTextField.text!, password: passwordTextField.text!)
            }
            loginAction.enabled = false
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in
                self.loginButton.enabled = true
            }
            
            alertController.addTextFieldWithConfigurationHandler({ (textField:UITextField) in
                textField.placeholder = "username"
            })
            
            alertController.addTextFieldWithConfigurationHandler({ (textField:UITextField) in
                textField.placeholder = "password"
                textField.secureTextEntry = true
            })
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object:alertController.textFields?[0],
            queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
                
                let loginTextField = alertController.textFields![0] as UITextField
                let passwordTextField = alertController.textFields![1] as UITextField
                loginAction.enabled = !loginTextField.text!.isEmpty &&  !passwordTextField.text!.isEmpty
            }
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object:alertController.textFields?[1],
            queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
                
                let loginTextField = alertController.textFields![0] as UITextField
                let passwordTextField = alertController.textFields![1] as UITextField
                loginAction.enabled = !loginTextField.text!.isEmpty &&  !passwordTextField.text!.isEmpty
            }

            alertController.addAction(loginAction)
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
    func loginWithUsernamePassword(username:String, password:String) {
        RFCredential.shareInstance.setCredential(username, pw: password)
        RFSoap.shareInstance.sendRequest(CompletionHandler)
    }
    
    func showTryAgainAlert(title:String, message:String, okActionRequired:Bool) {
            dispatch_async(dispatch_get_main_queue(), {
            self.progressHUD!.hideAnimated(true)
            let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            
            if (okActionRequired) {
                let okAction = UIAlertAction(title: "Retry", style: .Default) { (action) -> Void in
                    
                    let server : String = self.serverTextField.text!
                    if( !server.isEmpty ) {
                        RFSoap.shareInstance.server = server
                        RFSoap.shareInstance.sendRequest(self.CompletionHandler)
                    } else {
                        self.loginButton.enabled = true
                    }
                }
                    alertViewController.addAction(okAction)
                }
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
                self.loginButton.enabled = true
            }
            alertViewController.addAction(cancelAction)
            
            self.presentViewController(alertViewController, animated: true, completion: nil)
        })
    }
    
    func defaultColor() -> UIColor {
        return UIColor.init(red:(0.0/255), green:(161.0/255), blue:(222.0/255), alpha:1.0)
    }
    
    func tapOnBackground() {
        dissmissKeyboard()
    }
    
    func dissmissKeyboard() {
        serverTextField.resignFirstResponder()
    }
    
    func setURL(urlString:String){
        self.serverTextField.text = urlString
        loginButton!.enabled = self.serverTextField.text?.characters.count > 0
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let nsString = textField.text! as NSString
        let newString = nsString.stringByReplacingCharactersInRange(range,
                                                                    withString: string)
        self.loginButton.enabled = newString.characters.count > 0
        return true
    }
    
}

