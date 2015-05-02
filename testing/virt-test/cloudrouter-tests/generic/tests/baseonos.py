# :difficulty: simple
# Put this file into the cloudrouter-tests/generic/tests directory and use
# ./run -t $type --tests="cloudrouter.baseonos" to execute it.
import logging

def run(test, params, env):
    """
    Docstring describing template.

    Detailed description of the test:

    1) Get a living VM
    2) Establish a remote session to it
    3) Run the shell commands to check basic onos functionality.

    :param test: Test object.
    :param params: Dictionary with test parameters.
    :param env: Test environment object.
    """
    vm = env.get_vm(params["main_vm"])
    vm.verify_alive()
    timeout = float(params.get("login_timeout", 240))
    session = vm.wait_for_login(timeout=timeout)
    cloudrouter = session.cmd("yum install -y onos",timeout=300)
    logging.info("Install ONOS package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q onos")
    logging.info("ONOS version: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl enable onos")
    logging.info("Enable onos service: %s", cloudrouter)
    cmd = "file -E /etc/systemd/system/multi-user.target.wants/onos.service"
    cloudrouter = session.cmd(cmd)
    logging.info("Service enabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl start onos")
    logging.info("Start onos service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof java")
    logging.info("onos is running on PID: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl disable onos")
    logging.info("Disable the onos service: %s", cloudrouter)
    cloudrouter = session.cmd(cmd,ok_status=[1])
    logging.info("Service disabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl stop onos")
    logging.info("Stopping onos service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof java",ok_status=[1])
    logging.info("onos is not running: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -e onos")
    logging.info("Removing the ONOS package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q onos",ok_status=[1])
    logging.info("ONOS rpm is removed: %s", cloudrouter)
