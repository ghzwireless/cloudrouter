# :difficulty: simple
# Put this file into the cloudrouter-tests/generic/tests directory and use
# ./run -t $type --tests="cloudrouter.basebird" to execute it.
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
    cloudrouter = session.cmd("yum install -y bird")
    logging.info("Install BIRD package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q bird")
    logging.info("BIRD version: %s", cloudrouter)
    cloudrouter = session.cmd("file -E /etc/bird.conf")
    logging.info("BIRD config file exists: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl enable bird")
    logging.info("Enable BIRD service: %s", cloudrouter)
    cmd = "file -E /etc/systemd/system/multi-user.target.wants/bird.service"
    cloudrouter = session.cmd(cmd)
    logging.info("Service enabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl start bird")
    logging.info("Start BIRD service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof bird")
    logging.info("BIRD is running on PID: %s", cloudrouter)
    birdcmd = "birdc -v show status|grep '0013 Daemon is up and running'"
    cloudrouter = session.cmd(birdcmd)
    logging.info("birdc cmd show daemon is running: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl disable bird")
    logging.info("Disable the BIRD service: %s", cloudrouter)
    cloudrouter = session.cmd(cmd,ok_status=[1])
    logging.info("Service disabled in systemd: %s", cloudrouter)
    cloudrouter = session.cmd("systemctl stop bird")
    logging.info("Stopping BIRD service: %s", cloudrouter)
    cloudrouter = session.cmd("pidof bird",ok_status=[1])
    logging.info("BIRD is not running: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -e bird")
    logging.info("Removing the BIRD package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q bird",ok_status=[1])
    logging.info("BIRD rpm is removed: %s", cloudrouter)
