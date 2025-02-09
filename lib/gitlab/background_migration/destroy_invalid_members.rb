# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DestroyInvalidMembers < Gitlab::BackgroundMigration::BatchedMigrationJob # rubocop:disable Style/Documentation
      scope_to ->(relation) { relation.where(member_namespace_id: nil) }

      def perform
        each_sub_batch(operation_name: :delete_all) do |sub_batch|
          deleted_members_data = sub_batch.map do |m|
            { id: m.id, source_id: m.source_id, source_type: m.source_type }
          end

          deleted_count = sub_batch.delete_all

          Gitlab::AppLogger.info({ message: 'Removing invalid member records',
                                   deleted_count: deleted_count,
                                   deleted_member_data: deleted_members_data })
        end
      end
    end
  end
end
