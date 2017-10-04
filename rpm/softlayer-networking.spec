Name: softlayer-networking		
Version: 1.0
Release: 3
Summary: cloud-init openstack softlayer networking util	

Group: System
License: MIT
URL:  https://github.com/jayninja/softlayer-networking
Source0: softlayer-networking.tar.gz

Requires: bash	

%description
cloud-init does not seem to properly handle configdrive networking. As such, I am parsing it for SL integration.

%prep
%setup -q -n softlayer-networking


%install
mkdir -p $RPM_BUILD_ROOT/etc/init.d
mkdir -p $RPM_BUILD_ROOT/bin

install -m 755 softlayer-networking $RPM_BUILD_ROOT/etc/init.d/softlayer-networking
install -m 755 softlayer.sh $RPM_BUILD_ROOT/bin/softlayer.sh
install -m 755 jq $RPM_BUILD_ROOT/bin/tmpjq

%post
chkconfig softlayer-networking on

%files
/bin/tmpjq
/bin/softlayer.sh
/etc/init.d/softlayer-networking

%changelog

