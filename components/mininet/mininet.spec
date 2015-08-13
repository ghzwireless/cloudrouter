Name: mininet
Version: 2.2.1
Release: 3%{?dist}
Summary: Internet Virtualization

License:  BSD
URL: http://mininet.github.com/
Source0: https://github.com/mininet/mininet/archive/%{version}.tar.gz
Patch0: 0001-Modify-Makefile-to-work-with-rpmbuild.patch
Patch1: 0010-Modify-sys-mount.patch 

BuildRequires: python-networkx, python-devel, pyflakes, pylint, python-pep8, help2man
Requires: python-networkx, screen, psmisc, xterm, iproute, telnet, openvswitch, iperf

%description
Emulator for rapid prototyping of Software Defined Networks 
http://mininet.org

%prep
%autosetup

%build
export PYTHONPATH=%{RPM_BUILD_DIR}/%{name}-%{version}/mininet/:${PYTHONPATH}
make %{?_smp_mflags}

%install
rm -rf ${RPM_BUILD_ROOT}
make install DESTDIR=${RPM_BUILD_ROOT}
cp bin/mn ${RPM_BUILD_ROOT}/%{_bindir}
mkdir -p ${RPM_BUILD_ROOT}/%{python_sitelib}
cp -r mininet ${RPM_BUILD_ROOT}/%{python_sitelib}
cp -r examples/ ${RPM_BUILD_ROOT}/%{python_sitelib}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_bindir}/*
%{python_sitelib}/*
%doc
%{_mandir}/man*/*

%changelog
* Thu Aug 13 2015 Jay Turner <jkt@iix.net> - 2.2.1-3
- Update mountflags for /sys mount to address CR-126
* Tue Jul 07 2015 John Siegrist <john@complects.com> - 2.2.1-2
- Updated source URL.
* Mon Jul 06 2015 Jay Turner <jkt@iix.net> - 2.2.1-1
- Upgrade to 2.2.1
* Mon Jul 06 2015 Jay Turner <jkt@iix.net> - 2.2.0-2
- Copy in the examples/ directory
* Thu Jul 02 2015 John Siegrist <jsiegrist@iix.net> - 2.2.0-1
- Added dist macro to Release
* Mon Mar 09 2015 Arun Babu Neelicattu <abn@iix.net> - 2.2.0-1
- Initial mininet release for CloudRouter.
