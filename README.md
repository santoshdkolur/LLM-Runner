# STEPS

Video of text generation
https://github.com/santoshdkolur/LLM-Runner/assets/48786464/cb9a881e-a9c4-4a40-9a45-b6e1e013c5f6


Things that would be covered in this guide:
1.	We will learn how to set-up an android device to run an LLM model locally.
2.	We will see how we can use my basic flutter application to interact with the LLM Model.
3.	We can also connect to a public ollama runtime which can be hosted on your very own colab notebook to try out the models.

**HOW TO SET-UP YOUR ANDROID DEVICE TO RUN AN LLM MODEL LOCALLY**
1.	We will be using the Termux application as our base. You can download the latest version of termux from here: [Termux Releases](https://github.com/termux/termux-app/releases) 
2.	Once termux is installed, let us open it up and install basic ubuntu using our guide from AnLinux application ([AnLinux App](https://play.google.com/store/apps/details?id=exa.lnx.a))
3.	You can either use the app to get the code to install ubuntu and follow the steps or follow the guide below
4.	On termux, run the following code :
```
pkg install wget openssl-tool proot -y && hash -r && wget https://raw.githubusercontent.com/EXALAB/AnLinux-Resources/master/Scripts/Installer/Ubuntu/ubuntu.sh && bash ubuntu.sh
```
5.	This should install ubuntu on your system, now to start ubuntu, type ./start-ubuntu.sh in your terminal.
6.	From here on, we can follow our normal guide to install ollama on linux. Run the below command to pull and install ollama on your device:
```
curl https://ollama.ai/install.sh | sh
```
7.	Once ollama is installed, we need to start the ollama server in the background by running the command:
```
ollama serve &
```
8.	We can see in the output that the ollama server has started running on our mobile phone. By default it will running on the endpoint “localhost:11434” of your phone. 
9.	To verify if the server is running or not, open any browser on your phone and paste the url “localhost:11434” without quotes. You must get an output which says “Ollama is running”.
10.	You can now pull any LLM that you would like to run on your phone. Please chose a model based on your phone’s configurations. For this example lets run “tinyllama:chat” model.
11.	Head on to the ollama website on your browser and click on the Models option on the top left corner. 
12.	Use the searchbar to search for tinyllama and select the option. Here under the Tags option, copy the code which is present across the “chat” option. 
13.	You can paste code on your terminal to run the model yourself and test it out. 😊

<img src="https://github.com/santoshdkolur/LLM-Runner/assets/48786464/f464bd96-eb35-4ce4-9cd3-839183492336" width="216" height="480">



**NOW LET US SEE HOW WE CAN USE THE BASIC FLUTTER APP TO INTERACT WITH THE MODEL**
1.	Please use the previous guide to set up the device upto the point where the ollama server is running on the port 11434.
2.	You can download and store as many models as you want by just copying the model links from ollama as seen previously. Replace the word ‘run’ with ‘pull’. 
 For example: If the command you copied is “ollama run tinyllama:chat”, open your terminal and run the command “ollama pull tinyllama:chat”
3.	Download my flutter application from the github repo: [LLM Runner](https://github.com/santoshdkolur/LLM-Runner/blob/main/LLM%20Runner.apk)
4.	Enter the ollama endpoint on opening the application, in this case it would be http://localhost:11434
5.	On the top right corner, you should be able to see a dropdown, here we will be able to see all the downloaded models that you currently have on ollama. You can choose the model which you would like to run. Since we just have one now, select tinyllama:chat
6.	You can type your chat at the bottom of the screen and hit send. Since the model is running locally on your mobile, the inference times will be very slow compared to say a computer. It also depends on the size of the model that you are running and the available ram in your smartphone. 
7.	You can see your chat history saved on the application sidebar and manage the sessions. You can swipe to delete the old sessions.
8.	You can even start a new session by clicking on the “+” icon on the top right corner. 

<img src="https://github.com/santoshdkolur/LLM-Runner/assets/48786464/a2ec3e0f-9760-4e5e-945b-e982b728b216" width="216" height="480">


**CONNECT TO AN OLLAMA ENDPOINT RUNNING ON COLAB**
1.	Here is the link to the colab notebook. Please save a copy onto your drive before running it. 
[Colab Notebook](https://colab.research.google.com/drive/1p5gMfgS2cr0euHy69yIMEcJPHMMirmdq?usp=sharing)
2.	Now, lets create an ngrok account. We would require this to make the ollama server endpoint accessible over the internet. 
3.	Head to [Ngrok](https://ngrok.com/) and create a free account. Once done, click on the Auth-Token option from the sidebar and copy your token. 
4.	Now, let’s go back to your colab file and paste the auth-token in the second cell of the notebook. Replace `<ngrok authtoken>` with your authtoken. 
5.	You can modify tinyllama:chat in the command “run_process(['ollama', 'pull','tinyllama:chat'])” on cell 3 with the LLM that wish to run.
6.	Once all the changes are made, make sure your runtime is set to T4 GPU on the top right corner. 
7.	Let’s run the cells one by one.
8.	When you get to the last cell, you should be able to see it generate an ngrok link in the output, let us copy that. Ex: https://9f5f-35-233-183-148.ngrok-free.app (do not end the url with ‘/’)
9.	Now, download the LLM Runner application from [LLM Runner](https://github.com/santoshdkolur/LLM-Runner/blob/main/LLM%20Runner.apk)
10.	When you open the application, it is going to ask for the Ollama endpoint url, paste the url that you copied from colab as seen above. Ex: https://9f5f-35-233-183-148.ngrok-free.app (do not end the url with ‘/’)
11.	On the top right corner, you should be able to see a dropdown, here we will be able to see all the downloaded models that you currently have on ollama. You can choose the model which you would like to run. Since we just have one now, select tinyllama:chat
12.	You can type your chat at the bottom of the screen and hit send. Since the model is running locally on your mobile, the inference times will be very slow compared to say a computer. It also depends on the size of the model that you are running and the available ram in your smartphone. 
13.	You can see your chat history saved on the application sidebar and manage the sessions. You can swipe to delete the old sessions.
14.	You can even start a new session by clicking on the “+” icon on the top right corner. 


<img src="https://github.com/santoshdkolur/LLM-Runner/assets/48786464/db13c9db-45ff-463b-91a6-34f3144e0350" width="370" height="184">
