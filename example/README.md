# Getting Started

```bash
yarn 
yarn build
```

Host an apple-app-site-association file on a server you control under `/.well-known/apple-app-site-association` and 
replace `7e0c70fee84c.ngrok.app` in this code base with your server domain. 

Example:
```json
{
  "webcredentials": {
    "apps": [ "VK5Q293EVL.org.reactjs.native.example.hello" ]
  }
}
```

```bash
cd example
cd ios && pod install && cd ..
yarn ios
```