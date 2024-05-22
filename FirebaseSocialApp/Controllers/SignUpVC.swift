//
//  SignUpVC.swift
//  FirebaseSocialApp
//
//  Created by kavita chauhan on 21/05/24.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth

class SignUpVC: UIViewController{
    
    //MARK: Outlets
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var imgCheck: UIImageView!
    @IBOutlet weak var imgProfile: UIImageView!
    
    //MARK: Properties
    let imagePicker = UIImagePickerController()
    var ref = DatabaseReference.init()
    var currentUserUid:String = ""
    var imgData:Data?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        self.ref = Database.database().reference()
    }

    
    @IBAction func btnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnSelectProfileImg(_ sender: Any) {
        choosePicture()
    }
    
    //MARK: Button Term's Condition
    @IBAction func btncheck(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            sender.layer.backgroundColor = UIColor.red.cgColor
        }else{
            sender.layer.backgroundColor = UIColor.clear.cgColor
        }
    }
    
    //MARK: Button Signup
    @IBAction func btnSignUP(_ sender: Any) {
        
        if txtName.text!.isEmpty && txtEmail.text!.isEmpty && txtPassword.text!.isEmpty{
            self.displayAlert(message: "Required all fields")
        }else if self.isValidEmail(txtEmail.text!) == false{
            self.displayAlert(message: "Plase enter valid email")
        }else if isValidPassword(txtPassword.text!) == false{
            self.displayAlert(message: "Please enter 6 digit password")
        }else{
            
            registerUser()
        }
    }
    
    //MARK: Function Save Data
    func saveData(){
        
        if let image = imgData {
            
            uploadImageToFirebaseStorage(imageData: image) { result in
                        switch result {
                        case .success(let downloadURL):
                            print("Image uploaded successfully. Download URL: \(downloadURL)")
                            UserDefaults.standard.set("\(downloadURL)", forKey: "profileUrl")
                            var user = self.ref.child("Users").child(self.currentUserUid)
                            let dict = ["name":self.txtName.text!,"email":self.txtEmail.text!,"profileImg": "\(downloadURL)"]
                              user.setValue(dict)

                        case .failure(let error):
                            print("Error uploading image: \(error)")
                           
                        }
                self.navigationController?.popViewController(animated: true)
                    }
  
        }else{
            print("did'nt selected image")
            var user = self.ref.child("Users").child(currentUserUid)
            let dict = ["name":self.txtName.text!,"email":self.txtEmail.text!]
            user.setValue(dict)
            self.navigationController?.popViewController(animated: true)

        }
       
    }
    
    
    //MARK: Function Register Data
    func registerUser(){
        Auth.auth().createUser(withEmail: txtEmail.text ?? "", password: txtPassword.text ?? "") { authResult, error in
          if let error = error as? NSError {
              self.displayAlert(message: error.localizedFailureReason ?? error.localizedDescription)
          } else {
              DispatchQueue.main.async {
                  var user = self.ref.child("Users").childByAutoId()
                  self.currentUserUid = user.key ?? ""
                  self.saveData()
              }
              print("User signs up successfully")
              
          }
        }
    }
    
    @IBAction func btnLogin(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        
    }
    
    //MARK: Function Password validation
    func isValidPassword(_ password: String) -> Bool {
      let minPasswordLength = 6
      return password.count >= minPasswordLength
    }
    
    
    //MARK: Function Upload Image in Storage
    func uploadImageToFirebaseStorage(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("Images").child("ProfileImage").child(currentUserUid)
        
        let uploadTask = storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    
                    let unknownError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    completion(.failure(unknownError))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
        
    }
    
}

//MARK: Image Picker Delegate
extension SignUpVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @objc func choosePicture(){
        let alert  = UIAlertController(title: "Select Image", message: "", preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .overCurrentContext
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            self.openCamera()
        }))
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
            self.openGallary()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let popoverController = alert.popoverPresentationController
        
        popoverController?.permittedArrowDirections = .up
        
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func openCamera() {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera))
        {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openGallary() {
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK:- ***************  UIImagePickerController delegate Methods ****************
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        imgProfile.image = selectedImage
        
        guard let imageData = selectedImage.jpegData(compressionQuality: 0.5) else {
            fatalError("Failed to convert image to data")
        }
        imgData = imageData
        
        dismiss(animated: true, completion: nil)
        
    }
    

    
}
