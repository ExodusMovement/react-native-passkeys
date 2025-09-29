import type {
	AuthenticationExtensionsLargeBlobInputs,
  AuthenticationExtensionsPrfInputs,
	AuthenticationResponseJSON,
	PublicKeyCredentialCreationOptionsJSON,
	PublicKeyCredentialRequestOptionsJSON,
	RegistrationResponseJSON,
} from "./ReactNativePasskeys.types";

// Import the native module. On web, it will be resolved to ReactNativePasskeys.web.ts
// and on native platforms to ReactNativePasskeys.ts
import ReactNativePasskeysModule from "./ReactNativePasskeysModule";

export async function create(
  { signal, ...request }: Omit<PublicKeyCredentialCreationOptionsJSON, "extensions"> & {
		// - only largeBlob is supported currently on iOS
		// - no extensions are currently supported on Android
		extensions?: { largeBlob?: AuthenticationExtensionsLargeBlobInputs, prf?: AuthenticationExtensionsPrfInputs };
	} & { signal?: AbortSignal },
): Promise<RegistrationResponseJSON | null> {

  if (signal) {
    console.warn('AbortSignal is currently not supported and will be ignored.');
  }

	return processResult(await ReactNativePasskeysModule.create(request));
}

export async function get(
	request: Omit<PublicKeyCredentialRequestOptionsJSON, "extensions"> & {
		// - only largeBlob is supported currently on iOS
		// - no extensions are currently supported on Android
		extensions?: { largeBlob?: AuthenticationExtensionsLargeBlobInputs; prf?: Required<AuthenticationExtensionsPrfInputs> };
	},
): Promise<AuthenticationResponseJSON | null> {
	return processResult(await ReactNativePasskeysModule.get(request));
}

function processResult<T>(result: T) {
  // Android returns string, iOS returns object
  if (typeof result === "string") {
    return JSON.parse(result);
  }
  return result;
}
