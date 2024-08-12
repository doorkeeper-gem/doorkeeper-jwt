# frozen_string_literal: true

require "spec_helper"

describe Doorkeeper::JWT do
  it "has a version number" do
    expect(Doorkeeper::JWT::VERSION).not_to be nil
  end

  describe ".generate" do
    it "creates a JWT token" do
      described_class.configure {}

      token = described_class.generate({})
      decoded_token = ::JWT.decode(token, nil, false)

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["token"]).to match(/^\h{32}$/)
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "none"
    end

    it "creates a JWT token with a custom payload" do
      described_class.configure do
        token_payload do
          { foo: "bar" }
        end
      end

      token = described_class.generate({})
      decoded_token = ::JWT.decode(token, nil, false)

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "none"
    end

    it "creates a JWT token with custom dynamic headers" do
      described_class.configure do
        token_headers do |opts|
          { kid: opts[:application][:uid] }
        end
      end

      token = described_class.generate(application: { uid: "foo" })
      decoded_token = ::JWT.decode(token, nil, false)

      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "none"
      expect(decoded_token[1]["kid"]).to eq "foo"
    end

    it "creates a signed JWT token" do
      described_class.configure do
        secret_key "super secret"
      end

      token = described_class.generate({})
      decoded_token = ::JWT.decode(token, "super secret", false)

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["token"]).to be_a(String)
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "none"
    end

    it "creates a signed JWT token using hs256" do
      described_class.configure do
        secret_key "super secret"
        signing_method :hs256
      end

      token = described_class.generate({})
      algorithm = { algorithm: "HS256" }
      decoded_token = ::JWT.decode(token, "super secret", true, algorithm)

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["token"]).to be_a(String)
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "HS256"
    end

    it "creates a signed JWT token with a custom payload" do
      described_class.configure do
        token_payload do
          { foo: "bar" }
        end

        secret_key "super secret"
        signing_method :hs256
      end

      token = described_class.generate({})
      algorithm = { algorithm: "HS256" }
      decoded_token = ::JWT.decode(token, "super secret", true, algorithm)

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "HS256"
    end

    it "creates a signed JWT token using the deprecated signing_method" do
      described_class.configure do
        token_payload do
          { foo: "bar" }
        end

        secret_key "super secret"
        signing_method :hs256
      end

      token = described_class.generate({})
      algorithm = { algorithm: "HS256" }
      decoded_token = ::JWT.decode(token, "super secret", true, algorithm)

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "HS256"
    end

    it "creates a signed JWT token with a custom dynamic payload" do
      described_class.configure do
        token_payload do |opts|
          { foo: "bar_#{opts[:resource_owner_id]}" }
        end

        secret_key "super secret"
        signing_method :hs256
      end

      token = described_class.generate(resource_owner_id: 1)
      algorithm = { algorithm: "HS256" }
      decoded_token = ::JWT.decode(token, "super secret", true, algorithm)

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar_1"
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "HS256"
    end

    it "creates a signed JWT token with an RSA key from a file" do
      described_class.configure do
        token_payload do
          { foo: "bar" }
        end

        secret_key_path "spec/support/1024key.pem"
        signing_method :rs512
      end

      token = described_class.generate({})
      secret_key = OpenSSL::PKey::RSA.new File.read("spec/support/1024key.pem")
      decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "RS512")

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "RS512"
    end

    it "creates a signed JWT token with an RSA key from a string" do
      secret_key = OpenSSL::PKey::RSA.new(1024)

      described_class.configure do
        token_payload do
          { foo: "bar" }
        end

        secret_key secret_key.to_s
        signing_method :rs512
      end

      token = described_class.generate({})
      decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "RS512")

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "RS512"
    end

    it "creates a signed JWT token with an ECDSA key from a file" do
      described_class.configure do
        token_payload do
          { foo: "bar" }
        end

        secret_key_path "spec/support/512key.pem"
        signing_method :es512
      end

      token = described_class.generate({})
      key_file = File.read("spec/support/512key_pub.pem")
      secret_key = OpenSSL::PKey::EC.new key_file
      decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "ES512")

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "ES512"
    end

    it "creates a signed JWT token with an ECDSA key from a string" do
      secret_key = OpenSSL::PKey::EC.generate("secp521r1")

      public_key = OpenSSL::PKey::EC.new(secret_key)
      public_key.private_key = nil

      described_class.configure do
        token_payload do
          { foo: "bar" }
        end

        secret_key secret_key
        signing_method :es512
      end

      token = described_class.generate({})
      decoded_token = ::JWT.decode(token, public_key, true, algorithm: "ES512")

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "ES512"
    end

    context "when use_application_secret used" do
      let(:secret_key) do
        OpenSSL::PKey::RSA.new(1024)
      end

      let(:application) do
        instance_double("Doorkeeper::Application",
                        secret: Digest::SHA256.digest(secret_key.to_s),
                        plaintext_secret: secret_key,
                        secret_strategy: class_double("Doorkeeper::SecretStoring::Sha256Hash",
                                                      allows_restoring_secrets?: true))
      end

      before do
        described_class.configure do
          use_application_secret true

          token_payload do
            { foo: "bar" }
          end

          signing_method :rs512
        end
      end

      it "creates a signed JWT token with an app secret", :aggregate_failures do
        token = described_class.generate(application: application)
        decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "RS512")

        expect(decoded_token[0]).to be_a(Hash)
        expect(decoded_token[0]["foo"]).to eq "bar"
        expect(decoded_token[1]).to be_a(Hash)
        expect(decoded_token[1]["alg"]).to eq "RS512"
      end
    end

    context "when use_application_secret used and Doorkeeper version < 5.1.0" do
      let(:secret_key) do
        OpenSSL::PKey::RSA.new(1024)
      end

      let(:application) { { secret: secret_key } }

      before do
        described_class.configure do
          use_application_secret true

          token_payload do
            { foo: "bar" }
          end

          signing_method :rs512
        end
      end

      it "creates a signed JWT token with an app secret", :aggregate_failures do
        token = described_class.generate(application: application)
        decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "RS512")

        expect(decoded_token[0]).to be_a(Hash)
        expect(decoded_token[0]["foo"]).to eq "bar"
        expect(decoded_token[1]).to be_a(Hash)
        expect(decoded_token[1]["alg"]).to eq "RS512"
      end
    end

    context "when use_application_secret used" do
      let(:secret_key) do
        OpenSSL::PKey::RSA.new(1024)
      end

      let(:application) do
        instance_double("Doorkeeper::Application",
                        secret: Digest::SHA256.digest(secret_key.to_s),
                        plaintext_secret: secret_key,
                        secret_strategy: class_double("Doorkeeper::SecretStoring::Sha256Hash",
                                                      allows_restoring_secrets?: false))
      end

      before do
        described_class.configure do
          use_application_secret true

          token_payload do
            { foo: "bar" }
          end

          signing_method :rs512
        end
      end

      it "creates a signed JWT token with an app secret", :aggregate_failures do
        expect { described_class.generate(application: application) }.to(
          raise_error.with_message(/secret strategy doesn't/)
        )
      end
    end
  end
end
