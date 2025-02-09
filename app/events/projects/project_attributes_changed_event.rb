# frozen_string_literal: true

module Projects
  class ProjectAttributesChangedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'namespace_id' => { 'type' => 'integer' },
          'root_namespace_id' => { 'type' => 'integer' },
          'attributes' => { 'type' => 'array' }
        },
        'required' => %w[project_id namespace_id root_namespace_id attributes]
      }
    end
  end
end
