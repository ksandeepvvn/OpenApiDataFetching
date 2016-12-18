//
//  Details.swift
//  OpenDataApi
//
//  Created by Sandeep on 18/12/16.
//  Copyright © 2016 Sandeep. All rights reserved.
//

import Foundation

struct Details{
    let title_Type: String
    var title_Location: String
    let description: String
    let latitude: Double
    let longitude: Double
    let content: String
    let external_Source_Link: String
    
    init(detailsData: [String: AnyObject]) {
        let detailDict = detailsData["data"]![0] as! [String: AnyObject]
        longitude = detailDict["lng"] as! Double
        latitude = detailDict["lat"] as! Double
        title_Type = detailDict["title_type"] as! String
        title_Location = detailDict["title_location"] as! String
        description = detailDict["description"] as! String
        content = detailDict["content"] as! String
        external_Source_Link = detailDict["external_source_link"] as! String
    }
}
