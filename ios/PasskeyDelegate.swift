import AuthenticationServices
// ! adapted from https://github.com/f-23/react-native-passkey/blob/fdcf7cf297debb247ada6317337767072158629c/ios/PasskeyDelegate.swift
import Foundation

class PasskeyDelegate: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private let handler: PasskeyResultHandler

    init(handler: PasskeyResultHandler) {
        self.handler = handler
    }

    // Perform the authorization request for a given ASAuthorizationController instance
    @available(iOS 15.0, *)
    func performAuthForController(controller: ASAuthorizationController) {
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
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

    @available(iOS 13.4, *)
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
      if #available(iOS 15.0, *) {
        switch authorization.credential {
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

            let response = AuthenticatorAttestationResponseJSON(
                clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
                publicKey: getPublicKey(from: credential.rawAttestationObject!)?
                    .toBase64URLEncodedString(),
                attestationObject: credential.rawAttestationObject!.toBase64URLEncodedString()
            )

            let registrationResult = RegistrationResponseJSON(
                id: credential.credentialID.toBase64URLEncodedString(),
                rawId: credential.credentialID.toBase64URLEncodedString(),
                response: response,
                clientExtensionResults: clientExtensionResults
            )

            handler.onSuccess(Either(registrationResult))

        case let credential as ASAuthorizationSecurityKeyPublicKeyCredentialRegistration:
            if credential.rawAttestationObject == nil {
                handler.onFailure((ASAuthorizationError(ASAuthorizationError.Code.failed)))
            }

            let response = AuthenticatorAttestationResponseJSON(
                clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
                publicKey: getPublicKey(from: credential.rawAttestationObject!)?
                    .toBase64URLEncodedString(),
                attestationObject: credential.rawAttestationObject!.toBase64URLEncodedString()
            )

            let registrationResult = RegistrationResponseJSON(
                id: credential.credentialID.toBase64URLEncodedString(),
                rawId: credential.credentialID.toBase64URLEncodedString(),
                response: response
            )

            handler.onSuccess(Either(registrationResult))

        case let credential as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            var largeBlob: AuthenticationExtensionsLargeBlobOutputsJSON? =
                AuthenticationExtensionsLargeBlobOutputsJSON()
            if #available(iOS 17.0, *), let result = credential.largeBlob?.result {
                switch result {
                case .read(data: let blobData):
                    largeBlob?.blob = blobData?.toBase64URLEncodedString()
                case .write(success: let successfullyWritten):
                    largeBlob?.written = successfullyWritten
                @unknown default: break
                }
            }

            let clientExtensionResults = AuthenticationExtensionsClientOutputsJSON(
                largeBlob: largeBlob)

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
                clientExtensionResults: clientExtensionResults
            )

            handler.onSuccess(Either(assertionResult))

        case let credential as ASAuthorizationSecurityKeyPublicKeyCredentialAssertion:
            let response = AuthenticatorAssertionResponseJSON(
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

            handler.onSuccess(Either(assertionResult))
        default:
            handler.onFailure((ASAuthorizationError(ASAuthorizationError.Code.failed)))
        }
      } else {
        // Fallback on earlier versions
      }
    }
}


