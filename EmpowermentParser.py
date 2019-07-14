import sys
import os.path
import datetime

def Main(argv=None):
    if argv is None:
        argv = sys.argv
	secretWorldPathName = "W:\\Secret World Legends\\"
	outputCSVPathName = "W:\\Secret World Legends\\"
    try:
        lines = []
        with open(secretWorldPathName + 'ClientLog.txt', 'r') as logFile:
            newLines = [line.split(' - ', 1)[1] for line in logFile if '.EmpDataLoggerDump' in line]
            lines.extend(newLines)
            logFile.close()
            now = datetime.datetime.now()
            os.rename(secretWorldPathName + '\ClientLog.txt', secretWorldPathName + '\ClientLog ' + now.strftime("%Y-%m-%d %H-%M-%S") + '.txt')
        with open(outputCSVPathName + 'EmpDataLoggerDump.csv', 'a+') as outFile:
            outFile.writelines(lines)
    except Exception as e:
        print(e)
        return 1

if __name__ == '__main__':
	sys.exit(Main())