require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe "Sidekiq Configuration" do
  it "has configured redis connection" do
    expect(Sidekiq.redis_pool).not_to be_nil
  end

  it "can enqueue jobs" do
    Sidekiq::Testing.fake! do
      expect {
        # Test enqueuing a simple job
        Sidekiq::Client.push(
          'class' => 'SampleWorker',
          'args' => ['test'],
          'queue' => 'default'
        )
      }.to change { Sidekiq::Queues['default'].size }.by(1)
    end
  end

  it "has expected queue configuration" do
    config = YAML.load_file(Rails.root.join('config', 'sidekiq.yml'), aliases: true)
    expect(config[:queues]).to include('default')
    expect(config[:queues]).to include('mailers')
    expect(config[:queues]).to include('low_priority')
  end
end
