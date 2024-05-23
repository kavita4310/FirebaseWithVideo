//
//  SignInVC.swift
//  FirebaseSocialApp
//
//  Created by kavita chauhan on 21/05/24.
//

import UIKit
import FirebaseAuth
import PKHUD

class SignInVC: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        txtEmail.text = ""
        txtPassword.text = ""
    }
    

    @IBAction func btnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: button Login
    @IBAction func btnLogin(_ sender: Any) {
        
        if txtEmail.text!.isEmpty && txtPassword.text!.isEmpty {
            self.displayAlert(message: "Please enter email and password")
        }else if self.isValidEmail(txtEmail.text!) == false{
            self.displayAlert(message: "Please enter valid email")
        }else{
            loginUser()
        }
        
    
    }
    
    
    //MARK: Function Login
    func loginUser(){
        DispatchQueue.main.async {
            Loader.showLoader()
        }
        Auth.auth().signIn(withEmail: txtEmail.text ?? "", password: txtPassword.text ?? "") { (authResult, error) in
          if let error = error as? NSError {
              print("error",error.localizedFailureReason ?? "")
              self.displayAlert(message: error.localizedFailureReason ?? error.localizedDescription)
          } else {
            print("User signs up successfully")
              DispatchQueue.main.async {
                  Loader.hideLoader()
              }
              let vc = self.storyboard?.instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
              vc.loginUserEmail = self.txtEmail.text ?? ""
              self.navigationController?.pushViewController(vc, animated: true)
              
          }
        }
    }
    
    //MARK: butotn Google Site
    
    @IBAction func btnGoogle(_ sender: Any) {

        if let url = URL(string: "https://www.google.com/") {
            if UIApplication.shared.canOpenURL(url) {
                // Open the URL
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("Cannot open URL")
            }
        }
    }
    //MARK: button Facebook Site

    @IBAction func btnFacebook(_ sender: Any) {

        if let url = URL(string: "https://www.facebook.com/") {
            if UIApplication.shared.canOpenURL(url) {
                // Open the URL
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("Cannot open URL")
            }
        }
    }
    
    //MARK: Button Sign 
    @IBAction func btnSignUP(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SignUpVC") as! SignUpVC
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    
}

//MARK: Alert Function & Email Validation

extension UIViewController {
    
    func displayAlert(title: String = "Altert ", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func presentAlert(title: String, message: String, preferredStyle: UIAlertController.Style = .alert, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for action in actions {
            alertController.addAction(action)
        }
        present(alertController, animated: true, completion: nil)
    }
    
    
    func isValidEmail(_ email: String) -> Bool {
      let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
      let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
      return emailPred.evaluate(with: email)
    }
}
