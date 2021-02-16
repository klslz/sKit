# soundcheck's tuning kit - pCP  1.0   Feb-14-2021

Copyright (c) 2021 - Klaus Schulz

Note: It's important that you make a backup. Just to be on the safe side.
Now with the new pCP backup function it should be easy.


The tuning kit (sKit) provides a small set of tools to customize and enhance
the piCorePlayer base OS. All tools are supporting RPi3, RPi4 
and related CM modules. sKit supports 32-bit and 64-bit pCP versions.

sKit-pCP is a spin-off of the "The Audio Streaming Series" 
over at https://soundcheck-audio.blogspot.com making all the proposed
measures in that series much easier to apply.


### sKit-manager

The tool installs, updates and removes the tuning kit.

Beside that it also adds some minor things 
  * a new advanced "ps" command
  * a new ps alias
to the OS




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
Audio Streaming series.




### sKit-restore.sh (Beta)

This tool restores SD-card images made with the pCP 7.01 backup function, while the
RPi is up'n running. Remember: pCP resides 100% in RAM.
The tools looks for a pcp-backup file under /tmp

Handle with care! As everything you'll find over here, you run this 100% at your own risk!







