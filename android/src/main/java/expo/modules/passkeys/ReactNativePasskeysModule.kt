package expo.modules.passkeys

import AuthenticationResponseJSON
import RegistrationResponseJSON
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.CreateCredentialInterruptedException
import androidx.credentials.exceptions.CreateCredentialProviderConfigurationException
import androidx.credentials.exceptions.CreateCredentialUnknownException
import androidx.credentials.exceptions.CreateCredentialUnsupportedException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.GetCredentialInterruptedException
import androidx.credentials.exceptions.GetCredentialProviderConfigurationException
import androidx.credentials.exceptions.GetCredentialUnknownException
import androidx.credentials.exceptions.GetCredentialUnsupportedException
import androidx.credentials.exceptions.NoCredentialException
import androidx.credentials.exceptions.publickeycredential.CreatePublicKeyCredentialDomException
import androidx.credentials.exceptions.publickeycredential.GetPublicKeyCredentialDomException
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ReactNativePasskeysModule internal constructor(private val context: ReactApplicationContext) :
        ReactContextBaseJavaModule(context) {

  private val mainScope = CoroutineScope(Dispatchers.Default)

  companion object {
    const val NAME = "ReactNativePasskeys"
  }

  override fun getName(): String {
    return NAME
  }

  @ReactMethod(isBlockingSynchronousMethod = true)
  fun isSupported(): Boolean {
    val minApiLevelPasskeys = 28
    val currentApiLevel = android.os.Build.VERSION.SDK_INT
    return currentApiLevel >= minApiLevelPasskeys
  }

  @ReactMethod(isBlockingSynchronousMethod = true)
  fun isAutoFillAvailable(): Boolean {
    return false
  }

  @ReactMethod
  fun create(request: ReadableMap, promise: Promise) {
    val credentialManager = CredentialManager.create(context.applicationContext!!)
    val json = Gson().toJson(request.toHashMap())
    val createPublicKeyCredentialRequest = CreatePublicKeyCredentialRequest(json)

    mainScope.launch {
      try {
        val result =
                currentActivity?.let {
                  credentialManager.createCredential(it, createPublicKeyCredentialRequest)
                }
        val response =
                result?.data?.getString(
                        "androidx.credentials.BUNDLE_KEY_REGISTRATION_RESPONSE_JSON"
                )
        val createCredentialResponse =
                Gson().fromJson(response, RegistrationResponseJSON::class.java)
        promise.resolve(createCredentialResponse)
      } catch (e: CreateCredentialException) {
        promise.reject("Passkey Create", getRegistrationException(e), e)
      }
    }
  }

  @ReactMethod
  fun get(request: ReadableMap, promise: Promise) {
    val credentialManager = CredentialManager.create(context.applicationContext!!)
    val json = Gson().toJson(request.toHashMap())
    val getCredentialRequest = GetCredentialRequest(listOf(GetPublicKeyCredentialOption(json)))

    mainScope.launch {
      try {
        val result =
                currentActivity?.let { credentialManager.getCredential(it, getCredentialRequest) }
        val response =
                result?.credential?.data?.getString(
                        "androidx.credentials.BUNDLE_KEY_AUTHENTICATION_RESPONSE_JSON"
                )
        val createCredentialResponse =
                Gson().fromJson(response, AuthenticationResponseJSON::class.java)
        promise.resolve(createCredentialResponse)
      } catch (e: GetCredentialException) {
        promise.reject("Passkey Get", getAuthenticationException(e), e)
      }
    }
  }

  private fun getRegistrationException(e: CreateCredentialException): String {
    when (e) {
      is CreatePublicKeyCredentialDomException -> {
        return "DomError: ${e.domError.toString()}"
      }
      is CreateCredentialCancellationException -> {
        return "UserCancelled: ${e.errorMessage.toString()}"
      }
      is CreateCredentialInterruptedException -> {
        return "Interrupted: ${e.errorMessage.toString()}"
      }
      is CreateCredentialProviderConfigurationException -> {
        return "NotConfigured: ${e.errorMessage.toString()}"
      }
      is CreateCredentialUnknownException -> {
        return "UnknownError: ${e.errorMessage.toString()}"
      }
      is CreateCredentialUnsupportedException -> {
        return "NotSupported: ${e.errorMessage.toString()}"
      }
      else -> {
        return "UnhandledError: ${e.errorMessage.toString()}"
      }
    }
  }

  private fun getAuthenticationException(e: GetCredentialException) =
          when (e) {
            is GetPublicKeyCredentialDomException -> {
              e.domError.toString()
            }
            is GetCredentialCancellationException -> {
              "UserCancelled"
            }
            is GetCredentialInterruptedException -> {
              "Interrupted"
            }
            is GetCredentialProviderConfigurationException -> {
              "NotConfigured"
            }
            is GetCredentialUnknownException -> {
              "UnknownError"
            }
            is GetCredentialUnsupportedException -> {
              "NotSupported"
            }
            is NoCredentialException -> {
              "NoCredentials"
            }
            else -> {
              e.toString()
            }
          }
}
