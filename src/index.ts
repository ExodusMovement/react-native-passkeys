import type {
	AuthenticationExtensionsLargeBlobInputs,
	AuthenticationResponseJSON,
	PublicKeyCredentialCreationOptionsJSON,
	PublicKeyCredentialRequestOptionsJSON,
	RegistrationResponseJSON,
} from './ReactNativePasskeys.types'

import ReactNativePasskeysModule from './ReactNativePasskeysModule'

export function isSupported(): boolean {
	return ReactNativePasskeysModule.isSupported()
}

export async function create(
	request: Omit<PublicKeyCredentialCreationOptionsJSON, 'extensions'> & {
		// - only largeBlob is supported currently on iOS
		// - no extensions are currently supported on Android
		extensions?: { largeBlob?: AuthenticationExtensionsLargeBlobInputs }
	},
): Promise<RegistrationResponseJSON | null> {
	return await ReactNativePasskeysModule.create(request)
}

export async function get(
	request: Omit<PublicKeyCredentialRequestOptionsJSON, 'extensions'> & {
		// - only largeBlob is supported currently on iOS
		// - no extensions are currently supported on Android
		extensions?: { largeBlob?: AuthenticationExtensionsLargeBlobInputs }
	},
): Promise<AuthenticationResponseJSON | null> {
	return ReactNativePasskeysModule.get(request)
}
