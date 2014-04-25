
# Getting Started
To get openvpn working, you have to create a .ovpn file and ssl-keys and place it on ./data/config. A HowTo for this you can find on [openvn.net](http://openvpn.net/howto.html)

## Installation
Download and start OpenVPNPortable_x.x.x.paf.exe. It doesn't install anything on your system. It just downloads and extracts the needed files to the directory of your choice.

To avoid downloading files during the "unzip process", you have to do this before you start the OpenVPNPortable_x.x.x.paf.exe:

1. Download the binary package and the current.txt from [here](http://sourceforge.net/projects/ovpnp/files/binpack/)
2. Place all the files in one single directory
3. Start the OpenVPNPortable_x.x.x.paf.exe in the console and add `/BINPACKURL=.` as parameter.
 
 
## Update
Just start OpenVPNPortable_x.x.x.paf.exe again and point it to the directory you already have OpenVPN Portable installed. It checks your version with the one on [sourceforge.net](http://sourceforge.net/projects/ovpnp/files/binpack/) and updates if needed.

## Usage
All you need to do is double click OpenVPNPortable.exe to start.

If you want to connect on program startup, disable the splash or some settings else, edit OpenVPNPortable.ini to change the behaviour of OpenVPN Portable.

## Last changes (1.8.2)
* Command line option to overwrite default URL for downloading openvpn binaries
* Fix driver install on 64-bit Systems
 
 
# How to build
## Requires
* MinGW and MSYS from [mingw.org](http://www.mingw.org/)
* OpenSSL from [http://www.slproweb.com/products/Win32OpenSSL.html](http://www.slproweb.com/products/Win32OpenSSL.html)
* NSIS from [sourceforge.net](http://nsis.sourceforge.net/)
 
 
### NSIS plugins
NSIS needs some plugins. You can find it on [Plugins-Site](http://nsis.sourceforge.net/Category:Plugins)

* [Inetc](http://nsis.sourceforge.net/Inetc_plug-in)
* [NotifyIcon](http://nsis.sourceforge.net/NotifyIcon_plug-in)
* [nsUnzip](http://nsis.sourceforge.net/NsUnzip_plugin)
* [FindProcDLL](http://nsis.sourceforge.net/FindProcDLL_plug-in)
* [InstDrv](http://nsis.sourceforge.net/InstDrv_plug-in)
* [ExecDos](http://nsis.sourceforge.net/ExecDos_plug-in)
* [NewAdvSplash](http://nsis.sourceforge.net/NewAdvSplash_plug-in)
* [UserMgr](http://nsis.sourceforge.net/UserMgr_plug-in)
* [UAC](http://nsis.sourceforge.net/UAC_plug-in)
* [Nsisunz](http://nsis.sourceforge.net/Nsisunz_plug-in)
 
 
## Create
* Compile the openvpn-gui and copy the binary to ./app/bin/openvpn-gui.exe. 
	Refer the readme on the gui source directory for build instructions.
	Take the source from this svn repository. It's optimized for portable use.
* Execute the CreatePAF.vbs
