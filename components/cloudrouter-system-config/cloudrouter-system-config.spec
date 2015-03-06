Summary: Default system configuration for CloudRouter
Name: cloudrouter-system-config
Version: 1
Release: 1
License: AGPLv3
Source0: 90-cloudrouter-default.conf
URL: https://cloudrouter.org/
BuildRequires: systemd

%description
Default system configuration for CloudRouter.

%prep
%setup -q -c -T

%install
install -dm 755 %{buildroot}/%{_sysconfdir}/sysctl.d/
install -pm 644 %{SOURCE0}  %{buildroot}/%{_sysconfdir}/sysctl.d/

%files
%defattr(-,root,root,-)
%config(noreplace) %{_sysconfdir}/sysctl.d/*

%changelog
* Fri Mar 06 2015 David Jorm <djorm@iix.net> - 1-1
- Initial release
