require 'action_dispatch/routing/route_set'

module SslRequirement
  module UrlForSecureOption
    # Add a secure option to the rewrite method.
    def url_for(options = {}, *args)
      secure = options.delete(:secure)

      # if secure && ssl check is not disabled, convert to full url with https
      if !secure.nil? && !SslRequirement.disable_ssl_check?
        if secure == true || secure == 1 || secure.to_s.downcase == "true"
          options.merge!({
            :only_path => false,
            :protocol => 'https'
          })

          # if we've been told to use different host for ssl, use it
          unless SslRequirement.ssl_host.nil?
            options.merge! :host => SslRequirement.ssl_host
          end

          # make it non-ssl and use specified options
        else
          options.merge!({
            :protocol => 'http'
          })
        end
      end

      super(options, *args)
    end
  end

  module UrlForNonSslHost
    # if full URL is requested for http and we've been told to use a
    # non-ssl host override, then use it
    def url_for(options, *args)
      if !options[:only_path] && !SslRequirement.non_ssl_host.nil?
        if !(/^https/ =~ (options[:protocol] || @request.try(:protocol)))
          options.merge! :host => SslRequirement.non_ssl_host
        end
      end
      super(options, *args)
    end
  end
end

ActionDispatch::Routing::RouteSet.send :prepend, SslRequirement::UrlForNonSslHost
ActionDispatch::Routing::RouteSet.send :prepend, SslRequirement::UrlForSecureOption
