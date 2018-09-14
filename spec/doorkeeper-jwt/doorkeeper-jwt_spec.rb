require 'spec_helper'

describe Doorkeeper::JWT do
  it 'has a version number' do
    expect(Doorkeeper::JWT::VERSION).not_to be nil
  end

  describe ".generate" do
    it "creates a JWT token" do
      Doorkeeper::JWT.configure do
      end

      token = Doorkeeper::JWT.generate({})
      decoded_token = ::JWT.decode(token, nil, false)
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["token"]).to be_a(String)
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

      token = Doorkeeper::JWT.generate({})
      decoded_token = ::JWT.decode(token, nil, false)
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["alg"]).to eq "none"
    end

    it "creates a JWT token with custom dynamic headers" do
      Doorkeeper::JWT.configure do
        token_headers do |opts|
          {
            kid: opts[:application][:uid]
          }
        end
      end

      token = Doorkeeper::JWT.generate(application: { uid: "foo" })
      decoded_token = ::JWT.decode(token, nil, false)
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "none"
      expect(decoded_token[1]["kid"]).to eq "foo"
    end

    it "creates a signed JWT token" do
      Doorkeeper::JWT.configure do
        secret_key "super secret"
      end

      token = Doorkeeper::JWT.generate({})
      decoded_token = ::JWT.decode(token, "super secret", false)
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["token"]).to be_a(String)
      expect(decoded_token[1]["alg"]).to eq "none"
    end

    it "creates a signed encrypted JWT token" do
      Doorkeeper::JWT.configure do
        secret_key "super secret"
        encryption_method :hs256
      end

      token = Doorkeeper::JWT.generate({})
      algorithm = { algorithm: "HS256" }
      decoded_token = ::JWT.decode(token, "super secret", true, algorithm)
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["token"]).to be_a(String)
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

      token = Doorkeeper::JWT.generate({})
      algorithm = { algorithm: "HS256" }
      decoded_token = ::JWT.decode(token, "super secret", true, algorithm)
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["alg"]).to eq "HS256"
    end

    it "creates a signed encrypted JWT token with a custom dynamic payload" do
      Doorkeeper::JWT.configure do
        token_payload do |opts|
          {
            foo: "bar_#{opts[:resource_owner_id]}"
          }
        end
        secret_key "super secret"
        encryption_method :hs256
      end

      token = Doorkeeper::JWT.generate(resource_owner_id: 1)
      algorithm = { algorithm: "HS256" }
      decoded_token = ::JWT.decode(token, "super secret", true, algorithm)
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar_1"
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

      token = Doorkeeper::JWT.generate({})
      secret_key = OpenSSL::PKey::RSA.new File.read("spec/support/1024key.pem")
      decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "RS512")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["alg"]).to eq "RS512"
    end

    it "creates a signed JWT token encrypted with an RSA key from a string" do
      secret_key = OpenSSL::PKey::RSA.new(1024)
      Doorkeeper::JWT.configure do
        token_payload do
          {
            foo: "bar"
          }
        end
        secret_key secret_key.to_s
        encryption_method :rs512
      end

      token = Doorkeeper::JWT.generate({})
      decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "RS512")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["alg"]).to eq "RS512"
    end

    it "creates a signed JWT token encrypted with an ECDSA key from a file" do
      Doorkeeper::JWT.configure do
        token_payload do
          {
            foo: "bar"
          }
        end
        secret_key_path "spec/support/512key.pem"
        encryption_method :es512
      end

      token = Doorkeeper::JWT.generate({})
      key_file = File.read("spec/support/512key_pub.pem")
      secret_key = OpenSSL::PKey::EC.new key_file
      decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "ES512")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["alg"]).to eq "ES512"
    end

    it "creates a signed JWT token encrypted with an ECDSA key from a string" do
      secret_key = OpenSSL::PKey::EC.new("secp521r1")
      secret_key.generate_key
      public_key = OpenSSL::PKey::EC.new secret_key
      public_key.private_key = nil

      Doorkeeper::JWT.configure do
        token_payload do
          {
            foo: "bar"
          }
        end
        secret_key secret_key
        encryption_method :es512
      end

      token = Doorkeeper::JWT.generate({})
      decoded_token = ::JWT.decode(token, public_key, true, algorithm: "ES512")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["alg"]).to eq "ES512"
    end

    it "creates a signed JWT token encrypted with an app secret" do
      secret_key = OpenSSL::PKey::RSA.new(1024)
      Doorkeeper::JWT.configure do
        use_application_secret true
        token_payload do
          {
            foo: "bar"
          }
        end
        secret_key secret_key.to_s
        encryption_method :rs512
      end

      token = Doorkeeper::JWT.generate(application: { secret: secret_key })
      decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "RS512")
      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]["alg"]).to eq "RS512"
    end
  end
end
