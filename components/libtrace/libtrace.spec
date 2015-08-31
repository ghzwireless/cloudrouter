%define name libtrace
%define version 3.0.22

BuildRoot: %{_tmppath}/%{name}-%{version}-build
Summary: libtrace is a library for trace processing
License: GPL
URL: http://research.wand.net.nz/software/libtrace.php
Name: %{name}
Version: %{version}
Release: 2%{?dist}
Source: http://research.wand.net.nz/software/libtrace/%{name}-%{version}.tar.bz2
Prefix: /usr
Group: System/Libraries
BuildRequires: gcc-c++ libpcap-devel doxygen zlib-devel lzo-devel bzip2-devel ncurses-devel

%description
libtrace is a library for trace processing. It supports multiple input methods, including device capture, raw and gz-compressed trace, and sockets; and mulitple input formats, including pcap and DAG.

%package devel
Summary: libtrace development headers
Group: System/Libraries
Provides: libtrace-devel

%description devel
This package contains necessary header files for libtrace development.

%package tools
Summary: libtrace tools
Group: System Environment/Tools
Provides: libtrace-tools

%description tools
Helper utilities for use with the libtrace process library.

%prep
%setup -q

%build
./configure --prefix %{_prefix} --libdir=%{_libdir}
make %{?_smp_mflags}

%install
make DESTDIR=%{buildroot} install

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc COPYING README
%{_libdir}/*.so.*

%files devel
%defattr(-,root,root,-)
%doc COPYING
%{_includedir}/*
%{_mandir}/man3/*
%{_libdir}/libpacketdump/*.so
%{_libdir}/libpacketdump/*.protocol
%{_libdir}/*.so
%{_libdir}/*.a
%exclude %{_libdir}/*.la

%files tools
%defattr(-,root,root,-)
%doc COPYING
%{_bindir}/*
%{_mandir}/man1/*

%changelog
* Sat Aug 29 2015 John Siegrist <jsiegrist@iix.net> - 3.0.22-2
- Added the dist macro to the Release version.

* Tue Jun 02 2015 Arun Babu Neelicattu <arun.neelicattu@gmail.com> - 3.0.22-1
- Initial specfile derrived from
  http://software.opensuse.org/download.html?project=home:cdwertmann:oml&package=libtrace

