#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../spec_helper'])

describe "puppetca agent" do
    before do
        @agent = MCollective::Test::LocalAgentTest.new("puppetca", :config => {:libdir => "/usr/libexec/mcollective"}).plugin
    end

    describe "#meta" do
        it "should have valid metadata" do
            @agent.should have_valid_metadata
        end
    end

    describe "#clean" do
        it "should remove signed certs if they exist" do
            @agent.expects(:paths_for_cert).with("certname").twice.returns({:signed => "signed", :request => "request"})
            @agent.expects(:has_cert?).with("certname").returns(true)
            File.expects(:unlink).with("signed")

            @agent.expects(:cert_waiting?).with("certname").returns(false)
            result = @agent.call(:clean, :certname => "certname")
            result.should be_successful
        end

        it "should remove unsigned certs if they exist" do
            @agent.expects(:paths_for_cert).with("certname").twice.returns({:signed => "signed", :request => "request"})
            @agent.expects(:has_cert?).with("certname").returns(false)

            @agent.expects(:cert_waiting?).with("certname").returns(true)
            File.expects(:unlink).with("request")

            result = @agent.call(:clean, :certname => "certname")
            result.should be_successful
        end

        it "should fail if there are no certs to delete" do
            @agent.expects(:paths_for_cert).with("certname").twice.returns({:signed => "signed", :request => "request"})
            @agent.expects(:has_cert?).with("certname").returns(false)
            @agent.expects(:cert_waiting?).with("certname").returns(false)

            result = @agent.call(:clean, :certname => "certname")
            result.should be_aborted_error
        end

        it "should return the message if there are no certs but msg.size is not 0" do
            @agent.expects(:paths_for_cert).with("certname").twice.returns({:signed => "signed", :request => "request"})
            @agent.expects(:has_cert?).with("certname").returns(false)
            @agent.expects(:cert_waiting?).with("certname").returns(false)
            Array.any_instance.expects(:size).returns(1)
            result = @agent.call(:clean, :certname => "certname")
            result.should be_successful
        end
    end
    describe "#revoke" do
        it "should revoke a cert" do
           @agent.expects(:run).with(" --color=none --revoke 'certname'", :stdout => :output, :chomp => true)
           result = @agent.call(:revoke, :certname => "certname")
           result.should be_successful
        end
    end

    describe "sign" do
        it "should fail if the cert has already been signed" do
            @agent.expects(:has_cert?).with("certname").returns(true)
            result = @agent.call(:sign, :certname => "certname")
            result.should be_aborted_error
        end

        it "should fail if there are no certs to sign" do
            @agent.expects(:has_cert?).with("certname").returns(false)
            @agent.expects(:cert_waiting?).with("certname").returns(false)
            result = @agent.call(:sign, :certname => "certname")
            result.should be_aborted_error
        end

        it "should sign a cert if there is one waiting" do
            @agent.expects(:has_cert?).with("certname").returns(false)
            @agent.expects(:cert_waiting?).with("certname").returns(true)
            @agent.expects(:run).with(" --color=none --sign 'certname'", :stdout => :output, :chomp => true)
            result = @agent.call(:sign, :certname => "certname")
            result.should be_successful
        end
    end

    describe "list" do
        it "should list all certs, signed and waiting" do
            Dir.expects(:entries).with("/requests").returns("requested.pem")
            Dir.expects(:entries).with("/signed").returns("signed.pem")
            result = @agent.call(:list)
            result.should be_successful
        end
    end

    describe "has_cert" do
        it "should return true if we have a signed cert matching certname" do
            @agent.stubs(:paths_for_cert).with("certname").returns({:signed => "signed", :request => "request"})
            File.expects(:exist?).with("signed").returns(true)
            File.expects(:unlink).with("signed")
            @agent.expects(:cert_waiting?).returns(false)
            result = @agent.call(:clean, :certname => "certname")
            result.should be_successful
        end
        it "should return false if we have a signed cert matching certname" do
            @agent.stubs(:paths_for_cert).with("certname").returns({:signed => "signed", :request => "request"})
            File.expects(:exist?).with("signed").returns(false)
            @agent.expects(:cert_waiting?).returns(false)
            result = @agent.call(:clean, :certname => "certname")
            result.should be_aborted_error
        end
    end

    describe "cert_waiting" do
        it "should return true if there is a signing request waiting" do
            @agent.stubs(:paths_for_cert).with("certname").returns({:signed => "signed", :request => "request"})
            @agent.expects(:has_cert?).with("certname").returns(false)
            File.expects(:exist?).with("request").returns(true)
            File.expects(:unlink).with("request")
            result = @agent.call(:clean, :certname => "certname")
            result.should be_successful
       end

        it "should return true if there is a signing request waiting" do
            @agent.stubs(:paths_for_cert).with("certname").returns({:signed => "signed", :request => "request"})
            @agent.expects(:has_cert?).with("certname").returns(false)
            File.expects(:exist?).with("request").returns(false)
            result = @agent.call(:clean, :certname => "certname")
            result.should be_aborted_error
       end
    end

    describe "paths_for_cert" do
        it "should return get paths to all files involged with a cert" do
            @agent.expects(:has_cert?).with("certname").returns(false)
            File.expects(:exist?).with("/requests/certname.pem").returns(true)
            File.expects(:unlink).with("/requests/certname.pem")
            result = @agent.call(:clean, :certname => "certname")
            result.should be_successful
        end
    end
end
