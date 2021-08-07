# soundcheck's tuning kit  (sKit)  1.4   Apr-26-2021

Copyright (c) 2021 - Klaus Schulz


The tuning kit (sKit) provides a small set of tools to customize and enhance
the piCorePlayer base OS. The idea is to run the RPI most efficient for best
audio processing.

sKit is supporting RPi4 and related CM modules and 32-bit as well
as 64-bit pCP versions.

sKit-pCP is a spin-off of the "The Audio Streaming Series"  over 

@ my blog: https://soundcheck-audio.blogspot.com 


The idea behind sKit was to make all my suggested tuning measures much 
easier to apply.


### sKit-manager

The tool allows to install, update and remove sKit.

During installation, sKit manager  

  * sets up the sKit file structure and environment
  * installs a new advanced "ps" command
  * a new ps alias
  * adds some initial modifications

The update downloads and installs the updated
git data.


The removal function should provide a pCP installation without a trace
of sKit.


### sKit-custom-squeezelite.sh

This tool offers, builds and installs different customized 
and optimized variants of squeezelite based on the squeezelite
repo you'll find on this site.
And it also configures squeezelite in line with my recommendations.


### sKit-led-manager.sh

This tool disables or enables

* the two RPi main LEDs (ACT and PWR) 
* and ethernet port LEDs


### sKit-src-manager.sh

This tool allows to choose some of my recommended high quality libsoxr presets, 
for squeezelite.


### sKit-tweaks

This tool runs activates pCP related efficiency tweaks during the boot process.
The first batch of mods will be applied after 20 seconds the 2nd more agressive
batch will be launched after 180 seconds.
The default configuration of the tool is to get autostarted at system boot. 
It can to be enabled or disabled via the pCP-WEB-UI under custom commands..


### sKit-check.sh

This tool checks the configuration state of pCP against 

* sKit enabled configs and tweaks 
* and some of the recommendations made in my Audio Streaming series blog. 


As OPTION:


### sKit-restore.sh (Beta)

This tool restores SD-card images made with the pCP 8.0.x  backup function. And that while the
RPi is up'n running! 

Remember: pCP resides 100% in RAM.

INFO: The tools looks for a pcp-backup file under /tmp. You'd need to copy your backup image there,
before starting the restore procedure.


Handle with care! As everything you'll find over here, you run this 100% at your own risk!

The tool has actually nothing to do with the actual system modificactions. 
I simply thought it'd be a nice idea to share it. It makes my life a lot easier handling the backups.






