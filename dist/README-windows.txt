DhikrAtWork v{{VERSION}} - Windows Installation
================================================

DhikrAtWork is an Islamic dhikr tracking desktop app for Windows and macOS.


INSTALLATION

1. Extract this zip to a folder (all files must stay together).
2. Right-click Install.bat and choose "Run as administrator".
3. Click Yes on the UAC prompt to allow administrator access.
4. The installer imports the certificate and installs the app automatically.
5. Find DhikrAtWork in your Start Menu once installation completes.


SECURITY NOTICE

Windows may warn that this software is not signed with a paid certificate.
DhikrAtWork is free open-source software. The self-signed certificate
(DhikrAtWork.cer) is included and imported by Install.bat automatically.

You can verify safety by:
  - Checking the SHA256 checksum in DhikrAtWork-v{{VERSION}}-windows-x64.zip.sha256
    (attached to the GitHub Release) against your downloaded file
  - Scanning the zip on VirusTotal (link in the GitHub Release notes)
  - Reviewing the source code: https://github.com/thecodeartificerX/dhikratwork


SHA256 VERIFICATION

The SHA256 checksum for this zip is in the separate .sha256 file attached to
the GitHub Release alongside this zip.

To verify (run in Command Prompt or PowerShell):
  certutil -hashfile DhikrAtWork-v{{VERSION}}-windows-x64.zip SHA256

Compare the output to the hash in DhikrAtWork-v{{VERSION}}-windows-x64.zip.sha256.
