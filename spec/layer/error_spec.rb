require 'spec_helper'

describe Layer::Error do
  describe ".from_response" do
    it 'should raise NotFound error when status is 404' do
      response = {status: 404}
      expect {
        raise Layer::Error.from_response(response)
      }.to raise_error(Layer::Errors::NotFound)

    end

    it "should raise BadRequest error when status is 400" do
      response = {status: 400}
      expect {
        raise Layer::Error.from_response(response)
      }.to raise_error(Layer::Errors::BadRequest)
    end

    it "should raise Conflict error when status is 409" do
      response = {status: 409}
      expect {
        raise Layer::Error.from_response(response)
      }.to raise_error(Layer::Errors::Conflict)
    end

    it "should raise ResourceDeleted error when status is 410" do
      response = {status: 410}
      expect {
        raise Layer::Error.from_response(response)
      }.to raise_error(Layer::Errors::ResourceDeleted)
    end

    (500..599).each do |error|
      it "should raise ServerError when status is #{error}" do
        response = {status: error}
        expect {
          raise Layer::Error.from_response(response)
        }.to raise_error(Layer::Errors::ServerError)
      end
    end

    it "should return Error when status isn't found/handled" do
      expect {
        raise Layer::Error.from_response({})
      }.to raise_error(Layer::Error)
    end
  end

  describe ".initialize" do
    it "should set @response instance variable" do
      begin
        raise Layer::Error.new({})
      rescue => e
        expect(e.response).to eq({})
      end
    end

    it "should build correct error message containing status & body" do
      status = '200'
      body = 'random_test_body'
      args = {
        status: status,
        body: body
      }
      error_msg = Layer::Error.new(args).send(:build_error_message)
      expect(error_msg).to include(status)
      expect(error_msg).to include(body)
    end
  end
end
