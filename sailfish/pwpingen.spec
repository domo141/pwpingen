#
# There is probably a proper way (one-command-build after git clone)
# but I could not find a way to do it. The following worked for me...

# podman run --pull=never --rm -it --privileged -v $PWD:$PWD -w $PWD \
#            -h podman-container sailfishos-platform-sdk-aarch64:latest sudo \
#            rpmbuild --build-in-place -D "%_rpmdir $PWD" -bb pwpingen.spec

# Used podman pull docker.io/coderus/sailfishos-platform-sdk-aarch64
# to get that particular container image (2021-09-02).

Name:        pwpingen
Summary:     Password and Pin Generator
Version:     1.1
Release:     1
License:     BSD-2-Clause, 0BSD, MIT
#Source0:     pwpingen.qml
#Source1:     pwpingen.py
#Source2:     pwpingen.png
#Source3:     pwpingen.desktop
Requires:    sailfishsilica-qt5 >= 0.10.9
Requires:    pyotherside-qml-plugin-python3-qt5
Requires:    libsailfishapp-launcher
BuildArch:   noarch
BuildRequires:  desktop-file-utils


%description
Derive passwords and pin codes based on key
material hashed from user input.


%prep
cat "$0"
#env
#id
#%setup -q -n %{name}-%{version}
#%setup -q
#cp $OLDPWD/pwpingen* .


%build
# could compile .py -> .pyc but in this case having .py may be more useful..

%install
set -euf
# protection around "user error" with --buildroot=$PWD (tried before
# --build-in-place) -- rpmbuild w/o sudo and container image default
# uid/gid saved me from deleting all files from current directory).
# "inverse logic" even though it is highly unlikely rm -rf fails...
test ! -f %{buildroot}/pwpingen.qml && rm -rf %{buildroot} ||
rm -rf %{buildroot}%{_datadir}
mkdir -p %{buildroot}%{_datadir}/
mkdir %{buildroot}%{_datadir}/%{name}/ \
      %{buildroot}%{_datadir}/%{name}/qml/ \
      %{buildroot}%{_datadir}/applications/ \
      %{buildroot}%{_datadir}/icons/ \
      %{buildroot}%{_datadir}/icons/hicolor/ \
      %{buildroot}%{_datadir}/icons/hicolor/86x86/ \
      %{buildroot}%{_datadir}/icons/hicolor/86x86/apps/
install -m 755 pwpingen.qml pwpingen.py %{buildroot}%{_datadir}/%{name}/qml/.
install -m 644 pwpingen.png %{buildroot}%{_datadir}/icons/hicolor/86x86/apps/.
install -m 644 pwpingen.desktop %{buildroot}%{_datadir}/applications/.

set +f
desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
   %{buildroot}%{_datadir}/applications/*.desktop


%clean
set -euf
# protection around "user error" with --buildroot=$PWD ...
test ! -f %{buildroot}/pwpingen.qml && rm -rf %{buildroot} ||
rm -rf %{buildroot}%{_datadir}


%files
%defattr(-,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
