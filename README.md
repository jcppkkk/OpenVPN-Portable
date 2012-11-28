# Getting Started

To get openvpn working you have to create a .ovpn file and ssl-keys to ./data/config directory. 
A HowTo for this you can find on http://openvpn.net/howto.html

## Usage

All you need to do is double click OpenVPNPortable.exe to start.

If you want to connect on program startup, disable the splash or some 
settings else, copy the ./other/OpenVPNPortableSource/OpenVPNPortable.ini
to ./ and edit it to change the behaviour of OpenVPNPortable.

## Last changes

* remove completely compressed version with upx (too many false positives on virus scanners)
* cleanup repository
* update to newest stable openvpn binaries

# How to build

## Requires

* MinGW and MSYS from http://www.mingw.org/
* OpenSSL from http://www.slproweb.com/products/Win32OpenSSL.html
* UPX from http://upx.sourceforge.net/
* NSIS from http://nsis.sourceforge.net/

## Create

* Compile the openvpn-gui and copy the binary to ./app/bin/openvpn-gui.exe. 
	Refer the readme on the gui source directory for build instructions.
	Take the source from this svn repository. It's optimized for portable use.
* Compile the OpenVPNPortable.nsi and copy the binary to ./
* Execute the CreatePAF.vbs