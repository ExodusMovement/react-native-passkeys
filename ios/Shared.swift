import Foundation
import AuthenticationServices
import LocalAuthentication

typealias Base64URLString = String

/**
 String extension to help with base64-url encoding
 */
extension String {
  // Encode a string to Base64 encoded string
  // Convert the string to data, then encode the data with base64EncodedString()
  func base64Encoded() -> String? {
    data(using: .utf8)?.base64EncodedString()
  }

  // Decode a Base64 string
  // Convert it to data, then create a string from the decoded data
  func base64Decoded() -> String? {
    guard let data = Data(base64Encoded: self) else { return nil }
    return String(data: data, encoding: .utf8)
  }
}
/**
 Data extension to enable base64-url encoding & decoding
 */
public extension Data {
  init?(base64URLEncoded input: String) {
    var base64 = input
    base64 = base64.replacingOccurrences(of: "-", with: "+")
    base64 = base64.replacingOccurrences(of: "_", with: "/")
    while base64.count % 4 != 0 {
      base64 = base64.appending("=")
    }
    self.init(base64Encoded: base64)
  }

  internal func toBase64URLEncodedString() -> Base64URLString {
    var result = self.base64EncodedString()
    result = result.replacingOccurrences(of: "+", with: "-")
    result = result.replacingOccurrences(of: "/", with: "_")
    result = result.replacingOccurrences(of: "=", with: "")
    return result
  }
}

internal enum AuthenticatorAttachment: String, Codable {
  case platform
  // - cross-platform marks that the user wants to select a security key
  case crossPlatform = "cross-platform"
}

internal enum AuthenticatorTransport: String, Codable {
  case ble
  case hybrid
  case nfc
  case usb
  case internalTransport = "internal"
  case smartCard = "smart-card"


    @available(iOS 15.0, *)
    func appleise() -> ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport? {
    switch self {
      case .ble:
        return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.bluetooth
      case .nfc:
        return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.nfc
      case .usb:
        return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.usb
        // - including these to be clear that they are not yet supported on iOS although they exist in the spec
        // case .hybrid:
        // case .internal:
        // case .smart-card:
      default:
        // tODO: warn user
        return nil
    }
  }

}


internal struct PublicKeyCredentialRpEntity: Codable {
  var name: String
  var id: String?
}

internal struct PublicKeyCredentialUserEntity: Codable {
  var name: String
  var displayName: String
  var id: Base64URLString
}

typealias COSEAlgorithmIdentifier = Int

internal enum PublicKeyCredentialType: String, Codable {
  case publicKey = "public-key"
}

internal struct PublicKeyCredentialParameters: Codable {
  // ! the defaults here are NOT the standard but they are most widely supported & popular
  var alg: COSEAlgorithmIdentifier = -7
  var type: PublicKeyCredentialType = .publicKey

    @available(iOS 15.0, *)
    func appleise() -> ASAuthorizationPublicKeyCredentialParameters {
        return ASAuthorizationPublicKeyCredentialParameters.init(algorithm: ASCOSEAlgorithmIdentifier(rawValue: self.alg))
  }
}

internal enum ResidentKeyRequirement: String, Codable {
  case discouraged
  case preferred
  case required

    @available(iOS 15.0, *)
    func appleise() -> ASAuthorizationPublicKeyCredentialResidentKeyPreference {
    switch self {
      case .discouraged:
        return ASAuthorizationPublicKeyCredentialResidentKeyPreference.discouraged
      case .preferred:
        return ASAuthorizationPublicKeyCredentialResidentKeyPreference.preferred
      case .required:
        return ASAuthorizationPublicKeyCredentialResidentKeyPreference.required
      default:
        return ASAuthorizationPublicKeyCredentialResidentKeyPreference.preferred
    }
  }
}

internal enum UserVerificationRequirement: String, Codable {
  case discouraged
  case preferred
  case required

    @available(iOS 15.0, *)
    func appleise () -> ASAuthorizationPublicKeyCredentialUserVerificationPreference {
    switch self {
      case .discouraged:
        return ASAuthorizationPublicKeyCredentialUserVerificationPreference.discouraged
      case .preferred:
        return ASAuthorizationPublicKeyCredentialUserVerificationPreference.preferred
      case .required:
        return ASAuthorizationPublicKeyCredentialUserVerificationPreference.required
      default:
        return ASAuthorizationPublicKeyCredentialUserVerificationPreference.preferred
    }
  }
}



internal struct PublicKeyCredentialDescriptor: Codable {
  var id: Base64URLString
  var transports: [AuthenticatorTransport]?
  var type: PublicKeyCredentialType = .publicKey

    @available(iOS 15.0, *)
    func getPlatformDescriptor() -> ASAuthorizationPlatformPublicKeyCredentialDescriptor {
    return ASAuthorizationPlatformPublicKeyCredentialDescriptor.init(credentialID: Data(base64URLEncoded: self.id)!)
  }

    @available(iOS 15.0, *)
    func getCrossPlatformDescriptor() -> ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor {
    var transports = ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.allSupported

    if self.transports?.isEmpty == false {
      transports = self.transports!.compactMap { $0.appleise() }
    }

    return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.init(credentialID: Data(base64URLEncoded: self.id)!,
                                                                        transports: transports)
  }
}

internal struct AuthenticatorSelectionCriteria: Codable {
  var authenticatorAttachment: AuthenticatorAttachment?
  var residentKey: ResidentKeyRequirement?
  var requireResidentKey: Bool? = false
  var userVerification: UserVerificationRequirement? = .preferred
}


internal enum AttestationConveyancePreference: String, Codable {
  case direct
  case enterprise
  case indirect
  case none

    @available(iOS 15.0, *)
    func appleise() -> ASAuthorizationPublicKeyCredentialAttestationKind {
    switch self {
      case .none:
        return ASAuthorizationPublicKeyCredentialAttestationKind.none
      case .direct:
        return ASAuthorizationPublicKeyCredentialAttestationKind.direct
      case .indirect:
        return ASAuthorizationPublicKeyCredentialAttestationKind.indirect
      case .enterprise:
        return ASAuthorizationPublicKeyCredentialAttestationKind.enterprise
    }
  }
}

internal enum LargeBlobSupport: String, Codable {
  case preferred
  case required
}


internal struct AuthenticationExtensionsLargeBlobInputs: Codable {
  // - Only valid during registration.
  var support: LargeBlobSupport?

  // - A boolean that indicates that the Relying Party would like to fetch the previously-written blob associated with the asserted credential. Only valid during authentication.
  var read: Bool?

  // - An opaque byte string that the Relying Party wishes to store with the existing credential. Only valid during authentication.
  // - We impose that the data is passed as base64-url encoding to make better align the passing of data from RN to native code
  var write: Base64URLString?
}


internal struct AuthenticationExtensionsClientInputs: Codable {
  var largeBlob: AuthenticationExtensionsLargeBlobInputs?
}


protocol PasskeyResultHandler {
    @available(iOS 15.0, *)
    func onSuccess(_ data: PublicKeyCredentialJSONResponse)
  func onFailure(_ error: Error)
}

extension LAContext {
  enum BiometricType: String {
    case none
    case touchID
    case faceID
    case opticID
  }

  var biometricType: BiometricType {
    var error: NSError?

    guard self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      // Capture these recoverable error thru Crashlytics
      return .none
    }

    if #available(iOS 11.0, *) {
      switch self.biometryType {
        case .none:
          return .none
        case .touchID:
          return .touchID
        case .faceID:
          return .faceID
        case .opticID:
          return .opticID
        @unknown default:
          return .none
      }
    } else {
      return  self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
    }
  }
}

extension Encodable {
  func asDictionary() throws -> [String: Any]? {
    let data = try JSONEncoder().encode(self)
    let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
    return dictionary
  }
}

