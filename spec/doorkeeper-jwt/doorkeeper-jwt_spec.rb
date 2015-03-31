require 'spec_helper'

describe Doorkeeper::JWT do
  it 'has a version number' do
    expect(Doorkeeper::JWT::VERSION).not_to be nil
  end

  describe ".generate" do
    it "creates a JWT token" do
      Doorkeeper::JWT.configure do
      end

      token = Doorkeeper::JWT.generate(nil)
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

      token = Doorkeeper::JWT.generate(nil)
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

      token = Doorkeeper::JWT.generate(nil)
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

      token = Doorkeeper::JWT.generate(nil)
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

      token = Doorkeeper::JWT.generate(nil)
      decoded_token = ::JWT.decode(token, "super secret", "HS256")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["typ"]).to eq "JWT"
      expect(decoded_token[1]["alg"]).to eq "HS256"
    end

    it "creates a signed encrypted JWT token with a custom dynamic payload" do
      Doorkeeper::JWT.configure do
        token_payload do |resource_owner_id|
          {
            foo: "bar_#{resource_owner_id}"
          }
        end
        secret_key "super secret"
        encryption_method :hs256
      end

      token = Doorkeeper::JWT.generate(1)
      decoded_token = ::JWT.decode(token, "super secret", "HS256")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar_1"
      expect(decoded_token[1]["typ"]).to eq "JWT"
      expect(decoded_token[1]["alg"]).to eq "HS256"
    end

    it "creates a signed JWT token encrypted with an RSA key from a file" do
      Doorkeeper::JWT.configure do
        token_payload do
          {
            foo: "bar"
          }
        end
        secret_key_path "spec/support/1024key.pem"
        encryption_method :rs512
      end

      token = Doorkeeper::JWT.generate(nil)
      secret_key = OpenSSL::PKey::RSA.new File.read("spec/support/1024key.pem")
      decoded_token = ::JWT.decode(token, secret_key, "RS512")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["typ"]).to eq "JWT"
      expect(decoded_token[1]["alg"]).to eq "RS512"
    end
  end
end
