# MATLAB Scope #

* A MATLAB library that integrates with the open source microscope operating software [Micro-manager](https://micro-manager.org/).
* Version 0.3

## Contents ##

* Setup
* Contribution guidelines
* Contacts
* Current Todo list


### How do I get set up? ###

1. Install micro-manager on the computer in a location with no spaces in the file name. Currently this code is supporting micro-manager versions 1.4.15 to 1.4.23. Roy is working on making the code compatible with v2.0.
2. Set up micro-manager for your given microscope setup: add all of the components and set up 
3. Add the java library to MATLAB's javapath. Follow the instructions on the bottom of [Micro-manager's MATLAB configuration](https://micro-manager.org/wiki/Matlab_Configuration).
4. Modify the "ScopeStartupForReference.m" to have to correct path to the installation location for micro-manager, images base path, and other components required in the file and save the file as "ScopeStartup.m".
5. Add the MATLAB scope control library to the MATLAB path. 
6. Initialize an instance of the "Scope". e.g. ``` Scp = Scope; ``` 
7. Run an imaging protocol, examples can be found in the "Utilities>ProtocolExamples" folder.



### Contribution guidelines ###

* The current code setup has been tested on Roy Wollman's scope setup and by Eric Greenwald on one of Jin Zhang's scope setups.
* Any contributions should try to maintain the current functions that are available. Changes to any main functionalities would have to be tested before being merged. 

### Who do I talk to? ###

* Roy Wollman
* Eric Greenwald

### Todo ###

* Test Scheduler compatability with real scope. (and hopefully with Wollman's setup).
* Add pause capability to scheduler.
* Look into integrating the Opentrons Liquid handler plate definitions into scope plate.
* Look into what it means to make this an actual MATLAB toolbox.
* Modify ScopeStartup.m organization so that it would be more clear what needs to be edited.
* Try to understand/get more information on the Results analysis tools that Wollman uses and has created.
* Clean up home directory of loose .m files and un-needed folders/files