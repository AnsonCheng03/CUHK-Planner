//
//  ContentView.swift
//  CUHK Planner
//
//  Created by Anson Cheng on 20/11/2022.
//

import SwiftUI

struct ContentView: View {
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack {
            Image("emblem")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width / 3)
            Spacer()
                .frame(height: 50)
            
            
            Text("Login")
                .font(.headline)
            TextField("SID", text: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Value@*/.constant("")/*@END_MENU_TOKEN@*/)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.black, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
            TextField("Password", text: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Value@*/.constant("")/*@END_MENU_TOKEN@*/)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.black, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
            
            
            Spacer()
                .frame(height: 25)
            Button(action: {
                    print("sign up bin tapped")
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
            Button("Use without login") {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
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
