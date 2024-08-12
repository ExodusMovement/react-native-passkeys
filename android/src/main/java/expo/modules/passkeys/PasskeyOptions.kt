/**
 * navigator.credentials.get request options
 *
 * Specification reference: https://w3c.github.io/webauthn/#dictionary-assertion-options
 */
/*
class PublicKeyCredentialCreationOptions: Record {

    @Field
    var rp: PublicKeyCredentialRpEntity = PublicKeyCredentialRpEntity()

    @Field
    var user: PublicKeyCredentialUserEntity = PublicKeyCredentialUserEntity()

    @Field
    var challenge: String = ""

    @Field
    var pubKeyCredParams: List<PublicKeyCredentialParameters> = listOf()

    @Field
    var timeout: Int? = null

    @Field
    var excludeCredentials: List<PublicKeyCredentialDescriptor>? = null

    @Field
    var authenticatorSelection: AuthenticatorSelectionCriteria? = null

    @Field
    var attestation: String? = null

}

class AuthenticatorSelectionCriteria: Record {

    @Field
    var authenticatorAttachment: String? = null

    @Field
    var residentKey: String? = null

    @Field
    var requireResidentKey: Boolean? = null

    @Field
    var userVerification: String? = null
}

class PublicKeyCredentialParameters: Record {
    @Field
    var type: String = ""

    @Field
    var alg: Long = 0
}
        */

/**
 * navigator.credentials.get request options
 *
 * Specification reference: https://w3c.github.io/webauthn/#dictionary-assertion-options
 */
/*
class PublicKeyCredentialRequestOptions: Record {
    @Field
    var challenge: String = ""

    @Field
    var rpId: String = ""

    // TODO: implement the timeout
    @Field
    var timeout: Int? = null

    @Field
    var allowCredentials: List<PublicKeyCredentialParameters>? = null

    @Field
    var userVerification: String? = null
}

class PublicKeyCredentialRpEntity: Record {

    @Field
    var name: String = ""

    @Field
    var id: String? = null
}
*/

/**
 * Specification reference: https://w3c.github.io/webauthn/#dictdef-publickeycredentialuserentity
 */
/*
class PublicKeyCredentialUserEntity: Record {

    @Field
    var name: String = ""

    @Field
    var displayName: String = ""

    @Field
    var id: String = ""
}
*/

/**
 * Specification reference: https://w3c.github.io/webauthn/#dictdef-publickeycredentialdescriptor
 */
/*
class PublicKeyCredentialDescriptor: Record {

    @Field
    var id: String = ""

    @Field
    var transports: List<String>? = null

    @Field
    var type: String = "public-key"
}
*/

class RegistrationResponseJSON {
    var id: String = ""

    var rawId: String = ""

    var response: AuthenticatorAttestationResponseJSON = AuthenticatorAttestationResponseJSON()

    var authenticatorAttachment: String? = null

    var clientExtensionResults: AuthenticationExtensionsClientOutputsJSON? = null

    var type: String = "public-key"
}

/**
 * Specification reference:
 * https://w3c.github.io/webauthn/#dictdef-authenticatorattestationresponsejson
 */
class AuthenticatorAttestationResponseJSON {

    var clientDataJSON: String = ""

    // - Required in L3 but not in L2 so leaving optional as most have not adapted L3 yet
    var authenticatorData: String? = null

    // - Required in L3 but not in L2 so leaving optional as most have not adapted L3 yet
    var transports: List<String>? = null

    var publicKeyAlgorithm: Int? = null

    var publicKey: String? = null

    var attestationObject: String = ""
}

/** Specification reference: https://w3c.github.io/webauthn/#dictdef-authenticationresponsejson */
class AuthenticationResponseJSON {

    var type: String = "public-key"

    // - base64URL version of rawId
    var id: String = ""

    var rawId: String? = null

    var authenticatorAttachment: String? = null

    var response: AuthenticatorAssertionResponseJSON = AuthenticatorAssertionResponseJSON()

    var clientExtensionResults: AuthenticationExtensionsClientOutputsJSON? = null
}

class AuthenticatorAssertionResponseJSON {

    var authenticatorData: String = ""

    var clientDataJSON: String = ""

    var signature: String = ""

    var userHandle: String? = null

    var attestationObject: String? = null
}

class AuthenticationExtensionsClientOutputsJSON {

    // ? this is only available in iOS 17 but I cannot set this here
    // @available(iOS 17.0, *)
    var largeBlob: AuthenticationExtensionsLargeBlobOutputsJSON? = null
}
/**
 * We convert this to `AuthenticationExtensionsLargeBlobOutputsJSON` instead of
 * `AuthenticationExtensionsLargeBlobOutputs` for consistency and because it is what is actually
 * returned to RN
 *
 * Specification reference:
 * https://w3c.github.io/webauthn/#dictdef-authenticationextensionslargebloboutputs
 */
class AuthenticationExtensionsLargeBlobOutputsJSON {

    var supported: Boolean? = null

    var blob: String? = null

    var written: Boolean? = null
}
