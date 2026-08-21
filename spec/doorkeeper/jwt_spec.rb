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

    it "refuses to issue an unsigned token when a secret_key is configured" do
      described_class.configure do
        secret_key "super secret"
      end

      expect { described_class.generate({}) }
        .to raise_error(Doorkeeper::JWT::SigningMethodMissing, /Refusing to issue an unsigned/)
    end

    it "refuses to issue an unsigned token when a secret_key_path is configured" do
      described_class.configure do
        secret_key_path "spec/support/1024key.pem"
      end

      expect { described_class.generate({}) }
        .to raise_error(Doorkeeper::JWT::SigningMethodMissing, /Refusing to issue an unsigned/)
    end

    it "refuses to issue an unsigned token when use_application_secret is enabled" do
      described_class.configure do
        use_application_secret true
      end

      expect { described_class.generate(application: { secret: "secret" }) }
        .to raise_error(Doorkeeper::JWT::SigningMethodMissing, /Refusing to issue an unsigned/)
    end

    it "warns when issuing an unsigned token with no signing key configured" do
      described_class.configure {}

      expect { described_class.generate({}) }
        .to output(/issuing UNSIGNED/).to_stderr
    end

    it "refuses to issue an unsigned token when the signing_method block returns nil" do
      described_class.configure do
        secret_key "super secret"
        signing_method { |_opts| nil }
      end

      expect { described_class.generate({}) }
        .to raise_error(Doorkeeper::JWT::SigningMethodMissing, /Refusing to issue an unsigned/)
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

    it "creates a signed JWT token using the deprecated encryption_method" do
      allow(Kernel).to receive(:warn)

      described_class.configure do
        token_payload do
          { foo: "bar" }
        end

        secret_key "super secret"
        encryption_method :hs256
      end

      expect(Kernel).to have_received(:warn).with(/deprecated/)

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

        secret_key_path "spec/support/2048key.pem"
        signing_method :rs512
      end

      token = described_class.generate({})
      secret_key = OpenSSL::PKey::RSA.new File.read("spec/support/2048key.pem")
      decoded_token = ::JWT.decode(token, secret_key, true, algorithm: "RS512")

      expect(decoded_token[0]).to be_a(Hash)
      expect(decoded_token[0]["foo"]).to eq "bar"
      expect(decoded_token[1]).to be_a(Hash)
      expect(decoded_token[1]["alg"]).to eq "RS512"
    end

    it "creates a signed JWT token with an RSA key from a string" do
      secret_key = OpenSSL::PKey::RSA.new(2048)

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

      public_key = OpenSSL::PKey.read(secret_key.public_to_pem)

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

    context "when signing_method and secret_key are configured with blocks" do
      let(:rsa_key) { OpenSSL::PKey::RSA.new(2048) }

      before do
        rsa_key = self.rsa_key

        described_class.configure do
          token_payload do |opts|
            { foo: "bar_#{opts[:resource_owner_id]}" }
          end

          signing_method do |opts|
            opts[:scopes].to_s.include?("admin") ? :rs512 : :hs256
          end

          secret_key do |opts|
            opts[:scopes].to_s.include?("admin") ? rsa_key : "super secret"
          end
        end
      end

      it "signs with the algorithm and key selected for the request", :aggregate_failures do
        hs_token = described_class.generate(resource_owner_id: 1, scopes: "read")
        rs_token = described_class.generate(resource_owner_id: 2, scopes: "admin")

        hs_decoded = ::JWT.decode(hs_token, "super secret", true, algorithm: "HS256")
        rs_decoded = ::JWT.decode(rs_token, rsa_key.public_key, true, algorithm: "RS512")

        expect(hs_decoded[0]["foo"]).to eq "bar_1"
        expect(hs_decoded[1]["alg"]).to eq "HS256"
        expect(rs_decoded[0]["foo"]).to eq "bar_2"
        expect(rs_decoded[1]["alg"]).to eq "RS512"
      end

      it "passes the same options to every block", :aggregate_failures do
        received = []

        described_class.configure do
          signing_method do |opts|
            received << opts
            :hs256
          end
          secret_key do |opts|
            received << opts
            "super secret"
          end
        end

        described_class.generate(resource_owner_id: 1, scopes: "read")

        expect(received).not_to be_empty
        expect(received.uniq).to eq [{ resource_owner_id: 1, scopes: "read" }]
      end
    end

    context "when secret_key_path is configured with a block" do
      before do
        described_class.configure do
          token_payload do
            { foo: "bar" }
          end

          signing_method do |opts|
            opts[:scopes] == "admin" ? :es512 : :rs512
          end

          secret_key_path do |opts|
            opts[:scopes] == "admin" ? "spec/support/512key.pem" : "spec/support/2048key.pem"
          end
        end
      end

      it "reads the key file selected for the request", :aggregate_failures do
        rs_token = described_class.generate(scopes: "read")
        es_token = described_class.generate(scopes: "admin")

        rsa_key = OpenSSL::PKey::RSA.new(File.read("spec/support/2048key.pem"))
        ec_key = OpenSSL::PKey::EC.new(File.read("spec/support/512key_pub.pem"))
        rs_decoded = ::JWT.decode(rs_token, rsa_key, true, algorithm: "RS512")
        es_decoded = ::JWT.decode(es_token, ec_key, true, algorithm: "ES512")

        expect(rs_decoded[0]["foo"]).to eq "bar"
        expect(rs_decoded[1]["alg"]).to eq "RS512"
        expect(es_decoded[0]["foo"]).to eq "bar"
        expect(es_decoded[1]["alg"]).to eq "ES512"
      end

      it "does not evaluate the secret_key block when the path takes precedence" do
        described_class.configure do
          token_payload do
            { foo: "bar" }
          end

          signing_method :rs512
          secret_key_path "spec/support/2048key.pem"
          secret_key do |_opts|
            raise "secret_key must not be resolved when secret_key_path is set"
          end
        end

        expect { described_class.generate(scopes: "read") }.not_to raise_error
      end
    end

    context "when use_application_secret used" do
      let(:secret_key) do
        OpenSSL::PKey::RSA.new(2048)
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
        OpenSSL::PKey::RSA.new(2048)
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
        OpenSSL::PKey::RSA.new(2048)
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

  describe ".signing_key_configured?" do
    it "is true when a secret_key is configured" do
      described_class.configure do
        secret_key "super secret"
      end

      expect(described_class.signing_key_configured?).to be true
    end

    it "is true when a secret_key_path is configured" do
      described_class.configure do
        secret_key_path "spec/support/1024key.pem"
      end

      expect(described_class.signing_key_configured?).to be true
    end

    it "is true when use_application_secret is enabled" do
      described_class.configure do
        use_application_secret true
      end

      expect(described_class.signing_key_configured?).to be true
    end

    it "is false when no signing key is configured" do
      described_class.configure {}

      expect(described_class.signing_key_configured?).to be false
    end
  end
end
