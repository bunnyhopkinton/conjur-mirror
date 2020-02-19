module Authentication
  module OAuth

    Log = LogMessages::Authentication::OAuth
    Err = Errors::Authentication::OAuth
    # Possible Errors Raised:
    #   ProviderDiscoveryTimeout
    #   ProviderDiscoveryFailed

    DiscoverIdentityProvider = CommandClass.new(
      dependencies: {
        logger:                    Rails.logger,
        open_id_discovery_service: OpenIDConnect::Discovery::Provider::Config
      },
      inputs:       %i(provider_uri)
    ) do

      def call
        log_provider_uri
        discover_provider
      end

      private

      def log_provider_uri
        @logger.debug(Log::IdentityProviderUri.new(@provider_uri))
      end

      # returns an OpenIDConnect::Discovery::Provider::Config::Resource instance.
      # While this leaks 3rd party code into ours, the only time this Resource
      # is used is inside of FetchProviderCertificate.  This is unlikely change, and hence
      # unlikely to be a problem
      def discover_provider
        @discovered_provider = @open_id_discovery_service.discover!(@provider_uri).tap do
          @logger.debug(Log::IdentityProviderDiscoverySuccess.new)
        end
      rescue HTTPClient::ConnectTimeoutError => e
        raise_error(Err::ProviderDiscoveryTimeout, e)
      rescue => e
        raise_error(Err::ProviderDiscoveryFailed, e)
      end

      def raise_error(error_class, original_error)
        raise error_class.new(@provider_uri, original_error.inspect)
      end
    end
  end
end