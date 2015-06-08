#!/usr/bin/python

import os
import logging
import logging.handlers
import time
import re
import subprocess
import trparse
import argparse

class CheckRoute:
    def __init__(self):
        self.e_hops = []
        self.e_num_hops = 0
        self.traceroute = None
        self.testpassed=False

    def load(self, e_hops, output):
        self.e_hops=e_hops
        self.e_num_hops = len(e_hops)
        self.traceroute = trparse.loads(output)
        self.vroute()

    def clear(self):
        self.e_hops = []
        self.e_num_hops = 0
        self.traceroute = None
        self.testpassed = False

    def vroute(self):
        for x in xrange(0, self.e_num_hops):
            if self.traceroute.hops[x].probes[0].ip == self.e_hops[x]:
                self.testpassed=True
            else:
                self.testpassed=False

    def passed(self):
        if self.testpassed is True:
            self.clear()
            return True
        else:
            self.clear()
            return False

class RunCore:
    def __init__(self, imn_file):
        self.imn_file = imn_file
        self.sessionid = 0
        self.start_coregui(self.imn_file)

    def start_coregui(self, imn_file):
        output = subprocess.check_output(["core-gui", "--batch", imn_file])
        matchObj = re.search( r'.*Session id is ([\d]+)', output, re.MULTILINE)
        if matchObj:
            print "CORE started at session: ", matchObj.group(1)
            self.sessionid = matchObj.group(1)
        else:
            print "Could not find CORE session!!"
            exit(1)

    def stop_coregui(self):
        output = subprocess.check_output(["core-gui", "--closebatch", self.sessionid])
        print "shutting down CORE session %s" % self.sessionid

    def node_cmd(self, node, cmd):
        ccname = "/tmp/pycore." + self.sessionid + "/" + node
        vcmd = ["vcmd", "-I", "-c", ccname, "--"]
        fullcmd = vcmd + cmd
        output = subprocess.check_output(fullcmd)
        return output
    
    def runtraceroute(self, node, ip):
        corecmd = ["traceroute", "-w", "2", ip]
        cmdoutput = self.node_cmd(node, corecmd)
        match = re.search(r'([1-9]+)  ([*]+ [*]+ [*]+)', cmdoutput)
        if match is None:
            return cmdoutput
        count=1
        while match is not None:
            print "rerun traceroute %s" % count
            cmdoutput = self.node_cmd(node, corecmd)
            match = re.search(r'([1-9]+)  ([*]+ [*]+ [*]+)', cmdoutput)
            if match is None:
                return cmdoutput
            count += 1
            if count > 10:
                print "Max traceroute reruns"
                return cmdoutput

class TestLogger:
    def __init__(self,debug=False):
        self.testresults = []
        self.testdesc = []
        self.allpass = True
        self.debug=debug
        self.logger = logging.getLogger('MyLogger')
        self.logger.setLevel(logging.INFO)
        self.loghandler = logging.FileHandler('/tmp/coretest.log',mode='w')
        self.loghandler.setLevel(logging.INFO)
        self.logger.addHandler(self.loghandler)

        if self.debug is True:
            self.console = logging.StreamHandler()
            self.console.setLevel(logging.DEBUG)
            self.logger.addHandler(self.console)


    def writelog(self,message):
        if self.debug is True:
            self.logger.debug(message)
            self.logger.info(message)
        else:
            self.logger.info(message)

    def consoleresult(self,desc, result,output):
        self.testresults.append(result)
        if result == False:
            self.allpass = False
        self.testdesc.append(desc)
        consoleoutput = "Test: %s" % desc
        if result == True:
             consoleoutput += "\nStatus: Pass"
        else:
            consoleoutput += "\nStatus: Fail"
        self.writelog(consoleoutput)
        self.writelog(output)
        print consoleoutput

    def summery(self):
        consoleoutput = """
        ===========================
        |      Test Summery       |
        ===========================\n"""

        for x in xrange(0, len(self.testresults)):
            test = int(x) + 1
            if self.testresults[x] == True:
                consoleoutput += "\nTest %s: Passed" % test
            else:
                consoleoutput += "\nTest %s: Failed" % test
        if self.allpass == True:
            consoleoutput +=  "\nAll tests PASSED"
        else:
            consoleoutput += "\nSome tests FAILED"
        print consoleoutput

    def returncode(self):
        if self.allpass == True:
            return 0
        else:
            return 1

def runtest(imn_file,debug):
    testlogger = TestLogger(debug=debug)
    mycore =  RunCore(imn_file)
    routecheck = CheckRoute()

    #allow OSPF data to propagate
    print "90s sleep"
    time.sleep(90)

    corecmd = ["birdc", "show", "route"]
    cmdoutput = mycore.node_cmd("n2", corecmd)
    testlogger.writelog(cmdoutput)

    cmdoutput = mycore.runtraceroute("n2","10.0.2.10")
    expected_route = ["10.0.0.3","10.0.2.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n2 to n18",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n2","10.0.3.10")
    expected_route = ["10.0.0.4","10.0.3.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n2 to n19",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n2","10.0.4.10")
    expected_route = ["10.0.0.5","10.0.4.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n2 to n20",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n2","10.0.17.10")
    expected_route = ["10.0.10.1","10.0.5.1","10.0.16.2","10.0.18.2","10.0.17.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n2 to n25",routecheck.passed(),cmdoutput)

    corecmd = ["birdc", "show", "route"]
    cmdoutput = mycore.node_cmd("n3", corecmd)
    testlogger.writelog(cmdoutput)

    cmdoutput = mycore.runtraceroute("n3","10.0.1.10")
    expected_route = ["10.0.0.2","10.0.1.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n3 to n17",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n3","10.0.3.10")
    expected_route = ["10.0.0.4","10.0.3.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n3 to n19",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n3","10.0.4.10")
    expected_route = ["10.0.0.5","10.0.4.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n3 to n20",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n3","10.0.17.10")
    expected_route = ["10.0.13.1","10.0.6.1","10.0.16.2","10.0.18.2","10.0.17.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n3 to n25",routecheck.passed(),cmdoutput)

    corecmd = ["birdc", "show", "route"]
    cmdoutput = mycore.node_cmd("n4", corecmd)
    testlogger.writelog(cmdoutput)

    cmdoutput = mycore.runtraceroute("n4","10.0.1.10")
    expected_route = ["10.0.0.2","10.0.1.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n4 to n17",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n4","10.0.2.10")
    expected_route = ["10.0.0.3","10.0.2.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n4 to n18",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n4","10.0.4.10")
    expected_route = ["10.0.0.5","10.0.4.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n4 to n20",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n4","10.0.17.10")
    expected_route = ["10.0.14.1","10.0.12.1","10.0.16.2","10.0.18.2","10.0.17.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n4 to n25",routecheck.passed(),cmdoutput)

    corecmd = ["birdc", "show", "route"]
    cmdoutput = mycore.node_cmd("n5", corecmd)
    testlogger.writelog(cmdoutput)

    cmdoutput = mycore.runtraceroute("n5","10.0.1.10")
    expected_route = ["10.0.0.2","10.0.1.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n5 to n17",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n5","10.0.2.10")
    expected_route = ["10.0.0.3","10.0.2.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n5 to n18",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n5","10.0.3.10")
    expected_route = ["10.0.0.4","10.0.3.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n5 to n19",routecheck.passed(),cmdoutput)

    cmdoutput = mycore.runtraceroute("n5","10.0.17.10")
    expected_route = ["10.0.15.1","10.0.9.1","10.0.16.2","10.0.18.2","10.0.17.10"]
    routecheck.load(expected_route,cmdoutput)
    testlogger.consoleresult("traceroute from n5 to n25",routecheck.passed(),cmdoutput)


    mycore.stop_coregui()
    testlogger.summery()
    return testlogger.returncode()

def main():
    parser = argparse.ArgumentParser(description='This automation will ')
    parser.add_argument('--debug', action='count', help='Prints additional command output to screen')
    parser.add_argument('--file', help='imn file for core to use')
    args = parser.parse_args()
    if args.debug == 1:
        debug=True
    else:
        debug=False
    if args.file is set:
        imn_file=args.file
        if not os.path.isfile(imn_file):
            print "File does not exist"
    else:
        imn_file = "/home/cloudrouter/cloudrouter/testing/core/peering-test1/peering-test1-allinoneconfig.imn"

    runtest(imn_file,debug)

if __name__ == "__main__":
    main()
