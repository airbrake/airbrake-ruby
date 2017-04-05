require 'spec_helper'

RSpec.describe Airbrake::Config::Validator do
  subject { described_class.new(config) }

  describe "#valid_project_id?" do
    context "when project id is zero" do
      let(:config) { Airbrake::Config.new(project_id: 0) }

      it "returns false" do
        expect(subject.valid_project_id?).to be false
      end

      it "sets correct error message" do
        expect { subject.valid_project_id? }.to(
          change { subject.error_message }.to(/:project_id is required/)
        )
      end
    end

    context "when project_id is a String" do
      let(:config) { Airbrake::Config.new(project_id: '000') }

      context "and when it's zero" do
        it "returns false" do
          expect(subject.valid_project_id?).to be false
        end

        it "sets correct error message" do
          expect { subject.valid_project_id? }.
            to(
              change { subject.error_message }.to(/:project_id is required/)
            )
        end
      end

      context "and when it consists of letters" do
        let(:config) { Airbrake::Config.new(project_id: 'bingo') }

        it "returns false" do
          expect(subject.valid_project_id?).to be false
        end

        it "sets correct error message" do
          expect { subject.valid_project_id? }.to(
            change { subject.error_message }.to(/:project_id is required/)
          )
        end
      end

      context "and when it's numerical" do
        let(:config) { Airbrake::Config.new(project_id: '123') }

        it "returns true" do
          expect(subject.valid_project_id?).to be true
        end

        it "doesn't set the error message" do
          expect { subject.valid_project_id? }.not_to(change { subject.error_message })
        end
      end
    end

    context "when project id is non-zero" do
      let(:config) { Airbrake::Config.new(project_id: 123) }

      it "returns true" do
        expect(subject.valid_project_id?).to be true
      end

      it "doesn't set the error message" do
        expect { subject.valid_project_id? }.not_to(change { subject.error_message })
      end
    end
  end

  describe "#valid_project_key?" do
    context "when it's a String" do
      context "and when it's empty" do
        let(:config) { Airbrake::Config.new(project_key: '') }

        it "returns false" do
          expect(subject.valid_project_key?).to be false
        end

        it "sets correct error message" do
          expect { subject.valid_project_key? }.
            to change { subject.error_message }.
            to(/:project_key is required/)
        end
      end

      context "and when it's non-empty" do
        let(:config) { Airbrake::Config.new(project_key: '123abc') }

        it "returns true" do
          expect(subject.valid_project_key?).to be true
        end

        it "doesn't set the error message" do
          expect { subject.valid_project_key? }.not_to(change { subject.error_message })
        end
      end
    end

    context "when it's not a String" do
      let(:config) { Airbrake::Config.new(project_key: 123) }

      it "returns false" do
        expect(subject.valid_project_key?).to be false
      end

      it "sets correct error message" do
        expect { subject.valid_project_key? }.to(
          change { subject.error_message }.to(/:project_key is required/)
        )
      end
    end
  end

  describe "#valid_environment?" do
    context "when config.environment is not set" do
      let(:config) { Airbrake::Config.new }

      it "returns true" do
        expect(subject.valid_environment?).to be true
      end

      it "doesn't set the error message" do
        expect { subject.valid_environment? }.not_to(change { subject.error_message })
      end
    end

    context "when config.environment is set" do
      context "and when it is not a Symbol or String" do
        let(:config) { Airbrake::Config.new(environment: 123) }

        it "returns false" do
          expect(subject.valid_environment?).to be false
        end

        it "sets the error message" do
          expect { subject.valid_environment? }.to(
            change { subject.error_message }.
              to(/the 'environment' option must be configured with a Symbol/)
          )
        end
      end

      context "and when it is a Symbol" do
        let(:config) { Airbrake::Config.new(environment: :bingo) }

        it "returns true" do
          expect(subject.valid_environment?).to be true
        end

        it "doesn't set the error message" do
          expect { subject.valid_environment? }.not_to(change { subject.error_message })
        end
      end

      context "and when it is a String" do
        let(:config) { Airbrake::Config.new(environment: 'bingo') }

        it "returns true" do
          expect(subject.valid_environment?).to be true
        end

        it "doesn't set the error message" do
          expect { subject.valid_environment? }.not_to(change { subject.error_message })
        end
      end

      context "and when it is kind of a String" do
        let(:string_inquirer) { Class.new(String) }

        let(:config) do
          Airbrake::Config.new(environment: string_inquirer.new('bingo'))
        end

        it "returns true" do
          expect(subject.valid_environment?).to be true
        end

        it "doesn't set the error message" do
          expect { subject.valid_environment? }.not_to(change { subject.error_message })
        end
      end
    end
  end
end
