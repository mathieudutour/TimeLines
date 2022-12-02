//
//  ContactPickerHelper.swift
//  TimeLine
//
//  Created by Matt B on 31/10/2022.
//  Copyright © 2022 Mathieu Dutour. All rights reserved.
//

import Foundation
import Contacts
import TimeLineShared
import PhoneNumberKit
import CoreLocation

extension ContactPicker.Coordinator {
    typealias CDM = CoreDataManager
    
    func convertToContact(cnContact: CNContact, completion: @escaping(_ contact: Contact?) -> ()) {
        if let postalAddress = cnContact.postalAddresses.first?.value {
            getTimeZone(for: parseAddress(postalAddress), cnContact.givenName, completion: completion)
        } else if let phoneNumber = cnContact.phoneNumbers.first?.value,
                  let country = getCountryFrom(phoneNumber: phoneNumber.stringValue) {
            getTimeZone(for: country, cnContact.givenName, completion: completion)
        } else if let emailAddress = cnContact.emailAddresses.first?.value {
            if let country = getCountryFrom(email: (emailAddress as String)) {
                getTimeZone(for: country, cnContact.givenName, completion: completion)
            }
        } else {
            DispatchQueue.main.async {
                completion(CDM.shared.createContact(name: cnContact.givenName))
            }
        }
    }
    
    private func getTimeZone(for address: String, _ contactName: String, completion: @escaping(_ contact: Contact?) -> ()) {
        getCoordinateFrom(address: address) { [weak self] addressCoordinates, locationName in
            guard let self = self else { return }
            
            self.getTimeZone(from: addressCoordinates) { timeZone in
                DispatchQueue.main.async {
                    completion(CDM.shared.createContact(
                        name: contactName,
                        latitude: addressCoordinates.latitude,
                        longitude: addressCoordinates.longitude,
                        locationName: locationName,
                        timezone: timeZone
                    ))
                }
            }
        }
    }
    
    private func getTimeZone(from coordinates: CLLocationCoordinate2D, completion: @escaping(_ timeZoneInHours: Int32) -> ()) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )) { placemark, error in
            if let timeZoneInSeconds = placemark?.last?.timeZone?.secondsFromGMT() {
                completion(Int32(timeZoneInSeconds / 60 / 60))
            } else {
                completion(0)
            }
        }
    }
    
    private func getCoordinateFrom(
        address: String,
        locationName: String? = nil,
        completion: @escaping(_ coordinate: CLLocationCoordinate2D, _ locationName: String) -> ()
    ) {
        CLGeocoder().geocodeAddressString(address) { coordinates, error in
            if let coordinates = coordinates?.first?.location?.coordinate, error == nil {
                completion(coordinates, locationName ?? address)
            } else {
                completion(CLLocationCoordinate2D(), address)
            }
        }
    }
    
    private func getCountryFrom(phoneNumber: String) -> String? {
        let phoneNumberKit = PhoneNumberKit()
        do {
            if let countryISOCode = phoneNumberKit.mainCountry(
                forCode: try phoneNumberKit.parse(phoneNumber).countryCode
            ) {
                return Locale(identifier: "en_\(countryISOCode)")
                    .localizedString(forRegionCode: countryISOCode)
            }
        }
        catch {
            print("❌ Failed to parse country from phone number: ", error)
        }
        return nil
    }
    
    private func getCountryFrom(email: String) -> String? {
        if let dotIndex = email.lastIndex(of: ".") {
            return TLDCountries.getCountryName(from: String(email[dotIndex...]))
        }
        return nil
    }
    
    private func parseAddress(_ postalAddress: CNPostalAddress) -> String {
        var address = ""
        for addressPart in [postalAddress.city, postalAddress.postalCode, postalAddress.country] {
            if !addressPart.isEmpty {
                let separatorCharacter = addressPart == postalAddress.country ? ", " : " "
                address.isEmpty ? address.append(addressPart) : address.append(separatorCharacter + addressPart)
            }
        }
        return address
    }
    
}
