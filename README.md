# EmpDataLogger

EmpDataLogger logs the result of every item upgrade you perform in the Upgrade interface. The results are put in ClientLog.txt as raw data. The included python script (EmpowermentParser.py) will extract that data from the Client Log and store it in .csv format.

I've been using this to test the critical upgrade chance to see if there's any variation, or if it's just a flat 10% (spoiler alert: it's probably just 10%). You can see the results here:
https://docs.google.com/spreadsheets/d/1-Al3wLRqpgdaN-I0jZywudRt1-eC4x59fvR2Ebv9X8o/edit?usp=sharing

Instructions: Unzip the addon file to your Flash folder (path: \Secret World Legends\Data\Gui\Custom\Flash\ ) while the game is not running. Congratulations, you should be logging!

To extract the data, you either need Python (https://www.python.org/) installed on your system, or you need to send me the ClientLog.txt file from your Secret World Legends directory (\Secret World Legends) so that I can extract it myself.

To extract yourself: 

1) Open the "EmpowermentParser.py" file in a text editor like Notepad++ (https://notepad-plus-plus.org/) 

2) Change the following lines to reflect your Secret World Legends path: 

        secretWorldPathName = "W:\\Secret World Legends\\" 
  
        outputCSVPathName = "W:\\Secret World Legends\\" 
  
3) Save the python file

4) Run the python file (if python is installed, double-clicking should work)

This will create an EmpDataLoggerDump.csv file in your SWL directory. Send that file to me.

To let me do the work: Send me your ClientLog.txt file.
