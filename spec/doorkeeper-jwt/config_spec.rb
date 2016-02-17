require "spec_helper"

describe Doorkeeper::JWT, 'configuration' do
  subject{ Doorkeeper::JWT.configuration }

  describe 'token_payload' do
    it 'is nil by default' do
      Doorkeeper::JWT.configure do
      end

      expect(subject.token_payload).to be_a(Proc)
    end

    it 'sets the block that is accessible via authenticate_admin' do
      block = proc {}
      Doorkeeper::JWT.configure do
        token_payload &block
      end
      expect(subject.token_payload).to eq(block)
    end
  end

  describe 'encryption_method' do
    it 'defaults to nil' do
      Doorkeeper::JWT.configure do
      end
      expect(subject.encryption_method).to be_nil
    end

    it 'can change the value' do
      Doorkeeper::JWT.configure do
        encryption_method :rs512
      end
      expect(subject.encryption_method).to eq :rs512
    end
  end

  describe "use_application_secret" do
    it "defaults to false" do
      Doorkeeper::JWT.configure do
      end
      expect(subject.use_application_secret).to be false
    end

    it "changes the value of secret_key to the application's secret" do
      Doorkeeper::JWT.configure do
        use_application_secret true
      end
      expect(subject.use_application_secret).to be true
    end
  end

  describe 'secret_key' do
    it 'defaults to nil' do
      Doorkeeper::JWT.configure do
      end
      expect(subject.secret_key).to be_nil
    end

    it 'can change the value' do
      Doorkeeper::JWT.configure do
        secret_key "foo"
      end
      expect(subject.secret_key).to eq "foo"
    end
  end

  describe 'secret_key_path' do
    it 'defaults to nil' do
      Doorkeeper::JWT.configure do
      end
      expect(subject.secret_key_path).to be_nil
    end

    it 'can change the value' do
      Doorkeeper::JWT.configure do
        secret_key_path "../support/1024key.pem"
      end
      expect(subject.secret_key_path).to eq "../support/1024key.pem"
    end
  end

  it 'raises an exception when configuration is not set' do
    expect do
      Doorkeeper::JWT.configuration
    end.to raise_error Doorkeeper::JWT::MissingConfiguration
  end
end
