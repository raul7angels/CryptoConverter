//
//  ViewController.swift
//  BitcoinTicker
//
//  Created by Angela Yu on 23/01/2016.
//  Copyright © 2016 London App Brewery. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

struct CryptoData {
    var name: String
    var priceInBtc: Double
    var volume: Double
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let btcURL = "https://apiv2.bitcoinaverage.com/indices/global/ticker/BTC"
    let cryptoURL = "http://api.cryptocoincharts.info/listCoins"
    
    let currencyArray = ["AUD", "BRL","CAD","CNY","EUR","GBP","HKD","IDR","ILS","INR","JPY","MXN","NOK","NZD","PLN","RON","RUB","SEK","SGD","USD","ZAR"]
    let symbolArray = ["$", "R$", "$", "¥", "€", "£", "$", "Rp", "₪", "₹", "¥", "$", "kr", "$", "zł", "lei", "₽", "kr", "$", "$", "R"]
    
    var topCryptoArray: ArraySlice<CryptoData> = []
    
    var btcRate : Double = 0
    var currentCurrency = ""
    var currentCoin = 0
    
    //Pre-setup IBOutlets
    @IBOutlet weak var bitcoinPriceLabel: UILabel!
    @IBOutlet weak var currencyPicker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencyPicker.delegate = self
        currencyPicker.dataSource = self
        getbtcData(currency: currencyArray[0], symbol: symbolArray[0])
        getCryptoData(top: 50)
        
    }
    
    
    //TODO: Place your 3 UIPickerView delegate methods here
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return currencyArray.count
        } else if topCryptoArray.count > 0 {
            return topCryptoArray.count
        } else {
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return currencyArray[row]
        } else if topCryptoArray.count > 0 {
            return topCryptoArray[row].name
        } else {
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            let selectedCurrency = currencyArray[row]
            let selectedSymbol = symbolArray[row]
            getbtcData(currency: selectedCurrency, symbol: selectedSymbol)
        } else if topCryptoArray.count > 0 {
            let coinPrice = Double(btcRate) * topCryptoArray[row].priceInBtc
            updateUI(price: coinPrice, currency: currentCurrency)
            currentCoin = row
        } else {
            
        }
    }
    
    
    //MARK: - Networking
    /***************************************************************/
    
    func getbtcData(currency: String, symbol: String) {
        let url = btcURL + currency
        
        Alamofire.request(url, method: .get)
            .responseJSON { response in
                if response.result.isSuccess {
                    
                    print("Sucess! Got the data")
                    let priceJSON : JSON = JSON(response.result.value!)
                    self.updatePriceData(json: priceJSON, currency: symbol)
                    
                } else {
                    print("Error: \(String(describing: response.result.error))")
                    self.bitcoinPriceLabel.text = "Connection Issues"
                }
        }
        
    }
    
    
    func getCryptoData(top: Int){
        
        Alamofire.request(cryptoURL, method: .get).responseJSON { response in
            
            if response.result.isSuccess {
                
                print("Sucess! Got the data")
                let priceJSON : JSON = JSON(response.result.value!)
                
                var cryptoArray: [CryptoData] = []
                
                // Create an array of CryptoData objects from JSON
                for (_, object) in priceJSON {
                    if object["volume_btc"].intValue > 10, object["name"] != "" {
                        cryptoArray.append(CryptoData(name: object["name"].stringValue, priceInBtc: object["price_btc"].doubleValue, volume: object["volume_btc"].doubleValue))
                    }
                }
                
                // Sort and slice the array to get the top x highest volume cryptocurrencies
                cryptoArray.sort { $0.volume > $1.volume }
                self.topCryptoArray = cryptoArray.prefix(top)
                
                // Fixing the positioning so BTC would be the first item in the Array
                let btcElement = self.topCryptoArray.remove(at: 1)
                self.topCryptoArray.insert(btcElement, at: 0)
                print(self.topCryptoArray.count)
                self.currencyPicker.reloadAllComponents()
                
            } else {
                print("Error: \(String(describing: response.result.error))")
                self.bitcoinPriceLabel.text = "Connection Issues"
            }
        }
        
    }
    
    
    //MARK: - JSON Parsing
    /***************************************************************/
    
    func updatePriceData(json : JSON, currency: String) {
        var adjustedPrice : Double = 0
        
        if let lastPrice = json["last"].double {
            if topCryptoArray.count > 0 {
                adjustedPrice = Double(lastPrice) * topCryptoArray[currentCoin].priceInBtc
            } else {
                adjustedPrice = lastPrice
            }
            currentCurrency = currency
            btcRate = lastPrice
            updateUI(price: adjustedPrice, currency: currency)
        }
    }
    
    
    func updateUI(price: Double, currency: String) {
        
        bitcoinPriceLabel.text = "\(price.rounded(toPlaces: 2)) \(currency)"
    }
    
}

