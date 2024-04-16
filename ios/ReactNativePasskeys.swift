import Foundation
import LocalAuthentication
import AuthenticationServices


@available(iOS 15.0, *)
struct PasskeyContext {
  let passkeyDelegate: PassKeyDelegate
  struct Promise {
    let resolve: RCTPromiseResolveBlock
    let reject: RCTPromiseRejectBlock
  }

  var promise: Promise
}

func handleASAuthorizationError(error: NSError) -> Error {
  switch error.code {
    case 1001:
      return AppError.userCancelledException
    case 1004:
      return AppError.passkeyRequestFailedException(error)
    case 4004:
      return AppError.notConfiguredException
    default:
      return AppError.genericError("Unknown Exception")
  }
}


@objc(ReactNativePasskeys)
class ReactNativePasskeys: NSObject, PasskeyResultHandler {
  private var passkeyContext: PasskeyContext?

   func isSupported() -> Bool {
          if #available(iOS 15.0, *) {
              return true
          } else {
              return false
          }
      }

  private func isAvailable() throws -> Bool {
    if #unavailable(iOS 15.0) {
      throw AppError.notSupportedException
    }

    if passkeyContext != nil {
      throw AppError.pendingPasskeyRequestException
    }

    if LAContext().biometricType == .none {
      throw AppError.biometricException
    }

    return true
  }



  @objc
  func create(_ request: NSDictionary ,
              withResolver resolve: @escaping RCTPromiseResolveBlock,
              withRejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: request)

      let creationOptions = try JSONDecoder().decode(PublicKeyCredentialCreationOptions.self, from: jsonData)

      let _ = try isAvailable()

      let passkeyDelegate = PassKeyDelegate(handler: self)
      let promise = PasskeyContext.Promise(
        resolve: resolve,
        reject: reject
      )
      let context = PasskeyContext(passkeyDelegate: passkeyDelegate, promise: promise)

      guard let challengeData: Data = Data(base64URLEncoded: creationOptions.challenge) else {
        throw AppError.invalidChallengeException
      }

      guard let userId: Data = Data(base64URLEncoded: creationOptions.user.id) else {
        throw AppError.invalidUserIdException
      }

      var crossPlatformKeyRegistrationRequest: ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequest?
      var platformKeyRegistrationRequest: ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest?

      if creationOptions.authenticatorSelection?.authenticatorAttachment == AuthenticatorAttachment.crossPlatform {
        crossPlatformKeyRegistrationRequest = prepareCrossPlatformRegistrationRequest(challenge: challengeData,
                                                                                      userId: userId,
                                                                                      request: creationOptions)
      } else {
        platformKeyRegistrationRequest = preparePlatformRegistrationRequest(challenge: challengeData,
                                                                            userId: userId,
                                                                            request: creationOptions)
      }

      let authController: ASAuthorizationController;

      if platformKeyRegistrationRequest != nil {
        authController = ASAuthorizationController(authorizationRequests: [platformKeyRegistrationRequest!]);
      } else {
        authController = ASAuthorizationController(authorizationRequests: [crossPlatformKeyRegistrationRequest!])
      }

      passkeyContext = context

      context.passkeyDelegate.performAuthForController(controller: authController);

    } catch let error {
      passkeyContext = nil
      let nsError = NSError(domain: "exodus",
                            code: (error as NSError).code,
                            userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
      reject("ERROR_PROCESSING_REQUEST", nsError.localizedDescription , nsError)
    }
  }

  internal func onSuccess(_ data: PublicKeyCredentialJSONResponse) {
    switch data {
      case .registration(let registrationResult):
        if let resultDict = try? registrationResult.asDictionary() {
          passkeyContext?.promise.resolve(resultDict)
          passkeyContext = nil
        } else {
          let error = AppError.genericError("failed to serialize registration response")
          let nsError = NSError(domain: "exodus",
                                code: (error as NSError).code,
                                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
          passkeyContext?.promise.reject("ERROR_PROCESSING_REGISTRATION_RESULT",nsError.localizedDescription, nsError)
          passkeyContext = nil
        }
      case .authentication(let assertionResult):
        if let resultDict = try? assertionResult.asDictionary() {
          passkeyContext?.promise.resolve(resultDict)
          passkeyContext = nil
        } else {
          let error = AppError.genericError("failed to serialize auth response")
          let nsError = NSError(domain: "exodus",
                                code: (error as NSError).code,
                                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
          passkeyContext?.promise.reject("ERROR_PROCESSING_AUTH_RESULT",nsError.localizedDescription, nsError)
          passkeyContext = nil
        }
    }
  }

  internal func onFailure(_ error: Error) {
    guard let promise = passkeyContext?.promise else {
      NSLog("Passkey context has been lost")
      return
    }
    passkeyContext = nil
    let nsError = error as NSError
    let customError = handleASAuthorizationError(error:nsError)

    promise.reject(nsError.domain, customError.localizedDescription, customError)
  }

  @objc
  func get(_ request: NSDictionary ,
           withResolver resolve: @escaping RCTPromiseResolveBlock,
           withRejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: request)

      let requestOptions = try JSONDecoder().decode(PublicKeyCredentialRequestOptions.self, from: jsonData)
      // - all the throws are already in the helper `isAvailable` so we don't need to do anything
      // ? this seems like a code smell ... what is the best way to do this
      let _ = try isAvailable()


      let passkeyDelegate = PassKeyDelegate(handler: self)
      let promise = PasskeyContext.Promise(
        resolve: resolve,
        reject: reject
      )
      let context = PasskeyContext(passkeyDelegate: passkeyDelegate, promise: promise)

      guard let challengeData: Data = Data(base64URLEncoded: requestOptions.challenge) else {
        throw AppError.invalidChallengeException
      }

      let crossPlatformKeyAssertionRequest = prepareCrossPlatformAssertionRequest(challenge: challengeData, request: requestOptions)
      let platformKeyAssertionRequest = preparePlatformAssertionRequest(challenge: challengeData, request: requestOptions)

      let authController = ASAuthorizationController(authorizationRequests: [platformKeyAssertionRequest, crossPlatformKeyAssertionRequest])

      passkeyContext = context
      passkeyDelegate.performAuthForController(controller: authController);

    }  catch let error {
      let nsError = NSError(domain: "exodus",
                            code: (error as NSError).code,
                            userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
      reject("ERROR_PROCESSING_REQUEST", nsError.localizedDescription , nsError)
    }
  }
}

private func preparePlatformRegistrationRequest(challenge: Data,
                                                userId: Data,
                                                request: PublicKeyCredentialCreationOptions) -> ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest {
  let platformKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    relyingPartyIdentifier: request.rp.id!)

  let platformKeyRegistrationRequest =
  platformKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge,
                                                                    name: request.user.name,
                                                                    userID: userId)

  //    if let residentCredPref = request.authenticatorSelection?.residentKey {
  //        platformKeyRegistrationRequest.residentKeyPreference = residentCredPref.appleise()
  //    }

  // TODO: integrate this
  // platformKeyRegistrationRequest.shouldShowHybridTransport

  if #available(iOS 17, *) {
    switch (request.extensions?.largeBlob?.support) {
      case .preferred:
        platformKeyRegistrationRequest.largeBlob = ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput.supportPreferred
      case .required:
        platformKeyRegistrationRequest.largeBlob = ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput.supportRequired
      case .none:
        break
    }
  }

  if let userVerificationPref = request.authenticatorSelection?.userVerification {
    platformKeyRegistrationRequest.userVerificationPreference = userVerificationPref.appleise()
  }

  if let rpAttestationPref = request.attestation {
    platformKeyRegistrationRequest.attestationPreference = rpAttestationPref.appleise()
  }

  if let excludedCredentials = request.excludeCredentials {
    if !excludedCredentials.isEmpty {
      if #available(iOS 17.4, *) {
        platformKeyRegistrationRequest.excludedCredentials = excludedCredentials.map({ $0.getPlatformDescriptor() })
      }
    }
  }

  return platformKeyRegistrationRequest
}


private func prepareCrossPlatformRegistrationRequest(challenge: Data,
                                                     userId: Data,
                                                     request: PublicKeyCredentialCreationOptions) -> ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequest {

  let crossPlatformCredentialProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: request.rp.id!)


  let crossPlatformRegistrationRequest =
  crossPlatformCredentialProvider.createCredentialRegistrationRequest(challenge: challenge,
                                                                      displayName: request.user.displayName,
                                                                      name: request.user.name,
                                                                      userID: userId)

  // Set request options to the Security Key provider
  crossPlatformRegistrationRequest.credentialParameters = request.pubKeyCredParams.map({ $0.appleise() })

  if let residentCredPref = request.authenticatorSelection?.residentKey {
    crossPlatformRegistrationRequest.residentKeyPreference = residentCredPref.appleise()
  }

  if let userVerificationPref = request.authenticatorSelection?.userVerification {
    crossPlatformRegistrationRequest.userVerificationPreference = userVerificationPref.appleise()
  }

  if let rpAttestationPref = request.attestation {
    crossPlatformRegistrationRequest.attestationPreference = rpAttestationPref.appleise()
  }

  if let excludedCredentials = request.excludeCredentials {
    if !excludedCredentials.isEmpty {
      if #available(iOS 17.4, *) {
        crossPlatformRegistrationRequest.excludedCredentials = excludedCredentials.map({ $0.getCrossPlatformDescriptor() })
      }
    }
  }

  return crossPlatformRegistrationRequest

}

private func prepareCrossPlatformAssertionRequest(challenge: Data,
                                                  request: PublicKeyCredentialRequestOptions) -> ASAuthorizationSecurityKeyPublicKeyCredentialAssertionRequest {

  let crossPlatformCredentialProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(
    relyingPartyIdentifier: request.rpId)


  let crossPlatformAssertionRequest: ASAuthorizationSecurityKeyPublicKeyCredentialAssertionRequest =
  crossPlatformCredentialProvider.createCredentialAssertionRequest(challenge: challenge)

  if let allowCredentials = request.allowCredentials {
    if !allowCredentials.isEmpty {
      crossPlatformAssertionRequest.allowedCredentials =  allowCredentials.map({ $0.getCrossPlatformDescriptor() })
    }
  }

  return crossPlatformAssertionRequest
}

private func preparePlatformAssertionRequest(challenge: Data, request: PublicKeyCredentialRequestOptions) -> ASAuthorizationPlatformPublicKeyCredentialAssertionRequest {

  let platformKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
    relyingPartyIdentifier: request.rpId)


  let platformKeyAssertionRequest: ASAuthorizationPlatformPublicKeyCredentialAssertionRequest =
  platformKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)


  if #available(iOS 17, *) {
    if (request.extensions?.largeBlob?.read == true) {
      platformKeyAssertionRequest.largeBlob = ASAuthorizationPublicKeyCredentialLargeBlobAssertionInput.read
    }

    else if let blob = request.extensions?.largeBlob?.write {
      platformKeyAssertionRequest.largeBlob = ASAuthorizationPublicKeyCredentialLargeBlobAssertionInput.write(
        Data(base64URLEncoded: blob)!
      )
    }
  }

  // TODO: integrate this
  // platformKeyAssertionRequest.shouldShowHybridTransport

  if let userVerificationPref = request.userVerification {
    platformKeyAssertionRequest.userVerificationPreference = userVerificationPref.appleise()
  }


  if let allowCredentials = request.allowCredentials {
    if !allowCredentials.isEmpty {
      platformKeyAssertionRequest.allowedCredentials = allowCredentials.map({ $0.getPlatformDescriptor() })
    }
  }

  return platformKeyAssertionRequest
}
