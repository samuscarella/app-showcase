//
//  FeedVC.swift
//  app-showcase
//
//  Created by Stephen Muscarella on 9/3/16.
//  Copyright © 2016 samuscarella. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postField: MaterialTextField!
    @IBOutlet weak var imageSelectorImage: UIImageView!
    
    var posts = [Post]()
    var imageSelected = false
    var imagePicker: UIImagePickerController!
    
    static var imageCache = NSCache()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 374
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        DataService.ds.ref.child("posts").observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                self.posts = []
                for snap in snapshots {
//                    print("SNAP: \(snap)")
                    
                    if let postDict = snap.value as?  Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                    }
                }
            }
                
            self.tableView.reloadData()
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            
            cell.request?.cancel()
            
            var img: UIImage?
            
            if let url = post.imageUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(post, img: img)
            
            return cell
        } else {
            return PostCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let post = posts[indexPath.row]
        
        if post.imageUrl == nil {
            return 180
        } else {
            return tableView.estimatedRowHeight
        }
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelectorImage.image = image
        imageSelected = true
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }

    @IBAction func makePost(sender: AnyObject) {
        
        if let txt = postField.text where txt != "" {
            
            if let img = imageSelectorImage.image where imageSelected == true {
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                let imgData = UIImageJPEGRepresentation(img, 0.2)!
                let apiData = "5XQZ02GV3af1fd66f1b3cd095155503591c0c77b".dataUsingEncoding(NSUTF8StringEncoding)!
                let keyJSON = "json".dataUsingEncoding(NSUTF8StringEncoding)!
                
                Alamofire.upload(.POST, url, multipartFormData: { MultipartFormData in
                    
                    MultipartFormData.appendBodyPart(data: imgData, name: "fileupload", fileName: "image", mimeType: "image/jpg")
                    MultipartFormData.appendBodyPart(data: apiData, name: "key")
                    MultipartFormData.appendBodyPart(data: keyJSON, name: "format")
                    
                    
                    }) { encodingResult in
                    
                        switch encodingResult {
                        case .Success(let upload, _, _):
                            upload.validate().responseJSON(completionHandler: { response in
                                
                                if let info = response.result.value as? Dictionary<String, AnyObject> {
                                    
                                    if let links = info["links"] as? Dictionary<String, AnyObject> {
                                        if let imgLink = links["image_link"] as? String {
                                            print("LINK: \(imgLink)")
                                            self.postToFirebase(imgLink)
                                        }
                                    }
                                }
                            })
                        case .Failure(let error):
                            print(error)
                        }
                }
        
            } else {
                self.postToFirebase(nil)
            }
        }
    }
    
    func postToFirebase(imgUrl: String?) {
        
        //Wrap mandatroy data in dictionary
        var post: Dictionary<String, AnyObject> = [
            "description": postField.text!,
            "likes": 0
        ]
        //Wrap optionals in dictionary
        if imgUrl != nil {
            post["imageUrl"] = imgUrl!
        }
        
        let firebasePost = DataService.ds.ref.child("posts").childByAutoId()
        firebasePost.setValue(post)
        postField.text = ""
        imageSelectorImage.image = UIImage(named: "camera")
        
        tableView.reloadData()
    }
}
