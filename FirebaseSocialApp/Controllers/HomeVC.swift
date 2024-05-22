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
   
    
    

    @IBOutlet weak var tableVw: UITableView!
    
    var player: AVPlayer?
     var playerLayer: AVPlayerLayer?
    var videoUID:String = ""
    var videoList:[[String:Any]] = []
    var likeStatus:Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchDatafromDatabase()
        tableVw.delegate = self
        tableVw.dataSource = self
        
        let videonib = UINib(nibName: "VideoTCell", bundle: nil)
        self.tableVw.register(videonib, forCellReuseIdentifier: "VideoTCell")

    }
    
    
    //MARK: Function FetchData from Database
    func fetchDatafromDatabase(){
        
        let ref = Database.database().reference().child("Videos")
        
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
                self.tableVw.reloadData()
            }
        }
        
    }
    
    
    
    @IBAction func btnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
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
    
    func openVideoPicker(sourceType: UIImagePickerController.SourceType) {
         if UIImagePickerController.isSourceTypeAvailable(sourceType) {
             let picker = UIImagePickerController()
             picker.delegate = self
             picker.sourceType = sourceType
             picker.mediaTypes = [kUTTypeMovie as String]
             picker.allowsEditing = true
             self.present(picker, animated: true, completion: nil)
         }else{
             print("Camera source not available")
         }
     }
     
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            // Read the video data from the URL
            do {
                let videoData = try Data(contentsOf: videoURL)
                // Call the function to upload video data to Firebase Storage
                uploadImageToFirebaseStorage(videoData: videoData) { result in
                    switch result {
                    case .success(let downloadURL):
                        print("Video uploaded successfully: \(downloadURL)")
                        let ref = Database.database().reference()
                        let uid = ref.child("VideoUrl").child(self.videoUID)
                        let dict = ["url":"\(downloadURL)","like":false]
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
        let storageRef = Storage.storage().reference().child("Videos").child(videoUID)
        
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
    
  
    
    
}
extension HomeVC: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoTCell", for: indexPath) as! VideoTCell
        
        if let imageUrlString = videoList[indexPath.row]["url"] as? String,
                  let imageUrl = URL(string: imageUrlString) {
                   cell.imgvideoList.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "Logo")) { (image, error, cacheType, url) in
                       if let error = error {
                           print("Error fetching image: \(error)")
                       }
                   }
               } else {
            
                   cell.imgvideoList.image = UIImage(named: "Logo")
               }
        
        let likeUnlike = videoList[indexPath.row]["like"] as? Bool ?? false
        if likeUnlike{
            cell.btnLikeUnlike.layer.backgroundColor = UIColor.red.cgColor
        }else{
            cell.btnLikeUnlike.layer.backgroundColor = UIColor.white.cgColor
        }
        cell.btnLikeUnlike.tag = indexPath.row
        cell.btnLikeUnlike.addTarget(self, action: #selector(actionWithParam(_:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func actionWithParam(_ sender: UIButton) {
        let index = sender.tag
           var likeStatus = videoList[index]["like"] as? Bool ?? false
           likeStatus.toggle()
           videoList[index]["like"] = likeStatus
           
           if likeStatus {
               sender.layer.backgroundColor = UIColor.red.cgColor
           } else {
               sender.layer.backgroundColor = UIColor.white.cgColor
           }
           
           updateLikeStatus(at: index, likeStatus: likeStatus)
    }
    
    func updateLikeStatus(at index: Int, likeStatus: Bool) {
        
           let ref = Database.database().reference()
           let videoId = ref.child("VideoUrl").childByAutoId().key
           if let videoId = videoList[index]["id"] as? String {
               let likeStatusRef = ref.child("VideoUrl").child(videoId)
               likeStatusRef.updateChildValues(["like": likeStatus]) { error, _ in
                   if let error = error {
                       print("Error updating like status: \(error)")
                   } else {
                       print("Successfully updated like status")
                       DispatchQueue.main.async {
                        self.fetchDatafromDatabase()
                       }
                      
                   }
               }
           } else {
               print("No valid video ID found for the video at index \(index)")
           }
       }
   
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
}
