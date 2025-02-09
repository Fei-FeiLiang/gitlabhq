# frozen_string_literal: true

module API
  class Metadata < ::API::Base
    helpers ::API::Helpers::GraphqlHelpers
    include APIGuard

    allow_access_with_scope :read_user, if: -> (request) { request.get? || request.head? }

    before { authenticate! }

    feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

    METADATA_QUERY = <<~EOF
      {
        metadata {
          version
          revision
          kas {
            enabled
            externalUrl
            version
          }
        }
      }
    EOF

    helpers do
      def run_metadata_query
        run_graphql!(
          query: METADATA_QUERY,
          context: { current_user: current_user },
          transform: ->(result) { result.dig('data', 'metadata') }
        )
      end
    end

    desc 'Get the metadata information of the GitLab instance.' do
      detail 'This feature was introduced in GitLab 15.2.'
    end
    get '/metadata' do
      run_metadata_query
    end

    # Support the deprecated `/version` route.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/366287
    desc 'Get the version information of the GitLab instance.' do
      detail 'This feature was introduced in GitLab 8.13 and deprecated in 15.5. ' \
             'We recommend you instead use the Metadata API.'
    end
    get '/version' do
      run_metadata_query
    end
  end
end
