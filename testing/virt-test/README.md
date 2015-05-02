### SETUP

1. install autotest and [virt-test](https://github.com/autotest/virt-test)

2. download and extract the cloudrouter image

3. convert the cloudrouter image to qcow2 format.

        $ qemu-img convert -f raw -O qcow2 cloudrouter-fedora-full.raw cloudrouter-1-64.qcow2

4. boot the image with virt-install or virt-manager and attach the virttest-cloud-init.iso image to the cdrom. This will configure the cloudrouter user and set both root and the cloudrouter passwords to the default password in virt-test '123456'.  The vm will auto shutdown when it is done configuring the image.

5. Create a 7zip image that is the base image for tests.  Make sure the cloudrouter-1-64.qcow2 file is in the base of the 7zip archive.

        $ 7za a virt-test/shared/data/images/cloudrouter-1-64.qcow2.7z cloudrouter-1-64.qcow2

6. edit test-providers.d/cloudrouter.ini and set the full filesystem path to the cloudrouter-tests folder in the uri line.

7. run the cloudrouter tests with one or more tests.

        $ sudo ./run -t qemu -g Linux.Cloudrouter.1.x86_64 --tests "cloudrouter.baseos cloudrouter.basebird cloudrouter.basequagga cloudrouter.baseonos cloudrouter.baseopendaylight"
