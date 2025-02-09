# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PoolRepository do
  describe 'associations' do
    it { is_expected.to belong_to(:shard) }
    it { is_expected.to belong_to(:source_project) }
    it { is_expected.to have_many(:member_projects) }
  end

  describe 'validations' do
    let!(:pool_repository) { create(:pool_repository) }

    it { is_expected.to validate_presence_of(:shard) }
    it { is_expected.to validate_presence_of(:source_project) }
  end

  describe '#disk_path' do
    it 'sets the hashed disk_path' do
      pool = create(:pool_repository)

      expect(pool.disk_path).to match(%r{\A@pools/\h{2}/\h{2}/\h{64}})
    end
  end

  describe '#unlink_repository' do
    let(:pool) { create(:pool_repository, :ready) }
    let(:alternates_file) { File.join(repository_path, 'objects', 'info', 'alternates') }

    let(:repository_path) do
      Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        File.join(TestEnv.repos_path, pool.source_project.repository.relative_path)
      end
    end

    before do
      pool.link_repository(pool.source_project.repository)
    end

    context 'when the last member leaves' do
      it 'schedules pool removal' do
        expect(::ObjectPool::DestroyWorker).to receive(:perform_async).with(pool.id).and_call_original

        pool.unlink_repository(pool.source_project.repository)

        expect(File).not_to exist(alternates_file)
      end
    end

    context 'when skipping disconnect' do
      it 'does not change the alternates file' do
        before = File.read(alternates_file)
        pool.unlink_repository(pool.source_project.repository, disconnect: false)

        expect(File.read(alternates_file)).to eq(before)
      end
    end

    context 'when the second member leaves' do
      it 'does not schedule pool removal' do
        other_project = create(:project, :repository, pool_repository: pool)
        pool.link_repository(other_project.repository)

        expect(::ObjectPool::DestroyWorker).not_to receive(:perform_async).with(pool.id)

        pool.unlink_repository(pool.source_project.repository)

        expect(File).not_to exist(alternates_file)
      end
    end
  end
end
