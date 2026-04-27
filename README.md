<div align="center">
  <img width="256" height="256" alt="reflectogram" src="https://github.com/user-attachments/assets/e08e53af-f159-4a57-b0b1-3a53095a8fa1"/>
  <h1>ReflectoGram</h1>
  <p>Custom Telegram client for iOS 6+</p>
  <img src="https://img.shields.io/badge/language-swift-red"/>
  <a href="https://github.com/spytaspund/TgPrism"><img src="https://img.shields.io/badge/Based_on_-TgPrism-blue?logo=github"/></a>
  <a href="https://j-w-i.org"><img src="https://img.shields.io/badge/Thanks_to-J__W__I-purple"/></a>
</div>

### Features:
- **Security**: JSON responses encrypted with AES, media is signed with unique tokens. Read more [here](https://github.com/spytaspund/TgPrism/blob/main/README.md#features)
- **Versatility**: This client can run on **almost any** iOS, starting from iOS 6 and up to **iOS 26!**
- **Design variety**: There are different layouts and styles for different configurations (iPad, iPhone, iOS 6 or iOS7+)
- **Caching**: Almost everything here is cached. Messages, media, avatars, a lot of things!

### Screenshots:
<details>
  <summary>Click to view screenshots for iPhone and iPad</summary>
  <div align="center">
    <img src="https://github.com/user-attachments/assets/1f6eb4f7-0cbe-4117-8685-61e819ee698f" width="300"/>
    <img src="https://github.com/user-attachments/assets/bae1950e-96ac-45b6-a990-77633701ba66" width="300"/>
    <img src="https://github.com/user-attachments/assets/0f9bf1cb-b757-4970-a6d4-7ce4d55aed55" width="500"/>
  </div>
</details>

### Installation:
- Just download the latest iPA from Releases tab and install/sideload it however you want.

### Building:
- Building is a little complicated because of the custom Swift toolchain used in this project.
  TLDR: You'll need to have a Mac on either MacOS Monterey/Mojave/Big Sur and follow the [J_W_I Swift for iOS 6 installation guide](https://j-w-i.org/swiftonios6guidepart1.html).
1. As stated above, follow [this guide](https://j-w-i.org/swiftonios6guidepart1.html).
2. Clone the repository:

   `git clone https://github.com/spytaspund/ReflectoGram`
3. Run build shell file. It should create an iPA file in the specified directory:

   `./build.command ReflectoGram build`
4. Head to the [Installation](#installation) section.
