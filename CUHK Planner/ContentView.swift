//
//  ContentView.swift
//  CUHK Planner
//
//  Created by Anson Cheng on 20/11/2022.
//

import SwiftUI
import Foundation
import CommonCrypto
import SWXMLHash

struct CUSISTTB: Codable {
    var K : String
    var STRM : String
    var STRM_DESCR : String
    var CLASS_NBR : String
    var CLASS_MTG_NBR : String
    var DESCR : String
    var CRSE_ID : String
    var SUBJECT : String
    var CATALOG_NBR : String
    var SSR_COMPONENT : String
    var START_DT : String
    var END_DT : String
    var MEETING_TIME_START : String
    var MEETING_TIME_END : String
    var MON : String
    var TUES : String
    var WED : String
    var THURS : String
    var FRI : String
    var SAT : String
    var SUN : String
    var FACILITY_ID : String
    var SSR_COMPONENT1 : String
    var CLASS_SECTION : String
    var FDESCR : String
    var BLDG_CD : String
    var LAT : String
    var LNG : String
    var INSTRUCTORS : String
    var COMDESC : String
}

extension String{
    func removeAMPSemicolon() -> String{
        return replacingOccurrences(of: "amp;", with: "")
    }
    
    func replaceAnd() -> String{
        return replacingOccurrences(of: "&", with: "And")
    }
    
    func removeNewLine() -> String{
        return replacingOccurrences(of: "\n", with: "")
    }
    
    func replaceAposWithApos() -> String{
        return replacingOccurrences(of: "Andapos;", with: "'")
    }
    
    func parse<D>(to type: D.Type) -> D? where D: Decodable {

        let data: Data = self.data(using: .utf8)!

        let decoder = JSONDecoder()

        do {
            let _object = try decoder.decode(type, from: data)
            return _object

        } catch {
            return nil
        }
    }
    
}

struct AES {
    private let key: Data
    private let iv: Data
    
    init?(key: String, iv: String) {
        guard key.count == kCCKeySizeAES128 || key.count == kCCKeySizeAES256, let keyData = key.data(using: .utf8) else {
            debugPrint("Error: Failed to set a key.")
            return nil
        }
        
        guard iv.count == kCCBlockSizeAES128, let ivData = iv.data(using: .utf8) else {
            debugPrint("Error: Failed to set an initial vector.")
            return nil
        }
        
        self.key = keyData
        self.iv  = ivData
    }
    
    func encrypt(string: String) -> Data? {
        return crypt(data: string.data(using: .utf8), option: CCOperation(kCCEncrypt))
    }
    
    func decrypt(data: Data?) -> String? {
        guard let decryptedData = crypt(data: data, option: CCOperation(kCCDecrypt)) else { return nil }
        return String(bytes: decryptedData, encoding: .utf8)
    }
    
    func crypt(data: Data?, option: CCOperation) -> Data? {
        guard let data = data else { return nil }
        
        let cryptLength = data.count + key.count
        var cryptData   = Data(count: cryptLength)
        
        var bytesLength = Int(0)
        
        let status = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                        CCCrypt(option, CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), keyBytes.baseAddress, key.count, ivBytes.baseAddress, dataBytes.baseAddress, data.count, cryptBytes.baseAddress, cryptLength, &bytesLength)
                    }
                }
            }
        }
        
        guard Int32(status) == Int32(kCCSuccess) else {
            debugPrint("Error: Failed to crypt data. Status \(status)")
            return nil
        }
        
        cryptData.removeSubrange(bytesLength..<cryptData.count)
        return cryptData
    }
}

func encodeCUSIS(data: String) -> String {
    return (AES(
        key: "e3ded030ce294235047550b8f69f5a28",
        iv: "e0b2ea987a832e24"
    )?.encrypt(
        string: data
    )?
        .base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)))! as String
}

struct ContentView: View {
    @State var signInSuccess = false
    
    var body: some View {
        return Group {
            if (signInSuccess) {
                Main()
            }
            else {
                Login(signInSuccess: $signInSuccess)
            }
        }
    }
}

struct Login: View {
    
    func CUSISLogin (username : String, password : String) {
        guard let url = URL(string: "https://campusapps.itsc.cuhk.edu.hk/store/CLASSSCHD/STT.asmx") else { fatalError("Missing URL") }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = [
            "Content-Type" : "text/xml; charset=utf-8",
            "User-Agent" : "ClassTT/2.4 CFNetwork/1333.0.4 Darwin/21.5.0"
        ]
        urlRequest.httpBody = "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><GetTimeTable xmlns=\"http://tempuri.org/\"><asP1> \(encodeCUSIS(data: username)) </asP1><asP2> \(encodeCUSIS(data: password)) </asP2><asP3>hk.edu.cuhk.ClassTT</asP3></GetTimeTable></soap:Body></soap:Envelope>".data(using: .utf8)
        
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }
            
            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    
                    let xml = XMLHash.parse(data)["soap:Envelope"]["soap:Body"]["GetTimeTableResponse"]["GetTimeTableResult"].element!.text
                    let cusisttb = xml.parse(to: [CUSISTTB].self)
                    
                    if(cusisttb?.isEmpty == true) {
                        ErrorMessage = "Incorrect username / password"
                        loginError = true
                        return;
                    }
                    
                    let userDefaults = UserDefaults.standard
                    userDefaults.set(username, forKey: "CUSISusername")
                    userDefaults.set(password, forKey: "CUSISpasswords")
                    signInSuccess = true;
                }
            } else {
                ErrorMessage = String(
                    data: data!,
                    encoding: .utf8
                )!
                loginError = true
            }
        }
        
        dataTask.resume()
    }
    
    @Binding var signInSuccess: Bool
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    @State private var bypassLoginPrompt = false
    @State private var loginError = false
    
    @State var ErrorMessage: String = "";
    
    var body: some View {
        //Login Page
        
        VStack {
            Image("emblem")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width / 3)
            Spacer()
                .frame(height: 50)
            
            
            Text("Login")
                .font(.headline)
            TextField("SID", text: $username)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.black, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
                .onAppear {
                    username = UserDefaults.standard.string(forKey: "CUSISusername") ?? ""
                }
            
            SecureField("Password", text: $password)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.black, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
                .onAppear {
                    password = UserDefaults.standard.string(forKey: "CUSISpasswords") ?? ""
                }
            
            Spacer()
                .frame(height: 25)
            
            Button(action: {
                CUSISLogin(username: username, password: password)
            }) {
                Text("Login")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .font(.system(size: 18))
                    .padding()
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            .background(Color(red: 230 / 255, green: 70 / 255, blue: 140 / 255))
            .cornerRadius(10)
            .alert(ErrorMessage, isPresented: $loginError) {
                Button("Retry") { }
            }
            .onAppear {
                let userDefaults = UserDefaults.standard
                if(userDefaults.string(forKey: "CUSISusername") != "" && userDefaults.string(forKey: "CUSISpasswords") != "") {
                    CUSISLogin(username: userDefaults.string(forKey: "CUSISusername")!, password: userDefaults.string(forKey: "CUSISpasswords")!)
                }
            }
            
            Spacer()
                .frame(height: 15)
            
            Button("Use without login") {
                bypassLoginPrompt = true
            }.alert("You have to login in order to get the datas from CUSIS", isPresented: $bypassLoginPrompt) {
                Button("Continue") { signInSuccess = true; }
                Button("Cancel") { }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
