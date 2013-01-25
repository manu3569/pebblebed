require 'deepstruct'

module Pebblebed
  module RSpecHelper
    def god!(options = {})
      stub_current_identity(options.merge(:id => 1, :god => true))
    end

    def user!(options = {})
      stub_current_identity(options.merge(:id => 1, :god => false))
    end

    def guest!
      stub_current_identity
    end

    def stub_current_identity(options = {})
      guest = options.empty?

      identity = nil
      unless guest
        identity = default_identity_options.merge(options)
      end

      @current_identity = DeepStruct.wrap(identity)

      checkpoint = stub(:get => DeepStruct.wrap(:identity => identity), :service_url => 'http://example.com')
      Pebblebed::Connector.any_instance.stub(:checkpoint => checkpoint)

      unless guest
        session = options.fetch(:session) { 'validsession' }
        stub_current_session session
      end
    end

    def default_identity_options
      {:realm => 'testrealm'}
    end

    def stub_current_session(session)
      app.any_instance.stub(:current_session).and_return session
    end

    def current_identity
      @current_identity
    end

    def another_identity
      id = current_identity ? (current_identity.id + 1) : 1
      DeepStruct.wrap(default_identity_options.merge(:id => id, :god => false))
    end
  end
end

