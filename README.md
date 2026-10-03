# Simple Server Rust

A simple guide to help you set up and manage your own small **Rust dedicated server** on Windows.

![Windows](https://img.shields.io/badge/Windows-0078D4?logo=windows\&logoColor=white)
![Status](https://img.shields.io/badge/status-active-success)

---

## 👤 For Users

### 📥 Download

You can download the latest version from the [GitHub Releases](https://github.com/ctrl-bownes/server_rust_tutorial/releases) page.

> [!IMPORTANT]
> Be sure to **extract the `.zip` file** before starting!

### ⚙️ Installation

1. Extract the downloaded `.zip`.
2. Run `setup.bat`.
3. Follow the instructions provided by the setup.

Once the setup is complete, a shortcut named:

```text
Full Guide Here - Open Me If Lost
```

will be created inside your `rust_server` folder.

> [!TIP]
> You can also open the guide manually with `guide\open_me.html`.

---

## 🔄 Automatic Updates

The package includes `setup_updater.bat`, which handles updates for the server package.

Every time you launch:

```text
start_server.bat
```

the package automatically checks GitHub for a newer version.

If an update is available, you will be asked whether you want to install it.

The updater only updates the **package files and guide**.

It does **not** modify:

```text
rust_server\server_files
start_server.bat
```

You can also run:

```text
setup_updater.bat
```

manually whenever you want to check for and install package updates.

> [!NOTE]
> Rust server updates are separate from package updates. Updating the package does not automatically update the Rust server itself.

---

## 📖 What the Guide Covers

* Installing SteamCMD
* Installing the Rust dedicated server
* Starting and connecting to the server
* Basic server commands
* Server configuration
* Server files and folders
* Installing Oxide/uMod
* Installing plugins
* Port Forwarding

---

## 💻 Requirements

* Windows
* A web browser
* Internet connection

Internet access is required to:

* Download SteamCMD
* Install Rust
* Update Rust
* Install Oxide/uMod

---

## 🛠️ For Developers

The guide is a simple **HTML/CSS/JavaScript** project.

```text
guide/
├── open_me.html
├── stylesheet.css
├── lucide.min.js  # offline lucide library
├── script.js
└── images/
```

No framework or build system is required.

You can open:

```text
guide/open_me.html
```

directly in a browser while working on the guide.

---

## 🤝 Contributing

Found an error or want to improve something?

Feel free to:

* Open an issue
* Submit a pull request
* Improve the guide
* Fix errors or outdated information

---

## ⚠️ Disclaimer

This is an independent community project.

It is **not affiliated with, endorsed by, sponsored by, or officially connected to Facepunch Studios or Rust**.

The guide does not require an account and does not collect or store personal data.

> [!NOTE]
> AI has been used in parts of this project.

