require 'spec_helper'
require 'ostruct'

describe Raptor::Protocol::HTTP::Request do
  it_should_behave_like 'Raptor::Protocol::HTTP::PDU'

  let(:url) { 'http://test.com' }
  let(:url_with_query) { 'http://test.com/?id=1&stuff=blah' }

  describe '#initialize' do
    it 'sets the instance attributes by the options' do
      options = {
          url: url,
          http_method: :get,
          http_version: '1.0',
          parameters: { 'test' => 'blah' }
      }
      r = described_class.new( options )
      r.http_method.should  == options[:http_method]
      r.http_version.should == options[:http_version]
      r.parameters.should   == options[:parameters]
    end
    it 'uses the setter methods when configuring' do
      options = { url: url, http_method: 'gEt', parameters: { 'test' => 'blah' } }
      described_class.new( options ).http_method.should == :get
    end
  end

  describe '#http_method' do
    it 'defaults to :get' do
      described_class.new( url: url ).http_method.should == :get
    end
  end

  describe '#http_version' do
    it 'defaults to 1.1' do
      described_class.new( url: url ).http_version.should == '1.1'
    end
  end

  describe '#http_method=' do
    it 'normalizes the HTTP method to a downcase symbol' do
      request = described_class.new( url: url )
      request.http_method = 'pOsT'
      request.http_method.should == :post
    end
  end

  describe '#parameters' do
    it 'defaults to an empty Hash' do
      described_class.new( url: url ).parameters.should == {}
    end

    it 'recursively forces converts keys and values to strings' do
      with_symbols = {
          test:         'blah',
          another_hash: {
              stuff: 'test'
          }
      }
      with_strings = {
          'test'         => 'blah',
          'another_hash' => {
              'stuff' => 'test'
          }
      }

      request = described_class.new( url: url )
      request.parameters = with_symbols
      request.parameters.should == with_strings
    end
  end

  describe '#query_parameters' do
    it 'decodes the URL query parameters' do
      weird_url = 'http://test.com/?first=test%3Fblah%2F&second%2F%26=blah'
      r = described_class.new( url: weird_url, http_method: :other )
      r.query_parameters.should == { 'first' => 'test?blah/', 'second/&' => 'blah' }
    end

    context 'when the request method is' do
      context 'GET' do
        context 'when no parameters have been provided as options' do
          it 'returns the query parameters as a Hash' do
            r = described_class.new( url: url_with_query, http_method: :get )
            r.query_parameters.should == { 'id' => '1', 'stuff' => 'blah' }
          end
        end
        context 'when there are parameters as options' do
          let(:parameters) { { 'id' => '2', 'stuff' => 'blah' } }

          context 'and the URL has no query parameters' do
            it 'returns the parameters from options' do
              r = described_class.new( url: url, http_method: :get, parameters: parameters )
              r.query_parameters.should == parameters
            end
          end
          context 'and the URL has query parameters' do
            it 'returns the query parameters merged with the options parameters' do
              r = described_class.new( url: url_with_query, http_method: :get, parameters: parameters )
              r.query_parameters.should == { 'id' => '1', 'stuff' => 'blah' }.merge(parameters)
            end
          end
        end
      end
      context 'other' do
        it 'returns the query parameters as a Hash' do
          r = described_class.new( url: url_with_query, http_method: :other )
          r.query_parameters.should == { 'id' => '1', 'stuff' => 'blah' }
        end
      end
    end
  end

  describe '#effective_url' do
    it 'encodes the URL query parameters' do
      r = described_class.new( url: url, parameters: { 'first' => 'test?blah/', 'second/&' => 'blah' } )
      r.effective_url.to_s.should == 'http://test.com/?first=test%3Fblah%2F&second%2F%26=blah'
    end

    context 'when the request method is' do
      context 'GET' do
        context 'when no parameters have been provided as options' do
          it 'returns the original URL' do
            r = described_class.new( url: url_with_query, http_method: :get )
            r.effective_url.to_s.should == url_with_query
          end
        end
        context 'when there are parameters as options' do
          let(:parameters) { { 'id' => '2', 'stuff' => 'blah' } }

          context 'and the URL has no query parameters' do
            it 'returns a URL with the option parameters' do
              r = described_class.new( url: url, http_method: :get, parameters: parameters )
              r.effective_url.to_s.should == "#{url}/?id=2&stuff=blah"
            end
          end
          context 'and the URL has query parameters' do
            it 'returns the query parameters merged with the options parameters' do
              r = described_class.new( url: url_with_query, http_method: :get, parameters: parameters )
              r.effective_url.to_s.should == "#{url}/?id=2&stuff=blah"
            end
          end
        end
      end
      context 'other' do
        it 'returns the original URL' do
          r = described_class.new( url: url_with_query, http_method: :other )
          r.effective_url.to_s.should == url_with_query
        end
      end
    end
  end

  describe '#effective_body' do
    context 'when no body has been provided' do
      it 'returns an empty string' do
        described_class.new( url: url ).effective_body.should == ''
      end
    end

    context 'when the request method is' do
      context 'POST' do
        context 'when no parameters have been provided as options' do
          it 'returns the original body' do
            options = {
                url: url_with_query,
                http_method: :post,
                body: 'stuff=1&blah=test'
            }
            described_class.new( options ).effective_body.should == options[:body]
          end
        end
        context 'when there are parameters as options' do
          let(:parameters) { { 'id' => '2', 'stuff' => 'blah' } }

          context 'and there is no body configured' do
            it 'returns the escaped option parameters' do
              options = {
                  url: url_with_query,
                  http_method: :post,
                  parameters: parameters
              }
              described_class.new( options ).effective_body.to_s.should ==
                  "id=2&stuff=blah"
            end
          end
          context 'and there is a body' do
            it 'returns the body parameters merged with the options parameters' do
              options = {
                  url: url_with_query,
                  http_method: :post,
                  body: 'stuff 4354%$43=$#535!35VWE g4 %yt5&stuff=1',
                  parameters: parameters
              }
              described_class.new( options ).effective_body.to_s.should ==
                  "stuff+4354%25%2443=%24%23535%2135VWE+g4+%25yt5&stuff=blah&id=2"
            end
          end
        end
      end

      context 'other' do
        it 'returns the original body' do
          options = {
              url: url_with_query,
              http_method: :other,
              body: 'stuff'
          }
          described_class.new( options ).effective_body.should == options[:body]
        end
        it 'escapes the original body' do
          options = {
              url: url_with_query,
              http_method: :other,
              body: 'stuff here #$^#46 %H# '
          }
          described_class.new( options ).effective_body.should ==
              'stuff+here+%23%24%5E%2346+%25H%23+'
        end
      end
    end
  end

  describe '#on_complete' do
    it 'adds a callback block to be passed the response' do
      request = described_class.new( url: url )

      passed_response = nil
      request.on_complete { |res| passed_response = res }

      response = Raptor::Protocol::HTTP::Response.new( url: url )
      request.handle_response( response )

      passed_response.should == response
    end

    it 'can add multiple callbacks' do
      request = described_class.new( url: url )

      passed_responses = []

      2.times do
        request.on_complete { |res| passed_responses << res }
      end

      response = Raptor::Protocol::HTTP::Response.new( url: url )
      request.handle_response( response )

      passed_responses.size.should == 2
      passed_responses.uniq.size.should == 1
      passed_responses.uniq.first.should == response
    end
  end

  describe '#on_success' do
    it 'adds a callback block to be called on a successful request' do
      request = described_class.new( url: url )

      passed_response = nil
      request.on_success { |res| passed_response = res }

      response = Raptor::Protocol::HTTP::Response.new( url: url, code: 200 )
      request.handle_response( response )

      passed_response.should == response
    end

    it 'can add multiple callbacks' do
      request = described_class.new( url: url )

      passed_responses = []

      2.times do
        request.on_success { |res| passed_responses << res }
      end

      response = Raptor::Protocol::HTTP::Response.new( url: url, code: 200 )
      request.handle_response( response )

      passed_responses.size.should == 2
      passed_responses.uniq.size.should == 1
      passed_responses.uniq.first.should == response
    end
  end

  describe '#on_failure' do
    it 'adds a callback block to be called on a failed request' do
      request = described_class.new( url: url )

      passed_response = nil
      request.on_failure { |res| passed_response = res }

      response = Raptor::Protocol::HTTP::Response.new( url: url, code: 0 )
      request.handle_response( response )

      passed_response.should == response
    end

    it 'can add multiple callbacks' do
      request = described_class.new( url: url )

      passed_responses = []

      2.times do
        request.on_failure { |res| passed_responses << res }
      end

      response = Raptor::Protocol::HTTP::Response.new( url: url, code: 0 )
      request.handle_response( response )

      passed_responses.size.should == 2
      passed_responses.uniq.size.should == 1
      passed_responses.uniq.first.should == response
    end
  end

  describe '#handle_response' do
    context 'when a response is successful' do
      let(:response) { Raptor::Protocol::HTTP::Response.new( url: url, code: 200 ) }

      it 'calls #on_complete callbacks' do
        request = described_class.new( url: url )

        passed_response = nil
        request.on_complete { |res| passed_response = res }
        request.handle_response( response )

        passed_response.should == response
      end
      it 'calls #on_success callbacks' do
        request = described_class.new( url: url )

        passed_response = nil
        request.on_success { |res| passed_response = res }
        request.handle_response( response )

        passed_response.should == response
      end
      it 'does not call #on_failure callbacks' do
        request = described_class.new( url: url )

        passed_response = nil
        request.on_failure { |res| passed_response = res }
        request.handle_response( response )

        passed_response.should be_nil
      end
    end
    context 'when a request fails' do
      let(:response) { Raptor::Protocol::HTTP::Response.new( url: url, code: 0 ) }

      it 'calls #on_complete callbacks' do
        request = described_class.new( url: url )

        passed_response = nil
        request.on_complete { |res| passed_response = res }
        request.handle_response( response )

        passed_response.should == response
      end
      it 'does not call #on_success callbacks' do
        request = described_class.new( url: url )

        passed_response = nil
        request.on_success { |res| passed_response = res }
        request.handle_response( response )

        passed_response.should be_nil
      end
      it 'calls #on_failure callbacks' do
        request = described_class.new( url: url )

        passed_response = nil
        request.on_failure { |res| passed_response = res }
        request.handle_response( response )

        passed_response.should == response
      end
    end
  end

  describe '#to_s' do
    it 'returns a String representation of the request'
  end
end
