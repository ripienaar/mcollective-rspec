#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

describe "package agent" do
    before do
        @agent = MCTest::LocalAgentTest.new("package", :config => {:libdir => "/usr/libexec/mcollective"}).plugin
    end
    describe "#yum_clean" do
        it "should fail if /usr/bin/yum doesn't exist" do
            File.expects(:exist?).with("/usr/bin/yum").returns(false)
            result = @agent.call(:yum_clean)
            result.should be_aborted_error
        end

        it "should succeed if the agent responds to 'run' and the run method returns 0" do
            File.expects(:exist?).with("/usr/bin/yum").returns(true)
            @agent.expects(:run).with("/usr/bin/yum clean all", :stdout => :output, :chomp => true).returns(0)
            result = @agent.call(:yum_clean)
            result.should be_successful
        end

        it "should fail if the agent responds to 'run' and the run method doesn't return 0" do
            File.expects(:exist?).with("/usr/bin/yum").returns(true)
            @agent.expects(:run).with("/usr/bin/yum clean all", :stdout => :output, :chomp => true).returns(1)
            result = @agent.call(:yum_clean)
            result.should be_aborted_error
        end
    end

    describe "#apt_update" do
        it "should fail if /usr/bin/apt-get doesn't exist" do
            File.expects(:exist?).with("/usr/bin/apt-get").returns(false)
            result = @agent.call(:apt_update)
            result.should be_aborted_error
        end

        it "should succeed if the agent responds to 'run' and the run method returns 0" do
            File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
            @agent.expects(:run).with("/usr/bin/apt-get update", :stdout => :output, :chomp => true).returns(0)
            result = @agent.call(:apt_update)
            result.should be_successful
        end

        it "should fail if the agent responds to 'run' and the run method doesn't return 0" do
            File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
            @agent.expects(:run).with("/usr/bin/apt-get update", :stdout => :output, :chomp => true).returns(1)
            result = @agent.call(:apt_update)
            result.should be_aborted_error
        end
    end

    describe "#checkupdates" do
        it "should fail if neither /usr/bin/yum or /usr/bin/apt-get are present" do
            File.expects(:exist?).with("/usr/bin/yum").returns(false)
            File.expects(:exist?).with("/usr/bin/apt-get").returns(false)
            result = @agent.call(:checkupdates)
            result.should be_aborted_error
        end

        it "should call yum_checkupdates if /usr/bin/yum exists" do
            File.expects(:exist?).with("/usr/bin/yum").returns(true)
            @agent.expects(:yum_checkupdates_action).returns(true)
            result = @agent.call(:checkupdates)
            result.should be_true
        end

        it "should call apt_checkupdates if /usr/bin/apt-get exists" do
            File.expects(:exist?).with("/usr/bin/yum").returns(false)
            File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
            @agent.expects(:apt_checkupdates_action).returns(true)
            result = @agent.call(:checkupdates)
            result.should be_true
        end
    end

    describe "#yum_checkupdates" do
        it "should fail if /usr/bin/yum does not exist" do
            File.expects(:exist?).with("/usr/bin/yum").returns(false)
            result = @agent.call(:yum_checkupdates)
            result.should be_aborted_error
        end

        it "should succeed if it responds to run and there are no packages to update" do
            File.expects(:exist?).with("/usr/bin/yum").returns(true)
            @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(0)
            result = @agent.call(:yum_checkupdates)
            result.should be_successful
        end

        it "should succeed if it responds to run and there are packages to update" do
            File.expects(:exist?).with("/usr/bin/yum").returns(true)
            @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(100)
            @agent.expects(:do_yum_outdated_packages)
            result = @agent.call(:yum_checkupdates)
            result.should be_successful
        end

        it "should fail if it responds to run but returns a different exit code than 0 or 100" do
            File.expects(:exist?).with("/usr/bin/yum").returns(true)
            @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(2)
            result = @agent.call(:yum_checkupdates)
            result.should be_aborted_error
        end
    end

    describe "#apt_checkupdates" do
        it "should fail if /usr/bin/apy-get does not exist" do
            File.expects(:exist?).with("/usr/bin/apt-get").returns(false)
            result = @agent.call(:apt_checkupdates)
            result.should be_aborted_error
        end

        it "should succeed if it responds to run and returns exit code of 0" do
            @agent.stubs("reply").returns({:output => "Inst emacs23 [23.1+1-4ubuntu7] (23.1+1-4ubuntu7.1 Ubuntu:10.04/lucid-updates) []", :exitcode => 0})

            File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
            @agent.expects(:run).with("/usr/bin/apt-get --simulate dist-upgrade", :stdout => :output, :chomp => true).returns(0)

            result = @agent.call(:apt_checkupdates)
            result.should be_successful

        end

        it "should fail if it responds to 'run' but returns an error code that is not 0" do
            File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
            @agent.expects(:run).with("/usr/bin/apt-get --simulate dist-upgrade", :stdout => :output, :chomp => true).returns(1)
            result = @agent.call(:apt_checkupdates)
            result.should be_aborted_error
        end
    end

    describe "#do_pkg_action" do
        before(:all) do
            module Puppet
                class Type
                end
            end
        end

        before(:each) do
            @puppet_type = mock
            @puppet_type.stubs(:clear)
            @puppet_package = mock
        end

        describe "#puppet provider" do
            it "should use the correct provider for version 0.24" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("0.24")
                Puppet::Type.expects(:type).with(:package).twice.returns(@puppet_type)

                @puppet_type.expects(:clear)
                @puppet_type.expects(:create).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:install).returns(0)
                @puppet_package.expects(:properties).twice.returns({:ensure => :absent})
                @puppet_package.expects(:flush)

                result = @agent.call(:install, :package => "package")
                result.should be_successful
                result[:data][:output].should == 0

            end

            it "should use the correct provider for a version that is not 0.24" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("something else")
                Puppet::Type.expects(:type).with(:package).returns(@puppet_type)

                @puppet_type.expects(:new).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:install).returns(0)
                @puppet_package.expects(:properties).twice.returns({:ensure => :absent})
                @puppet_package.expects(:flush)

                result = @agent.call(:install, :package => "package")
                result.should be_successful
                result[:data][:output].should == 0

            end
        end


        describe "#install" do
            it "should install if ensure is set to absent" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("0.24")
                Puppet::Type.expects(:type).with(:package).twice.returns(@puppet_type)

                @puppet_type.expects(:clear)
                @puppet_type.expects(:create).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:install).returns(0)
                @puppet_package.expects(:properties).twice.returns({:ensure => :absent})
                @puppet_package.expects(:flush)

                result = @agent.call(:install, :package => "package")
                result.should be_successful
                result[:data][:output].should == 0

            end

            it "should not install if ensure is not set to absent" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("0.24")
                Puppet::Type.expects(:type).with(:package).twice.returns(@puppet_type)

                @puppet_type.expects(:clear)
                @puppet_type.expects(:create).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:properties).twice.returns({:ensure => :not_absent})
                @puppet_package.expects(:flush)

                result = @agent.call(:install, :package => "package")
                result.should be_successful
                result[:data][:output].should == ""
            end
        end

        describe "#update" do
            it "should update unless ensure is set to absent" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("0.24")
                Puppet::Type.expects(:type).with(:package).twice.returns(@puppet_type)

                @puppet_type.expects(:clear)
                @puppet_type.expects(:create).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:update).returns(0)
                @puppet_package.expects(:properties).twice.returns({:ensure => :not_absent})
                @puppet_package.expects(:flush)

                result = @agent.call(:update, :package => "package")
                result.should be_successful
                result[:data][:output].should == 0
            end

            it "should not update if ensure is set to absent" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("0.24")
                Puppet::Type.expects(:type).with(:package).twice.returns(@puppet_type)

                @puppet_type.expects(:clear)
                @puppet_type.expects(:create).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:properties).twice.returns({:ensure => :absent})
                @puppet_package.expects(:flush)

                result = @agent.call(:update, :package => "package")
                result.should be_successful
                result[:data][:output].should == ""
            end
        end

        describe "#uninstall" do
            it "should uninstall unless ensure is set to absent" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("0.24")
                Puppet::Type.expects(:type).with(:package).twice.returns(@puppet_type)

                @puppet_type.expects(:clear)
                @puppet_type.expects(:create).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:uninstall).returns(0)
                @puppet_package.expects(:properties).twice.returns({:ensure => :not_absent})
                @puppet_package.expects(:flush)

                result = @agent.call(:uninstall, :package => "package")
                result.should be_successful
                result[:data][:output].should == 0
            end

            it "should not uninstall if ensure is set to absent" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("0.24")
                Puppet::Type.expects(:type).with(:package).twice.returns(@puppet_type)

                @puppet_type.expects(:clear)
                @puppet_type.expects(:create).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:properties).twice.returns({:ensure => :absent})
                @puppet_package.expects(:flush)

                result = @agent.call(:uninstall, :package => "package")
                result.should be_successful
                result[:data][:output].should == ""
            end
        end

        describe "#status" do
            it "should return the status of the package" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("0.24")
                Puppet::Type.expects(:type).with(:package).twice.returns(@puppet_type)

                @puppet_type.expects(:clear)
                @puppet_type.expects(:create).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:flush).twice
                @puppet_package.expects(:properties).twice.returns("Package Status")

                result = @agent.call(:status, :package => "package")
                result.should be_successful
                result[:data][:output].should == "Package Status"
            end
        end
        describe "#purge" do
            it "should run purge on the package object" do
                @agent.expects(:require).with('puppet')

                Puppet.expects(:version).returns("0.24")
                Puppet::Type.expects(:type).with(:package).twice.returns(@puppet_type)

                @puppet_type.expects(:clear)
                @puppet_type.expects(:create).with(:name => "package").returns(@puppet_package)
                @puppet_package.expects(:provider).returns(@puppet_package)
                @puppet_package.expects(:flush)
                @puppet_package.expects(:purge).returns("Purged")
                @puppet_package.expects(:properties)

                result = @agent.call(:purge, :package => "package")
                result.should be_successful
                result[:data][:output].should == "Purged"
            end
        end
        describe "#Exceptions" do
            it "should fail if exception is raised" do
                @agent.expects(:require).raises("Exception")
                result = @agent.call(:install, :package => "package")
                result.should be_aborted_error
            end
        end
    end
    describe "#do_yum_outdated_packages" do
        it "should not do anything with obsoleted packages" do
            File.expects(:exist?).with("/usr/bin/yum").returns(true)
            @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(100)
            @agent.stubs(:reply).returns(:output => "Obsoleting")

            result = @agent.call(:yum_checkupdates)
            result.should be_successful
        end

        it "should return packages which need to be updated" do
            File.expects(:exist?).with("/usr/bin/yum").returns(true)
            @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(100)
            @agent.stubs(:reply).returns(:output => "Package version repo", :outdated_packages => "")

            result = @agent.call(:yum_checkupdates)
            result.should be_successful
        end
    end
end
