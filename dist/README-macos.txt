DhikrAtWork v{{VERSION}} — Islamic dhikr tracking desktop app for macOS.

INSTALLATION
============

1. Open the downloaded zip file — DhikrAtWork-v{{VERSION}}-macos-arm64.zip.
2. Drag DhikrAtWork.app into your Applications folder.
3. First launch: RIGHT-CLICK DhikrAtWork.app → Open (do NOT double-click).
4. A dialog will appear saying the app is from an unidentified developer.
   Click "Open" to confirm. This happens once only.
5. On subsequent launches, double-click the app as normal.

SECURITY NOTICE
===============

macOS Gatekeeper may warn that DhikrAtWork is from an unidentified developer.
This is expected. DhikrAtWork is free, open-source software distributed without
a paid Apple Developer certificate. The app is safe to use.

You can verify this yourself:
  - Check the SHA256 checksum in DhikrAtWork-v{{VERSION}}-macos-arm64.zip.sha256
    (attached to the GitHub Release) matches your downloaded file.
  - Scan the file at https://www.virustotal.com (see GitHub Release notes for link).
  - Review the source code at https://github.com/thecodeartificerX/dhikratwork

VERIFICATION
============

The SHA256 checksum for this zip is in the separate .sha256 file attached to
the GitHub Release alongside this zip.

To verify on macOS, open Terminal and run:
  shasum -a 256 DhikrAtWork-v{{VERSION}}-macos-arm64.zip

Compare the output to the hash in DhikrAtWork-v{{VERSION}}-macos-arm64.zip.sha256.
