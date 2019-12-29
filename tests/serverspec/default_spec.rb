require "spec_helper"
require "serverspec"

package = ""
service = "snmpd"
snmptrapd_service = "snmptrapd"
config_dir = "/etc/snmp"
config_mode = 600
default_user = "root"
default_group = "wheel"
ports = [161]
extra_packages = []
snmpd_user = default_user
snmpd_group = default_group
snmptrapd_user = default_user
snmptrapd_group = default_group
snmptrapd_service = "snmptrapd"

case os[:family]
when "openbsd"
  service = "netsnmpd"
  snmptrapd_service = "netsnmptrapd"
  package = "net-snmp"
  snmpd_user = "_netsnmp"
  snmpd_group = "_netsnmp"
  snmptrapd_user = snmpd_user
  snmptrapd_group = snmpd_group
when "freebsd"
  config_dir = "/usr/local/etc/snmp"
  package = "net-mgmt/net-snmp"
when "ubuntu"
  service = "snmpd"
  package = "snmpd"
  default_group = "root"
  snmpd_group = default_group
  extra_packages = ["snmp", "snmp-mibs-downloader"]
  snmptrapd_user = snmpd_user
  snmptrapd_group = snmpd_group
when "redhat"
  package = "net-snmp"
  extra_packages = ["net-snmp-utils"]
  default_group = "root"
  snmptrapd_group = default_group
  snmpd_group = default_group
end

config = "#{config_dir}/snmpd.conf"
snmptrapd_config = "#{config_dir}/snmptrapd.conf"
snmp_config = "#{config_dir}/snmp.conf"

describe package(package) do
  it { should be_installed }
end

extra_packages.each do |p|
  describe package p do
    it { should be_installed }
  end
end

describe file(config_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
end

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_mode config_mode }
  it { should be_owned_by snmpd_user }
  it { should be_grouped_into snmpd_group }
  its(:content) { should match(/Managed by ansible/) }
  its(:content) { should match(/syscontact root/) }
end

describe file(snmp_config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  its(:content) { should match(/Managed by ansible/) }
end

describe file(snmptrapd_config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by snmptrapd_user }
  it { should be_grouped_into snmptrapd_group }
  its(:content) { should match(/Managed by ansible/) }
  its(:content) { should match(/disableAuthorization yes/) }
end

case os[:family]
when "openbsd"
  describe file("/etc/rc.conf.local") do
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    it { should be_mode 644 }
    its(:content) { should match(/^#{Regexp.escape("#{service}_flags=-u _netsnmp -r -a")}/) }
    its(:content) { should match(/^#{Regexp.escape("#{snmptrapd_service}_flags=-Ls daemon")}/) }
  end
when "redhat"
  describe file("/etc/sysconfig/#{service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
    its(:content) { should match(/OPTIONS="-LS0-6d"/) }
  end

  describe file("/etc/sysconfig/#{snmptrapd_service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
    its(:content) { should match(/OPTIONS="-Ls daemon"/) }
  end
when "ubuntu"
  describe file("/etc/default/#{service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
    its(:content) { should match(/SNMPDRUN=yes/) }
  end
when "freebsd"
  describe file("/etc/rc.conf.d") do
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
  end

  describe file("/etc/rc.conf.d/#{service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
  end

  describe file("/etc/rc.conf.d/#{snmptrapd_service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
    its(:content) { should match(Regexp.escape('snmptrapd_flags="-p /var/run/snmptrapd.pid -Ls daemon"')) }
  end
end

describe service(snmptrapd_service) do
  it { should be_running }
  it { should be_enabled }
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it do
      if os[:family] == "openbsd"
        pending "due to bug in serverspec, port does not work on OpenBSD"
      end
      should be_listening
    end
  end
end

describe command "snmpwalk -v 2c -c public -Ov 127.0.0.1 sysContact" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/STRING: root/) }
end
