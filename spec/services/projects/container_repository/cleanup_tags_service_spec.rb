# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::CleanupTagsService do
  let_it_be_with_reload(:container_repository) { create(:container_repository) }
  let_it_be(:user) { container_repository.project.owner }

  let(:params) { {} }
  let(:extra_params) { {} }
  let(:service) { described_class.new(container_repository: container_repository, current_user: user, params: params.merge(extra_params)) }

  before do
    stub_container_registry_config(enabled: true)
  end

  describe '#execute' do
    subject { service.execute }

    shared_examples 'returning error message' do |message|
      it "returns error #{message}" do
        expect(::Projects::ContainerRepository::Gitlab::CleanupTagsService).not_to receive(:new)
        expect(::Projects::ContainerRepository::ThirdParty::CleanupTagsService).not_to receive(:new)
        expect(service).not_to receive(:log_info)

        expect(subject).to eq(status: :error, message: message)
      end
    end

    shared_examples 'handling invalid regular expressions' do
      shared_examples 'handling invalid regex' do
        it_behaves_like 'returning error message', 'invalid regex'

        it 'calls error tracking service' do
          expect(::Gitlab::ErrorTracking).to receive(:log_exception).and_call_original

          subject
        end
      end

      context 'when name_regex_delete is invalid' do
        let(:extra_params) { { 'name_regex_delete' => '*test*' } }

        it_behaves_like 'handling invalid regex'
      end

      context 'when name_regex is invalid' do
        let(:extra_params) { { 'name_regex' => '*test*' } }

        it_behaves_like 'handling invalid regex'
      end

      context 'when name_regex_keep is invalid' do
        let(:extra_params) { { 'name_regex_keep' => '*test*' } }

        it_behaves_like 'handling invalid regex'
      end
    end

    shared_examples 'handling all types of container repositories' do
      shared_examples 'calling service' do |service_class, extra_log_data: {}|
        let(:service_double) { instance_double(service_class.to_s) }

        it "uses cleanup tags service #{service_class}" do
          expect(service_class).to receive(:new).with(container_repository: container_repository, current_user: user, params: params).and_return(service_double)
          expect(service_double).to receive(:execute).and_return('return value')
          expect(service).to receive(:log_info)
                               .with(
                                 {
                                   container_repository_id: container_repository.id,
                                   container_repository_path: container_repository.path,
                                   project_id: container_repository.project.id
                                 }.merge(extra_log_data))
          expect(subject).to eq('return value')
        end
      end

      context 'with a migrated repository' do
        before do
          container_repository.update_column(:migration_state, :import_done)
        end

        context 'supporting the gitlab api' do
          before do
            allow(container_repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(true)
          end

          it_behaves_like 'calling service', ::Projects::ContainerRepository::Gitlab::CleanupTagsService, extra_log_data: { gitlab_cleanup_tags_service: true }

          context 'with container_registry_new_cleanup_service disabled' do
            before do
              stub_feature_flags(container_registry_new_cleanup_service: false)
            end

            it_behaves_like 'calling service', ::Projects::ContainerRepository::ThirdParty::CleanupTagsService, extra_log_data: { third_party_cleanup_tags_service: true }
          end
        end

        context 'not supporting the gitlab api' do
          before do
            allow(container_repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(false)
          end

          it_behaves_like 'calling service', ::Projects::ContainerRepository::ThirdParty::CleanupTagsService, extra_log_data: { third_party_cleanup_tags_service: true }
        end
      end

      context 'with a non migrated repository' do
        before do
          container_repository.update_column(:migration_state, :default)
          container_repository.update!(created_at: ContainerRepository::MIGRATION_PHASE_1_ENDED_AT - 1.week)
        end

        it_behaves_like 'calling service', ::Projects::ContainerRepository::ThirdParty::CleanupTagsService, extra_log_data: { third_party_cleanup_tags_service: true }
      end
    end

    context 'with valid user' do
      it_behaves_like 'handling invalid regular expressions'
      it_behaves_like 'handling all types of container repositories'
    end

    context 'for container expiration policy' do
      let(:user) { nil }
      let(:params) { { 'container_expiration_policy' => true } }

      it_behaves_like 'handling invalid regular expressions'
      it_behaves_like 'handling all types of container repositories'
    end

    context 'with not allowed user' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'returning error message', 'access denied'
    end

    context 'with no user' do
      let(:user) { nil }

      it_behaves_like 'returning error message', 'access denied'
    end
  end
end
