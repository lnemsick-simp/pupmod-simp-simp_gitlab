require 'beaker-rspec'
require 'simp/beaker_helpers'
include Simp::BeakerHelpers
require 'tmpdir'
require 'pry' if ENV['PRY'] == 'yes'

$LOAD_PATH.unshift(File.expand_path('../acceptance/support',__FILE__))

require 'helpers/simp_gitlab_beaker_helpers'
require 'helpers/curl_ssl_cmd'
require 'shared_examples/gitlab_web_service'

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    else
      install_puppet
    end
  end
end

RSpec.configure do |c|
  # provide SUT variables to individual examples AND example groups
  c.include SimpGitlabBeakerHelpers::SutVariables
  c.extend SimpGitlabBeakerHelpers::SutVariables

  # ensure that environment OS is ready on each host
  fix_errata_on hosts

  # Detect cases in which no examples are executed (e.g., nodeset does not
  # have hosts with required roles)
  c.fail_if_no_examples = true

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    begin
      # Install modules and dependencies from spec/fixtures/modules
      copy_fixture_modules_to( hosts )

      # Generate and install PKI certificates on each SUT
      Dir.mktmpdir do |cert_dir|
        run_fake_pki_ca_on( default, hosts, cert_dir )
        hosts.each{ |sut| copy_pki_to( sut, cert_dir, '/etc/pki/simp-testing' )}
      end

    rescue StandardError, ScriptError => e
      if ENV['PRY']
        require 'pry'; binding.pry
      else
        raise e
      end
    end
  end
end

