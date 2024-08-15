import React, {useState} from 'react';

import {SafeAreaView, Pressable, Text, StyleSheet} from 'react-native';
import * as ReactNativePasskeys from '@exodus/react-native-passkeys';

const RP_ID = 'pub-997edccf58a24892bbf821ac69d0575e.r2.dev';
const USER1 = {
  id: 'MQ',
  name: 'user1',
  displayName: 'User1',
};
const USER2 = {
  id: 'Mg',
  name: 'user2',
  displayName: 'User2',
};

function App() {
  const [registerCredential, setRegisterCredential] = useState<any>();

  const register = async () => {
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
        extensions: {largeBlob: {support: 'required'}},
      });
      setRegisterCredential(credential);
      console.log(':: register credential', credential);
    } catch (error) {
      console.error(error);
    }
  };

  const login = async () => {
    try {
      const credential = await ReactNativePasskeys.get({
        rpId: RP_ID,
        challenge: 'BGw59yIW2FjyFPwF1cPQbdu8tIYw2qlE8FWGwKLp_Fk',
        userVerification: 'required',
        ...(registerCredential && {
          allowCredentials: [
            {
              id: registerCredential?.id,
              type: 'public-key',
            },
          ],
        }),
      });
      console.log('login credential', credential);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <Pressable onPress={register}>
        <Text>Register</Text>
      </Pressable>
      <Pressable onPress={login}>
        <Text>Login</Text>
      </Pressable>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 20,
  },
});

export default App;
