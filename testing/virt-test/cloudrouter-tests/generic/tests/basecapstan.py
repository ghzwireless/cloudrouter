# :difficulty: simple
# Put this file into the cloudrouter-tests/generic/tests directory and use
# ./run -t $type --tests="cloudrouter.basecapstan" to execute it.
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
    cloudrouter = session.cmd("sudo dnf install -y capstan",timeout=300)
    logging.info("Install Capstan package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q capstan")
    logging.info("Capstan version: %s", cloudrouter)
    cloudrouter = session.cmd("capstan -h")
    logging.info("Checking Capstan help cmd", cloudrouter)
    cloudrouter = session.cmd("sudo dnf remove -y capstan") 
    logging.info("Removing the Capstan package: %s", cloudrouter)
    cloudrouter = session.cmd("rpm -q capstan",ok_status=[1])
    logging.info("Capstan rpm is removed: %s", cloudrouter)
