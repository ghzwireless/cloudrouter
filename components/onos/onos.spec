%define __jar_repack 0

Name: onos
Summary: Open Network Operating System
Version: 1.3.0
Release: 1%{?dist}
Source0: http://downloads.onosproject.org/release/onos-%{version}.tar.gz
Source1: onos.service
Group: Applications/Communications
License: ASL 2.0
URL: http://www.onosproject.org
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-buildroot
%{?rhel:Requires: java-1.8.0-openjdk-devel}
%{?fedora:Requires: java-devel >= 1.8.0}
Requires(pre): shadow-utils, glibc-common
Requires(postun): shadow-utils
BuildRequires: systemd
Provides: onos

%pre
%global onos_user onos
%global onos_home /opt/%{name}

# Create onos user/group
getent passwd %{onos_user} > /dev/null \
    || useradd --system --no-create-home --home-dir %{onos_home} %{onos_user}
getent group %{onos_user} > /dev/null \
    || groupadd --system %{onos_user}

# disable debug packages and the stripping of the binaries
%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}

%description
Open Network Operating System (ONOS) provides the control plane for a software-defined network (SDN), managing network components such as switches and links, and running a variety of applications which provide communication services to end hosts and neighboring networks.

%prep
%autosetup -N -c -n %{name}

%build

%install
install -d %{buildroot}/$(dirname %{onos_home})
cp -R %{_builddir}/%{name}/%{name}-%{version} %{buildroot}/%{onos_home}
install -D %{SOURCE1} %{buildroot}/%{_unitdir}/%{name}.service

%clean
rm -rf %
 
%post
%systemd_post %{name}.service

%postun
%systemd_postun_with_restart %{name}.service

# remove installed files
rm -rf %{onos_home}

# remove onos user/group; removing the user also removes the group.
userdel %{onos_user}

%files
# ONOS uses systemd to run as user:group onos:onos
%attr(0775,onos,onos) %{onos_home}
%attr(0644,-,-) %{_unitdir}/%{name}.service

%changelog
* Tue Nov 03 2015 David Jorm <djorm@iix.net> - 1.3.0-1
- Upgrade to 1.3.0 (Drake)
* Thu Sep 03 2015 David Jorm <djorm@iix.net> - 1.2.2-1
- Upgrade to 1.2.2 (Cardinal)
* Wed Aug 05 2015 Jay Turner <jkt@iix.net> - 1.2.1-3
- Modified requires to accommodate for CentOS which does not provide java-devel
* Tue Jul 07 2015 John Siegrist <jsiegrist@iix.net> - 1.2.1-2
- Modified %postun to remove explicit groupdel call.
* Thu Jul 02 2015 John Siegrist <jsiegrist@iix.net> - 1.2.1-1
- Added dist macro to Release
* Wed Jul 01 2015 Jay Turner <jkt@iix.net> - 1.2.1-1
- Update to 1.2.1 (Cardinal)
* Tue Jun 09 2015 David Jorm - 1.2.0-1
- Upgrade to 1.2.0 (Cardinal)
* Fri Apr 17 2015 Arun Babu Neelicattu <arun.neelicattu@gmail.com> - 1.1.0-3
- Fix installation directory setup.
* Fri Apr 17 2015 David Jorm - 1.1.0-2
- Update Java dependency to 1.8
* Thu Apr 16 2015 David Jorm - 1.1.0-1
- Initial creation
