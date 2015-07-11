# :difficulty: simple
# Put this file into the cloudrouter-tests/generic/tests directory and use
# ./run -t $type --tests="cloudrouter.basefastnetmon" to execute it.
import logging

def run(test, params, env):
    """
    Docstring describing template.

    Detailed description of the test:

    1) Get a living VM
    2) Establish a remote session to it
    3) Run the shell commands to check basic bird functionality.

    :param test: Test object.
    :param params: Dictionary with test parameters.
    :param env: Test environment object.
    """
    vm = env.get_vm(params["main_vm"])
    vm.verify_alive()
    timeout = float(params.get("login_timeout", 240))
    session = vm.wait_for_login(timeout=timeout)
    cloudrouter = session.cmd("sudo dnf install -y fastnetmon",timeout=300)
    logging.info("Install FastNetMon package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q fastnetmon")
    logging.info("FastNetMon version: %s", cloudrouter)
    cloudrouter = session.cmd("sudo file -E /etc/fastnetmon.conf")
    logging.info("FastNetMon config file exists: %s", cloudrouter)
    cloudrouter = session.cmd("sudo systemctl enable fastnetmon")
    logging.info("Enable BIRD service: %s", cloudrouter)
    cmd = "sudo file -E /etc/systemd/system/multi-user.target.wants/fastnetmon.service"
    cloudrouter = session.cmd(cmd)
    logging.info("Service enabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("sudo systemctl start fastnetmon")
    logging.info("Start FastNetMon service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof fastnetmon")
    logging.info("FastNetMon is running on PID: %s", cloudrouter)
    cloudrouter = session.cmd("sudo systemctl disable fastnetmon")
    logging.info("Disable the FastNetMon service: %s", cloudrouter)
    cloudrouter = session.cmd(cmd,ok_status=[1])
    logging.info("Service disabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("sudo systemctl stop fastnetmon")
    logging.info("Stopping FastNetMon service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof fastnetmon",ok_status=[1])
    logging.info("FastNetMon is not running: %s", cloudrouter)
    cloudrouter = session.cmd("sudo rpm -e fastnetmon")
    logging.info("Removing the FastNetMon package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q fastnetmon",ok_status=[1])
    logging.info("FastNetMon rpm is removed: %s", cloudrouter)
