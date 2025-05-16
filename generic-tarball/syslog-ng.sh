# Run the build scripts
apt-get -qq update

# Install syslog-ng.
apt-get -qq install -y --no-install-recommends syslog-ng-core

# Clean up system
apt-get -qq clean
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
