import AuthenticationServices

/**
 navigator.credentials.create request options

 Specification reference: https://w3c.github.io/webauthn/#dictionary-makecredentialoptions
*/
struct PublicKeyCredentialCreationOptions: Codable {

  var rp: PublicKeyCredentialRpEntity

  var user: PublicKeyCredentialUserEntity

  var challenge: Base64URLString

  var pubKeyCredParams: [PublicKeyCredentialParameters]

  var timeout: Int?

  var excludeCredentials: [PublicKeyCredentialDescriptor]?


  var authenticatorSelection: AuthenticatorSelectionCriteria?


  var attestation: AttestationConveyancePreference?


  var extensions: AuthenticationExtensionsClientInputs?


}

/**
 navigator.credentials.get request options

 Specification reference: https://w3c.github.io/webauthn/#dictionary-assertion-options
 */
struct PublicKeyCredentialRequestOptions: Codable {
    var challenge: Base64URLString
    var rpId: String
    // TODO: implement the timeout
    var timeout: Int? = 60000
    var allowCredentials: [PublicKeyCredentialDescriptor]?
    var userVerification: UserVerificationRequirement?
    var extensions: AuthenticationExtensionsClientInputs?
}
