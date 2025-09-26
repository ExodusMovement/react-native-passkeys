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
    func performAuthForController(controller: ASAuthorizationController) {
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
            let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        handler.onFailure(error)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
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
          
            var prf: AuthenticationExtensionsPRFOutputsJSON?
            if #available(iOS 18.0, *) {
              prf = credential.prf.map { it in AuthenticationExtensionsPRFOutputsJSON(
                enabled: it.isSupported,
                results: it.first.map { first in AuthenticationExtensionsPRFValuesJSON(first: first.serialize(), second: it.second.serialize()) }
              )
              }
            }
  

            let clientExtensionResults = AuthenticationExtensionsClientOutputsJSON(
                largeBlob: largeBlob,
                prf: prf
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

            handler.onSuccess(.registration(registrationResult))

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

            handler.onSuccess(.registration(registrationResult))

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
          
            var prf: AuthenticationExtensionsPRFOutputsJSON?
            if #available(iOS 18.0, *) {
              prf = credential.prf.map { AuthenticationExtensionsPRFOutputsJSON(
                  results: AuthenticationExtensionsPRFValuesJSON(first: $0.first.serialize(), second: $0.second.serialize())
                )
              }
            }

            let clientExtensionResults = AuthenticationExtensionsClientOutputsJSON(
                largeBlob: largeBlob,
                prf: prf
            )

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

            handler.onSuccess(.authentication(assertionResult))

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

            handler.onSuccess(.authentication(assertionResult))
        default:
            handler.onFailure((ASAuthorizationError(ASAuthorizationError.Code.failed)))
        }
    }
}


