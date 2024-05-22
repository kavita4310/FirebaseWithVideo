//
//  VideoTCell.swift
//  FirebaseSocialApp
//
//  Created by kavita chauhan on 22/05/24.
//

import UIKit

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
    
}
