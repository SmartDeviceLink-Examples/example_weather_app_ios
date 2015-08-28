# iOS Mobile Weather Tutorial

**Branch: master**  
The master branch contains the MobileWeather app without any SmartDeviceLink related code. The idea is to keep the master branch be the original app. When new features will be added to the native app they will be commited or merged into the maste branch. As for other repositories for SmartDeviceLink the model shown at http://nvie.com/posts/a-successful-git-branching-model/ is used.

**Branch: tutorial**  
The tutorial for SmartDeviceLink is always based on one commit of the master branch. Each step of the tutorial is covered by one commit of this branch. All commits of the tutorial branch are also tagged with step-x.y where “x” is the section number and “y” is the step number (e.g. step-1.1). All commits covering the last step of a section are also tagged with section-x where “x” is the section number (e.g. section-1). This way an app developer can check out each step or a whole section very easy.

*Example*  

```
o  
|\  
| o step-1.1  
| |  
| o step-1.2  
o |  
| o (tutorial) step-1.3, section-1  
o   (master)
```
   
**Tutorial update procedure**  
From time to time the tutorial will be updated either due to updates of the native app or to updates of SmartDeviceLink. This repository will be maintained by using `git rebase`. Clones of this repository may have issues to pull updates of the tutorial branch.

New steps will be added at the end of the current tutorial by adding more commits to the existing tutorial. The tags used to simplify the checkout of each step will be updated.

*Example*  

```
o  
|\  
| o step-1.1  
| |  
| o step-1.2  
o |  
| o step-1.3
o | (master)
  o (tutorial) step-1.4, section-1
```

When new code has been added to the original app in the master branch the following procedure will be performed:  

1. Checkout HEAD of the tutorial branch
2. Rebase from the desired commit of the master branch
3. When needed solve conflicts and continue rebase
4. Recreate the tags on the rebased tutorial branch (git tag –force is recommended)
5. Push the new tutorial branch with the recreated tags to origin

*Example*  

```
o  
|
o
|\
o |  (master)
  o step-1.1  
  |  
  o step-1.2  
  |  
  o step-1.3
  | 
  o (tutorial) step-1.4, section-1
```
