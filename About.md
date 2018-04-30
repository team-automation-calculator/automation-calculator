This application is about making automation decisions easier. In my life I seem to constantly be asking myself, should I automate this task that I do occasionally? 

Examples of automation decisions:

* Should I set up a build pipeline for a side project, or should I deploy it manually?
* Should I clean my floors by manually or purchase an expensive cleaning robot?
* How much time would I save if I bought and installed a dishwasher vs cleaning my dishes by hand?

Here is how one of those automation decisions would map to the models in this application.

* The deployment scenario would be an AutomationScenario. I am doing 10 deploys regardless of which method I use. Each deploy would be an iteration in the AutomationScenario. Deploying it manually would be a solution with no or little initial cost, but it would have a higher iteration cost because I have to spend time each deploy doing it manually. Another solution would be a build pipeline, which would have a higher initial cost to set up but would iteration cost to almost 0 because I would not have to spend time on each deployment with this solution. 

The graph is for visualizing the Solutions in an AutomationScenario, so users can see at what point automation pays off, and see how much they save by automating a situation that will happen an arbitrary number of times.
