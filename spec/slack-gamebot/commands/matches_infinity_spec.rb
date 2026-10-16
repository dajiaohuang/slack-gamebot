require 'spec_helper'

describe SlackGamebot::Commands::Matches do
  let!(:game) { Game.create!(name: 'tiny', client_id: 'fake-client', client_secret: 'fake-secret') }
  let!(:team) { Team.create!(game:, team_id: 'TOWN', token: 'fake-token', name: 'Tiny', active: false, gifs: false) }
  let!(:winner) { User.create!(team:, user_id: 'UOWN1', user_name: 'Ada') }
  let!(:loser) { User.create!(team:, user_id: 'UOWN2', user_name: 'Ben') }
  let(:app) { SlackGamebot::Server.new(team:) }
  let(:client) { app.send(:client) }
  let!(:matches) do
    Array.new(11) do |score|
      Match.lose!(team:, winners: [winner], losers: [loser], scores: [[score, 21]])
    end
  end

  ['infinity', 'INFINITY', '<@UOWN2> infinity'].each do |arguments|
    it "shows all matches for #{arguments}" do
      expect(client.web_client).not_to receive(:users_info)
      expect(message: "tiny matches #{arguments}", user: loser.user_id, channel: 'COWN').to respond_with_slack_message(
        matches.map { |match| "#{match} once" }.join("\n")
      )
    end
  end
end
