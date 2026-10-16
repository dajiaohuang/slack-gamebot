require 'spec_helper'

describe SlackGamebot::App do
  describe '#prepare!' do
    around do |example|
      keys = %w[SLACK_API_TOKEN SLACK_CLIENT_ID SLACK_CLIENT_SECRET SLACK_RUBY_BOT_ALIASES]
      original = keys.to_h { |key| [key, ENV.fetch(key, nil)] }
      keys.each { |key| ENV.delete(key) }
      ENV['SLACK_API_TOKEN'] = 'fake-owned-token'
      example.run
    ensure
      original.each { |key, value| value ? ENV[key] = value : ENV.delete(key) }
    end

    before do
      stub_request(:post, 'https://slack.com/api/team.info').to_return(
        headers: { 'Content-Type' => 'application/json' },
        body: { ok: true, team: { id: 'TOWN', name: 'Tiny', domain: 'owned.invalid' } }.to_json
      )
    end

    it 'leaves multi-game installations without environment credentials unchanged' do
      ENV.delete('SLACK_API_TOKEN')
      described_class.new.prepare!
      expect(Game.count).to eq 0
      expect(Team.count).to eq 0
    end

    it 'creates the documented single-token team and default game' do
      described_class.new.prepare!
      team = Team.find_by(team_id: 'TOWN')
      expect(team).not_to be_nil
      expect(team.game.name).to eq 'default'
      expect(team.token).to eq 'fake-owned-token'
    end

    it 'uses the configured game and is idempotent' do
      ENV['SLACK_CLIENT_ID'] = 'fake-client'
      ENV['SLACK_CLIENT_SECRET'] = 'fake-secret'
      ENV['SLACK_RUBY_BOT_ALIASES'] = 'tiny pp'
      2.times { described_class.new.prepare! }
      expect(Game.count).to eq 1
      expect(Team.count).to eq 1
      expect(Team.first.game.client_id).to eq 'fake-client'
      expect(Team.first.game.aliases).to eq %w[tiny pp]
    end
  end
end
