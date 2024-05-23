//
//  VideoTCell.swift
//  FirebaseSocialApp
//
//  Created by kavita chauhan on 22/05/24.
//

import UIKit
import AVKit
import AVFoundation

//protocol VideoLikeStatusDelegate:AnyObject{
//    func didtapLike(cell:VideoTCell)
//}

class VideoTCell: UITableViewCell {
    
    @IBOutlet weak var imgvideoList: UIImageView!
    
    @IBOutlet weak var btnLikeUnlike: UIButton!
    
    //    var delegate:VideoLikeStatusDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    @IBAction func btnLike(_ sender: Any) {
        //        delegate?.didtapLike(cell: self)
    }
    
//    func commitInit(videoUrl: String) {
//        guard let videoUrls = URL(string: videoUrl) else { return }
//        getThumbnailfromVideo(url: videoUrls) { image in
//            self.imgvideoList.image = image
//        }
//    }
    
    
//    func getThumbnailfromVideo(url: URL, completion: @escaping ((_ image: UIImage?) -> Void)) {
//        DispatchQueue.global().async {
//            let asset = AVAsset(url: url)
//            let avassetImgGenerator = AVAssetImageGenerator(asset: asset)
//            avassetImgGenerator.appliesPreferredTrackTransform = true
//            let thumbnailTime = CMTimeMake(value: 3, timescale: 5)
//            
//            do {
//                let cgThumbImg = try avassetImgGenerator.copyCGImage(at: thumbnailTime, actualTime: nil)
//                let thumbnailImg = UIImage(cgImage: cgThumbImg)
//                DispatchQueue.main.async {
//                    completion(thumbnailImg)
//                }
//            } catch {
//                print(error.localizedDescription,"thumnailerro-=-=")
//                DispatchQueue.main.async {
//                    completion(nil)
//                }
//            }
//        }
//    }
}
