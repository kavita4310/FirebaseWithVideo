//
//  HomeVC.swift
//  FirebaseSocialApp
//
//  Created by kavita chauhan on 21/05/24.
//

import UIKit
import AVKit
import AVFoundation
import MobileCoreServices
import Firebase
import FirebaseStorage
import SDWebImage


class HomeVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
   
    //MARK: Outlets
    @IBOutlet weak var tableVw: UITableView!
    
    //MARK: Properties
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var playerViewcontroller = AVPlayerViewController()
    var videoUID:String = ""
    var videoList:[[String:Any]] = []
    var likeStatus:Bool = false
    var loginUserEmail:String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configuration()
    }
    
   
    func configuration(){
        fetchDatafromDatabase()
        tableVw.delegate = self
        tableVw.dataSource = self
        
        let videonib = UINib(nibName: "VideoTCell", bundle: nil)
        self.tableVw.register(videonib, forCellReuseIdentifier: "VideoTCell")

    }
    
    
    //MARK: Function FetchData from Database
    func fetchDatafromDatabase(){
        
        let ref = Database.database().reference().child("VideoUrl")
        
        ref.observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.exists() else {
                print("No data available")
                return
            }
            self.videoList.removeAll()
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot else { continue }
                
                if let userData = childSnapshot.value as? [String: Any] {
                    
                    self.videoList.append(userData)
                }
                DispatchQueue.main.async {
                    Loader.hideLoader()
                }
                self.tableVw.reloadData()
            }
        }
        
    }
    
    @IBAction func btnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    @IBAction func btnLogoutUser(_ sender: Any) {
        showDeleteConfirmationAlert()
    }
    
    //MARK: Funtion Confirm Dialouge
    func showDeleteConfirmationAlert() {
           let alert = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account?", preferredStyle: .alert)

           let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
           alert.addAction(cancelAction)

           let okAction = UIAlertAction(title: "OK", style: .destructive) { _ in
               self.deleteUser()
           }
           alert.addAction(okAction)

           present(alert, animated: true, completion: nil)
       }
    
    
    //MARK: Function Delete User from Database
    func deleteUser() {
           guard let user = Auth.auth().currentUser else {
               print("No user is logged in.")
               return
           }
        if user.email == loginUserEmail {
            user.delete { error in
                if let error = error {
                    // Handle error (e.g., re-authentication required)
                    if let authError = error as NSError?, authError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                       
                    } else {
                        // Other errors
                        print("Error deleting user: \(error.localizedDescription)")
                    }
                } else {
                    print("User deleted successfully.")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
         
       }
    
    //MARK: Button Upload Video
    
    @IBAction func btnUploadVieo(_ sender: Any) {
        let alert = UIAlertController(title: "Select Video", message: "Choose video source", preferredStyle: .actionSheet)
              
              alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
                  self.openVideoPicker(sourceType: .photoLibrary)
              }))
              
              alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                  self.openVideoPicker(sourceType: .camera)
              }))
              
              alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
              
              self.present(alert, animated: true, completion: nil)
          }
    
    //MARK: Function Open Video Gallery
    func openVideoPicker(sourceType: UIImagePickerController.SourceType) {
          if UIImagePickerController.isSourceTypeAvailable(sourceType) {
              let picker = UIImagePickerController()
              picker.delegate = self
              picker.sourceType = sourceType
              picker.mediaTypes = [UTType.movie.identifier]
              picker.allowsEditing = true
              self.present(picker, animated: true, completion: nil)
          } else {
              let alert = UIAlertController(title: "Warning", message: "Selected source is not available", preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
              self.present(alert, animated: true, completion: nil)
          }
      }

     
    //MARK: Function Delegate Method of UIImage Picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            // Read the video data from the URL
            do {
                let videoData = try Data(contentsOf: videoURL)
                // Call the function to upload video data to Firebase Storage
                DispatchQueue.main.async {
                    Loader.showLoader()
                }
                uploadImageToFirebaseStorage(videoData: videoData) { [self] result in
                    switch result {
                    case .success(let downloadURL):
                        print("Video uploaded successfully: \(downloadURL)")
                        let ref = Database.database().reference()
                        let uid = ref.child("VideoUrl").child(videoUID)
                        let dict = ["url":"\(downloadURL)","like":false,"uid":videoUID]
                        uid.setValue(dict)
                        DispatchQueue.main.async {
                            self.fetchDatafromDatabase()
                        }
                    case .failure(let error):
                        print("Error uploading video: \(error)")
                    }
                }
            } catch {
                print("Error reading video data: \(error)")
            }
        }
    }

     
     func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
         picker.dismiss(animated: true, completion: nil)
     }
    
    //MARK: Function Upload Image in Storage
    func uploadImageToFirebaseStorage(videoData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
         var ref = Database.database().reference()
        let uid = ref.child("VideoUrl").childByAutoId()
         videoUID = uid.key ?? ""
        let storageRef = Storage.storage().reference().child("VideoUrl").child(videoUID)
        
        let uploadTask = storageRef.putData(videoData, metadata: nil) { (metadata, error) in
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
    
    //MARK: Function Play Video
    
    func playVideo(videoUrl:String){
        guard let url = URL(string: videoUrl) else {return}
        player = AVPlayer(url: url)
        playerViewcontroller.player = player
        self.present(playerViewcontroller, animated: true)
        self.playerViewcontroller.player?.play()
    }
  
    //MARK: Function Fetch and Update Like Status
    func fetchUpdate<T>(key: String, value: T,uid:String) {
        let ref = Database.database().reference().child("VideoUrl")

        ref.observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.exists() else {
                print("No data available")
                return
            }
            
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot else { continue }
                
                if let userData = childSnapshot.value as? [String: Any] {
                    if let email = userData["uid"] as? String, email == uid {
                        let childKey = childSnapshot.key
                        let userRef = ref.child(childKey)
                        userRef.updateChildValues([key: value])
                        DispatchQueue.main.async {
                            self.fetchDatafromDatabase()
                        }
                        
                    }
                }
            }
        }
    }
    
    
    
}

//MARK: UITableView Delegate and Datasource

extension HomeVC: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoTCell", for: indexPath) as! VideoTCell
        cell.selectionStyle = .none
        if let videoUrlString = videoList[indexPath.row]["url"] as? String,
                  let videoUrl = URL(string: videoUrlString) {
                   generateThumbnail(for: videoUrl) { (image) in
                       DispatchQueue.main.async {
                           cell.imgvideoList.image = image ?? UIImage(named: "logo-yallagan-white")
                       }
                   }
               } else {
                   cell.imgvideoList.image = UIImage(named: "logo-yallagan-white")
               }
        
        let likeUnlike = videoList[indexPath.row]["like"] as? Bool ?? false
        cell.btnLikeUnlike.tintColor = likeUnlike ? UIColor.red : UIColor.black
              
        let tagValue = indexPath.section * 1000 + indexPath.row
        cell.btnLikeUnlike.tag = tagValue
        cell.btnLikeUnlike.addTarget(self, action: #selector(actionWithParam(_:)), for: .touchUpInside)
        
        return cell
    }
    
    //MARK: Function Generate Thumnail of Video
    func generateThumbnail(for url: URL, completion: @escaping (UIImage?) -> Void) {
           DispatchQueue.global().async {
               let asset = AVAsset(url: url)
               let assetImageGenerator = AVAssetImageGenerator(asset: asset)
               assetImageGenerator.appliesPreferredTrackTransform = true
               let time = CMTime(seconds: 2, preferredTimescale: 2)
               
               do {
                   let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
                   let thumbnail = UIImage(cgImage: imageRef)
                   completion(thumbnail)
               } catch {
                   print("Error generating thumbnail: \(error.localizedDescription)")
                   completion(nil)
               }
           }
       }
    
    //MARK: Button like Action
    @objc func actionWithParam(_ sender: UIButton) {
        let section = sender.tag / 1000
        let row = sender.tag % 1000
           let index = row
           var likeStatus = videoList[index]["like"] as? Bool ?? false
           likeStatus.toggle()
           videoList[index]["like"] = likeStatus

           if likeStatus {
               sender.tintColor = UIColor.red
           } else {
               sender.tintColor = UIColor.black
           }
        
        var uidata = videoList[index]["uid"] as? String ?? ""
        DispatchQueue.main.async {
            Loader.showLoader()
        }
        fetchUpdate(key: "like", value: likeStatus, uid: uidata)

       }
    
    

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let videoUrlString = videoList[indexPath.row]["url"] as? String{
            playVideo(videoUrl: videoUrlString)
        }
    }
}
