////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import UIKit
import RealmSwift

//TODO: Provide your foursquare client ID and client secret
let clientID = "YOUR CLIENT ID"
let clientSecret = "YOUR CLIENT SECRET"

class Venue : Object {
    dynamic var foursquareID = ""
    dynamic var name = ""
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = UIViewController()
        self.window!.makeKeyAndVisible()
        
        NSFileManager.defaultManager().removeItemAtPath(Realm.defaultPath, error: nil)
        
        // Query Foursquare API
        let foursquareVenues = self.getFoursquareVenues()
        
        // Persist the results to Realm
        self.persistToDefaultRealm(foursquareVenues)
        
        return true
    }
    
    func getFoursquareVenues() -> [String : NSDictionary] {
        // Call the foursquare API - here we use an NSData method for our API request,
        // but you could use anything that will allow you to call the API and serialize
        // the response as an NSDictionary or NSArray
        let url = NSURL(string: "https://api.foursquare.com/v2/venues/search?near=San%20Francisco&client_id=\(clientID)&client_secret=\(clientSecret)&v=20140101&limit=50")!
        var error: NSError?
        let apiResponse = NSData(contentsOfURL: url, options: nil, error: &error)
        precondition(error == nil, "Error when retrieving venues: \(error)")

        // Serialize the NSData object from the response into an NSDictionary
        let serializedResponse = (NSJSONSerialization.JSONObjectWithData(apiResponse!,
            options: nil, error: nil)! as NSDictionary)["response"] as [String: AnyObject]

        // Extract the venues from the response as an NSDictionary
        return serializedResponse["venues"]! as [String: NSDictionary]
    }

    func persistToDefaultRealm(foursquareVenues: [String: NSDictionary]) -> () {
        // Open the default Realm file
        let realm = Realm()

        // Wrap a write transaction to save to the default Realm
        realm.write {
            // Add the Venue objects to the default Realm
            realm.add(foursquareVenues.values.map { venue in
                // Store the foursquare venue name and id in a Realm Object
                let newVenue = Venue()
                newVenue.foursquareID = venue["id"] as String
                newVenue.name = venue["name"] as String
                return newVenue
            })
        }

        // Show all the venues that were persisted
        NSLog("Here are all the venues persisted to the default Realm: \n\n \(realm.objects(Venue))")
    }
}
