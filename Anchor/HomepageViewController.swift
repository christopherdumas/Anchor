//
//  HomepageViewController.swift
//  Anchor
//
//  Created by Christopher Dumas on 10/11/15.
//  Copyright © 2015 Christopher Dumas. All rights reserved.
//
import Firebase
import UIKit

class HomepageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var username: String = "Anonymous"
    var password: String = "P@$$W0RD"
    var realm: String     = "None"
    var teacherPosts: [[Post]] = []
    var sections: [String] = []
    var admins: [String] = []
    var myRootRef = Firebase(url:"https://anchor-ios-app.firebaseio.com")
    var refreshControl = UIRefreshControl()
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var newAnchor: UIBarButtonItem!
    
    @IBOutlet weak var postButton: UIBarButtonItem!
    
    func dicToPost(dic: NSDictionary) -> Post {
        return Post(text: "Placeholder")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let _ = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.systemFontOfSize(19, weight: UIFontWeightThin)]
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.refreshControl.backgroundColor = UIColor.redColor()
        self.refreshControl.tintColor = UIColor.whiteColor()
        self.refreshControl.addTarget(self, action: Selector("updateTableView"), forControlEvents: .ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        let realmRef = myRootRef.childByAppendingPath(realm)
        updateTableView(realmRef)
    }
    
    func update() {
        dispatch_async(dispatch_get_main_queue()) {
            let realmRef = self.myRootRef.childByAppendingPath(self.realm)
            self.updateTableView(realmRef)
            self.tableView.reloadData()
        }
    }
    
    func updateTableView(ref: Firebase) {
        ref.observeEventType(.Value, withBlock: { snapshot in
            self.admins = (snapshot.value.objectForKey("admins")! as! [String])
            self.sections = (snapshot.value.objectForKey("groups")! as! [String])
            let posts = (snapshot.value.objectForKey("posts")! as! NSDictionary).allValues as! [NSDictionary]
            
            func distinct<T: Equatable>(source: [T]) -> [T] {
                var unique = [T]()
                for item in source {
                    if !unique.contains(item) {
                        unique.append(item)
                    }
                }
                return unique
            }
            
            func groupPosts(posts: [NSDictionary]) -> [(String, [Post])] {
                let postGroups = posts.map { ($0["group"] as! String) }
                let distinctGroups = distinct(postGroups)
                
                return distinctGroups.map {
                    (group) in
                    return (group, posts.filter { (post) -> Bool in
                        return (post["group"] as! String) == group
                        }.enumerate().map(Post.fromDictionary))
                }
            }
            
            self.teacherPosts = groupPosts(posts).map({ $0.1 })
            self.tableView.reloadData()
            
            if let _ = self.admins.indexOf(self.username) {
                self.postButton.enabled = true
                self.postButton.tintColor = UIColor.redColor()
            } else {
                self.postButton.enabled = false
                self.postButton.tintColor = UIColor.clearColor()
            }
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        self.refreshControl.endRefreshing()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "Adminpage" {
            let vc = segue.destinationViewController as! AdminViewController
            vc.username = self.username
            vc.password = self.password
            vc.realm = self.realm
            vc.admins = self.admins
        } else if segue.identifier == "Postpage" {
            let vc = segue.destinationViewController as! PostViewController
            
            let myIndexPath = self.tableView.indexPathForSelectedRow
            vc.post = self.teacherPosts[myIndexPath!.section][myIndexPath!.row]
            vc.realm = self.realm
            vc.username = self.username
        } else if segue.identifier == "Addpostpage" {
            let vc = segue.destinationViewController as! SpeakViewController
            vc.realm = self.realm
            vc.username = self.username
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.teacherPosts.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teacherPosts[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        let post = teacherPosts[indexPath.section][indexPath.row]
        cell.textLabel!.text = post.text
        cell.textLabel!.font = UIFont.systemFontOfSize(16, weight: UIFontWeightThin)
        cell.detailTextLabel!.text = "By " + post.author
        cell.detailTextLabel!.font = UIFont.systemFontOfSize(11, weight: UIFontWeightThin)
        return cell
    }
}