//
//  ViewController.swift
//  OpenDataApi
//
//  Created by Sandeep on 18/12/16.
//  Copyright © 2016 Sandeep. All rights reserved.
//


import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController,
                      WeatherGetterDelegate,
                      CLLocationManagerDelegate,
                      UITextFieldDelegate,MKMapViewDelegate
{
    @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var cityLabel: UILabel!
    
  @IBOutlet weak var descriptions: UILabel!
    
  @IBOutlet weak var link: UILabel!
    
  @IBOutlet weak var location: UILabel!
    
  @IBOutlet weak var content: UILabel!
    
  @IBOutlet weak var getLocationDetailButton: UIButton!
  @IBOutlet weak var cityTextField: UITextField!
  @IBOutlet weak var getCityDetailButton: UIButton!
  
  let locationManager = CLLocationManager()
  var weather: DetailsGetter!
    var lat: Double = 13.03297
    var long: Double = 80.26518
    var city: String = "Chennai"
    
    @IBOutlet weak var mapView: MKMapView!
  
  // MARK: -
  
  override func viewDidLoad() {
    super.viewDidLoad()
    weather = DetailsGetter(delegate: self)
    
    // Initialize UI
    // -------------
    
    descriptions.hidden = true
    cityLabel.hidden = true
    location.hidden = true
    link.hidden = true
    content.hidden = true
    mapView.hidden = true
    cityTextField.text = ""
    cityTextField.placeholder = "Enter city name"
    cityTextField.delegate = self
    cityTextField.enablesReturnKeyAutomatically = true
    getCityDetailButton.enabled = false
    zoomToRegion(lat, long: long, city: city)
    mapView.delegate = self
    
    getLocation()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
  // MARK: - Button events and states
  // --------------------------------
  
  @IBAction func getWeatherForLocationButtonTapped(sender: UIButton) {
    setWeatherButtonStates(false)
    getLocation()
  }
  
  @IBAction func getWeatherForCityButtonTapped(sender: UIButton) {
    guard let text = cityTextField.text where !text.trimmed.isEmpty else {
      return
    }
    setWeatherButtonStates(false)
    weather.getWeatherByCity(cityTextField.text!.urlEncoded)
  }
  
    func didGetWeather(weather: Details) {
        
        dispatch_async(dispatch_get_main_queue()) {
            self.cityLabel.text = weather.title_Type
            self.descriptions.text = weather.description
            self.link.text = weather.external_Source_Link
            self.location.text = weather.title_Location
            self.content.text = weather.content
            self.getLocationDetailButton.enabled = true
            
            
            
            
            
            self.lat = weather.latitude
            self.long = weather.longitude
            self.city = weather.title_Location
            self.zoomToRegion(self.lat, long: self.long, city: self.city)
            self.getCityDetailButton.enabled = self.cityTextField.text?.characters.count > 0
            self.cityLabel.hidden = false
            self.location.hidden = false
            self.descriptions.hidden = false
            self.content.hidden = false
            self.link.hidden = false
            self.mapView.hidden = false
            self.getCityDetailButton.hidden = true
            self.getLocationDetailButton.hidden = true
            self.cityTextField.hidden = true
            self.textLabel.hidden = true
        }
    }
    
    func didNotGetWeather(error: NSError) {
        // This method is called asynchronously, which means it won't execute in the main queue.
        // All UI code needs to execute in the main queue, which is why we're wrapping the call
        // to showSimpleAlert(title:message:) in a dispatch_async() call.
        dispatch_async(dispatch_get_main_queue()) {
            self.showSimpleAlert("Can't get the Location",
                                 message: "The Location service isn't responding.")
            self.getLocationDetailButton.enabled = true
            self.getCityDetailButton.enabled = self.cityTextField.text?.characters.count > 0
        }
        print("didNotGetWeather error: \(error)")
    }
    
    
  func setWeatherButtonStates(state: Bool) {
    getLocationDetailButton.enabled = state
    getCityDetailButton.enabled = state
  }
    func zoomToRegion(lat: Double, long: Double, city: String) {
        let annotation = MKPointAnnotation()
        
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        let region = MKCoordinateRegionMakeWithDistance(location, 5000.0, 7000.0)
        
        annotation.coordinate = location
        annotation.title = city
        mapView.addAnnotation(annotation)
        mapView.setRegion(region, animated: true)
        
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        
        if overlay is MKPolyline {
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 5
            
        }
        return polylineRenderer
    }
  

  
  
  // MARK: - CLLocationManagerDelegate and related methods
  
  func getLocation() {
    guard CLLocationManager.locationServicesEnabled() else {
      showSimpleAlert(
        "Please turn on location services",
        message: "This app needs location services" +
                 "for your current location.\n" +
                 "Go to Settings → Privacy → Location Services and turn location services on."
      )
      getLocationDetailButton.enabled = true
      return
    }
    
    let authStatus = CLLocationManager.authorizationStatus()
    guard authStatus == .AuthorizedWhenInUse else {
      switch authStatus {
        case .Denied, .Restricted:
          let alert = UIAlertController(
            title: "Location services for this app are disabled",
            message: "In order to get your current location, please open Settings for this app, choose \"Location\"  and set \"Allow location access\" to \"While Using the App\".",
            preferredStyle: .Alert
          )
          let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
          let openSettingsAction = UIAlertAction(title: "Open Settings", style: .Default) {
            action in
            if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
              UIApplication.sharedApplication().openURL(url)
            }
          }
          alert.addAction(cancelAction)
          alert.addAction(openSettingsAction)
          presentViewController(alert, animated: true, completion: nil)
          getLocationDetailButton.enabled = true
          return
          
        case .NotDetermined:
          locationManager.requestWhenInUseAuthorization()
          
        default:
          print("Oops! Shouldn't have come this far.")
      }
      
      return
    }
  
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    locationManager.requestLocation()
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let newLocation = locations.last!
    weather.getWeatherByCoordinates(newLocation.coordinate.latitude,
                                    longitude: newLocation.coordinate.longitude)
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    dispatch_async(dispatch_get_main_queue()) {
      self.showSimpleAlert("Can't determine your location",
                           message: "The GPS and other location services aren't responding.")
    }
    print("locationManager didFailWithError: \(error)")
  }
  
  

  func textField(textField: UITextField,
                 shouldChangeCharactersInRange range: NSRange,
                                               replacementString string: String) -> Bool {
    let currentText = textField.text ?? ""
    let prospectiveText = (currentText as NSString).stringByReplacingCharactersInRange(
      range,
      withString: string).trimmed
    getCityDetailButton.enabled = prospectiveText.characters.count > 0
    return true
  }

  func textFieldShouldClear(textField: UITextField) -> Bool {

    textField.text = ""
    
    getCityDetailButton.enabled = false
    return true
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    getWeatherForCityButtonTapped(getCityDetailButton)
    return true
  }
  
  // Tapping on the view should dismiss the keyboard.
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    view.endEditing(true)
  }
  
  
  // MARK: - Utility methods
  // -----------------------

  func showSimpleAlert(title: String, message: String) {
    let alert = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .Alert
    )
    let okAction = UIAlertAction(
      title: "OK",
      style:  .Default,
      handler: nil
    )
    alert.addAction(okAction)
    presentViewController(
      alert,
      animated: true,
      completion: nil
    )
  }
  
}
extension String {
  
  // A handy method for %-encoding strings containing spaces and other
  // characters that need to be converted for use in URLs.
  var urlEncoded: String {
    return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLUserAllowedCharacterSet())!
  }
  
  // Trim excess whitespace from the start and end of the string.
  var trimmed: String {
    return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
  }
  
}


