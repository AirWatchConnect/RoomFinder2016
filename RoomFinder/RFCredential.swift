//
//  RFCredential.swift
//  RoomFinderSwift
//
//  Created by Jing Wang on 3/24/16.
//  Copyright © 2016 Jing Wang. All rights reserved.
//

import Foundation


class RFCredential {
    private var username : String = ""
    private var password : String = ""
    
    static let shareInstance = RFCredential()
    
    func setCredential( un : String, pw : String ) {
        username = un
        password = pw
    }
    
    func getUsername() -> String {
        return username
    }
    
    func getPassword() -> String {
        return password
    }
    
    func isCredentialsEmpty() -> Bool
    {
        if(username == "" || password == "")
        {
            return true
        }
        else
        {
            return false
        }
    }
    
}