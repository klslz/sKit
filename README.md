# soundcheck's tuning kit  (sKit)  1.6   Aug-02-2021 

TEST and Development VERSION - DON't USE IT!

Copyright (c) 2021 - Klaus Schulz


The tuning kit (sKit) provides a small set of tools to customize and enhance
the piCorePlayer base OS. The idea is to run the RPI most efficient for best
audio processing.

sKit is supporting RPi3, RPi4 and related CM modules and also 32-bit as well
as 64-bit pCP versions.

sKit-pCP is a spin-off of the "The Audio Streaming Series" 
over at my blog: https://soundcheck-audio.blogspot.com 
The idea was to make all tuning measures much easier to apply.


### sKit-manager

The tool installs, updates and removes the tuning kit.

Beside that it also adds some minor things 

  * a new advanced "ps" command
  * a new ps alias

to the OS

and also add some initial modifications


It now removes the entire sKit installation.


### sKit-custom-squeezelite.sh

This tool offers, builds and installs different customized and optimized variants of squeezelite 




### sKit-led-manager.sh

This tool disables and reenables the two RPi main LEDs (ACT and PWR) and ethernet port LEDs




### sKit-src-manager.sh

This tool allows to choose some high quality libsoxr presets, for squeezelite



### sKit-tweaks

This tool runs several pCP related efficiency tweaks. 
It'll be autostarted at system boot. It needs to be activated in the pCP-WEB-UI.



### sKit-check.sh

This tool checks the configuration state of pCP against the recommendations made in the
Audio Streaming series. That'll be the tool that's being used most!


As OPTION:


### sKit-restore.sh (Beta)

This tool restores SD-card images made with the pCP 7.0.1 backup function. And that while the
RPi is up'n running! 

Remember: pCP resides 100% in RAM.

INFO: The tools looks for a pcp-backup file under /tmp. You'd need to copy your backup image there,
before starting the restore procedure.


Handle with care! As everything you'll find over here, you run this 100% at your own risk!

The tool has actually nothing to do with the actual system modificactions. 
I simply thought it'd be a nice idea to share it. It makes my life a lot easier handling the backups.






