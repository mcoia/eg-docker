# Run the build scripts
apt-get update

# Install syslog-ng.
apt-get install -y --no-install-recommends syslog-ng-core

# Clean up system
apt-get clean
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*