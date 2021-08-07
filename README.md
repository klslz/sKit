# soundcheck's tuning kit  (sKit)  1.5   Aug-07-2021

Copyright (c) 2021 - Klaus Schulz


The tuning kit (sKit) provides a small set of tools to customize and enhance
the piCorePlayer base OS. The idea is to run the RPI most efficient for best
audio processing.

sKit is supporting RPi4 and related CM modules and 32-bit as well
as 64-bit pCP versions.

sKit for pCP is a spin-off of the "The Audio Streaming Series"  over 

@ my blog: https://soundcheck-audio.blogspot.com 


The idea behind sKit was to make most of my suggested tuning measures much 
easier to apply.


### sKit-manager.sh

The tool allows to install, update and remove sKit.

The "install" function  

  * downloads the toolbox 
  * sets up the sKit file structure and environment
  * installs some pCP packages
  * changes the enviroment
  * adds some initial modifications and optimizations

The "update" function downloads and installs the updated
sKit toolbox directly from the git repositoriy.

The "removal" function removes sKit without a trace.


### sKit-custom-squeezelite.sh

This tool offers, builds and installs different customized 
and optimized variants of squeezelite based on my own 
squeezelite fork, which you can also find on this site.

It further configures squeezelite in line with my recommendations.


### sKit-led-manager.sh

This tool disables or enables

* the two RPi main LEDs (ACT and PWR) 
* and ethernet port LEDs


### sKit-src-manager.sh

This tool allows to choose some of my recommended high quality libsoxr presets, 
for squeezelite.


### sKit-tweaks

This tool applies efficiency measures during the boot process.
The first batch of measures will be applied after 20 seconds, 
the 2nd more agressive batch will be launched after 180 seconds.
The default configuration of the tool is to get autostarted 20s after system boot. 
It can easily be enabled or disabled via the pCP-WEB-UI under custom commands.


### sKit-check.sh

This tool checks the configuration state of your pCP installation against 

* sKit enabled configs and tweaks 
* and some of the recommendations made in my "Audio Streaming Series". 


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






