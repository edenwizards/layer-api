require 'spec_helper'

describe Layer::HttpClient do

  before do
    @layer = Layer::Platform::Client.new
    @client = @layer.client
    @default_headers = @client.default_layer_headers.reject{|k, v| k == 'If-None-Match'}
  end

  describe ".connection" do
    it "should use the default base url" do
      conn = @client.connection
      expect(conn.url_prefix.to_s).to eq(@client.base_url)
    end

    it "should return a connection containing default layer headers" do
      conn = @client.connection

      # Remove If-None-Match header since it's always going to be random
      # and we can't compare it
      expect(conn.headers).to include(@default_headers)
      expect(conn.headers).to include("If-None-Match")
    end

    it "should use custom api errors middleware" do
      conn = @client.connection

      api_errors = Layer::Middleware::ApiErrors
      expect(conn.builder.handlers).to include(api_errors)
    end

    it "should re-use the same connection object" do
      conn = @client.connection

      new_conn = @client.connection
      expect(conn.object_id).to eq(new_conn.object_id)
    end
  end

  describe ".run_request" do
    it "should successfully add default layer headers to request" do
      VCR.use_cassette('conversation') do
        request = @client.run_request(:get, 'users/test/blocks')
        expect(request.env.request_headers).to include(@default_headers)
        expect(request.env.request_headers).to include("If-None-Match")
      end
    end

    it "should make request to url that is supplied as param" do
      VCR.use_cassette('conversation') do
        request_url = 'users/test/blocks'
        request = @client.run_request(:get, request_url)
        request_actual = request.env.url.to_s.sub("#{@client.base_url}/", "")

        expect(request_actual).to eq (request_url)
      end
    end

    it "should use the http method that is supplied as a param" do
      VCR.use_cassette('announcement') do
        method = :post
        request = @client.run_request(method, 'announcements', announcement_params)

        expect(request.env.method).to eq(method)
      end
    end
  end

  describe ".call" do
    it "should run request & return response body" do
      VCR.use_cassette('conversation') do
        existing_conversation = @layer.create_conversation(conversation_params)
        existing_id = @layer.get_stripped_id(existing_conversation["id"])

        url = "#{@client.base_url}/conversations/#{existing_id}"
        body = @client.call(:get, url, conversation_params)

        # Compare body with expected values
        expect(body["participants"]).to match_array(conversation_params[:participants])
        expect(body["distinct"]).to eq(conversation_params[:distinct])
        expect(body["metadata"].to_json).to eq(conversation_params[:metadata].to_json)
      end
    end

    it "should run request & return nil if response has no body" do
      VCR.use_cassette('conversation') do
        existing_conversation = @layer.create_conversation(conversation_params)
        existing_conversation_id = @layer.get_stripped_id(existing_conversation["id"])

        operations = [
          {operation: "add", property: "participants", value: "user1"},
          {operation: "add", property: "participants", value: "user2"}
        ]

        response = @layer.edit_conversation(existing_conversation_id, operations)
        expect(response).to be(nil)
      end
    end
  end

  describe ".default_layer_headers" do
    it "should pass api_token into Authorization header" do
      api_token = "1234"
      layer = Layer::Platform::Client.new(api_token: api_token)

      expect(layer.client.default_layer_headers['Authorization']).to include(api_token)
    end
  end

  describe ".base_url" do
    it "should contain app_id" do
      app_id = "1234"
      layer = Layer::Platform::Client.new(app_id: app_id)
      expect(layer.client.base_url).to include(app_id)
    end
  end
end
