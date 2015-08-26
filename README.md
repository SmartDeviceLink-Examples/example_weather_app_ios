# iOS Mobile Weather Tutorial
**Branch: master**
The master branch contains the MobileWeather app without any SDL related code. The idea is to keep the master branch be the original app. When new features will be added to the native app they should be commited or merged into the maste branch. As for other repositories we can follow the original branching model shown at http://nvie.com/posts/a-successful-git-branching-model/.

**Branch: tutorial-{version} (e.g. tutorial-2.0)**
The actual tutorial for SDL is always based on one commit of the master branch. Each step of the tutorial is covered by one commit of this branch. All commits of the latest tutorial branch (currently tutorial-2.0) are also tagged with step-x.y where “x” is the section number and “y” is the step number (e.g. step-1.1). All commits covering the last step of a section are also tagged with section-x where “x” is the section number (e.g. section-1). This way an app developer can check out each step or a whole section very easy.

*Example*  
&nbsp;&nbsp;&nbsp;o  
&nbsp;&nbsp;&nbsp;|\  
&nbsp;&nbsp;&nbsp;|&nbsp;\  
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;o step-1.1  
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;|  
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;o step-1.2  
&nbsp;&nbsp;&nbsp;o&nbsp;&nbsp;|  
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;o (tutorial-2.0) step-1.3, section-1  
&nbsp;&nbsp;&nbsp;o
   
**Append more steps at the end of the current step**  
New steps can be easily added at the end of the current tutorial by adding more commits to the existing tutorial.

**Update tutorial when master branch has changed**  
When new code has been added to the original app in the master branch you need to do the following steps:  
1.  Create a new tutorial branch based on the desired commit of the master branch
2.	Name the new tutorial branch based on the latest tutorial version (e.g. tutorial-2.0.1 or tutorial-2.1
3.	Cherry pick each commit from the previous tutorial branch
4.	When needed solve conflicts before commiting the cherry pick
5.	Recreate the tags on the new commits (git tag –force  is recommended)
6.	Push the new tutorial branch with the recreated tags to origin


*Example*  
o   
|\    
|&nbsp;\   
|&nbsp;&nbsp;&nbsp;o   
|&nbsp;&nbsp;&nbsp;|  
|&nbsp;&nbsp;&nbsp;o   
o&nbsp;&nbsp;|   
|&nbsp;&nbsp;&nbsp;o (tutorial-2.0)   
o   
&nbsp;\  
&nbsp;&nbsp;\  
&nbsp;&nbsp;&nbsp;o step-1.1  
&nbsp;&nbsp;&nbsp;|  
&nbsp;&nbsp;&nbsp;o step-1.2  
&nbsp;&nbsp;&nbsp;|  
&nbsp;&nbsp;&nbsp;o (tutorial-2.1) step-1.3, section-1


**Modify an existing step or add a step in the middle of the tutorial**  
To modify or to add new steps in the middle of the tutorial you need to do the following steps:  
1.	Create a new tutorial branch based on the previous commit of the latest tutorial branch where a new step has to be added or the next step has to be modified
2.	Name the new tutorial branch based on the latest tutorial version (e.g. tutorial-2.1)
3.	When adding a new step: Implement and commit the new step into the new tutorial branch 
4.	When modifying a step: Implement the changes and do an ammended commit
5.	Cherry pick each commit from the previous branch to cover all following steps
6.	When needed solve conflicts before commiting the cherry pick
7.	Recreate the tags on the new commits (git tag –force  is recommended)
8.	Push the new tutorial branch with the recreated tags to origin

*Example*  
&nbsp;&nbsp;&nbsp;o  
&nbsp;&nbsp;&nbsp;|\  
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;\  
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;o step-1.1  
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;|  
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;o step-1.2  
&nbsp;&nbsp;&nbsp;o&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;\  
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;o&nbsp;&nbsp;&nbsp;\  
&nbsp;&nbsp;&nbsp;o&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;o &nbsp;step-1.3  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;o (tutorial-2.1) step-1.4, section-1  
