import Foundation

enum AppError: Error {
  case notSupportedException
  case notConfiguredException
  case pendingPasskeyRequestException
  case biometricException
  case userCancelledException
  case invalidChallengeException
  case missingUserIdException
  case invalidUserIdException
  case passkeyRequestFailedException(Error)
  case passkeyAuthorizationFailedException(Error)
  case genericError(String)
}

extension AppError: LocalizedError {
  var errorDescription: String? {
    switch self {
      case .notConfiguredException:
        return     "Your Apple app site association is not properly configured."
      case .notSupportedException:
        return "Passkeys are not supported on this iOS version. Please use iOS 15 or above."
      case .pendingPasskeyRequestException:
        return "There is already a pending passkey request"
      case .biometricException:
        return "Biometrics must be enabled"
      case .userCancelledException:
        return "User cancelled the passkey interaction"
      case .invalidChallengeException:
        return "The provided challenge was invalid"
      case .missingUserIdException:
        return "`userId` is required"
      case .invalidUserIdException:
        return "The provided userId was invalid"
      case .passkeyRequestFailedException(let originalError):
        return "The passkey request failed: \(originalError.localizedDescription)"
      case .passkeyAuthorizationFailedException(let originalError):
        return "The passkey authorization failed: \(originalError.localizedDescription)"
      case .genericError(let message):
        return message
    }
  }
}
