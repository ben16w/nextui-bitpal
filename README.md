# NextUI BitPal

A NextUI port of the BitPal gaming companion from PakUI that offers missions and tracks progress for your game library.

## Description

A port of BitPal from [PakUI](https://github.com/tenlevels/PakUI) to [NextUI](https://github.com/LoveRetro/NextUI). BitPal, created by [tenlevels](https://github.com/tenlevels), is a friendly gaming companion that offers missions and tracks your progress as you play through your game library.

This pak packages BitPal as a standalone Tool pak for TrimUI devices running NextUI. At build time, the original BitPal from PakUI is downloaded, and a small set of patches are applied so it works cleanly on NextUI devices.

## Supported Platforms

This pak is designed and tested for:

- `tg5040`: Trimui Brick (formerly `tg3040`), Trimui Smart Pro

> Important: NextUI only. `tg5040` is the sole supported platform.

## Disclaimer

This project bundles a patched copy of BitPal from PakUI and is not officially supported by the PakUI maintainers. Please do not file issues related to this pak with PakUI.

## Installation

1. Mount your MinUI SD card to your computer.
2. Download the latest [release](https://github.com/ben16w/nextui-bitpal/releases) from GitHub.
3. Copy the zip file to the correct platform folder in the "/Tools" folder on the SD card. Please ensure the new zip file name is `BitPal.pak.zip`.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/<PLATFORM>/BitPal.pak/launch.sh` file on your SD card.
6. Eject your SD card and insert it back into your MinUI device.

Note: The `<PLATFORM>` folder name is based on the name of your device. For example, if you are using a TrimUI Brick, the folder is `tg5040`.

## Usage

- From NextUI, open **Tools** and select **BitPal** to launch.
- Follow on-screen prompts to view missions, track sessions, and explore recommendations.

## Troubleshooting

- Logs are written to your device’s userdata logs folder as `BitPal.txt` (e.g., `/.userdata/tg5040/logs/BitPal.txt`).
- Create an empty `debug` file in `/.userdata/<PLATFORM>/BitPal` to enable verbose logging.
- If you encounter problems or bugs, please [open an issue](https://github.com/ben16w/nextui-bitpal/issues/new) in this GitHub repository with details and a copy of the log file.
- For general support or questions you can join the [NextUI Discord](https://discord.gg/HKd7wqZk3h) and go to the **BitPal** channel.

## Development

- A Linux/macOS host is required with `curl`, `jq`, `zip`, `unzip`, `diff`, and `make`.
- The original BitPal content is copied from the PakUI release at build time into the local `BitPal` folder.
- Local changes are maintained as `.patch` files in the [patches](patches) directory.
- The [bpgtt](bin/bpgtt) script is used to update BitPal data files.

```bash
# Clean any prior build artifacts
make clean

# Download PakUI BitPal, fetch runtime binaries, and vendor into ./BitPal
make build

# Apply local patches from ./patches to files inside ./BitPal
make apply-patches

# After editing files in ./BitPal, generate/refresh patches into ./patches
make save-patches

# Create a distributable archive at ./dist/BitPal.pak.zip
make release
```

## Known Issues

- If a game is started outside BitPal it currently won't be tracked. This should be fixed in a future release.

## Thanks

- [tenlevels](https://github.com/tenlevels) and the PakUI team for creating BitPal and PakUI.
- [frysee](https://github.com/frysee), [ro8inmorgan](https://github.com/ro8inmorgan) and the rest of the NextUI contributors for developing [NextUI](https://github.com/LoveRetro/NextUI).
- [josegonzalez](https://github.com/josegonzalez), for pak repositories and tools, which this project uses.
- [Pobega](https://github.com/Pobega) for [minui-bash](https://github.com/pobega/minui-bash).

## License

PakUI and BitPal are licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/). See the original PakUI [LICENSE](https://raw.githubusercontent.com/tenlevels/PakUI/refs/heads/main/LICENSE.txt) file for more details.

Bundled third-party binaries in [bin](bin) are licensed by their respective projects and distributed according to those licenses.

The NextUI BitPal project code is licensed under the [MIT License](https://opensource.org/licenses/MIT). See the project [LICENSE](LICENSE) file for more details.
