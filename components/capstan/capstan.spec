%define debug_package %{nil}
%define go_path %{_builddir}/go
%define go_package github.com/cloudius-systems/capstan

Summary:	Capstan, a tool for building and running your application on OSv.
Name:		capstan
Version:	0.1.8
Release:	1%{?dist}
License:	BSD
Group:		Development/Tools/Building
Source:		https://github.com/cloudius-systems/%{name}/archive/v%{version}.tar.gz
Provides:	capstan
BuildArch:	x86_64
Requires: qemu-system-x86
BuildRequires: golang git

%description
Capstan is a tool for rapidly building and running your application on OSv. Capstan is as simple and fast as using Docker for creating containers, but the result is a complete virtual machine image that will run on any hypervisor with OSv support.

%prep
%autosetup -q

%build
export GOPATH=%{go_path}
mkdir -p ${GOPATH}/src/%{go_package}
cp -R * ${GOPATH}/src/%{go_package}/.
go get %{go_package}
go build -ldflags "-X main.VERSION '%{version}-%{release}'" %{go_package}
go install %{go_package}
mkdir -p %{buildroot}/usr/bin/

%install
mkdir -p %{buildroot}/usr/bin/
install %{go_path}/bin/capstan %{buildroot}/usr/bin/%{name}

%post

%clean
rm -rf ${RPM_BUILD_ROOT}
#rm -rf %{go_path}

%files
%defattr(-,root,root,-)
%config %attr(755,root,root) /usr/bin/%{name}

%changelog
* Thu Jul 02 2015 John Siegrist <jsiegrist@iix.net> - 0.1.8-1
- Added dist macro to Release
* Sat Apr 13 2015 Arun Babu Neelicattu  <arun.neelicattu@gmail.com> - 0.1.8-1
- initial packaging
