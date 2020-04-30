from flask import Flask
import json
import subprocess

app = Flask(__name__)

result = {}

'''
{
  “hostname”: “the machine’s host name here”,
  “ip_address”: “the machine’s IP address here”,
  “cpus”: “the number of host CPUs here”,
  “memory”: “the machine’s memory (in GBs) here”,
}
'''

def fetch(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    return (p.communicate()[0]).decode('ascii').strip()

def hostname():
    result["hostname"] = fetch("/usr/bin/hostname")

def ipaddr():
    result["ip_address"] = fetch("ip address show eth0 | grep 'inet\b' | cut -d' ' -f6")

def cpus():
    result["cpus"] = fetch("grep -c '^processor' /proc/cpuinfo")

def memory():
    result["memory"] = fetch("awk '/^MemTotal/ {print $2}' /proc/meminfo")

@app.route('/status')
def status():
    hostname()
    ipaddr()
    cpus()
    memory()
    return json.dumps(result)
