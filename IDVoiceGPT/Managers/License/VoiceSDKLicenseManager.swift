//
//  LicenseManager.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 21.07.2023.
//  Copyright © 2023 ID R&D. All rights reserved.
//

import Foundation
import VoiceSdk

class VoiceSDKLicenseManager {
    // The private license key
    // TODO: Replace 'YOUR_VOICE_SDK_LICENCE_KEY' with your actual VoiceSDK license key
    private var licenseKey = "YOUR_VOICE_SDK_LICENCE_KEY'"
    
    func setLicense() throws {
        do {
            try MobileLicense.setLicense(licenseKey)
        } catch {
            throw error
        }
    }
}
