import React from 'react';

import {SafeAreaView, Pressable, Text, View, StyleSheet} from 'react-native';
import * as ReactNativePasskeys from '@exodus/react-native-passkeys';

function App() {
  const register = async () => {
    console.log(4);
    try {
      const credential = await ReactNativePasskeys.create({
        /*
        challenge: 'nhkQXfE59Jb97VyyNJkvDiXucMEvltduvcrDmGrODHY',
        rp: {
          name: 'Passkey Test',
          id: 'pub-997edccf58a24892bbf821ac69d0575e.r2.dev',
        },
        user: {
          id: '2HzoHm_hY0CjuEESY9tY6-3SdjmNHOoNqaPDcZGzsr0',
          name: 'Passkey Test',
          displayName: 'Passkey Test',
        },
        pubKeyCredParams: [
          {
            type: 'public-key',
            alg: -7,
          },
          {
            type: 'public-key',
            alg: -257,
          },
        ],
        timeout: 1800000,
        attestation: 'none',
        excludeCredentials: [],
        authenticatorSelection: {
          // authenticatorAttachment: 'platform',
          // requireResidentKey: false,
          residentKey: 'required',
          // userVerification: 'required',
        },
      });
      */

        challenge: 'BGw59yIW2FjyFPwF1cPQbdu8tIYw2qlE8FWGwKLp_Fk',
        rp: {
          id: 'pub-997edccf58a24892bbf821ac69d0575e.r2.dev',
          name: 'Exodus',
        },
        user: {
          id: 'YQ==',
          name: 'Name',
          displayName: 'DisplayName',
        },
        pubKeyCredParams: [{alg: -7, type: 'public-key'}],
        // authenticatorSelection: {
        //   userVerification: 'required',
        //   residentKey: 'required',
        // },
        // extensions: {largeBlob: {support: 'required'}},
        authenticatorSelection: {
          // authenticatorAttachment: 'platform',
          residentKey: 'required',
          // requireResidentKey: true,
          // userVerification: 'preferred',
        },
      });
      console.log('credential', credential);
    } catch (err) {
      console.log(':: err', err);
      throw err;
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <Pressable onPress={register}>
        <Text>Register</Text>
      </Pressable>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default App;
