import React, {useState} from 'react';
import {toBase64url} from '@exodus/bytes/base64.js';

import {SafeAreaView, Pressable, Text, StyleSheet, View} from 'react-native';
import * as ReactNativePasskeys from '@passkeys/react-native-passkeys';
import type {
  AuthenticationExtensionsClientOutputsJSON,
  RegistrationResponseJSON,
} from '../src/ReactNativePasskeys.types.ts';

const RP_ID = '7e0c70fee84c.ngrok.app';
const USER1 = {
  id: 'MQ',
  name: 'user1',
  displayName: 'User1',
};

function App() {
  const [registerCredential, setRegisterCredential] =
    useState<RegistrationResponseJSON>();
  const [extensions, setExtensions] =
    useState<AuthenticationExtensionsClientOutputsJSON>();
  const [error, setError] = useState<string>();

  const register = async () => {
    setError(undefined);
    try {
      const credential = await ReactNativePasskeys.create({
        challenge: 'BGw59yIW2FjyFPwF1cPQbdu8tIYw2qlE8FWGwKLp_Fk',
        rp: {
          id: RP_ID,
          name: 'Exodus',
        },
        user: USER1,
        // user: USER2,
        pubKeyCredParams: [{alg: -7, type: 'public-key'}],
        authenticatorSelection: {
          residentKey: 'required',
        },
        extensions: {
          largeBlob: {support: 'required'},
          prf: {
            eval: {
              first: toBase64url(new TextEncoder().encode('1234567890')),
            },
          },
        },
      });
      if (!credential) {
        return;
      }

      setRegisterCredential(credential);
      setExtensions(credential?.clientExtensionResults);
    } catch (error) {
      setError(error instanceof Error ? error.message : String(error));
    }
  };

  const login = async () => {
    setError(undefined);
    try {
      const credential = await ReactNativePasskeys.get({
        rpId: RP_ID,
        challenge: 'BGw59yIW2FjyFPwF1cPQbdu8tIYw2qlE8FWGwKLp_Fk',
        userVerification: 'required',
        extensions: {
          prf: {
            eval: {
              first: toBase64url(new TextEncoder().encode('1234567890')),
            },
          },
        },
        ...(registerCredential && {
          allowCredentials: [
            {
              id: registerCredential?.id,
              type: 'public-key',
            },
          ],
        }),
      });
      setExtensions(credential?.clientExtensionResults);
    } catch (error) {
      setError(error instanceof Error ? error.message : String(error));
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Pressable onPress={register} style={styles.pressable}>
          <Text>Register</Text>
        </Pressable>
        <Pressable onPress={login} style={styles.pressable}>
          <Text>Login</Text>
        </Pressable>
      </View>

      {registerCredential && (
        <View style={styles.section}>
          <Text style={styles.h2}>Credential</Text>
          <Text>Registered as {registerCredential.id}</Text>
        </View>
      )}

      {extensions && (
        <View style={styles.section}>
          <Text style={styles.h2}>Extensions</Text>
          <Text>{JSON.stringify(extensions, null, 2)}</Text>
        </View>
      )}

      {error && <Text style={styles.error}>{error}</Text>}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    gap: 20,
    margin: 40,
  },
  pressable: {
    padding: 10,
    backgroundColor: 'rgba(113,113,113,0.17)',
    borderRadius: 5,
  },
  header: {flexDirection: 'row', columnGap: 8},
  h2: {fontSize: 20, fontWeight: '500'},
  section: {rowGap: 16},
  error: {
    color: 'red',
    fontWeight: '600',
    fontSize: 16,
    position: 'absolute',
    textAlign: 'center',
    bottom: 40,
  },
});

export default App;
