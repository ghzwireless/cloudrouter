### SETUP

1. install autotest and [virt-test](https://github.com/autotest/virt-test)

2. download and extract the cloudrouter image

3. convert the cloudrouter image to qcow2 format.

        $ qemu-img convert -f raw -O qcow2 cloudrouter-fedora-minimal.raw cloudrouter-2-64.qcow2

4. Create a 7zip image that is the base image for tests.  Make sure the cloudrouter-1-64.qcow2 file is in the base of the 7zip archive.

        $ 7za a virt-test/shared/data/images/cloudrouter-2-64.qcow2.7z cloudrouter-2-64.qcow2

5. edit test-providers.d/cloudrouter.ini and set the full filesystem path to the cloudrouter-tests folder in the uri line.

6. run the cloudrouter tests with one or more tests.

        $ sudo ./run -t qemu -g Linux.Cloudrouter.2.x86_64 --tests "cloudrouter.baseos cloudrouter.basebird cloudrouter.basequagga cloudrouter.baseonos cloudrouter.baseopendaylight cloudrouter.basefastnetmon cloudrouter.basemininet cloudrouter.basecapstan"

Note: if running a test on centos builds you will need to run "sed -i -e 's/dnf/yum/g' cloudrouter-tests/generic/tests/*.py"
