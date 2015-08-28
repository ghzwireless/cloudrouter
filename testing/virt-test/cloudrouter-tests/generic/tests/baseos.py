# :difficulty: simple
# Put this file into the cloudrouter-tests/generic/tests directory and use
# ./run -t $type --tests="cloudrouter.baseos" to execute it.
import logging

def run(test, params, env):
    """
    Docstring describing template.

    Detailed description of the test:

    1) Get a living VM
    2) Establish a remote session to it
    3) Run the shell commands to check basic cloudrouter distro.

    :param test: Test object.
    :param params: Dictionary with test parameters.
    :param env: Test environment object.
    """
    vm = env.get_vm(params["main_vm"])
    vm.verify_alive()
    timeout = float(params.get("login_timeout", 240))
    session = vm.wait_for_login(timeout=timeout)
    cloudrouter = session.cmd("rpm -qa|grep cloudrouter|grep release")
    logging.info("Cloudrouter release file version: %s", cloudrouter)
    cloudrouter = session.cmd("grep cloudrouter /etc/passwd")
    logging.info("Cloudrouter user is in passwd: %s", cloudrouter)
    cloudrouter = session.cmd("grep wheel /etc/group|grep cloudrouter")
    logging.info("Cloudrouter user is in wheel: %s", cloudrouter)
