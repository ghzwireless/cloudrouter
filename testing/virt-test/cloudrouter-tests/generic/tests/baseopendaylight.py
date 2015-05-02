# :difficulty: simple
# Put this file into the cloudrouter-tests/generic/tests directory and use
# ./run -t $type --tests="cloudrouter.baseopendaylight" to execute it.
import logging

def run(test, params, env):
    """
    Docstring describing template.

    Detailed description of the test:

    1) Get a living VM
    2) Establish a remote session to it
    3) Run the shell commands to check basic opendaylight functionality.

    :param test: Test object.
    :param params: Dictionary with test parameters.
    :param env: Test environment object.
    """
    vm = env.get_vm(params["main_vm"])
    vm.verify_alive()
    timeout = float(params.get("login_timeout", 240))
    session = vm.wait_for_login(timeout=timeout)
    cloudrouter = session.cmd("yum install -y opendaylight-helium",timeout=300)
    logging.info("Install OpenDaylight package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q opendaylight-helium")
    logging.info("OpenDaylight version: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl enable opendaylight-helium")
    logging.info("Enable opendaylight-helium service: %s", cloudrouter)
    cmd = "file -E /etc/systemd/system/multi-user.target.wants/opendaylight-helium.service"
    cloudrouter = session.cmd(cmd)
    logging.info("Service enabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl start opendaylight-helium")
    logging.info("Start opendaylight service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof java")
    logging.info("opendaylight is running on PID: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl disable opendaylight-helium")
    logging.info("Disable the opendaylight-helium service: %s", cloudrouter)
    cloudrouter = session.cmd(cmd,ok_status=[1])
    logging.info("Service disabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl stop opendaylight-helium")
    logging.info("Stopping opendaylight-helium service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof java",ok_status=[1])
    logging.info("opendaylight is not running: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -e opendaylight-helium")
    logging.info("Removing the OpenDaylight package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q opendaylight-helium",ok_status=[1])
    logging.info("OpenDaylight rpm is removed: %s", cloudrouter)
