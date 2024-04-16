import Foundation
import AuthenticationServices

class PassKeyDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding  {
  private let handler: PasskeyResultHandler

  init(handler: PasskeyResultHandler) {
    self.handler = handler
  }

  // Perform the authorization request for a given ASAuthorizationController instance
  @available(iOS 15.0, *)
  func performAuthForController(controller: ASAuthorizationController) {
    controller.delegate = self;
    controller.presentationContextProvider = self;
    controller.performRequests();
  }

  @available(iOS 13.0, *)
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
  }


  @available(iOS 13.0, *)
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    handler.onFailure(error)
  }

  @available(iOS 15.0, *)
  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithAuthorization authorization: ASAuthorization) {

    switch (authorization.credential) {
      case let credential as ASAuthorizationPlatformPublicKeyCredentialRegistration:
        if credential.rawAttestationObject == nil {
          handler.onFailure((ASAuthorizationError(ASAuthorizationError.Code.failed)))
        }

        var largeBlob: AuthenticationExtensionsLargeBlobOutputsJSON?
        if #available(iOS 17.0, *) {
          largeBlob = AuthenticationExtensionsLargeBlobOutputsJSON(
            supported: credential.largeBlob?.isSupported
          )
        }

        let clientExtensionResults = AuthenticationExtensionsClientOutputsJSON(
          largeBlob: largeBlob
        )

        let response =  AuthenticatorAttestationResponseJSON(
          clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
          attestationObject: credential.rawAttestationObject!.toBase64URLEncodedString()
        )

        let registrationResult =  RegistrationResponseJSON(
          id: credential.credentialID.toBase64URLEncodedString(),
          rawId: credential.credentialID.toBase64URLEncodedString(),
          response: response,
          clientExtensionResults: clientExtensionResults
        )

        let result = PublicKeyCredentialJSONResponse.registration(registrationResult)

        handler.onSuccess(result)

      case let credential as ASAuthorizationSecurityKeyPublicKeyCredentialRegistration:
        if credential.rawAttestationObject == nil {
          handler.onFailure((ASAuthorizationError(ASAuthorizationError.Code.failed)))
        }

        let response =  AuthenticatorAttestationResponseJSON(
          clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
          attestationObject: credential.rawAttestationObject!.toBase64URLEncodedString()
        )

        let registrationResult =  RegistrationResponseJSON(
          id: credential.credentialID.toBase64URLEncodedString(),
          rawId: credential.credentialID.toBase64URLEncodedString(),
          response: response
        )

        let result = PublicKeyCredentialJSONResponse.registration(registrationResult)

        handler.onSuccess(result)

      case let credential as ASAuthorizationPlatformPublicKeyCredentialAssertion:
        var largeBlob: AuthenticationExtensionsLargeBlobOutputsJSON? = AuthenticationExtensionsLargeBlobOutputsJSON()
        if #available(iOS 17.0, *), let result = credential.largeBlob?.result {
          switch (result) {
            case .read(data: let blobData):
              largeBlob?.blob = blobData?.toBase64URLEncodedString()
            case .write(success: let successfullyWritten):
              largeBlob?.written = successfullyWritten
            @unknown default: break
          }
        }

        let clientExtensionResults = AuthenticationExtensionsClientOutputsJSON(largeBlob: largeBlob)

        let response = AuthenticatorAssertionResponseJSON(
          authenticatorData: credential.rawAuthenticatorData.toBase64URLEncodedString(),
          clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
          signature: credential.signature!.toBase64URLEncodedString(),
          userHandle: credential.userID!.toBase64URLEncodedString()
        )


        let assertionResult = AuthenticationResponseJSON(
          id: credential.credentialID.toBase64URLEncodedString(),
          rawId: credential.credentialID.toBase64URLEncodedString(),
          response: response,
          clientExtensionResults:clientExtensionResults
        )

        let result = PublicKeyCredentialJSONResponse.authentication(assertionResult)

        handler.onSuccess(result)

      case let credential as ASAuthorizationSecurityKeyPublicKeyCredentialAssertion:
        let response =  AuthenticatorAssertionResponseJSON(
          authenticatorData: credential.rawAuthenticatorData.toBase64URLEncodedString(),
          clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
          signature: credential.signature!.toBase64URLEncodedString(),
          userHandle: credential.userID!.toBase64URLEncodedString()
        )

        let assertionResult = AuthenticationResponseJSON(
          id: credential.credentialID.toBase64URLEncodedString(),
          rawId: credential.credentialID.toBase64URLEncodedString(),
          response: response
        )
        let result = PublicKeyCredentialJSONResponse.authentication(assertionResult)
        handler.onSuccess(result)
      default:
        handler.onFailure((ASAuthorizationError(ASAuthorizationError.Code.failed)))
    }
  }
}
