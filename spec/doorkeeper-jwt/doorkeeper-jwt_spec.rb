require 'spec_helper'

describe Doorkeeper::JWT do
  it 'has a version number' do
    expect(Doorkeeper::JWT::VERSION).not_to be nil
  end

  describe ".generate" do
    it "creates a JWT token" do
      Doorkeeper::JWT.configure do
      end

      token = Doorkeeper::JWT.generate
      decoded_token = ::JWT.decode(token, nil, nil)
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["token"]).to be_a(String)
      expect(decoded_token[1]["typ"]).to eq "JWT"
      expect(decoded_token[1]["alg"]).to eq "none"
    end

    it "creates a JWT token with a custom payload" do
      Doorkeeper::JWT.configure do
        token_payload do
          {
            foo: "bar"
          }
        end
      end

      token = Doorkeeper::JWT.generate
      decoded_token = ::JWT.decode(token, nil, nil)
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["typ"]).to eq "JWT"
      expect(decoded_token[1]["alg"]).to eq "none"
    end

    it "creates a signed JWT token" do
      Doorkeeper::JWT.configure do
        secret_key "super secret"
      end

      token = Doorkeeper::JWT.generate
      decoded_token = ::JWT.decode(token, "super secret", nil)
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["token"]).to be_a(String)
      expect(decoded_token[1]["typ"]).to eq "JWT"
      expect(decoded_token[1]["alg"]).to eq "none"
    end

    it "creates a signed encrypted JWT token" do
      Doorkeeper::JWT.configure do
        secret_key "super secret"
        encryption_method :hs256
      end

      token = Doorkeeper::JWT.generate
      decoded_token = ::JWT.decode(token, "super secret", "HS256")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["token"]).to be_a(String)
      expect(decoded_token[1]["typ"]).to eq "JWT"
      expect(decoded_token[1]["alg"]).to eq "HS256"
    end

    it "creates a signed encrypted JWT token with a custom payload" do
      Doorkeeper::JWT.configure do
        token_payload do
          {
            foo: "bar"
          }
        end
        secret_key "super secret"
        encryption_method :hs256
      end

      token = Doorkeeper::JWT.generate
      decoded_token = ::JWT.decode(token, "super secret", "HS256")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["typ"]).to eq "JWT"
      expect(decoded_token[1]["alg"]).to eq "HS256"
    end
  end
end
