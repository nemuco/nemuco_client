require "nemuco_client/version"
require 'recursive-open-struct'
require 'oauth2'

module NemucoClient
  class API
    def initialize(opts = {})
      @cache   = opts[:cache]
      @logger  = opts[:logger]
      @version = opts[:version] || 'v1'
    end

    def lunches(opts = {})
      resp = token.get("#{path_prefix}/lunches", opts)
      parse_response(resp)
    end

    def lunch(id, opts = {})
      resp = token.get("#{path_prefix}/lunches/#{id}", opts)
      parse_response(resp)
    end

    def page_by_facebook_id(facebook_id, opts = {})
      resp = token.get("#{path_prefix}/pages/by_facebook_id/#{facebook_id}", opts)
      parse_response(resp)
    end

    private #---------------------------------------------------------------------

    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def path_prefix
      "/api/#{@version}"
    end

    def parse_response(resp)
      RecursiveOpenStruct.new({
        body: JSON.parse(resp.response.body),
        headers: resp.response.headers
      }, recurse_over_arrays: true)
    end

    def client
      OAuth2::Client.new(
        ENV['NEMUCO_CLIENT_ID'],
        ENV['NEMUCO_CLIENT_SECRET'],
        site: ENV['NEMUCO_HOST'],
        raise_errors: false
      )
    end

    def token
      if access_token = cache.read('access_token')
        logger.debug "Using access token from cache #{access_token}"
        token = OAuth2::AccessToken.new(client, access_token)
      else
        logger.debug "Obtaining new access token"
        token = client.client_credentials.get_token
        cache.write('access_token', token.token, expires_in: 1.hour)
      end

      token
    end
  end
end
