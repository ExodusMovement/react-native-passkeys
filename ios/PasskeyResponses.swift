/**
    Specification reference: https://w3c.github.io/webauthn/#typedefdef-publickeycredentialjson
*/
@available(iOS 15.0, *)
enum PublicKeyCredentialJSONResponse {
  case registration(RegistrationResponseJSON)
  case authentication(AuthenticationResponseJSON)
}

/**
    Specification reference: https://w3c.github.io/webauthn/#dictdef-registrationresponsejson
*/
@available(iOS 15.0, *)
internal struct RegistrationResponseJSON: Codable {
  var id: Base64URLString
  var rawId: Base64URLString
  var response: AuthenticatorAttestationResponseJSON
  var authenticatorAttachment: AuthenticatorAttachment?
  var clientExtensionResults: AuthenticationExtensionsClientOutputsJSON?
  var type: PublicKeyCredentialType = .publicKey
}

/**
    Specification reference: https://w3c.github.io/webauthn/#dictdef-authenticatorattestationresponsejson
*/
@available(iOS 15.0, *)
internal struct AuthenticatorAttestationResponseJSON: Codable {
  var clientDataJSON: Base64URLString
  // - Required in L3 but not in L2 so leaving optional as most have not adapted L3 yet
  var authenticatorData: Base64URLString?
  // - Required in L3 but not in L2 so leaving optional as most have not adapted L3 yet
  var transports: [AuthenticatorTransport]?
  var publicKeyAlgorithm: Int?
  var publicKey: Base64URLString?
  var attestationObject: Base64URLString
}

/**
    Specification reference: https://w3c.github.io/webauthn/#dictdef-authenticationresponsejson
*/

internal struct AuthenticationResponseJSON: Codable {
  var type: PublicKeyCredentialType = .publicKey
  // - base64URL version of rawId
  var id: Base64URLString
  var rawId: Base64URLString?
  var authenticatorAttachment: AuthenticatorAttachment?
  var response: AuthenticatorAssertionResponseJSON

  var clientExtensionResults: AuthenticationExtensionsClientOutputsJSON?
}

/**
    Specification reference: https://w3c.github.io/webauthn/#dictdef-authenticatorassertionresponsejson
*/
internal struct AuthenticatorAssertionResponseJSON: Codable {
  var authenticatorData: Base64URLString
  var clientDataJSON: Base64URLString
  var signature: Base64URLString
  var userHandle: Base64URLString?
  var attestationObject: Base64URLString?
}

/**
    Specification reference: https://w3c.github.io/webauthn/#dictdef-authenticationextensionsclientoutputsjson
*/
internal struct  AuthenticationExtensionsClientOutputsJSON: Codable {

  // ? this is only available in iOS 17 but I cannot set this here
  // @available(iOS 17.0, *)
  var largeBlob: AuthenticationExtensionsLargeBlobOutputsJSON?

}

/**
 We convert this to `AuthenticationExtensionsLargeBlobOutputsJSON` instead of `AuthenticationExtensionsLargeBlobOutputs` for consistency
 and because it is what is actually returned to RN

 Specification reference: https://w3c.github.io/webauthn/#dictdef-authenticationextensionslargebloboutputs
 */
internal struct AuthenticationExtensionsLargeBlobOutputsJSON: Codable {
  var supported: Bool?
  var blob: Base64URLString?
  var written: Bool?
}
