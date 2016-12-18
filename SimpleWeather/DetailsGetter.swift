//
//  DetailsGetter.swift
//  OpenDataApi
//
//  Created by Sandeep on 18/12/16.
//  Copyright © 2016 Sandeep. All rights reserved.
//
import Foundation


// MARK: Details Getter Method
// ===========================
// DetailsGetter should be used by a class or struct, and that class or struct
// should adopt this protocol and register itself as the delegate.
// The delegate's didGetdetails method is called if the details data was
// acquired from OpendetailsMap.org and successfully converted from JSON into
// a Swift dictionary.
// The delegate's didNotGetdetails method is called if either:
// - The details was not acquired from OpenWeatherMap.org, or
// - The received details data could not be converted from JSON into a dictionary.
protocol WeatherGetterDelegate {
  func didGetWeather(weather: Details)
  func didNotGetWeather(error: NSError)
}


// MARK: detailsGetter
// ===================

class DetailsGetter {
  
  private let openWeatherMapBaseURL = "https://brottsplatskartan.se/api/events/?location="
  private var delegate: WeatherGetterDelegate
  
  
  // MARK: -
  
  init(delegate: WeatherGetterDelegate) {
    self.delegate = delegate
  }
  
  func getWeatherByCity(city: String) {
    let weatherRequestURL = NSURL(string: "\(openWeatherMapBaseURL)\(city)")!
    getWeather(weatherRequestURL)
  }
  
  func getWeatherByCoordinates(latitude: Double, longitude: Double) {
    let weatherRequestURL = NSURL(string: "\(openWeatherMapBaseURL)lat=\(latitude)&lon=\(longitude)")!
    getWeather(weatherRequestURL)
  }
  
  private func getWeather(weatherRequestURL: NSURL) {
    
    // This is a pretty simple networking task, so the shared session will do.
    let session = NSURLSession.sharedSession()
    session.configuration.timeoutIntervalForRequest = 3
    
    // The data task retrieves the data.
    let dataTask = session.dataTaskWithURL(weatherRequestURL) {
      (data: NSData?, response: NSURLResponse?, error: NSError?) in
      if let networkError = error {
        // Case 1: Error
        // An error occurred while trying to get data from the server.
        self.delegate.didNotGetWeather(networkError)
      }
      else {
        // Case 2: Success
        // We got data from the server!
        do {
          // Try to convert that data into a Swift dictionary
          let detailsData = try NSJSONSerialization.JSONObjectWithData(
            data!,
            options: .MutableContainers) as! [String: AnyObject]
          
          // If we made it to this point, we've successfully converted the
          // JSON-formatted weather data into a Swift dictionary.
          // Let's now used that dictionary to initialize a Weather struct.
          let response_Details = Details(detailsData: detailsData)
          // which will use it to display the weather to the user.
          self.delegate.didGetWeather(response_Details)
        }
        catch let jsonError as NSError {
          // An error occurred while trying to convert the data into a Swift dictionary.
          self.delegate.didNotGetWeather(jsonError)
        }
      }
    }
    
    // The data task is set up...launch it!
    dataTask.resume()
  }
  
}


