# :difficulty: simple
# Put this file into the cloudrouter-tests/generic/tests directory and use
# ./run -t $type --tests="cloudrouter.basequagga" to execute it.
import logging

def run(test, params, env):
    """
    Docstring describing template.

    Detailed description of the test:

    1) Get a living VM
    2) Establish a remote session to it
    3) Run the shell commands to check basic quagga functionality.

    :param test: Test object.
    :param params: Dictionary with test parameters.
    :param env: Test environment object.
    """
    vm = env.get_vm(params["main_vm"])
    vm.verify_alive()
    timeout = float(params.get("login_timeout", 240))
    session = vm.wait_for_login(timeout=timeout)
    cloudrouter = session.cmd("yum install -y quagga",timeout=300)
    logging.info("Install QUAGGA package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q quagga")
    logging.info("QUAGGA version: %s", cloudrouter)
    cloudrouter = session.cmd("file -E /etc/quagga/zebra.conf")
    logging.info("zebra config file exists: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl enable zebra")
    logging.info("Enable zebra service: %s", cloudrouter)
    cmd = "file -E /etc/systemd/system/multi-user.target.wants/zebra.service"
    cloudrouter = session.cmd(cmd)
    logging.info("Service enabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl start zebra")
    logging.info("Start zebra service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof zebra")
    logging.info("zebra is running on PID: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl disable zebra")
    logging.info("Disable the zebra service: %s", cloudrouter)
    cloudrouter = session.cmd(cmd,ok_status=[1])
    logging.info("Service disabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl stop zebra")
    logging.info("Stopping zebra service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof zebra",ok_status=[1])
    logging.info("zebra is not running: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -e quagga")
    logging.info("Removing the QUAGGA package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q quagga",ok_status=[1])
    logging.info("QUAGGA rpm is removed: %s", cloudrouter)
