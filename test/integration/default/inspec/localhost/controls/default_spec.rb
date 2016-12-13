#
# Copyright (c) 2014 OneHealth Solutions, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# read platform information, see https://github.com/chef/inspec/issues/1396
property = apache_info(File.dirname(__FILE__))

describe 'apache2::default' do

  it "package #{property[:apache][:package]} is installed" do
    expect(package(property[:apache][:package])).to be_installed
  end

  it "service #{property[:apache][:service_name]} is enabled and running" do
    expect(service(property[:apache][:service_name])).to be_enabled
    expect(service(property[:apache][:service_name])).to be_running
  end

  it "directory #{property[:apache][:dir]} exists and is mode 755" do
    expect(file(property[:apache][:dir])).to be_directory
    expect(file(property[:apache][:dir])).to be_mode 755
  end

  %w(sites-enabled sites-available mods-enabled mods-available conf-available conf-enabled).each do |dir|
    it "directory #{property[:apache][:dir]}/#{dir} exists and is mode 755" do
      expect(file("#{property[:apache][:dir]}/#{dir}")).to be_directory
      expect(file("#{property[:apache][:dir]}/#{dir}")).to be_mode 755
    end
  end

  it "log dir #{property[:apache][:log_dir]} exists and is mode 755" do
    expect(file(property[:apache][:log_dir])).to be_directory
    expect(file(property[:apache][:log_dir])).to be_mode 755
  end

  it "lib dir #{property[:apache][:lib_dir]} exists and is mode 755" do
    expect(file(property[:apache][:lib_dir])).to be_directory
    expect(file(property[:apache][:lib_dir])).to be_mode 755
  end

  it "docroot dir #{property[:apache][:docroot_dir]} exists and is mode 755" do
    expect(file(property[:apache][:docroot_dir])).to be_directory
    expect(file(property[:apache][:docroot_dir])).to be_mode 755
  end

  it "cgi-bin dir #{property[:apache][:cgibin_dir]} exists and is mode 755" do
    expect(file(property[:apache][:cgibin_dir])).to be_directory
    expect(file(property[:apache][:cgibin_dir])).to be_mode 755
  end

  it "default site #{property[:apache][:dir]}/sites-available/default is a file" do
    if property[:apache][:default_site_enabled]
      expect(file("#{property[:apache][:dir]}/sites-available/default.conf")).to be_file
    else
      skip('default_site_enabled is false')
    end
  end

  it "#{property[:apache][:dir]}/sites-enabled/000-default.conf" do
    if property[:apache][:default_site_enabled]
      expect(file("#{property[:apache][:dir]}/sites-enabled/000-default.conf")).to be_linked_to "#{property[:apache][:dir]}/sites-available/default.conf"
    else
      skip('default_site_enabled is false')
    end
  end

  %w(a2ensite a2dissite a2enmod a2dismod a2enconf a2disconf).each do |mod_script|
    it "cookbook script /usr/sbin/#{mod_script} exists and is executable" do
      expect(file("/usr/sbin/#{mod_script}")).to be_file
      expect(file("/usr/sbin/#{mod_script}")).to be_executable
    end
  end

  it 'apache is listening on port 80' do
    expect(port(80)).to be_listening
  end

  it "listening on port 80 is defined in #{property[:apache][:dir]}/ports.conf" do
    expect(file("#{property[:apache][:dir]}/ports.conf")).to contain(/^Listen .*[: ]80$/)
  end

  #  it 'only listens on port 443 when SSL is enabled' do
  #    unless ran_recipe?('apache2::mod_ssl')
  #      apache_configured_ports.wont_include(443)
  #    end
  #  end

  # describe file("#{property[:apache][:dir]}/conf.d/security.conf") do
  #   its(:content) { should match /^ServerTokens #{Regexp.escape(property['apache']['servertokens'])} *$/ }
  # end

  # TODO: Verify this directory does NOT exist
  # Dir["#{property[:apache][:dir]}/conf.d/*.conf"].each do |f|
  #   it "#{f} does not contain a LoadModule directive" do
  #     expect(file(f)).to_not contain 'LoadModule'
  #   end
  # end

  subject(:config) { file(property[:apache][:conf]) }
  it "#{property[:apache][:conf]} is the config file dropped by the cookbook" do
    expect(config).to be_file
    expect(config).to contain '# Generated by Chef'
    expect(config).to contain %Q(ServerRoot "#{property[:apache][:dir]}")
    expect(config).to contain 'AccessFileName .htaccess'
    expect(config).to contain 'Files ~ "^\.ht"'
    expect(config).to contain 'LogLevel warn'
    if property[:apache][:version] == '2.4'
      expect(config).to contain "IncludeOptional #{property[:apache][:dir]}/conf-enabled/*.conf"
      expect(config).to_not contain "Include #{property[:apache][:dir]}/conf.d/*.conf"
    else
      expect(config).to contain "Include #{property[:apache][:dir]}/conf-enabled/*.conf"
      expect(config).to_not contain "Include #{property[:apache][:dir]}/conf.d/*.conf"
      expect(config).to_not contain "IncludeOptional #{property[:apache][:dir]}/conf-enabled/*.conf"
    end
  end

  # let(:pre_command) { "source #{property[:apache][:dir]}/envvars" }
  it 'the apache configuration has no syntax errors' do
    expect(command("APACHE_LOG_DIR=#{property[:apache][:log_dir]} #{property[:apache][:binary]} -t").exit_status).to eq 0
  end
end
